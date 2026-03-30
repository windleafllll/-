import { LengthMetrics, router } from '@kit.ArkUI'
import { toDoPlanDB, ToDoPlanDBInfo } from '../../database/ToDoPlanDB'
import { ToDoPlan } from '../ToDoPlan/ToDoPlan'
import { planDB, PlanDBInfo } from '../../database/PlanDB'

interface HabitProgress {
  /** 分钟类目标：Plan.times 为每次专注的秒数，此处为累加秒数 */
  doneSeconds: number
  doneTimes: number
}

interface PlanProgressItem {
  planId: string
  text: string
  /** 养习惯/定目标：当前统计周期内是否已达成本期目标 */
  phaseComplete: boolean
}

@CustomDialog
struct PlanOrderDialog {
  controller?: CustomDialogController
  initList?: ToDoPlanDBInfo[]
  onConfirm?: (orderedIds: number[]) => Promise<void>
  dialogWidth?: string
  listHeight?: number

  @State list: ToDoPlanDBInfo[] = []
  @State draggingIndex: number = -1
  @State dragStartIndex: number = -1
  @State dragTargetIndex: number = -1
  @State dragOffsetY: number = 0
  @State dragFollowCompY: number = 0
  @State listViewportHeight: number = 360
  private orderScroller: Scroller = new Scroller()
  // 与单行卡片可视高度接近，避免占位位移过头被容器裁切
  private rowMoveStep: number = 60
  private autoScrollDir: number = 0 // -1: top, 1: bottom, 0: stop
  private autoScrollTimerId: number = 0
  // 仅用于“排序目标计算”的自动滚动累计位移，不参与视觉跟手
  private dragCalcCarryY: number = 0

  aboutToAppear(): void {
    this.list = (this.initList ?? []).slice()
  }

  private swap(i: number, j: number) {
    if (i < 0 || j < 0 || i >= this.list.length || j >= this.list.length) {
      return
    }
    const a = this.list[i]
    this.list[i] = this.list[j]
    this.list[j] = a
  }

  private moveItem(from: number, to: number) {
    if (from < 0 || to < 0 || from >= this.list.length || to >= this.list.length) {
      return
    }
    if (from === to) {
      return
    }
    const item = this.list[from]
    this.list.splice(from, 1)
    this.list.splice(to, 0, item)
  }

  private clampIndex(idx: number): number {
    if (idx < 0) {
      return 0
    }
    if (idx >= this.list.length) {
      return this.list.length - 1
    }
    return idx
  }

  private handleDragMove(offsetY: number) {
    if (this.dragStartIndex < 0 || this.dragStartIndex >= this.list.length) {
      return
    }
    this.dragOffsetY = offsetY
    // 基于“展示计划容器”边缘触发自动滚动（平滑小步），避免瞬移脱手
    const edgeThreshold = Math.max(36, Math.floor(this.listViewportHeight * 0.12))
    const topTrigger = -(this.listViewportHeight / 2 - edgeThreshold)
    const bottomTrigger = (this.listViewportHeight / 2 - edgeThreshold)
    if (offsetY < topTrigger) {
      this.setAutoScrollDir(-1)
    } else if (offsetY > bottomTrigger) {
      this.setAutoScrollDir(1)
    } else {
      this.setAutoScrollDir(0)
    }
    const effectiveOffsetY = offsetY + this.dragCalcCarryY
    const deltaRows = Math.round(effectiveOffsetY / this.rowMoveStep)
    this.dragTargetIndex = this.clampIndex(this.dragStartIndex + deltaRows)
  }

  private setAutoScrollDir(dir: number) {
    if (this.autoScrollDir === dir) {
      return
    }
    // 方向反转时，清掉历史补偿，避免出现“反向拖动不跟手”
    if (this.autoScrollDir != 0 && dir != 0 && this.autoScrollDir != dir) {
      this.dragCalcCarryY = 0
      this.dragFollowCompY = 0
    }
    this.autoScrollDir = dir
    if (dir === 0) {
      this.stopAutoScrollTimer()
      return
    }
    this.startAutoScrollTimer()
  }

