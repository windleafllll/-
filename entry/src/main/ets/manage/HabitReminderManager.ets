import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { abilityAccessCtrl, common } from '@kit.AbilityKit'
import { notificationManager } from '@kit.NotificationKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { toDoPlanDB, ToDoPlanDBInfo } from '../database/ToDoPlanDB'
import { planDB, PlanDBInfo } from '../database/PlanDB'

interface HabitProgress {
  /** Plan.times 为秒，多条累加 */
  doneSeconds: number
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
  reminderType?: number
  title?: string
  content?: string
  triggerTimeInSeconds?: number
  hour?: number
  minute?: number
  year?: number
  month?: number
  day?: number
}

/** 系统当前返回的有效代理提醒（供「我的」页列表展示） */
export interface PublishedAgentReminderItem {
  id: number
  reminderType: number
  timeSummary: string
  title: string
  content: string
}

/** loadPublishedAgentReminders 的返回结构 */
export interface PublishedAgentRemindersLoadResult {
  items: PublishedAgentReminderItem[]
  error: string
}

interface PublishCandidate {
  planId: string
  triggerAt: number
  planType: string
  title: string
  content: string
}

interface MergedPublishCandidate {
  triggerAt: number
  planIds: string[]
  planTypes: string[]
  titles: string[]
  contents: string[]
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
  let seconds = 0
  let times = 0
  for (let i = 0; i < records.length; i++) {
    times += 1
    seconds += records[i].times
  }
  return { doneSeconds: seconds, doneTimes: times }
}

