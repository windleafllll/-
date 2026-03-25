import { router } from '@kit.ArkUI'

interface FurtherTimeItem {
  id: number
  title: string
  targetTime: number // ms
  createdAt: number // ms
}

interface LocalDatePickerResult {
  year: number
  month: number
  day: number
}

@CustomDialog
struct FurtherTimeCreateDialog {
  controllerTwo?: CustomDialogController
  initTitle?: string
  initTarget?: Date
  dialogHeader?: string
  onConfirm?: (title: string, target: Date) => boolean
  @State title: string = ''
  @State target: Date = new Date()

  aboutToAppear(): void {
    this.title = this.initTitle ?? ''
    this.target = this.initTarget ?? new Date()
  }

  private formatDateYMD(time: number): string {
    const d = new Date(time)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  build() {
    Column({ space: 12 }) {
      Text(this.dialogHeader ?? '创建计划')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)

      Column({ space: 8 }) {
        Text('计划名称')
          .fontSize(12)
          .fontColor(Color.Gray)
        TextInput({ placeholder: '请输入计划名称', text: this.title })
          .borderRadius(10)
          .padding(10)
          .backgroundColor('#f5f5f5')
          .onChange((value: string) => {
            this.title = value
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 8 }) {
        Text('实现日期（年月日）')
          .fontSize(12)
          .fontColor(Color.Gray)
        Row() {
          Text(this.formatDateYMD(this.target.getTime()))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Blank()
          Button('选择日期', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .onClick(() => {
              DatePickerDialog.show({
                selected: this.target,
                onAccept: (value: LocalDatePickerResult) => {
                  this.target = new Date(value.year, value.month, value.day)
                }
              })
            })
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor('#f5f5f5')
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 10 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor('#e8e8e8')
          .fontColor(Color.Black)
          .onClick(() => {
            this.controllerTwo?.close()
          })
        Button('确定')
          .layoutWeight(1)
          .backgroundColor('#f6726e')
          .onClick(() => {
            const ok = this.onConfirm?.(this.title, this.target) ?? true
            if (ok) {
              this.controllerTwo?.close()
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .alignItems(HorizontalAlign.Start)
  }
}

@CustomDialog
struct FurtherTimeDeleteDialog {
  controllerTwo?: CustomDialogController
  planTitle?: string
  onConfirmDelete?: () => void

  build() {
    Column({ space: 16 }) {
      Text('删除确认')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Text(`确定删除「${this.planTitle ?? ''}」吗？`)
        .fontSize(14)
        .fontColor(Color.Gray)
      Row({ space: 10 }) {
        // 按你的要求：取消更明显
        Button('取消')
          .layoutWeight(1)
          .backgroundColor('#f6726e')
          .fontColor(Color.White)
          .onClick(() => {
            this.controllerTwo?.close()
          })
        // 确定弱化
        Button('确定')
          .layoutWeight(1)
          .backgroundColor('#e8e8e8')
          .fontColor('#666666')
          .onClick(() => {
            this.onConfirmDelete?.()
            this.controllerTwo?.close()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@Component
struct FurtherTime {
  @State list: FurtherTimeItem[] = []
  @State dialogTitle: string = ''
  @State dialogTarget: Date = new Date()
  @State editingId: number | null = null
  @State listPadding: number = 15
  @State cardPadding: number = 15
  private dialogController: CustomDialogController | null = null
  private deleteDialogController: CustomDialogController | null = null

  aboutToAppear(): void {
    // 初始化持久化键（若已存在则不会覆盖）
    PersistentStorage.persistProp('FurtherTimeList', '[]')
    this.refreshListFromStorage()
  }

  private refreshListFromStorage() {
    const raw = AppStorage.get('FurtherTimeList') as string
    try {
      const parsed = JSON.parse(raw) as FurtherTimeItem[]
      if (Array.isArray(parsed)) {
        // 简单过滤，避免脏数据导致渲染报错
        this.list = parsed.filter((it) => typeof it?.title === 'string' && typeof it?.targetTime === 'number')
          .sort((a, b) => a.targetTime - b.targetTime)
        return
      }
    } catch (e) {
    }
    this.list = []
  }

  private saveListToStorage(next: FurtherTimeItem[]) {
    // 先计算新的列表快照
    const latestList = next
      .filter((it) => typeof it?.title === 'string' && typeof it?.targetTime === 'number')
      .sort((a, b) => a.targetTime - b.targetTime)
    // 强制触发一次列表重绘，避免编辑后 UI 不刷新的情况
    this.list = []
    setTimeout(() => {
      this.list = latestList
    }, 0)
    AppStorage.setOrCreate('FurtherTimeList', JSON.stringify(next))
  }

  private formatDateYMD(time: number): string {
    const d = new Date(time)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private remainingText(targetTime: number): string {
    const now = Date.now()
    const diff = targetTime - now
    if (diff <= 0) {
      return '已到期'
    }
    const totalMinutes = Math.floor(diff / 60000)
    const days = Math.floor(totalMinutes / (60 * 24))
    const hours = Math.floor((totalMinutes % (60 * 24)) / 60)
    const mins = totalMinutes % 60
    if (days > 0) {
      return `剩余 ${days}天${hours}小时`
    }
    if (hours > 0) {
      return `剩余 ${hours}小时${mins}分钟`
    }
    return `剩余 ${mins}分钟`
  }

  private updateResponsiveLayout(width: number) {
    this.listPadding = width >= 900 ? 24 : 15
    this.cardPadding = width >= 900 ? 20 : 15
  }

  private openCreateDialog() {
    this.dialogTitle = ''
    // 默认选明天
    this.dialogTarget = new Date(Date.now() + 24 * 60 * 60 * 1000)
    this.editingId = null
    // 每次打开都重建 controller，确保弹窗拿到最新 init 值
    this.dialogController = new CustomDialogController({
      builder: FurtherTimeCreateDialog({
        dialogHeader: '创建计划',
        initTitle: this.dialogTitle,
        initTarget: this.dialogTarget,
        onConfirm: (title: string, target: Date) => {
          this.dialogTitle = title
          this.dialogTarget = target
          return this.confirmSave()
        }
      }),
      cornerRadius: 15,
      width: '86%'
    })
    this.dialogController?.open()
  }

  private openEditDialog(item: FurtherTimeItem) {
    this.dialogTitle = item.title
    this.dialogTarget = new Date(item.targetTime)
    this.editingId = item.id
    this.dialogController = new CustomDialogController({
      builder: FurtherTimeCreateDialog({
        dialogHeader: '修改计划',
        initTitle: this.dialogTitle,
        initTarget: this.dialogTarget,
        onConfirm: (title: string, target: Date) => {
          this.dialogTitle = title
          this.dialogTarget = target
          return this.confirmSave()
        }
      }),
      cornerRadius: 15,
      width: '86%'
    })
    this.dialogController?.open()
  }

  private confirmSave(): boolean {
    if (this.dialogTitle.trim() === '') {
      AlertDialog.show({ title: '提示', message: '请输入计划名称' })
      return false
    }
    // 目标日期按当天 23:59:59 计算，避免早上就“到期”
    const d = new Date(this.dialogTarget)
    d.setHours(23, 59, 59, 999)
    let next: FurtherTimeItem[] = []
    if (this.editingId == null) {
      const item: FurtherTimeItem = {
        id: Date.now(),
        title: this.dialogTitle.trim(),
        targetTime: d.getTime(),
        createdAt: Date.now()
      }
      next = this.list.slice()
      next.push(item)
    } else {
      next = this.list.map((it) => {
        if (it.id === this.editingId) {
          const updated: FurtherTimeItem = {
            id: it.id,
            title: this.dialogTitle.trim(),
            targetTime: d.getTime(),
            createdAt: it.createdAt
          }
          return updated
        }
        return it
      })
    }
    this.saveListToStorage(next)
    this.editingId = null
    return true
  }

  private confirmDelete(item: FurtherTimeItem) {
    this.deleteDialogController = new CustomDialogController({
      builder: FurtherTimeDeleteDialog({
        planTitle: item.title,
        onConfirmDelete: () => {
          const next = this.list.filter((it) => it.id !== item.id)
          this.saveListToStorage(next)
        }
      }),
      cornerRadius: 15,
      width: '80%'
    })
    this.deleteDialogController?.open()
  }

  @Builder
  private deleteSwipeAction(item: FurtherTimeItem) {
    Row() {
      Button('删除')
        .height('100%')
        .backgroundColor(Color.Red)
        .fontColor(Color.White)
        .onClick(() => {
          this.confirmDelete(item)
        })
    }
    .height('100%')
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
      Text('未来倒计时')
        .fontWeight(FontWeight.Bold)
        .fontSize(18)
        .fontColor(Color.White)
      Blank()
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Image($r('app.media.ic_user_jiahao'))
          .width(22)
          .fillColor(Color.White)
      }
      .backgroundColor(Color.Transparent)
      .padding(6)
      .onClick(() => {
        this.openCreateDialog()
      })
    }
    .width('100%')
    .backgroundColor('#f6726e')
    .padding({ left: 15, right: 15 })
  }

  build() {
    Navigation() {
      Column() {
        if (this.list.length === 0) {
          Column({ space: 20 }) {
            Image($r('app.media.ic_tool_box'))
              .width(30)
            Text('当前没有未来倒计时，点击右上角 + 号创建一个吧')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
          }
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#fff1f1f1')
          .width('100%')
          .height('100%')
        } else {
          List({ space: 12 }) {
            ForEach(this.list, (v: FurtherTimeItem) => {
              ListItem() {
                Column({ space: 6 }) {
                  Row() {
                    Text(v.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                    Blank()
                    Text(this.remainingText(v.targetTime))
                      .fontSize(12)
                      .fontColor('#f6726e')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')

                  Text(`目标日期：${this.formatDateYMD(v.targetTime)}`)
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }
                .padding(this.cardPadding)
                .borderRadius(12)
                .backgroundColor(Color.White)
                .width('100%')
              }
              .onClick(() => {
                this.openEditDialog(v)
              })
              .swipeAction({ end: this.deleteSwipeAction(v) })
            }, (item: FurtherTimeItem) => item.id.toString())
          }
          .padding(this.listPadding)
          .backgroundColor('#fff1f1f1')
          .width('100%')
          .height('100%')
        }
      }
      .width('100%')
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .title(this.navigationTitle())
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      direction: GradientDirection.Bottom, // 渐变方向
      repeating: false, // 渐变颜色是否重复
      colors: [['#f6726e', 0.5], ['#fff1f1f1', 0.9]] // 数组末尾元素占比小于1时满足重复着色效果
    })
  }
}