  private startAutoScrollTimer() {
    if (this.autoScrollTimerId != 0) {
      return
    }
    this.autoScrollTimerId = setInterval(() => {
      if (this.autoScrollDir === 0) {
        return
      }
      // 已到“索引边界”时，暂停该方向增量（不销毁滚动状态机），
      // 这样用户反向拖动时可立刻恢复滚动。
      if (this.autoScrollDir < 0 && this.dragTargetIndex <= 0) {
        return
      }
      if (this.autoScrollDir > 0 && this.dragTargetIndex >= this.list.length - 1) {
        return
      }
      const step = 4
      const scrollDelta = this.autoScrollDir * step
      this.orderScroller.scrollBy(0, scrollDelta)
      // 只修正“目标索引计算”，保证手感跟手不漂移
      this.dragCalcCarryY += scrollDelta
      // 视觉补偿：容器滚动时，拖拽项反向跟随，避免“脱手”
      this.dragFollowCompY += scrollDelta
      const effectiveOffsetY = this.dragOffsetY + this.dragCalcCarryY
      const deltaRows = Math.round(effectiveOffsetY / this.rowMoveStep)
      this.dragTargetIndex = this.clampIndex(this.dragStartIndex + deltaRows)
    }, 16)
  }

  private stopAutoScrollTimer() {
    if (this.autoScrollTimerId != 0) {
      clearInterval(this.autoScrollTimerId)
      this.autoScrollTimerId = 0
    }
  }

  private getItemShiftY(index: number): number {
    if (this.dragStartIndex < 0 || this.dragTargetIndex < 0) {
      return 0
    }
    if (index === this.dragStartIndex) {
      return 0
    }
    if (this.dragTargetIndex > this.dragStartIndex) {
      if (index > this.dragStartIndex && index <= this.dragTargetIndex) {
        return -this.rowMoveStep
      }
      return 0
    }
    if (this.dragTargetIndex < this.dragStartIndex) {
      if (index >= this.dragTargetIndex && index < this.dragStartIndex) {
        return this.rowMoveStep
      }
      return 0
    }
    return 0
  }