function buildRemainText(plan: ToDoPlanDBInfo, progress: HabitProgress): string {
  const target = plan.timess ?? 0
  const unit = plan.timesss ?? '分钟'
  if (unit === '次') {
    const remain = Math.max(0, target - progress.doneTimes)
    return `还剩 ${remain} 次未完成`
  }
  const usedMin = Math.floor(progress.doneSeconds / 60)
  const remain = Math.max(0, target - usedMin)
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
      ringDuration: 15,
      title: '提醒测试',
      content: '10秒后代理提醒（可杀进程验证）',
      notificationId: 990011,
      slotType: notificationManager.SlotType.CONTENT_INFORMATION,
      wantAgent: {
        pkgName: 'com.example.todoplan',
        abilityName: 'EntryAbility'
      }
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

  // 按官方文档流程：定义 Timer 类型 ReminderRequest 后直接发布
  async runOfficialTimerTest10s(): Promise<string> {
    const notifyGranted = await this.ensureNotificationPermission()
    if (!notifyGranted) {
      return '通知权限未授予，已尝试打开通知设置页，请手动允许后重试'
    }
    const granted = await this.ensureReminderPermission()
    if (!granted) {
      return '代理提醒权限未授予'
    }
    const context = getContext() as common.UIAbilityContext
    const timer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      ringDuration: 15,
      title: '计时器',
      content: '计时器已结束',
      wantAgent: {
        pkgName: 'com.example.todoplan',
        abilityName: 'EntryAbility'
      },
      notificationId: 990012,
      slotType: notificationManager.SlotType.CONTENT_INFORMATION,
      triggerTimeInSeconds: 10
    } as reminderAgentManager.ReminderRequestTimer
    try {
      // keep context variable to match official pattern and avoid accidental removal
      if (!context.abilityInfo.name.length) {
      }
      const reminderId: number = await (reminderAgentManager.publishReminder(timer) as Promise<number>)
      hilog.info(0x0000, 'HabitReminder', `publish reminder result: id is ${reminderId}`)
      AppStorage.setOrCreate('TestReminderId', reminderId)
      return `已发布代理提醒，ID=${reminderId}，10秒后触发`
    } catch (e) {
      return `代理提醒发布失败: ${this.parseError(e as Object)}`
    }
  }

  async clearAllAgentRemindersForTest(): Promise<string> {
    const granted = await this.ensureReminderPermission()
    if (!granted) {
      return '代理提醒权限未授予'
    }
    try {
      await reminderAgentManager.cancelAllReminders()
      AppStorage.setOrCreate('TestReminderId', 0)
      return '已清空本应用代理提醒'
    } catch (e) {
      return `清空代理提醒失败: ${this.parseError(e as Object)}`
    }
  }

  async inspectValidAgentReminders(): Promise<string> {
    try {
      // 先执行一次同步，确保查看结果与当前计划状态一致
      await this.trySync(true, false)
      const list = await (reminderAgentManager.getValidReminders() as Promise<ValidReminderCompat[]>)
      if (list.length == 0) {
        return '当前无有效代理提醒'
      }
      let text = `有效代理提醒 ${list.length} 条`
      const show = list.length > 3 ? 3 : list.length
      for (let i = 0; i < show; i++) {
        const r = list[i]
        const rid = this.pickReminderId(r)
        const t = r.title ?? '无标题'
        const c = r.content ?? ''
        const typeText = `${r.reminderType ?? -1}`
        const timeText = this.formatReminderTimeSummary(r)
        text += `\n#${i + 1} id=${rid} type=${typeText} ${timeText}\n${t} ${c}`
      }
      if (list.length > show) {
        text += `\n...其余 ${list.length - show} 条省略`
      }
      return text
    } catch (e) {
      return `查询代理提醒失败: ${this.parseError(e as Object)}`
    }
  }

  /**
   * 与当前计划同步后，拉取系统侧全部有效代理提醒（getValidReminders），用于界面列表。
   */
  async loadPublishedAgentReminders(): Promise<PublishedAgentRemindersLoadResult> {
    try {
      await this.trySync(true, false)
      const list = await (reminderAgentManager.getValidReminders() as Promise<ValidReminderCompat[]>)
      const items: PublishedAgentReminderItem[] = []
      for (let i = 0; i < list.length; i++) {
        const r = list[i]
        const row: PublishedAgentReminderItem = {
          id: this.pickReminderId(r),
          reminderType: r.reminderType ?? -1,
          timeSummary: this.formatReminderTimeSummary(r),
          title: r.title ?? '无标题',
          content: r.content ?? ''
        }
        items.push(row)
      }
      const ok: PublishedAgentRemindersLoadResult = { items: items, error: '' }
      return ok
    } catch (e) {
      const fail: PublishedAgentRemindersLoadResult = {
        items: [],
        error: this.parseError(e as Object)
      }
      return fail
    }
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

  private pad2(n: number): string {
    return n < 10 ? `0${n}` : `${n}`
  }

  /** 将秒数拆成天/时/分/秒，为 0 的单位不展示；全为 0 时显示「0秒」 */
  private formatSecondsAsDayHourMinuteSecond(totalSeconds: number): string {
    let t = Math.floor(totalSeconds)
    if (t < 0) {
      t = 0
    }
    const d = Math.floor(t / 86400)
    const h = Math.floor((t % 86400) / 3600)
    const m = Math.floor((t % 3600) / 60)
    const s = t % 60
    let body = ''
    if (d > 0) {
      body += `${d}天`
    }
    if (h > 0) {
      body += `${h}时`
    }
    if (m > 0) {
      body += `${m}分`
    }
    if (s > 0) {
      body += `${s}秒`
    }
    if (body == '') {
      body = '0秒'
    }
    return `倒计时 ${body}`
  }

  private formatReminderTimeSummary(r: ValidReminderCompat): string {
    if (r.triggerTimeInSeconds != undefined) {
      return this.formatSecondsAsDayHourMinuteSecond(r.triggerTimeInSeconds)
    }
    if (r.hour != undefined && r.minute != undefined) {
      return `时刻 ${this.pad2(r.hour)}:${this.pad2(r.minute)}`
    }
    if (r.year != undefined && r.month != undefined && r.day != undefined) {
      return `日期 ${r.year}-${this.pad2(r.month)}-${this.pad2(r.day)}`
    }
    return '时间未知'
  }

  private parseError(err: Object): string {
    const e = err as ReminderErrorLike
    const codeText = e.code != undefined ? e.code.toString() : 'unknown'
    const msgText = e.message != undefined ? e.message : 'unknown'
    return `code=${codeText}, msg=${msgText}`
  }

  private pushMergedCandidate(list: MergedPublishCandidate[], c: PublishCandidate) {
    for (let i = 0; i < list.length; i++) {
      if (list[i].triggerAt === c.triggerAt) {
        list[i].planIds.push(c.planId)
        list[i].planTypes.push(c.planType)
        list[i].titles.push(c.title)
        list[i].contents.push(c.content)
        return
      }
    }
    list.push({
      triggerAt: c.triggerAt,
      planIds: [c.planId],
      planTypes: [c.planType],
      titles: [c.title],
      contents: [c.content]
    })
  }

  private upsertReminderMapItem(map: ReminderMapItem[], planId: string, reminderId: number) {
    for (let i = 0; i < map.length; i++) {
      if (map[i].planId === planId) {
        map[i].reminderIds.push(reminderId)
        return
      }
    }
    map.push({ planId: planId, reminderIds: [reminderId] })
  }

  private buildMergedContent(titles: string[]): string {
    if (titles.length == 0) {
      return '请按时完成计划'
    }
    if (titles.length == 1) {
      return `请按时完成：${titles[0]}`
    }
    const maxShow = titles.length > 6 ? 6 : titles.length
    let text = '请按时完成：'
    for (let i = 0; i < maxShow; i++) {
      if (i > 0) {
        text += '、'
      }
      text += titles[i]
    }
    if (titles.length > maxShow) {
      text += ` 等${titles.length}项`
    }
    return text
  }

  private allSameType(types: string[]): boolean {
    if (types.length <= 1) {
      return true
    }
    const first = types[0]
    for (let i = 1; i < types.length; i++) {
      if (types[i] != first) {
        return false
      }
    }
    return true
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

  private async ensureNotificationPermission(): Promise<boolean> {
    try {
      const ctx = getContext() as common.UIAbilityContext
      await notificationManager.requestEnableNotification(ctx)
      return true
    } catch (_e) {
      try {
        const ctx = getContext() as common.UIAbilityContext
        notificationManager.openNotificationSettings(ctx)
      } catch (_) {
      }
      return false
    }
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

  private countHabitGoalSameTitle(title: string, habitGoalAll: ToDoPlanDBInfo[]): number {
    let n = 0
    for (let i = 0; i < habitGoalAll.length; i++) {
      if (habitGoalAll[i].title === title) {
        n++
      }
    }
    return n
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

  // 使用与测试按钮一致的 Timer 类型发布方式
  private buildTimerReqByTrigger(triggerAt: number, now: number, title: string, content: string,
    notificationId: number): reminderAgentManager.ReminderRequestTimer {
    let seconds = Math.ceil((triggerAt - now) / 1000)
    if (seconds < 1) {
      seconds = 1
    }
    return {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: seconds,
      ringDuration: 15,
      title: title,
      content: content,
      wantAgent: {
        pkgName: 'com.example.todoplan',
        abilityName: 'EntryAbility'
      },
      notificationId: notificationId,
      slotType: notificationManager.SlotType.CONTENT_INFORMATION
    } as reminderAgentManager.ReminderRequestTimer
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
    if (unit === '次') {
      return progress.doneTimes >= target
    }
    return progress.doneSeconds >= target * 60
  }

  private async syncSystemReminders(force: boolean, returnSummary: boolean): Promise<string> {
    // 改回代理提醒：由系统代理，应用退后台/进程结束后仍可触发
    const notifyGranted = await this.ensureNotificationPermission()
    AppStorage.setOrCreate('HabitNotificationPermissionGranted', notifyGranted)
    if (!notifyGranted) {
      return '通知权限未授予'
    }
    const granted = await this.ensureReminderPermission()
    AppStorage.setOrCreate('HabitReminderPermissionGranted', granted)
    if (!granted) {
      return '代理提醒权限未授予'
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
    const habitGoalAll: ToDoPlanDBInfo[] = []
    for (let i = 0; i < habits.length; i++) {
      habitGoalAll.push(habits[i])
    }
    for (let i = 0; i < goals.length; i++) {
      habitGoalAll.push(goals[i])
    }

    // 代理提醒内容依赖 PlanDB 的完成记录；每次同步全量重建，保证内容新鲜
    let cleared = 0
    try {
      await reminderAgentManager.cancelAllReminders()
      cleared = await this.getValidReminderCount()
    } catch (_e) {
      // 部分机型可能不支持一次性清理，回退到已记录提醒清理
      await this.clearAllKnownReminders()
    }
    this.saveReminderMap([])
    let success = 0
    let failed = 0
    let failReason = ''
    const now = Date.now()
    const newReminderMap: ReminderMapItem[] = []
    const publishCandidates: PublishCandidate[] = []

    // 创建代理提醒：养习惯按下一个触发点提醒，定目标按目标日前一天18:00提醒
    try {
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
        const allowLegacy = this.countHabitGoalSameTitle(plan.title, habitGoalAll) <= 1
        const records =
          await planDB.queryRecordsForPlan(plan.id as number, plan.title, allowLegacy, rangeStart, now)
        const progress = buildProgress(records)
        const target = plan.timess ?? 0
        const unit = plan.timesss ?? '分钟'
        const reached =
          unit === '次' ? progress.doneTimes >= target : progress.doneSeconds >= target * 60
        // 仅当目标值有效(>0)时才判定“已完成即不提醒”
        if (target > 0 && reached) {
          continue
        }

        const triggerAt = this.nextTriggerByFreq(freq, now)
        if (triggerAt <= now) {
          continue
        }

        const content = buildRemainText(plan, progress)
        publishCandidates.push({
          planId: planId,
          triggerAt: triggerAt,
          planType: 'habit',
          title: plan.title,
          content: content
        })
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
        const allowLegacyGoal = this.countHabitGoalSameTitle(goal.title, habitGoalAll) <= 1
        const records =
          await planDB.queryRecordsForPlan(goal.id as number, goal.title, allowLegacyGoal, rangeStart, reminderTs)
        const goalTarget = goal.timess ?? 0
        // 仅当目标值有效(>0)时才判定“已完成即不提醒”
        if (goalTarget > 0 && this.isGoalDone(goal, records)) {
          continue
        }

        const progress = buildProgress(records)
        const content = buildRemainText(goal, progress)
        publishCandidates.push({
          planId: planId,
          triggerAt: reminderTs,
          planType: 'goal',
          title: goal.title,
          content: content
        })
      }

      // 同一天同一时刻的代理提醒合并成一条发布
      const mergedList: MergedPublishCandidate[] = []
      for (let i = 0; i < publishCandidates.length; i++) {
        this.pushMergedCandidate(mergedList, publishCandidates[i])
      }

      for (let i = 0; i < mergedList.length; i++) {
        const merged = mergedList[i]
        let title = `计划提醒（${merged.titles.length}项）`
        if (merged.titles.length == 1) {
          const type = merged.planTypes[0]
          if (type == 'habit') {
            title = `养习惯：${merged.titles[0]}`
          } else if (type == 'goal') {
            title = `定目标：${merged.titles[0]}`
          } else {
            title = `计划提醒：${merged.titles[0]}`
          }
        } else if (this.allSameType(merged.planTypes)) {
          const type = merged.planTypes[0]
          if (type == 'habit') {
            title = `养习惯提醒（${merged.titles.length}项）`
          } else if (type == 'goal') {
            title = `定目标提醒（${merged.titles.length}项）`
          }
        }
        const content = this.buildMergedContent(merged.titles)
        // 与测试按钮一致：统一使用 Timer 类型发布代理提醒
        const notificationId = 880000 + (i % 10000)
        const req = this.buildTimerReqByTrigger(merged.triggerAt, now, title, content, notificationId)
        const id = await this.publishReq(req)
        for (let j = 0; j < merged.planIds.length; j++) {
          this.upsertReminderMapItem(newReminderMap, merged.planIds[j], id)
        }
        success += 1
      }
    } catch (e) {
      failed = 1
      failReason = this.parseError(e as Object)
    }

    this.saveReminderMap(newReminderMap)
    AppStorage.setOrCreate('HabitReminderLastSyncAt', Date.now())
    AppStorage.setOrCreate('HabitReminderLastError', failReason)

    const summary = failReason.length > 0
      ? `养习惯${habits.length}条 + 定目标${goals.length}条（代理提醒），本次创建成功${success}条，失败${failed}条（${failReason}）`
      : `养习惯${habits.length}条 + 定目标${goals.length}条（代理提醒），本次创建成功${success}条，失败${failed}条`
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

