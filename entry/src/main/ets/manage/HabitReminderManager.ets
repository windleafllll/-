import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { abilityAccessCtrl } from '@kit.AbilityKit'
import { notificationManager } from '@kit.NotificationKit'
import { calendarManager } from '@kit.CalendarKit'
import { toDoPlanDB, ToDoPlanDBInfo } from '../database/ToDoPlanDB'
import { planDB, PlanDBInfo } from '../database/PlanDB'

interface HabitProgress {
  doneMinutes: number
  doneTimes: number
}

interface ReminderErrorLike {
  code?: number
  message?: string
}

interface ReminderMapItem {
  planId: string
  reminderIds: number[]
}

interface ValidReminderCompat {
  reminderId?: number
  id?: number
  requestId?: number
}

interface PublishCandidate {
  planId: string
  triggerAt: number
  title: string
  content: string
}

interface CalendarMapItem {
  planId: string
  eventIds: number[]
}

interface YMDParts {
  year: number
  month: number
  day: number
}

function startOfDay(ts: number): number {
  const d = new Date(ts)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

function startOfWeek(ts: number): number {
  const d = new Date(ts)
  d.setHours(0, 0, 0, 0)
  const day = d.getDay()
  const diff = (day + 6) % 7
  d.setDate(d.getDate() - diff)
  return d.getTime()
}

function startOfMonth(ts: number): number {
  const d = new Date(ts)
  d.setHours(0, 0, 0, 0)
  d.setDate(1)
  return d.getTime()
}

function buildProgress(records: PlanDBInfo[]): HabitProgress {
  let minutes = 0
  let times = 0
  for (let i = 0; i < records.length; i++) {
    times += 1
    minutes += records[i].times
  }
  return { doneMinutes: minutes, doneTimes: times }
}

function buildRemainText(plan: ToDoPlanDBInfo, progress: HabitProgress): string {
  const target = plan.timess ?? 0
  const unit = plan.timesss ?? '分钟'
  if (unit === '次') {
    const remain = Math.max(0, target - progress.doneTimes)
    return `还剩 ${remain} 次未完成`
  }
  const remain = Math.max(0, target - progress.doneMinutes)
  return `还剩 ${remain} 分钟未完成`
}

class HabitReminderManager {
  private started: boolean = false
  private syncInProgress: boolean = false

  start() {
    this.trySync(false, false)
  }

  async syncNowForDebug(): Promise<string> {
    return await this.trySync(true, true)
  }

  async testStatusBarNotification(): Promise<string> {
    try {
      await notificationManager.publish({
        id: 990010,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '杨桃树',
            text: '这是一条系统通知栏测试消息',
            additionalText: '如果看到它，说明通知样式链路正常'
          }
        }
      })
      return '已发送通知栏测试消息'
    } catch (e) {
      return `通知发送失败: ${this.parseError(e as Object)}`
    }
  }

  async runDebugTest(): Promise<string> {
    if (this.syncInProgress) {
      return '当前有同步任务在执行，请稍后再试'
    }
    const granted = await this.ensureReminderPermission()
    if (!granted) {
      return '代理提醒权限未授予'
    }
    await this.forceClearAllSystemReminders()
    const validCount = await this.getValidReminderCount()
    const req = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: 10,
      title: '提醒测试',
      content: '10秒后代理提醒（可杀进程验证）'
    } as reminderAgentManager.ReminderRequest
    try {
      const id = await (reminderAgentManager.publishReminder(req) as Promise<number>)
      return `测试提醒已发布，ID=${id}（当前系统可见提醒数=${validCount}）`
    } catch (e) {
      const detail = this.parseError(e as Object)
      if (detail.includes('1700002')) {
        return `代理提醒发布失败: ${detail}（当前系统可见提醒数=${validCount}）。这通常是“系统提醒池已满”，可能被其它App占用。请到系统的“提醒/日历/智能助手/系统管理的提醒事项”里清理旧提醒，或重启手机后再试。`
      }
      return `代理提醒发布失败: ${detail}（当前系统可见提醒数=${validCount}）`
    }
  }

  async testCalendarReminder10s(): Promise<string> {
    const ok = await this.ensureCalendarPermission()
    if (!ok) {
      return '日历权限未授予'
    }
    try {
      const now = Date.now()
      const start = now + 10 * 1000
      const end = start + 30 * 60 * 1000
      const cal = await this.getDefaultCalendar()
      // 若用户已创建“养习惯”，则为每个养习惯创建 10 秒后提醒（便于你杀进程验证）
      const all = await toDoPlanDB.query()
      const habits: ToDoPlanDBInfo[] = []
      for (let i = 0; i < all.length; i++) {
        if (all[i].event === '养习惯') {
          habits.push(all[i])
        }
      }
      await this.clearAllCalendarEvents()
      const newMap: CalendarMapItem[] = []

      if (habits.length > 0) {
        for (let i = 0; i < habits.length; i++) {
          const plan = habits[i]
          const freq = plan.time ?? '每天'
          const content = await this.buildReminderContent(plan, freq, start)
          const title = `习惯提醒：${plan.title}`
          const event = {
            type: calendarManager.EventType.NORMAL,
            title: title,
            startTime: start,
            endTime: end,
            reminderTime: [0],
            description: content
          } as calendarManager.Event
          const id = await (cal.addEvent(event) as Promise<number>)
          const planId = String(plan.id ?? '')
          if (planId !== '') {
            newMap.push({ planId: planId, eventIds: [id] })
          }
        }
        this.saveCalendarMap(newMap)
        return `已创建养习惯日历提醒 ${habits.length} 条（10秒后提醒）`
      }

      // 没有养习惯时，创建通用日历提醒
      const event = {
        type: calendarManager.EventType.NORMAL,
        title: '杨桃树-日历提醒测试',
        startTime: start,
        endTime: end,
        reminderTime: [0],
        description: '10秒后触发（通过系统日历提醒）'
      } as calendarManager.Event
      const id = await (cal.addEvent(event) as Promise<number>)
      this.saveCalendarMap([{ planId: '0', eventIds: [id] }])
      return `日历测试事件已创建，eventId=${id}（10秒后提醒）`
    } catch (e) {
      return `创建日历提醒失败: ${this.parseError(e as Object)}`
    }
  }

  // 给“清理提醒池”按钮用：清理本应用创建的日历提醒事件
  async forceClearAllCalendarReminders(): Promise<string> {
    const cancelled = await this.clearAllCalendarEvents()
    return `已清理日历提醒 ${cancelled} 条`
  }

  async clearAllKnownReminders(): Promise<string> {
    const map = this.getReminderMap()
    let cancelled = 0
    for (let i = 0; i < map.length; i++) {
      const ids = map[i].reminderIds
      for (let j = 0; j < ids.length; j++) {
        try {
          await reminderAgentManager.cancelReminder(ids[j])
          cancelled += 1
        } catch (_e) {
        }
      }
    }
    this.saveReminderMap([])
    return `已清理已记录提醒 ${cancelled} 条`
  }

  async forceClearAllSystemReminders(): Promise<string> {
    let cancelled = 0
    await this.clearAllKnownReminders()
    try {
      const list = await (reminderAgentManager.getValidReminders() as Promise<ValidReminderCompat[]>)
      for (let i = 0; i < list.length; i++) {
        const rid = this.pickReminderId(list[i])
        if (rid > 0) {
          try {
            await reminderAgentManager.cancelReminder(rid)
            cancelled += 1
          } catch (_e) {
          }
        }
      }
    } catch (_e) {
    }
    // 兜底：部分机型 getValidReminders 不完整，扩大区间尝试清理
    for (let i = 1; i <= 3000; i++) {
      try {
        await reminderAgentManager.cancelReminder(i)
        cancelled += 1
      } catch (_e) {
      }
    }
    return `已强制清理系统提醒 ${cancelled} 条`
  }

  private async getValidReminderCount(): Promise<number> {
    try {
      const list = await (reminderAgentManager.getValidReminders() as Promise<ValidReminderCompat[]>)
      return list.length
    } catch (_e) {
      return -1
    }
  }

  private pickReminderId(v: ValidReminderCompat): number {
    if (v.reminderId != undefined) {
      return v.reminderId
    }
    if (v.id != undefined) {
      return v.id
    }
    if (v.requestId != undefined) {
      return v.requestId
    }
    return 0
  }

  private parseError(err: Object): string {
    const e = err as ReminderErrorLike
    const codeText = e.code != undefined ? e.code.toString() : 'unknown'
    const msgText = e.message != undefined ? e.message : 'unknown'
    return `code=${codeText}, msg=${msgText}`
  }

  private async ensureReminderPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const ctx = getContext()
      const grant = await atManager.requestPermissionsFromUser(ctx, ['ohos.permission.PUBLISH_AGENT_REMINDER'])
      const arr = grant?.authResults
      if (arr && arr.length > 0) {
        return arr[0] === 0
      }
      return true
    } catch (_e) {
      return false
    }
  }

  private async ensureCalendarPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const ctx = getContext()
      const grant = await atManager.requestPermissionsFromUser(ctx, ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'])
      const arr = grant?.authResults
      if (arr && arr.length > 0) {
        return arr[0] === 0 && arr[1] === 0
      }
      return true
    } catch (_e) {
      return false
    }
  }

  private async getDefaultCalendar(): Promise<calendarManager.Calendar> {
    const mgr = calendarManager.getCalendarManager(getContext())
    return await mgr.getCalendar()
  }

  private getCalendarMap(): CalendarMapItem[] {
    const raw = AppStorage.get('HabitCalendarMap') as string
    if (!raw) {
      return []
    }
    try {
      return JSON.parse(raw) as CalendarMapItem[]
    } catch (_e) {
      return []
    }
  }

  private saveCalendarMap(map: CalendarMapItem[]) {
    AppStorage.setOrCreate('HabitCalendarMap', JSON.stringify(map))
  }

  private async clearAllCalendarEvents(): Promise<number> {
    const ok = await this.ensureCalendarPermission()
    if (!ok) {
      return 0
    }
    const map = this.getCalendarMap()
    if (map.length === 0) {
      return 0
    }
    let cancelled = 0
    try {
      const cal = await this.getDefaultCalendar()
      for (let i = 0; i < map.length; i++) {
        const ids = map[i].eventIds
        for (let j = 0; j < ids.length; j++) {
          try {
            // SDK expects eventId:number
            await (cal.deleteEvent(ids[j]) as Promise<void>)
            cancelled += 1
          } catch (_e) {
          }
        }
      }
    } catch (_e) {
    }
    this.saveCalendarMap([])
    return cancelled
  }

  private getReminderMap(): ReminderMapItem[] {
    const raw = AppStorage.get('HabitReminderMap') as string
    if (!raw) {
      return []
    }
    try {
      return JSON.parse(raw) as ReminderMapItem[]
    } catch (_e) {
      return []
    }
  }

  private saveReminderMap(map: ReminderMapItem[]) {
    AppStorage.setOrCreate('HabitReminderMap', JSON.stringify(map))
  }

  private buildFingerprint(habits: ToDoPlanDBInfo[]): string {
    let text = ''
    for (let i = 0; i < habits.length; i++) {
      const p = habits[i]
      text += `${p.id}|${p.title}|${p.time}|${p.timess}|${p.timesss};`
    }
    return text
  }

  private async buildReminderContent(plan: ToDoPlanDBInfo, freq: string, now: number): Promise<string> {
    const rangeStart =
      freq === '每天' ? startOfDay(now) :
        (freq === '每周' ? startOfWeek(now) : startOfMonth(now))
    const records = await planDB.queryByTitleAndRange(plan.title, rangeStart, now)
    const progress = buildProgress(records)
    return buildRemainText(plan, progress)
  }

  private buildAlarmReq(title: string, content: string, daysOfWeek: number[]): reminderAgentManager.ReminderRequest {
    return {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: 18,
      minute: 0,
      second: 0,
      daysOfWeek: daysOfWeek,
      title: title,
      content: content
    } as reminderAgentManager.ReminderRequest
  }

  private buildCalendarReq(triggerAt: number, title: string, content: string): reminderAgentManager.ReminderRequest {
    const d = new Date(triggerAt)
    return {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      year: d.getFullYear(),
      month: d.getMonth() + 1,
      day: d.getDate(),
      hour: 18,
      minute: 0,
      second: 0,
      title: title,
      content: content
    } as reminderAgentManager.ReminderRequest
  }

  private monthLast3At18(year: number, monthIndex: number): number[] {
    const last = new Date(year, monthIndex + 1, 0).getDate()
    const result: number[] = []
    result.push(new Date(year, monthIndex, last - 2, 18, 0, 0, 0).getTime())
    result.push(new Date(year, monthIndex, last - 1, 18, 0, 0, 0).getTime())
    result.push(new Date(year, monthIndex, last, 18, 0, 0, 0).getTime())
    return result
  }

  private firstFutureFrom(times: number[], now: number): number {
    for (let i = 0; i < times.length; i++) {
      if (times[i] > now) {
        return times[i]
      }
    }
    return 0
  }

  private async publishReq(req: reminderAgentManager.ReminderRequest): Promise<number> {
    return await (reminderAgentManager.publishReminder(req) as Promise<number>)
  }

  private nextDailyAt18(now: number): number {
    const d = new Date(now)
    d.setHours(18, 0, 0, 0)
    if (d.getTime() <= now) {
      d.setDate(d.getDate() + 1)
    }
    return d.getTime()
  }

  private nextWeeklySatAt18(now: number): number {
    const d = new Date(now)
    d.setHours(18, 0, 0, 0)
    const day = d.getDay()
    let add = (6 - day + 7) % 7
    if (add === 0 && d.getTime() <= now) {
      add = 7
    }
    d.setDate(d.getDate() + add)
    return d.getTime()
  }

  private nextMonthlyLast3At18(now: number): number {
    const d = new Date(now)
    const y = d.getFullYear()
    const m = d.getMonth()
    const c1 = this.monthLast3At18(y, m)
    const t1 = this.firstFutureFrom(c1, now)
    if (t1 > 0) {
      return t1
    }
    const y2 = m === 11 ? y + 1 : y
    const m2 = m === 11 ? 0 : m + 1
    const c2 = this.monthLast3At18(y2, m2)
    return this.firstFutureFrom(c2, now)
  }

  private nextTriggerByFreq(freq: string, now: number): number {
    if (freq === '每天') {
      return this.nextDailyAt18(now)
    }
    if (freq === '每周') {
      return this.nextWeeklySatAt18(now)
    }
    return this.nextMonthlyLast3At18(now)
  }

  private parseYMD(ymd: string): YMDParts | null {
    if (!ymd || ymd.split('-').length !== 3) {
      return null
    }
    const parts = ymd.split('-')
    const year = Number(parts[0])
    const month = Number(parts[1])
    const day = Number(parts[2])
    if (year <= 0 || month <= 0 || day <= 0) {
      return null
    }
    const result: YMDParts = { year: year, month: month, day: day }
    return result
  }

  // 目标实现日期前一天 18:00
  private calcGoalReminderTs(targetYmd: string, now: number): number {
    const parsed = this.parseYMD(targetYmd)
    if (parsed == null) {
      return 0
    }
    const d = new Date(parsed.year, parsed.month - 1, parsed.day, 18, 0, 0, 0)
    d.setDate(d.getDate() - 1)
    const ts = d.getTime()
    if (ts <= now) {
      return 0
    }
    return ts
  }

  private isGoalDone(plan: ToDoPlanDBInfo, records: PlanDBInfo[]): boolean {
    const progress = buildProgress(records)
    const target = plan.timess ?? 0
    const unit = plan.timesss ?? '分钟'
    const done = unit === '次' ? progress.doneTimes : progress.doneMinutes
    return done >= target
  }

  private async syncSystemReminders(force: boolean, returnSummary: boolean): Promise<string> {
    // 先尝试使用日历日程提醒（系统日历负责提醒，杀进程也能触发）
    const calGranted = await this.ensureCalendarPermission()
    AppStorage.setOrCreate('HabitCalendarPermissionGranted', calGranted)
    if (!calGranted) {
      return '日历权限未授予'
    }

    const all = await toDoPlanDB.query()
    const habits: ToDoPlanDBInfo[] = []
    const goals: ToDoPlanDBInfo[] = []
    for (let i = 0; i < all.length; i++) {
      if (all[i].event === '养习惯') {
        habits.push(all[i])
      } else if (all[i].event === '定目标') {
        goals.push(all[i])
      }
    }

    // 日历提醒的内容依赖 PlanDB 的完成记录（养习惯完成进度）。
    // 为避免内容滞后，这里不做“计划未变化”的短路判断：每次同步都重建本应用的日历提醒。

    const cleared = await this.clearAllCalendarEvents()
    let success = 0
    let failed = 0
    let failReason = ''
    const now = Date.now()
    const newCalMap: CalendarMapItem[] = []

    // 创建日历事件：按“每天/每周/每月”生成下一段触发时间
    try {
      const cal = await this.getDefaultCalendar()
      for (let i = 0; i < habits.length; i++) {
        const plan = habits[i]
        const planId = String(plan.id ?? '')
        if (planId === '') {
          continue
        }

        const freq = plan.time ?? '每天'
        const rangeStart =
          freq === '每天' ? startOfDay(now) :
            (freq === '每周' ? startOfWeek(now) : startOfMonth(now))

        // 先算当前周期/当天是否已达标；达标则不创建下一次提醒
        const records = await planDB.queryByTitleAndRange(plan.title, rangeStart, now)
        const progress = buildProgress(records)
        const target = plan.timess ?? 0
        const unit = plan.timesss ?? '分钟'
        const done = unit === '次' ? progress.doneTimes : progress.doneMinutes
        if (done >= target) {
          continue
        }

        const triggerAt = this.nextTriggerByFreq(freq, now)
        if (triggerAt <= now) {
          continue
        }

        const content = buildRemainText(plan, progress)
        const title = `习惯提醒：${plan.title}`
        const start = triggerAt
        const end = start + 30 * 60 * 1000
        const event = {
          type: calendarManager.EventType.NORMAL,
          title: title,
          startTime: start,
          endTime: end,
          reminderTime: [0],
          description: content
        } as calendarManager.Event

        const id = await (cal.addEvent(event) as Promise<number>)
        newCalMap.push({ planId: planId, eventIds: [id] })
        success += 1
      }

      // 定目标：若未完成，在“实现日期前一天 18:00”提醒
      for (let i = 0; i < goals.length; i++) {
        const goal = goals[i]
        const planId = String(goal.id ?? '')
        if (planId === '') {
          continue
        }
        const targetYmd = goal.time ?? ''
        const reminderTs = this.calcGoalReminderTs(targetYmd, now)
        if (reminderTs <= 0) {
          continue
        }

        // 只统计从目标创建开始到提醒时刻的完成进度
        const rangeStart = goal.date_added ?? 0
        const records = await planDB.queryByTitleAndRange(goal.title, rangeStart, reminderTs)
        if (this.isGoalDone(goal, records)) {
          continue
        }

        const progress = buildProgress(records)
        const content = buildRemainText(goal, progress)
        const title = `定目标提醒：${goal.title}`

        const start = reminderTs
        const end = start + 30 * 60 * 1000
        const event = {
          type: calendarManager.EventType.NORMAL,
          title: title,
          startTime: start,
          endTime: end,
          reminderTime: [0],
          description: content
        } as calendarManager.Event

        const id = await (cal.addEvent(event) as Promise<number>)
        newCalMap.push({ planId: planId, eventIds: [id] })
        success += 1
      }
    } catch (e) {
      failed = 1
      failReason = this.parseError(e as Object)
    }

    this.saveCalendarMap(newCalMap)
    AppStorage.setOrCreate('HabitReminderLastSyncAt', Date.now())
    AppStorage.setOrCreate('HabitReminderLastError', failReason)

    const summary = failReason.length > 0
      ? `养习惯${habits.length}条 + 定目标${goals.length}条（日历提醒，清理${cleared}条），本次创建成功${success}条，失败${failed}条（${failReason}）`
      : `养习惯${habits.length}条 + 定目标${goals.length}条（日历提醒，清理${cleared}条），本次创建成功${success}条，失败${failed}条`
    AppStorage.setOrCreate('HabitReminderLastSyncSummary', summary)

    if (returnSummary) {
      return summary
    }
    return summary
  }

  private async trySync(force: boolean, returnSummary: boolean): Promise<string> {
    if (this.syncInProgress) {
      const text = '同步进行中，请稍后重试'
      if (returnSummary) {
        return text
      }
      return text
    }
    this.syncInProgress = true
    try {
      return await this.syncSystemReminders(force, returnSummary)
    } finally {
      this.syncInProgress = false
    }
  }
}

export const habitReminderManager = new HabitReminderManager()