  private buildOrderedIds(): number[] {
    const ids: number[] = []
    for (let i = 0; i < this.list.length; i++) {
      const id = this.list[i].id
      if (id != null) {
        ids.push(id)
      }
    }
    return ids
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩层：点击空白处关闭
      Row() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.overlay_scrim'))
      .onClick(() => {
        this.controller?.close()
      })

      Column({ space: 12 }) {
        Text('调整计划顺序')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        if (this.list.length > 0) {
          Scroll(this.orderScroller) {
            List({ space: 8 }) {
              ForEach(this.list, (v: ToDoPlanDBInfo, index: number) => {
                ListItem() {
                  Row({ space: 10 }) {
                    Text((index + 1).toString())
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                      .width(22)

                    Column({ space: 2 }) {
                      Text(v.title)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(v.event)
                        .fontSize(11)
                        .fontColor($r('app.color.text_secondary'))
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 仅拖动按钮区域可触发拖拽
                    Row() {
                      Text('拖动')
                        .fontSize(12)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.draggingIndex === index ? $r('app.color.accent_blue_deep') : $r('app.color.accent_blue'))
                    }
                    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                    .borderRadius(999)
                    .backgroundColor(this.draggingIndex === index ? $r('app.color.tint_blue_light') : $r('app.color.tint_blue_soft'))
                    .gesture(
                      PanGesture({ direction: PanDirection.Vertical, distance: 1 })
                        .onActionStart(() => {
                          this.draggingIndex = index
                          this.dragStartIndex = index
                          this.dragTargetIndex = index
                          this.dragOffsetY = 0
                          this.dragFollowCompY = 0
                          this.dragCalcCarryY = 0
                          this.setAutoScrollDir(0)
                        })
                        .onActionUpdate((event: GestureEvent) => {
                          this.handleDragMove(event.offsetY)
                        })
                        .onActionEnd(() => {
                          if (this.dragStartIndex >= 0 && this.dragTargetIndex >= 0) {
                            this.moveItem(this.dragStartIndex, this.dragTargetIndex)
                          }
                          this.setAutoScrollDir(0)
                          this.dragOffsetY = 0
                          this.dragFollowCompY = 0
                          this.draggingIndex = -1
                          this.dragStartIndex = -1
                          this.dragTargetIndex = -1
                          this.dragCalcCarryY = 0
                        })
                    )
                  }
                  .padding(10)
                  .borderRadius(10)
                  .backgroundColor(this.draggingIndex === index ? $r('app.color.row_drag_highlight') : $r('app.color.row_neutral'))
                  .translate({
                    x: 0,
                    y: this.draggingIndex === index ? (this.dragOffsetY + this.dragFollowCompY) : this.getItemShiftY(index)
                  })
                  .scale({ x: this.draggingIndex === index ? 1.02 : 1, y: this.draggingIndex === index ? 1.02 : 1 })
                  .shadow(this.draggingIndex === index ? {
                    radius: 18,
                    color: $r('app.color.shadow_drag'),
                    offsetX: 0,
                    offsetY: 8
                  } : {
                    radius: 0,
                    color: $r('app.color.shadow_none'),
                    offsetX: 0,
                    offsetY: 0
                  })
                  .zIndex(this.draggingIndex === index ? 99 : 1)
                  .animation({ duration: this.draggingIndex === index ? 16 : 120 })
                }
              })
            }
          }
          // 隐藏滚动条 + 左右留白
          .scrollBar(BarState.Off)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .height(this.listHeight ?? 360)
          .onAreaChange((_, value) => {
            this.listViewportHeight = value.height as number
          })
        } else {
          Text('暂无计划')
            .fontColor($r('app.color.text_secondary'))
            .fontSize(12)
        }

        Row({ space: 12 }) {
          Button('取消', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.controller?.close()
            })

          Button('保存', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .fontColor($r('app.color.brand_primary'))
            .fontWeight(FontWeight.Bold)
            .onClick(async () => {
              const ids = this.buildOrderedIds()
              await (this.onConfirm?.(ids) ?? Promise.resolve())
              this.controller?.close()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
      .width(this.dialogWidth ?? '88%')
      .borderRadius(16)
      .backgroundColor($r('app.color.card_background'))
      .padding(16)
      .shadow({ radius: 24, color: $r('app.color.dialog_shadow'), offsetX: 0, offsetY: 10 })
      .onClick(() => {
        // 吃掉面板内点击，避免触发遮罩关闭
      })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct HomeTab {
  dialogToDoPlan: CustomDialogController | null = new CustomDialogController({
    builder: ToDoPlan(),
    customStyle: true,
    cornerRadius: 20,
    width: '88%',
    keyboardAvoidDistance: LengthMetrics.vp(32)
  })
  @State refreshing: boolean = true
  @StorageLink('PlanID') PlanID: number = -1
  @StorageLink('PlanChangedAt') planChangedAt: number = 0
  @State list: ToDoPlanDBInfo[] = []
  @State text: string = ''
  @State pagePadding: number = 15
  @State headerPadding: number = 10
  @State cardPadding: number = 15
  @State cardInnerSpace: number = 8
  @State titleFontSize: number = 20
  @State metaFontSize: number = 11
  @State cardLeftWidth: string = '72%'
  // 定目标卡片需要更多右侧空间，防止“开始”按钮被挤出屏幕
  @State targetCardLeftWidth: string = '60%'
  @State progressList: PlanProgressItem[] = []
  @State backNumber: string[] =
    ['app.media.ic_home_back_1', 'app.media.ic_home_back_2', 'app.media.ic_home_back_3', 'app.media.ic_home_back_4',
      'app.media.ic_home_back_5', 'app.media.ic_home_back_6', 'app.media.ic_home_back_7', 'app.media.ic_home_back_8',
      'app.media.ic_home_back_9', 'app.media.ic_home_back_10']

  @State lastPlanChangedAt: number = -1
  @State private screenWidth: number = 0
  private orderDialog: CustomDialogController | null = null

  @Builder
  deleteButton(id: number) {
    Button() {
      Image($r('app.media.ic_user_cha'))
        .width(20)
        .fillColor($r('app.color.brand_primary'))
    }
    .width(40)
    .height(40)
    .type(ButtonType.Circle)
    .margin(5)
    .backgroundColor($r('app.color.delete_icon_button_bg'))
    .onClick(async () => {
      await this.deleteToDoPlan(id)
      this.queryToDoPlan()
    })
  }

  async queryToDoPlan() {
    this.list = await toDoPlanDB.query()
    await this.computeProgressList()
  }

  private async openOrderDialog() {
    const list = await toDoPlanDB.query()
    const isPad = this.screenWidth >= 900
    const dialogWidth = isPad ? '70%' : '92%'
    const listHeight = isPad ? 520 : 360
    this.orderDialog = new CustomDialogController({
      builder: PlanOrderDialog({
        initList: list,
        dialogWidth: dialogWidth,
        listHeight: listHeight,
        onConfirm: async (orderedIds: number[]): Promise<void> => {
          await toDoPlanDB.updateSortOrders(orderedIds)
          this.planChangedAt = Date.now()
          await this.queryToDoPlan()
        }
      }),
      customStyle: true,
      cornerRadius: 14,
      width: '100%',
      height: '100%'
    })
    this.orderDialog.open()
  }

  async deleteToDoPlan(id: number) {
    await toDoPlanDB.delete(id)
    // 删除计划后触发提醒重建：清除旧日历提醒并为剩余习惯重新创建
    this.planChangedAt = Date.now()
  }

  private startOfDay(ts: number): number {
    const d = new Date(ts)
    d.setHours(0, 0, 0, 0)
    return d.getTime()
  }

  private startOfWeek(ts: number): number {
    const d = new Date(ts)
    d.setHours(0, 0, 0, 0)
    const day = d.getDay()
    const diff = (day + 6) % 7
    d.setDate(d.getDate() - diff)
    return d.getTime()
  }

  private startOfMonth(ts: number): number {
    const d = new Date(ts)
    d.setHours(0, 0, 0, 0)
    d.setDate(1)
    return d.getTime()
  }

  private buildProgress(records: PlanDBInfo[]): HabitProgress {
    let seconds = 0
    let times = 0
    for (let i = 0; i < records.length; i++) {
      times += 1
      seconds += records[i].times
    }
    return { doneSeconds: seconds, doneTimes: times }
  }

  private buildProgressText(plan: ToDoPlanDBInfo, progress: HabitProgress): string {
    const target = plan.timess ?? 0
    const unit = plan.timesss ?? '分钟'
    if (unit === '次') {
      const done = progress.doneTimes
      return `已完成 ${done}/${target} 次`
    }
    const doneMin = Math.floor(progress.doneSeconds / 60)
    return `已完成 ${doneMin}/${target} 分钟`
  }

  private computePhaseComplete(plan: ToDoPlanDBInfo, progress: HabitProgress): boolean {
    const target = plan.timess ?? 0
    if (target <= 0) {
      return false
    }
    const unit = plan.timesss ?? '分钟'
    if (unit === '次') {
      return progress.doneTimes >= target
    }
    return progress.doneSeconds >= target * 60
  }

  private findProgressText(id: number | null): string {
    if (id == null) {
      return ''
    }
    const key = id.toString()
    for (let i = 0; i < this.progressList.length; i++) {
      if (this.progressList[i].planId === key) {
        return this.progressList[i].text
      }
    }
    return ''
  }

  private findPhaseComplete(id: number | null): boolean {
    if (id == null) {
      return false
    }
    const key = id.toString()
    for (let i = 0; i < this.progressList.length; i++) {
      if (this.progressList[i].planId === key) {
        return this.progressList[i].phaseComplete
      }
    }
    return false
  }

  private countHabitGoalSameTitle(title: string): number {
    let n = 0
    for (let i = 0; i < this.list.length; i++) {
      const p = this.list[i]
      if (p.title === title && (p.event === '养习惯' || p.event === '定目标')) {
        n++
      }
    }
    return n
  }

  /** 任意类型计划中同名条数，用于首页展示区分 */
  private countSameTitleAll(title: string): number {
    let n = 0
    for (let i = 0; i < this.list.length; i++) {
      if (this.list[i].title === title) {
        n++
      }
    }
    return n
  }

  private planCardBackgroundRes(planId: number | null): Resource {
    const len = this.backNumber.length
    const idx = planId != null ? Math.abs(planId % len) : 0
    return $r(this.backNumber[idx])
  }

  private async computeProgressList(): Promise<void> {
    const now = Date.now()
    const result: PlanProgressItem[] = []
    for (let i = 0; i < this.list.length; i++) {
      const v = this.list[i]
      if (v.id == null) {
        continue
      }
      if (v.event !== '养习惯' && v.event !== '定目标') {
        continue
      }
      const planId = v.id.toString()
      let rangeStart = v.event === '定目标'
        ? (v.date_added ?? 0)
        : (v.time === '每周'
          ? this.startOfWeek(now)
          : (v.time === '每月' ? this.startOfMonth(now) : this.startOfDay(now)))
      const allowLegacy = this.countHabitGoalSameTitle(v.title) <= 1
      const records =
        await planDB.queryRecordsForPlan(v.id, v.title, allowLegacy, rangeStart, now)
      const progress = this.buildProgress(records)
      const text = this.buildProgressText(v, progress)
      const phaseComplete = this.computePhaseComplete(v, progress)
      const row: PlanProgressItem = { planId: planId, text: text, phaseComplete: phaseComplete }
      result.push(row)
    }
    this.progressList = result
  }

  private updateResponsiveSpacing(width: number) {
    this.screenWidth = width
    this.headerPadding = width >= 900 ? 20 : 10
    this.pagePadding = width >= 900 ? 22 : 15
    this.cardPadding = width >= 900 ? 20 : 15
    this.cardInnerSpace = width >= 900 ? 10 : 8
    this.titleFontSize = width >= 900 ? 22 : 20
    this.metaFontSize = width >= 900 ? 12 : 11
    // 大屏下收窄卡片左侧文字区，避免一行过长难读（仍铺满，不做居中容器）
    this.cardLeftWidth = width >= 900 ? '60%' : '72%'
    this.targetCardLeftWidth = width >= 900 ? '52%' : '60%'
  }

  @Builder
  planTitleForHabitOrGoal(v: ToDoPlanDBInfo) {
    Row() {
      Text(v.title)
        .fontColor($r('app.color.text_on_image'))
        .fontSize(this.titleFontSize)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .constraintSize({ minWidth: 0 })
      if (this.countSameTitleAll(v.title) > 1) {
        Text('#' + (v.id ?? ''))
          .fontColor($r('app.color.text_on_image'))
          .fontSize(this.metaFontSize)
          .fontWeight(FontWeight.Medium)
          .opacity(0.9)
          .flexShrink(0)
      }
      if (this.findPhaseComplete(v.id)) {
        Row({ space: 6 }) {
          Image($r('app.media.ic_user_dui'))
            .width(14)
            .height(14)
            .fillColor($r('app.color.text_on_brand'))
          Text('已达标')
            .fontColor($r('app.color.text_on_brand'))
            .fontSize(this.metaFontSize)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 10, right: 12, top: 6, bottom: 6 })
        .borderRadius(12)
        .backgroundColor($r('app.color.accent_send'))
        .flexShrink(0)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: 15 }) {
      // 新增/修改计划后：触发一次首页重拉数据
      if (this.planChangedAt != this.lastPlanChangedAt) {
        Blank()
          .onAppear(async () => {
            this.lastPlanChangedAt = this.planChangedAt
            this.refreshing = true
            await this.queryToDoPlan()
            this.refreshing = false
          })
      }

      Row({ space: 20 }) {

        Blank()

        Image($r('app.media.ic_user_jiahao'))
          .width(22)
          .height(22)
          .fillColor($r('app.color.text_on_gradient_primary'))
          .onClick(() => {
            if (this.dialogToDoPlan != null) {
              this.PlanID = -1
              this.dialogToDoPlan.open()
            }
          })

        Image($r('app.media.ic_user_gengduo'))
          .width(22)
          .height(22)
          .fillColor($r('app.color.text_on_gradient_primary'))
          .onClick(async () => {
            await this.openOrderDialog()
          })
      }
      .width('100%')
      .padding({ left: this.headerPadding, right: this.headerPadding })

      Refresh({ refreshing: $$this.refreshing }) {
        Scroll() {
          Column({ space: 10 }) {
            if (this.list.length > 0) {
              List({ space: 10 }) {
                ForEach(this.list, (v: ToDoPlanDBInfo) => {
                  ListItem() {
                    if (v.event == '番茄钟') {
                      Row() {
                        Column({ space: this.cardInnerSpace }) {
                          Row() {
                            Text(v.title)
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.titleFontSize)
                              .fontWeight(FontWeight.Bold)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1)
                              .constraintSize({ minWidth: 0 })
                            if (this.countSameTitleAll(v.title) > 1) {
                              Text('#' + (v.id ?? ''))
                                .fontColor($r('app.color.text_on_image'))
                                .fontSize(this.metaFontSize)
                                .fontWeight(FontWeight.Medium)
                                .opacity(0.9)
                                .flexShrink(0)
                            }
                          }
                          .width('100%')
                          if (v.times) {
                            Text('单次 ' + v.times.toString() + ' 分钟')
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                          }
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor($r('app.color.text_on_image'))
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })

                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage(this.planCardBackgroundRes(v.id))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(this.cardPadding)
                      .borderRadius(15)
                      .width('100%')
                    } else if (v.event == '养习惯') {
                      Row() {
                        Column({ space: this.cardInnerSpace }) {
                          this.planTitleForHabitOrGoal(v)

                          Row({ space: 10 }) {
                            Text('计划 ' + v.time)
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                            Text('目标 ' + v.timess + v.timesss)
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                          }

                          if (this.findProgressText(v.id) !== '') {
                            Text(this.findProgressText(v.id))
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor($r('app.color.text_on_image'))
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage(this.planCardBackgroundRes(v.id))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(this.cardPadding)
                      .borderRadius(15)
                      .width('100%')
                    } else if (v.event == '定目标') {
                      Row() {
                        Column({ space: this.cardInnerSpace }) {
                          this.planTitleForHabitOrGoal(v)

                          Row({ space: 10 }) {
                            Text('截止 ' + v.time)
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                            Text('目标 ' + v.timess + v.timesss)
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                          }

                          if (this.findProgressText(v.id) !== '') {
                            Text(this.findProgressText(v.id))
                              .fontColor($r('app.color.text_on_image'))
                              .fontSize(this.metaFontSize)
                              .fontWeight(FontWeight.Medium)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor($r('app.color.text_on_image'))
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage(this.planCardBackgroundRes(v.id))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(this.cardPadding)
                      .borderRadius(15)
                      .width('100%')
                    }
                  }
                  .swipeAction({ end: this.deleteButton(v.id) })
                  .onClick(() => {
                    if (this.dialogToDoPlan != null) {
                      this.PlanID = v.id as number
                      this.dialogToDoPlan.open()
                    }
                  })
                }, (v: ToDoPlanDBInfo) => `${v.id ?? 0}_${v.date_added}`)
              }
              .scrollBar(BarState.Off)
            } else {
              Row() {
                Text('请先点击 + 创建一个计划')
                  .fontColor($r('app.color.text_secondary'))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
              }
            }
          }
          .height('100%')
          .width('100%')
        }
        .scrollBar(BarState.Off)
      }
      .padding(this.pagePadding)
      .width('100%')
      .layoutWeight(1)
      .linearGradient({
        direction: GradientDirection.Bottom,
        repeating: false,
        colors: [
          [$r('app.color.page_gradient_2'), 0.0],
          [$r('app.color.page_gradient_3'), 0.12],
          [$r('app.color.page_gradient_end'), 0.4],
          [$r('app.color.list_area_background'), 0.78],
          [$r('app.color.list_area_background'), 1.0]
        ]
      })
      .onRefreshing(async () => {
        await this.queryToDoPlan()
        this.refreshing = false
      })
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_, value) => {
      this.updateResponsiveSpacing(value.width as number)
    })
  }
}