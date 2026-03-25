import {
  ItemRestriction,
  promptAction,
  router,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@kit.ArkUI'

import { wishWallDB, WishWallDBInfo } from '../../../database/WishWallDB'

interface WishRecord {
  id: string
  userId: number
  wishName: string
  createdAt: number
  effort: string
  originalWishId?: string
}

// 兼容历史存储：userId/createdAt 可能是字符串，effort/other 字段可能缺失
interface WishRecordRaw {
  id?: string
  userId?: number | string
  wishName?: string
  createdAt?: number | string
  effort?: string
  originalWishId?: string
}

interface WishWallSubmitPayload {
  mode: number // 0=许愿, 1=还原
  wishName: string
  effort: string
  originalWishId?: string
}

interface WishWallEditPayload {
  wishId: string
  userId: number
  createdAt: number
  wishName: string
  effort: string // '' 表示未还愿
}

interface WishOption {
  value: string
}

interface WishWallListItem {
  id: string
  text: string
  createdAt: number
}

@CustomDialog
struct CustomDialogNeedLogin {
  controllerTwo?: CustomDialogController
  onGoLogin?: () => void

  build() {
    Column({ space: 12 }) {
      Text('需要登录后才能许愿/还愿')
        .fontColor(Color.Black)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Row() {
        Button('直接跳转至登陆界面')
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor(Color.Blue)
          .onClick(() => {
            this.onGoLogin?.()
            this.controllerTwo?.close()
          })

        Button('取消')
          .fontSize(13)
          .fontColor(Color.Gray)
          .backgroundColor(Color.White)
          .onClick(() => {
            this.controllerTwo?.close()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding(18)
    .width('80%')
    .borderRadius(12)
    .backgroundColor('#fff')
  }
}

@CustomDialog
struct CustomDialogWishWall {
  controllerTwo?: CustomDialogController
  wishRecords: WishRecord[] = []
  onSubmit?: (payload: WishWallSubmitPayload) => Promise<void>
  @State mode: number = 0 // 0=许愿 1=还愿
  @State wishName: string = ''
  @State customRestoreName: string = ''
  @State restoreSelectedIndex: number = 0 // 0=自定义，其余=wishRecords[index-1]
  @State effort: string = ''

  private getRestoreCandidates(): WishRecord[] {
    const res: WishRecord[] = []
    for (let i = 0; i < this.wishRecords.length; i++) {
      const w = this.wishRecords[i]
      // 已还愿：effort 不为空，不允许再次选择
      if (w.effort == undefined || w.effort == '') {
        res.push(w)
      }
    }
    return res
  }

  private getRestoreOptions(): WishOption[] {
    const opts: WishOption[] = []
    opts.push({ value: '自定义' })
    const candidates = this.getRestoreCandidates()
    for (let i = 0; i < candidates.length; i++) {
      opts.push({ value: candidates[i].wishName })
    }
    return opts
  }

  private getSelectedRestoreName(): string {
    if (this.restoreSelectedIndex <= 0) {
      return this.customRestoreName
    }
    const idx = this.restoreSelectedIndex - 1
    const candidates = this.getRestoreCandidates()
    if (idx >= 0 && idx < candidates.length) {
      return candidates[idx].wishName
    }
    return this.customRestoreName
  }

  private getSelectedRestoreOriginalId(): string | undefined {
    if (this.restoreSelectedIndex <= 0) {
      return undefined
    }
    const idx = this.restoreSelectedIndex - 1
    const candidates = this.getRestoreCandidates()
    if (idx >= 0 && idx < candidates.length) {
      return candidates[idx].id
    }
    return undefined
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        Button('许愿')
          .fontSize(14)
          .fontColor(this.mode == 0 ? Color.White : '#f6726e')
          .backgroundColor(this.mode == 0 ? '#f6726e' : Color.White)
          .borderRadius(999)
          .height(40)
          .width('45%')
          .onClick(() => {
            this.mode = 0
            this.effort = ''
          })

        Button('还愿')
          .fontSize(14)
          .fontColor(this.mode == 1 ? Color.White : '#f6726e')
          .backgroundColor(this.mode == 1 ? '#f6726e' : Color.White)
          .borderRadius(999)
          .height(40)
          .width('45%')
          .onClick(() => {
            this.mode = 1
            this.restoreSelectedIndex = 0
            this.effort = ''
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      if (this.mode == 0) {
        TextInput({ placeholder: '请输入愿望名称', text: $$this.wishName })
          .width('100%')
          .height(40)
          .maxLength(20)
      } else {
        // build() 内必须只写 UI 声明，options 逻辑挪到 getRestoreOptions() 里
        Select(this.getRestoreOptions())
          .selected(this.restoreSelectedIndex)
          .value(this.restoreSelectedIndex == 0 ? '自定义' : this.getSelectedRestoreName())
          .onSelect((index: number, _value: string) => {
            this.restoreSelectedIndex = index
          })

        if (this.restoreSelectedIndex == 0) {
          TextInput({ placeholder: '输入自定义愿望名称', text: $$this.customRestoreName })
            .width('100%')
            .height(40)
            .maxLength(20)
        } else {
          Text('已选择：' + this.getSelectedRestoreName())
            .fontSize(13)
            .fontColor(Color.Gray)
            .fontWeight(FontWeight.Medium)
        }
      }

      if (this.mode == 1) {
        TextArea({ placeholder: '请输入愿望实现付出的努力（多行输入）', text: $$this.effort })
          .width('100%')
          .maxLines(5)
          .borderRadius(12)
          .padding(10)
          .maxLength(200)
      }

      Blank().height(8)

      Button('确认' + (this.mode == 0 ? '许愿' : '还愿'))
        .width('100%')
        .height(44)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#f6726e')
        .onClick(async () => {
          if (this.mode == 0) {
            if (this.wishName == '' || this.wishName == undefined) {
              promptAction.showToast({ message: '请输入愿望名称' })
              return
            }
          } else {
            if (this.restoreSelectedIndex == 0 &&
              (this.customRestoreName == '' || this.customRestoreName == undefined)) {
              promptAction.showToast({ message: '请输入自定义愿望名称' })
              return
            }
          }

          if (this.mode == 1) {
            if (this.effort == '' || this.effort == undefined) {
              promptAction.showToast({ message: '请输入愿望实现的努力' })
              return
            }
          }

          const finalWishName = this.mode == 0 ? this.wishName : this.getSelectedRestoreName()
          const originalId = this.mode == 1 ? this.getSelectedRestoreOriginalId() : undefined

          await this.onSubmit?.({
            mode: this.mode,
            wishName: finalWishName,
            effort: this.mode == 1 ? this.effort : '',
            originalWishId: originalId
          })

          this.controllerTwo?.close()
        })
    }
    .padding(18)
    .width('86%')
    .borderRadius(14)
    .backgroundColor('#fff')
  }
}

@CustomDialog
struct CustomDialogEditWishWall {
  controllerTwo?: CustomDialogController
  // 当前要编辑的愿望
  wishId: string = ''
  userId: number = 0
  createdAt: number = 0
  initialWishName: string = ''
  initialEffort: string = ''
  initialIsRestore: boolean = false
  onSubmit?: (payload: WishWallEditPayload) => Promise<void>
  @State mode: number = 0 // 0=许愿, 1=还原
  @State wishName: string = ''
  @State effort: string = ''

  // 初始化状态：根据传入的初始值决定 mode
  aboutToAppear() {
    this.mode = this.initialIsRestore ? 1 : 0
    this.wishName = this.initialWishName
    this.effort = this.initialEffort
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.mode == 0 ? '许愿编辑' : '还愿编辑')
          .fontSize(13)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#f6726e')
          .padding({
            left: 14,
            right: 14,
            top: 6,
            bottom: 6
          })
          .borderRadius(999)
      }
      .justifyContent(FlexAlign.Start)

      Column({ space: 8 }) {
        Text('愿望名称')
          .fontSize(13)
          .fontColor(Color.Gray)
          .fontWeight(FontWeight.Medium)

        if (this.mode == 0) {
          TextInput({ placeholder: '请输入愿望名称', text: $$this.wishName })
            .width('100%')
            .height(40)
            .maxLength(20)
        } else {
          Column() {
            Text(this.wishName)
              .fontSize(15)
              .fontColor('#9D174D')
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .width('100%')
              .padding(10)
          }
          .width('100%')
          .borderRadius(12)
          .backgroundColor('#F3F4F6')
        }
      }

      if (this.mode == 1) {
        Column({ space: 8 }) {
          Text('愿望实现付出的努力')
            .fontSize(13)
            .fontColor(Color.Gray)
            .fontWeight(FontWeight.Medium)

          TextArea({ placeholder: '请输入努力（多行输入）', text: $$this.effort })
            .width('100%')
            .maxLines(5)
            .borderRadius(12)
            .padding(10)
            .maxLength(200)
        }
      }

      Blank().height(6)

      Button('确认修改')
        .width('100%')
        .height(44)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#f6726e')
        .onClick(async () => {
          if (this.wishName == '' || this.wishName == undefined) {
            promptAction.showToast({ message: '请输入愿望名称' })
            return
          }
          if (this.mode == 1 && (this.effort == '' || this.effort == undefined)) {
            promptAction.showToast({ message: '请输入愿望实现的努力' })
            return
          }

          const finalEffort = this.mode == 1 ? this.effort : ''
          await this.onSubmit?.({
            wishId: this.wishId,
            userId: this.userId,
            createdAt: this.createdAt,
            wishName: this.wishName,
            effort: finalEffort
          })

          this.controllerTwo?.close()
        })
    }
    .padding(18)
    .width('86%')
    .borderRadius(14)
    .backgroundColor('#fff')
  }
}

@Entry
@Component
struct StudyRoom {
  @State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: '自习室' }, { text: '许愿墙' }] as ItemRestriction<SegmentButtonTextItem>,
    selectedFontColor: '#f6726e',
    selectedFontWeight: FontWeight.Bold,
    backgroundColor: '#31f6726e',
    backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
  })
  @State tabSelectedIndexes: number[] = [0]
  @State Choose: number = 0
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @StorageLink('id') user_id: number = 0
  @StorageLink('WishWallOpenAfterLogin') wishWallOpenAfterLogin: boolean = false
  @State wishRecords: WishRecord[] = []
  // 跑马灯：按钮下面从左往右飘过去
  @State marqueeDisplay: string = ''
  @State marqueeDisplay2: string = ''
  private marqueeSource: string = ''
  private marqueeFull: string = ''
  private marqueeOffset: number = 0
  private marqueeIntervalId: number = 0
  // 每行展示的字符数（越大，展示内容越多）
  private marqueeWindowLen: number = 120
  // 下方可滚动列表：展示大量假数据 + 用户愿望
  @State wishWallScrollItems: WishWallListItem[] = []
  private needLoginDialog: CustomDialogController | null = null
  private wishWallDialog: CustomDialogController | null = null
  private editWishDialog: CustomDialogController | null = null

  async aboutToAppear(): Promise<void> {
    await this.loadWishRecordsFromStorage()

    if (this.wishWallOpenAfterLogin) {
      this.Choose = 1
      this.wishWallOpenAfterLogin = false
      await this.loadWishRecordsFromStorage()
      this.openWishWallDialog()
    }
  }

  aboutToDisappear(): void {
    if (this.marqueeIntervalId != 0) {
      clearInterval(this.marqueeIntervalId)
      this.marqueeIntervalId = 0
    }
  }

  private formatTime(time: number): string {
    const d = new Date(time)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    const hh = d.getHours().toString().padStart(2, '0')
    const mm = d.getMinutes().toString().padStart(2, '0')
    return `${y}-${m}-${day} ${hh}:${mm}`
  }

  private getWishList(): WishRecord[] {
    const res: WishRecord[] = []
    for (let i = 0; i < this.wishRecords.length; i++) {
      const w = this.wishRecords[i]
      if (w.originalWishId == undefined || w.originalWishId == '') {
        res.push(w)
      }
    }
    return res
  }

  private getRestoreList(): WishRecord[] {
    const res: WishRecord[] = []
    for (let i = 0; i < this.wishRecords.length; i++) {
      const w = this.wishRecords[i]
      if (w.originalWishId != undefined && w.originalWishId != '') {
        res.push(w)
      }
    }
    return res
  }

  private getWishNameById(wishId?: string): string {
    if (wishId == undefined || wishId == '') {
      return ''
    }
    for (let i = 0; i < this.wishRecords.length; i++) {
      const w = this.wishRecords[i]
      if (w.id == wishId) {
        return w.wishName
      }
    }
    return '未知愿望'
  }

  private isRestoreRecord(v: WishRecord): boolean {
    // 兼容旧数据：历史版本可能用 originalWishId 标记“已还愿”
    // 新逻辑：还愿会更新原记录并用 effort 是否存在来标记
    return (v.originalWishId != undefined && v.originalWishId != '') || (v.effort != undefined && v.effort != '')
  }

  private getWishDisplayTitle(v: WishRecord): string {
    if (this.isRestoreRecord(v)) {
      return v.wishName + '（已还愿）'
    }
    return v.wishName
  }

  private getAllWishRecordsSorted(): WishRecord[] {
    const res: WishRecord[] = []
    for (let i = 0; i < this.wishRecords.length; i++) {
      res.push(this.wishRecords[i])
    }
    res.sort((a: WishRecord, b: WishRecord) => b.createdAt - a.createdAt)
    return res
  }

  private marqueeReset(nextSource: string) {
    // 限制长度，避免字符串无限增长影响性能
    const maxLen = 8000
    const safeSource = nextSource.length > maxLen ? nextSource.substring(nextSource.length - maxLen) : nextSource
    this.marqueeSource = safeSource
    this.marqueeFull = safeSource + '   ' + safeSource
    this.marqueeOffset = 0
    this.marqueeDisplay = this.marqueeFull.substring(0, this.marqueeWindowLen)
    const start2 = Math.floor(this.marqueeWindowLen / 2)
    this.marqueeDisplay2 = this.marqueeFull.substring(start2, start2 + this.marqueeWindowLen)
  }

  private startMarquee() {
    if (this.marqueeIntervalId != 0) {
      clearInterval(this.marqueeIntervalId)
    }
    if (this.marqueeSource.length <= this.marqueeWindowLen) {
      return
    }

    this.marqueeIntervalId = setInterval(() => {
      if (this.marqueeSource.length == 0) {
        return
      }
      this.marqueeOffset = (this.marqueeOffset + 1) % this.marqueeSource.length
      const start = this.marqueeOffset
      this.marqueeDisplay = this.marqueeFull.substring(start, start + this.marqueeWindowLen)
      const start2 = start + Math.floor(this.marqueeWindowLen / 2)
      this.marqueeDisplay2 = this.marqueeFull.substring(start2, start2 + this.marqueeWindowLen)
    }, 120)
  }

  private initMarqueeFakeData() {
    const now = Date.now()
    const fakeNames: string[] = [
      '早睡早起',
      '坚持背单词',
      '保持自律',
      '勇敢尝试',
      '把今天做到最好',
      '专注学习',
      '努力提升',
      '愿你顺利',
      '加油少年',
      '愿望成真'
    ]

    const parts: string[] = []
    const count = 240
    for (let i = 0; i < count; i++) {
      const name = fakeNames[i % fakeNames.length]
      const t = now - i * 30 * 60 * 1000 // 每条间隔 30 分钟
      parts.push(name + ' ' + this.formatTime(t))
    }
    const source = parts.join('   ')
    this.marqueeReset(source)
    this.startMarquee()
  }

  private buildWishWallScrollItems() {
    const now = Date.now()
    const fakeNames: string[] = [
      '早睡早起',
      '坚持背单词',
      '保持自律',
      '勇敢尝试',
      '把今天做到最好',
      '专注学习',
      '努力提升',
      '愿你顺利',
      '加油少年',
      '愿望成真'
    ]

    const fakeCount = 80
    const fakeItems: WishWallListItem[] = []
    for (let i = 0; i < fakeCount; i++) {
      const name = fakeNames[i % fakeNames.length]
      const t = now - i * 30 * 60 * 1000
      fakeItems.push({
        id: `fake_${i}`,
        text: name + ' ' + this.formatTime(t),
        createdAt: t
      })
    }

    const userItems: WishWallListItem[] = []
    for (let i = this.wishRecords.length - 1; i >= 0; i--) {
      const w = this.wishRecords[i]
      userItems.push({
        id: w.id,
        text: w.wishName + ' ' + this.formatTime(w.createdAt),
        createdAt: w.createdAt
      })
    }

    const combined = userItems.concat(fakeItems)
    this.wishWallScrollItems = []
    setTimeout(() => {
      this.wishWallScrollItems = combined
    }, 0)
  }

  private async loadWishRecordsFromStorage(): Promise<void> {
    if (this.user_id <= 0) {
      this.wishRecords = []
      return
    }
    // SQLite 持久化：直接从 DB 查询并刷新到状态
    try {
      const list = await wishWallDB.queryByUserId(this.user_id)
      this.wishRecords = list as WishRecord[]
    } catch (e) {
      this.wishRecords = []
    }
  }

  private saveWishRecordsToStorage(next: WishRecord[]) {
    // DB 模式下由 handleWishSubmit 负责 insert/update，这里不再使用
  }

  private openNeedLoginDialog() {
    this.needLoginDialog = new CustomDialogController({
      builder: CustomDialogNeedLogin({
        onGoLogin: () => {
          this.wishWallOpenAfterLogin = true
          router.pushUrl({ url: 'pages/user/UserLogin' }, router.RouterMode.Single)
        }
      }),
      cancel: () => {
      },
      cornerRadius: 14,
      width: '86%',
      customStyle: true
    })
    this.needLoginDialog.open()
  }

  private openWishWallDialog() {
    this.wishWallDialog = new CustomDialogController({
      builder: CustomDialogWishWall({
        wishRecords: this.wishRecords,
        onSubmit: async (payload: WishWallSubmitPayload) => {
          await this.handleWishSubmit(payload)
        }
      }),
      cancel: () => {
      },
      cornerRadius: 14,
      width: '88%',
      customStyle: true
    })
    this.wishWallDialog.open()
  }

  private openEditWishDialog(w: WishRecord) {
    this.editWishDialog = new CustomDialogController({
      builder: CustomDialogEditWishWall({
        wishId: w.id,
        userId: w.userId,
        createdAt: w.createdAt,
        initialWishName: w.wishName,
        initialEffort: w.effort,
        initialIsRestore: this.isRestoreRecord(w),
        onSubmit: async (payload: WishWallEditPayload) => {
          await this.handleWishEditSubmit(payload)
        }
      }),
      cancel: () => {
      },
      cornerRadius: 14,
      width: '88%',
      customStyle: true
    })
    this.editWishDialog.open()
  }

  private async handleWishSubmit(payload: WishWallSubmitPayload) {
    const now = Date.now()

    // 1) 许愿：新增记录
    if (payload.mode == 0) {
      const newId =
        this.user_id.toString() + '_' + now.toString() + '_' + Math.floor(Math.random() * 1000000).toString()
      const dbValue: WishWallDBInfo = {
        id: newId,
        userId: this.user_id,
        wishName: payload.wishName,
        createdAt: now,
        effort: ''
      }
      await wishWallDB.insert(dbValue)
      await this.loadWishRecordsFromStorage()
      promptAction.showToast({ message: '许愿成功' })
      return
    }

    // 2) 还原：更新原有记录（不是新增）
    const originalId = payload.originalWishId
    let didUpdate = false

    if (originalId != undefined && originalId != '') {
      // UI 弹窗传回原愿望 id，我们据此更新 DB 里的那条记录
      const found = this.wishRecords.find((w: WishRecord) => w.id == originalId)
      if (found) {
        const updated: WishWallDBInfo = {
          id: found.id,
          userId: found.userId,
          wishName: found.wishName,
          createdAt: found.createdAt,
          effort: payload.effort
        }
        await wishWallDB.update(updated)
        didUpdate = true
      }
    }

    // 如果找不到原记录（例如自定义还原），兜底新增
    if (!didUpdate) {
      const newId =
        this.user_id.toString() + '_' + now.toString() + '_' + Math.floor(Math.random() * 1000000).toString()
      const dbValue: WishWallDBInfo = {
        id: newId,
        userId: this.user_id,
        wishName: payload.wishName,
        createdAt: now,
        effort: payload.effort
      }
      await wishWallDB.insert(dbValue)
    }

    await this.loadWishRecordsFromStorage()
    promptAction.showToast({ message: '还愿成功' })
  }

  private async handleWishEditSubmit(payload: WishWallEditPayload) {
    const dbValue: WishWallDBInfo = {
      id: payload.wishId,
      userId: payload.userId,
      wishName: payload.wishName,
      createdAt: payload.createdAt, // 编辑时不改变许愿时间
      effort: payload.effort
    }
    await wishWallDB.update(dbValue)
    await this.loadWishRecordsFromStorage()
    promptAction.showToast({ message: '修改成功' })
  }

  private confirmDeleteWishOrRestore(w: WishRecord) {
    const isRestored = this.isRestoreRecord(w)
    AlertDialog.show({
      title: isRestored ? '删除还愿' : '删除愿望',
      message: isRestored ? '确定要删除该愿望的还愿记录吗？删除后将恢复为未还愿状态。' :
        '确定要删除该愿望吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: async () => {
          if (isRestored) {
            // 删除还愿：仅清空努力，保留愿望本身与原始许愿时间
            await wishWallDB.update({
              id: w.id,
              userId: w.userId,
              wishName: w.wishName,
              createdAt: w.createdAt,
              effort: ''
            })
            await this.loadWishRecordsFromStorage()
            promptAction.showToast({ message: '已删除还愿' })
          } else {
            // 删除愿望：整条记录删除
            await wishWallDB.delete(w.id, w.userId)
            await this.loadWishRecordsFromStorage()
            promptAction.showToast({ message: '已删除愿望' })
          }
        }
      }
    })
  }

  @Builder
  private deleteWishSwipeAction(item: WishRecord) {
    Row() {
      Button(this.isRestoreRecord(item) ? '删除还愿' : '删除愿望')
        .height('100%')
        .backgroundColor(Color.Red)
        .fontColor(Color.White)
        .onClick(() => {
          this.confirmDeleteWishOrRestore(item)
        })
    }
    .height('100%')
  }

  private async onWishWallClick() {
    // 许愿功能暂时停用登录校验（保留原逻辑，后续需要再开）
    if (false && this.isLogin == '未登录') {
      this.openNeedLoginDialog()
      return
    }
    await this.loadWishRecordsFromStorage()
    this.openWishWallDialog()
  }

  @Builder
  navigationTitle() {
    Row({ space: 10 }) {
      Image($r('app.media.ic_public_back'))
        .width(30)
        .fillColor(Color.White)
        .onClick(() => {
          router.back()
        })
      Text('自习室 | 许愿墙')
        .fontWeight(FontWeight.Bold)
        .fontSize(18)
        .fontColor(Color.White)
    }
    .width('100%')
    .backgroundColor('#f6726e')
    .padding({ left: 15, right: 15 })
  }

  build() {
    Navigation() {
      Column() {
        Column() {
          // SegmentButton({
          //   options: this.tabOptions,
          //   selectedIndexes: $tabSelectedIndexes,
          //   onItemClicked: (choose: number) => {
          //     this.Choose = choose
          //   }
          // })
          //   .width('50%')
          //   .margin({ bottom: 8 })
          //  this.Choose == 0

          if (false) {
            Column({ space: 40 }) {
              Button('创建自习室')
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .type(ButtonType.Circle)
                .width('28%')
                .backgroundColor('#ff60d1fd')
              Button('加入自习室')
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .type(ButtonType.Circle)
                .width('28%')
                .backgroundColor('#A7A8C6')
            }
          } else {
            Column({ space: 8 }) {
              Button('我要许愿 | 还愿')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#f6726e')
                .backgroundColor(Color.White)
                .borderRadius(12)
                .onClick(async () => {
                  await this.onWishWallClick()
                })

              if (this.wishRecords.length > 0) {
                List({ space: 10 }) {
                  ForEach(this.getAllWishRecordsSorted(), (v: WishRecord) => {
                    ListItem() {
                      Column({ space: 6 }) {
                        Text(this.getWishDisplayTitle(v))
                          .fontSize(15)
                          .fontColor('#9D174D')
                          .fontWeight(FontWeight.Bold)
                          .maxLines(2)

                        Text(this.formatTime(v.createdAt))
                          .fontSize(11)
                          .fontColor('#6B7280')
                          .fontWeight(FontWeight.Medium)
                      }
                      .padding({
                        left: 14,
                        right: 14,
                        top: 4,
                        bottom: 12
                      })
                      .borderRadius(14)
                      .backgroundColor('#FDF2F8')
                      .width('100%')
                    }
                    .swipeAction({ end: this.deleteWishSwipeAction(v) })
                    .onClick(() => {
                      this.openEditWishDialog(v)
                    })
                  })
                }
                .width('100%')
                .padding({
                  left: 14,
                  right: 14,
                  top: 0,
                  bottom: 30
                })
                .backgroundColor('#00000000')
              } else {
                Blank()
              }
            }
            .height('100%')
          }
        }
        .height('100%')
        .padding({ top: 10 })
      }
    }
    .title(this.navigationTitle())
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [['#f6726e', 0.5], ['#fff1f1f1', 0.9]]
    })
  }
}

