import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { cloudDatabase } from '@kit.CloudFoundationKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { furtherTimeDB, FurtherTimeDBInfo } from '../../database/FurtherTimeDB'
import { planDB, PlanDBInfo } from '../../database/PlanDB'
import { toDoPlanDB, ToDoPlanDBInfo } from '../../database/ToDoPlanDB'
import { wishWallDB, WishWallDBInfo } from '../../database/WishWallDB'

interface HuaweiLoginInfo {
  openId?: string
  unionId?: string
}

interface BackupPayload {
  openId: string
  unionId: string
  backedAt: number
  furtherTimeList: FurtherTimeDBInfo[]
  planList: PlanDBInfo[]
  toDoPlanList: ToDoPlanDBInfo[]
  wishWallList: WishWallDBInfo[]
}

interface BackupResp {
  code?: number
  message?: string
}

interface RestorePayload {
  openId: string
}

interface RestoreData {
  furtherTimeList?: FurtherTimeDBInfo[]
  planList?: PlanDBInfo[]
  toDoPlanList?: ToDoPlanDBInfo[]
  wishWallList?: WishWallDBInfo[]
}

interface RestoreResp {
  code?: number
  message?: string
  data?: RestoreData
}

interface BizErrorLike {
  code?: number
  message?: string
}

interface CloudIdObject {
  id: string
}

class cloud_further_time extends cloudDatabase.DatabaseObject {
  id: string = ''
  openId: string = ''
  localId: number = 0
  title: string = ''
  targetTime: number = 0
  createdAt: number = 0
  updatedAt: number = 0

  naturalbase_ClassName(): string {
    return 'cloud_further_time'
  }
}

class cloud_plan_record extends cloudDatabase.DatabaseObject {
  id: string = ''
  openId: string = ''
  localId: number = 0
  title: string = ''
  times: number = 0
  isAccomplish: number = 0
  date_added: number = 0
  updatedAt: number = 0

  naturalbase_ClassName(): string {
    return 'cloud_plan_record'
  }
}

class cloud_todo_plan extends cloudDatabase.DatabaseObject {
  id: string = ''
  openId: string = ''
  localId: number = 0
  title: string = ''
  event: string = ''
  time: string = ''
  timess: number = 0
  timesss: string = ''
  type: string = ''
  times: number = 0
  date_added: number = 0
  sort_order: number = 0
  updatedAt: number = 0

  naturalbase_ClassName(): string {
    return 'cloud_todo_plan'
  }
}

class cloud_wish_wall extends cloudDatabase.DatabaseObject {
  id: string = ''
  openId: string = ''
  localUserId: number = 0
  wishName: string = ''
  effort: string = ''
  createdAt: number = 0
  isRestored: number = 0
  updatedAt: number = 0

  naturalbase_ClassName(): string {
    return 'cloud_wish_wall'
  }
}

@CustomDialog
struct HelpDialog {
  controllerTwo?: CustomDialogController

  @Builder
  private helpStep(index: number, content: string) {
    Row({ space: 12 }) {
      Text(`${index}`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_on_brand'))
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .borderRadius(13)
        .backgroundColor($r('app.color.brand_primary'))
      Text(content)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(22)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column({ space: 0 }) {
      Text('云同步帮助')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Text('按顺序操作，即可在多台设备间同步待办、计划、倒计时与许愿墙等数据。')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .width('100%')
        .margin({ top: 8, bottom: 18 })

      Column({ space: 14 }) {
        this.helpStep(1, '在需要保留数据的设备上登录华为帐号，进入本页后点击【备份至服务器】。')
        this.helpStep(2, '在新设备或重装应用后，使用同一华为帐号登录，进入本页点击【恢复至本机】。')
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('温馨提示')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Text('建议两台设备上的本应用均更新至最新版本，可在应用商店检查更新，以减少兼容问题。')
          .fontSize(13)
          .fontColor($r('app.color.text_meta_emphasis'))
          .lineHeight(20)
          .width('100%')
      }
      .width('100%')
      .padding(14)
      .borderRadius(12)
      .backgroundColor($r('app.color.brand_primary_soft_bg'))
      .border({ width: 1, color: $r('app.color.input_border') })
      .margin({ top: 18 })

      Button('我知道了')
        .type(ButtonType.Normal)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_on_brand'))
        .backgroundColor($r('app.color.brand_primary'))
        .width('100%')
        .height(44)
        .borderRadius(12)
        .margin({ top: 20 })
        .onClick(() => {
          this.controllerTwo?.close()
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
    .border({ width: 1, color: $r('app.color.input_border') })
    .borderRadius(14)
  }
}

@CustomDialog
struct VIPDialog {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 10 }) {
      Text('提示')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Column({ space: 20 }) {
        Text('您可以开通季度卡来使用此项高级功能')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text('更可享受更多新颖高级功能，祝您养成专注好习惯')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Button('去季度卡页面看看')
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.brand_primary_soft_bg'))
        .width('70%')
        .onClick(() => {
          router.pushUrl({ url: '' })
        })

      Button('取消', { buttonStyle: ButtonStyleMode.TEXTUAL })
        .fontColor($r('app.color.text_secondary'))
        .width('70%')
        .onClick(() => {
          if (this.controllerTwo) {
            this.controllerTwo.close()
          }
        })
    }
    .padding({ top: 20, bottom: 20 })
    .width('70%')
    .backgroundColor($r('app.color.card_background'))
  }
}


@Entry
@Component
struct Cloud_synchronization {
  private static readonly CLOUD_DB_ZONE: string = 'todoplan'
  dialogHelp: CustomDialogController | null = new CustomDialogController({
    builder: HelpDialog(),
    customStyle: true,
    cornerRadius: 18,
    width: '78%'
  })
  dialogVIP: CustomDialogController | null = new CustomDialogController({
    builder: VIPDialog(),
    customStyle: true,
    cornerRadius: 18,
    width: '78%'
  })
  @StorageLink('isCloud') isClouds: boolean = false
  @StorageLink('isVIP') isVip: boolean = false
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @StorageLink('HuaweiLoginInfo') huaweiLoginInfo: string = ''
  @StorageLink('id') userId: number = 0
  @State backingUp: boolean = false
  @State restoring: boolean = false
  private databaseZone = cloudDatabase.zone(Cloud_synchronization.CLOUD_DB_ZONE)

  private parseHuaweiInfo(): HuaweiLoginInfo {
    if (this.huaweiLoginInfo.length == 0) {
      return {}
    }
    try {
      return JSON.parse(this.huaweiLoginInfo) as HuaweiLoginInfo
    } catch (_) {
      return {}
    }
  }

  private toCloudFurtherTime(openId: string, item: FurtherTimeDBInfo): cloud_further_time {
    const obj = new cloud_further_time()
    const localId = item.id ?? 0
    obj.id = `${openId}_ft_${localId}_${item.createdAt}`
    obj.openId = openId
    obj.localId = localId
    obj.title = item.title
    obj.targetTime = item.targetTime
    obj.createdAt = item.createdAt
    obj.updatedAt = Date.now()
    return obj
  }

  private toCloudPlanRecord(openId: string, item: PlanDBInfo): cloud_plan_record {
    const obj = new cloud_plan_record()
    const localId = item.id ?? 0
    obj.id = `${openId}_plan_${localId}_${item.date_added}`
    obj.openId = openId
    obj.localId = localId
    obj.title = item.title
    obj.times = item.times
    obj.isAccomplish = item.is_accomplish ? 1 : 0
    obj.date_added = item.date_added
    obj.updatedAt = Date.now()
    return obj
  }

  private toCloudToDoPlan(openId: string, item: ToDoPlanDBInfo): cloud_todo_plan {
    const obj = new cloud_todo_plan()
    const localId = item.id ?? 0
    obj.id = `${openId}_todo_${localId}_${item.date_added}`
    obj.openId = openId
    obj.localId = localId
    obj.title = item.title
    obj.event = item.event
    obj.time = item.time ?? ''
    obj.timess = item.timess ?? 0
    obj.timesss = item.timesss ?? ''
    obj.type = item.type
    obj.times = item.times ?? 0
    obj.date_added = item.date_added
    obj.sort_order = item.sort_order ?? 0
    obj.updatedAt = Date.now()
    return obj
  }

  private toCloudWishWall(openId: string, item: WishWallDBInfo): cloud_wish_wall {
    const obj = new cloud_wish_wall()
    obj.id = `${openId}_wish_${item.id}`
    obj.openId = openId
    obj.localUserId = item.userId
    obj.wishName = item.wishName
    obj.effort = item.effort
    obj.createdAt = item.createdAt
    obj.isRestored = item.effort.length > 0 ? 1 : 0
    obj.updatedAt = Date.now()
    return obj
  }

  private async upsertWithTag(tag: string, list: cloudDatabase.DatabaseObject[]): Promise<boolean> {
    if (list.length == 0) {
      return true
    }
    try {
      await this.databaseZone.upsert(list)
      return true
    } catch (e) {
      const biz = e as BizErrorLike
      const code = biz.code ?? -1
      const message = biz.message ?? '未知错误'
      hilog.error(0x0000, 'CloudSync', `upsert ${tag} failed code=${code}, msg=${message}`)
      promptAction.showToast({
        message: `备份失败[${tag}](${code})：${message}，zone=${Cloud_synchronization.CLOUD_DB_ZONE}`
      })
      return false
    }
  }

  private buildIdMap(list: CloudIdObject[]): Map<string, boolean> {
    const m = new Map<string, boolean>()
    for (let i = 0; i < list.length; i++) {
      m.set(list[i].id, true)
    }
    return m
  }

  private async deleteCloudFurtherTimeMissing(openId: string, currentList: cloud_further_time[]): Promise<boolean> {
    const q = new cloudDatabase.DatabaseQuery(cloud_further_time)
    q.equalTo('openId', openId)
    const oldList = await this.databaseZone.query(q) as cloud_further_time[]
    const idMap = this.buildIdMap(currentList)
    const needDelete: cloud_further_time[] = []
    for (let i = 0; i < oldList.length; i++) {
      if (!idMap.has(oldList[i].id)) {
        needDelete.push(oldList[i])
      }
    }
    if (needDelete.length == 0) {
      return true
    }
    try {
      await this.databaseZone.delete(needDelete)
      return true
    } catch (e) {
      const biz = e as BizErrorLike
      promptAction.showToast({
        message: `删除旧数据失败[cloud_further_time](${biz.code ?? -1})：${biz.message ?? '未知错误'}`
      })
      return false
    }
  }

  private async deleteCloudPlanMissing(openId: string, currentList: cloud_plan_record[]): Promise<boolean> {
    const q = new cloudDatabase.DatabaseQuery(cloud_plan_record)
    q.equalTo('openId', openId)
    const oldList = await this.databaseZone.query(q) as cloud_plan_record[]
    const idMap = this.buildIdMap(currentList)
    const needDelete: cloud_plan_record[] = []
    for (let i = 0; i < oldList.length; i++) {
      if (!idMap.has(oldList[i].id)) {
        needDelete.push(oldList[i])
      }
    }
    if (needDelete.length == 0) {
      return true
    }
    try {
      await this.databaseZone.delete(needDelete)
      return true
    } catch (e) {
      const biz = e as BizErrorLike
      promptAction.showToast({
        message: `删除旧数据失败[cloud_plan_record](${biz.code ?? -1})：${biz.message ?? '未知错误'}`
      })
      return false
    }
  }

  private async deleteCloudTodoMissing(openId: string, currentList: cloud_todo_plan[]): Promise<boolean> {
    const q = new cloudDatabase.DatabaseQuery(cloud_todo_plan)
    q.equalTo('openId', openId)
    const oldList = await this.databaseZone.query(q) as cloud_todo_plan[]
    const idMap = this.buildIdMap(currentList)
    const needDelete: cloud_todo_plan[] = []
    for (let i = 0; i < oldList.length; i++) {
      if (!idMap.has(oldList[i].id)) {
        needDelete.push(oldList[i])
      }
    }
    if (needDelete.length == 0) {
      return true
    }
    try {
      await this.databaseZone.delete(needDelete)
      return true
    } catch (e) {
      const biz = e as BizErrorLike
      promptAction.showToast({
        message: `删除旧数据失败[cloud_todo_plan](${biz.code ?? -1})：${biz.message ?? '未知错误'}`
      })
      return false
    }
  }

  private async deleteCloudWishMissing(openId: string, currentList: cloud_wish_wall[]): Promise<boolean> {
    const q = new cloudDatabase.DatabaseQuery(cloud_wish_wall)
    q.equalTo('openId', openId)
    const oldList = await this.databaseZone.query(q) as cloud_wish_wall[]
    const idMap = this.buildIdMap(currentList)
    const needDelete: cloud_wish_wall[] = []
    for (let i = 0; i < oldList.length; i++) {
      if (!idMap.has(oldList[i].id)) {
        needDelete.push(oldList[i])
      }
    }
    if (needDelete.length == 0) {
      return true
    }
    try {
      await this.databaseZone.delete(needDelete)
      return true
    } catch (e) {
      const biz = e as BizErrorLike
      promptAction.showToast({
        message: `删除旧数据失败[cloud_wish_wall](${biz.code ?? -1})：${biz.message ?? '未知错误'}`
      })
      return false
    }
  }

  private async backupToServer(): Promise<void> {
    if (this.backingUp) {
      return
    }
    if (this.isLogin != '已登录') {
      promptAction.showToast({ message: '请先登录华为账号' })
      return
    }
    const info = this.parseHuaweiInfo()
    const openId = info.openId ?? ''
    const unionId = info.unionId ?? ''
    if (openId.length == 0) {
      promptAction.showToast({ message: '未获取到OpenID，无法备份' })
      return
    }
    if (Cloud_synchronization.CLOUD_DB_ZONE.length == 0) {
      promptAction.showToast({ message: '请先配置Cloud DB存储区名' })
      return
    }

    this.backingUp = true
    try {
      const furtherTimeList = await furtherTimeDB.query()
      const planList = await planDB.query()
      const toDoPlanList = await toDoPlanDB.query()
      const wishWallList = await wishWallDB.queryByUserId(this.userId)
      const payload: BackupPayload = {
        openId: openId,
        unionId: unionId,
        backedAt: Date.now(),
        furtherTimeList: furtherTimeList,
        planList: planList,
        toDoPlanList: toDoPlanList,
        wishWallList: wishWallList
      }
      const ftObjects: cloud_further_time[] = []
      for (let i = 0; i < payload.furtherTimeList.length; i++) {
        ftObjects.push(this.toCloudFurtherTime(openId, payload.furtherTimeList[i]))
      }
      const planObjects: cloud_plan_record[] = []
      for (let i = 0; i < payload.planList.length; i++) {
        planObjects.push(this.toCloudPlanRecord(openId, payload.planList[i]))
      }
      const todoObjects: cloud_todo_plan[] = []
      for (let i = 0; i < payload.toDoPlanList.length; i++) {
        todoObjects.push(this.toCloudToDoPlan(openId, payload.toDoPlanList[i]))
      }
      const wishObjects: cloud_wish_wall[] = []
      for (let i = 0; i < payload.wishWallList.length; i++) {
        wishObjects.push(this.toCloudWishWall(openId, payload.wishWallList[i]))
      }

      // 先删除当前用户在云端“本次备份已不存在”的旧数据，再执行upsert覆盖
      const delFt = await this.deleteCloudFurtherTimeMissing(openId, ftObjects)
      if (!delFt) {
        return
      }
      const delPlan = await this.deleteCloudPlanMissing(openId, planObjects)
      if (!delPlan) {
        return
      }
      const delTodo = await this.deleteCloudTodoMissing(openId, todoObjects)
      if (!delTodo) {
        return
      }
      const delWish = await this.deleteCloudWishMissing(openId, wishObjects)
      if (!delWish) {
        return
      }

      const okFt = await this.upsertWithTag('cloud_further_time', ftObjects)
      if (!okFt) {
        return
      }
      const okPlan = await this.upsertWithTag('cloud_plan_record', planObjects)
      if (!okPlan) {
        return
      }
      const okTodo = await this.upsertWithTag('cloud_todo_plan', todoObjects)
      if (!okTodo) {
        return
      }
      const okWish = await this.upsertWithTag('cloud_wish_wall', wishObjects)
      if (!okWish) {
        return
      }
      promptAction.showToast({ message: '备份成功' })
    } catch (e) {
      const biz = e as BizErrorLike
      const code = biz.code ?? -1
      const message = biz.message ?? '未知错误'
      hilog.error(0x0000, 'CloudSync', `backup failed code=${code}, msg=${message}`)
      promptAction.showToast({ message: `备份失败(${code})：${message}` })
    } finally {
      this.backingUp = false
    }
  }

  private async clearLocalTables(): Promise<void> {
    const ftStore = await furtherTimeDB.getStoreInstance()
    await ftStore.executeSql('DELETE FROM FurtherTime')

    const planStore = await planDB.getStoreInstance()
    await planStore.executeSql('DELETE FROM Plan')

    const todoStore = await toDoPlanDB.getStoreInstance()
    await todoStore.executeSql('DELETE FROM ToDoPlan')

    const wishStore = await wishWallDB.getStoreInstance()
    await wishStore.executeSql('DELETE FROM WishWall')
  }

  private async restoreFromServer(): Promise<void> {
    if (this.restoring) {
      return
    }
    if (this.isLogin != '已登录') {
      promptAction.showToast({ message: '请先登录华为账号' })
      return
    }
    const info = this.parseHuaweiInfo()
    const openId = info.openId ?? ''
    if (openId.length == 0) {
      promptAction.showToast({ message: '未获取到OpenID，无法恢复' })
      return
    }
    if (Cloud_synchronization.CLOUD_DB_ZONE.length == 0) {
      promptAction.showToast({ message: '请先配置Cloud DB存储区名' })
      return
    }

    this.restoring = true
    try {
      const qFt = new cloudDatabase.DatabaseQuery(cloud_further_time)
      qFt.equalTo('openId', openId)
      const ftCloudList = await this.databaseZone.query(qFt) as cloud_further_time[]

      const qPlan = new cloudDatabase.DatabaseQuery(cloud_plan_record)
      qPlan.equalTo('openId', openId)
      const planCloudList = await this.databaseZone.query(qPlan) as cloud_plan_record[]

      const qTodo = new cloudDatabase.DatabaseQuery(cloud_todo_plan)
      qTodo.equalTo('openId', openId)
      const todoCloudList = await this.databaseZone.query(qTodo) as cloud_todo_plan[]

      const qWish = new cloudDatabase.DatabaseQuery(cloud_wish_wall)
      qWish.equalTo('openId', openId)
      const wishCloudList = await this.databaseZone.query(qWish) as cloud_wish_wall[]

      await this.clearLocalTables()

      for (let i = 0; i < ftCloudList.length; i++) {
        const it = ftCloudList[i]
        await furtherTimeDB.insert({
          id: null,
          title: it.title,
          targetTime: it.targetTime,
          createdAt: it.createdAt
        })
      }

      for (let i = 0; i < planCloudList.length; i++) {
        const it = planCloudList[i]
        await planDB.insert({
          id: null,
          title: it.title,
          times: it.times,
          is_accomplish: it.isAccomplish > 0,
          date_added: it.date_added,
          todo_plan_id: null
        })
      }

      for (let i = 0; i < todoCloudList.length; i++) {
        const it = todoCloudList[i]
        await toDoPlanDB.insert({
          id: null,
          title: it.title,
          event: it.event,
          time: it.time,
          timess: it.timess,
          timesss: it.timesss,
          type: it.type,
          times: it.times,
          date_added: it.date_added,
          sort_order: it.sort_order
        })
      }

      for (let i = 0; i < wishCloudList.length; i++) {
        const it = wishCloudList[i]
        await wishWallDB.insert({
          id: `${it.id}`,
          userId: this.userId,
          wishName: it.wishName,
          createdAt: it.createdAt,
          effort: it.effort
        })
      }

      promptAction.showToast({ message: '恢复成功' })
    } catch (e) {
      const biz = e as BizErrorLike
      const code = biz.code ?? -1
      const message = biz.message ?? '未知错误'
      hilog.error(0x0000, 'CloudSync', `restore failed code=${code}, msg=${message}`)
      promptAction.showToast({ message: `恢复失败(${code})：${message}` })
    } finally {
      this.restoring = false
    }
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Column({ space: 15 }) {
          Text('备份 | 恢复')
            .fontWeight(FontWeight.Bold)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Row({ space: 20 }) {
            Image($r('app.media.ic_public_cloud_upload'))
              .width(40)
              .fillColor($r('app.color.text_on_brand'))
            Text(this.backingUp ? '备份中...' : '备份至服务器')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_on_brand'))
          }
          .backgroundColor('#858CFF')
          .padding(15)
          .borderRadius(15)
          .width('100%')
          .onClick(async () => {
            await this.backupToServer()
          })

          Row({ space: 20 }) {
            Image($r('app.media.ic_public_cloud_download'))
              .width(40)
              .fillColor($r('app.color.text_on_brand'))
            Text(this.restoring ? '恢复中...' : '恢复至本机')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_on_brand'))
          }
          .padding(15)
          .backgroundColor('#58C7FF')
          .borderRadius(15)
          .width('100%')
          .onClick(async () => {
            await this.restoreFromServer()
          })

          Row() {
            Text('如何将全部数据导入至新设备？')
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
          }
          .padding(15)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(15)
          .border({ width: 1, color: $r('app.color.input_border') })
          .width('100%')
          .onClick(() => {
            if (this.dialogHelp != null) {
              this.dialogHelp.open()
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('app.color.list_area_background'))
        .width('100%')
        .padding(20)
        .borderRadius(15)

        // Column({ space: 15 }) {
        //   Row({ space: 5 }) {
        //     Text('同步')
        //       .fontWeight(FontWeight.Bold)
        //       .fontSize(14)
        //     Image($r('app.media.ic_user_vipcard'))
        //       .width(20)
        //   }
        //
        //   Row({ space: 20 }) {
        //     Image($r('app.media.ic_public_cloud_synchronise'))
        //       .width(40)
        //       .fillColor(Color.White)
        //     Column({ space: 5 }) {
        //       Text('自动同步近期数据')
        //         .fontSize(15)
        //         .fontWeight(FontWeight.Bold)
        //         .fontColor(Color.White)
        //       if (this.isClouds) {
        //         Text('已开启')
        //           .fontSize(11)
        //           .fontWeight(FontWeight.Medium)
        //           .fontColor(Color.White)
        //       } else {
        //         Text('未开启')
        //           .fontSize(11)
        //           .fontWeight(FontWeight.Medium)
        //           .fontColor(Color.White)
        //       }
        //     }
        //     .alignItems(HorizontalAlign.Start)
        //
        //     Toggle({ type: ToggleType.Switch, isOn: $$this.isClouds })
        //       .onChange((isOn: boolean) => {
        //         if (isOn == true) {
        //           if (!this.isVip) {
        //             if (this.dialogVIP != null) {
        //               this.dialogVIP.open()
        //               this.isClouds = false
        //             }
        //           }
        //         }
        //       })
        //   }
        //   .justifyContent(FlexAlign.SpaceBetween)
        //   .backgroundColor('#858CFF')
        //   .padding(15)
        //   .borderRadius(15)
        //   .width('100%')
        // }
        // .alignItems(HorizontalAlign.Start)
        // .backgroundColor('#fff1f1f1')
        // .width('100%')
        // .padding(20)
        // .borderRadius(15)
      }
      .padding(20)
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.list_area_background'))
    }
    .title('云同步')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [
        [$r('app.color.page_gradient_1'), 0.35],
        [$r('app.color.page_gradient_end'), 0.9]
      ]
    })
  }
}