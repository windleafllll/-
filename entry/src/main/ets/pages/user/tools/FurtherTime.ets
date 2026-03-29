import { router } from '@kit.ArkUI'
import { furtherTimeDB, FurtherTimeDBInfo } from '../../../database/FurtherTimeDB'

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
  onConfirm?: (title: string, target: Date) => Promise<boolean>
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
        .fontColor($r('app.color.text_primary'))

      Column({ space: 8 }) {
        Text('计划名称')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        TextInput({ placeholder: '请输入计划名称', text: this.title })
          .borderRadius(10)
          .border({ width: 1, color: $r('app.color.input_border') })
          .padding(10)
          .backgroundColor($r('app.color.dialog_input_surface'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_hint'))
          .onChange((value: string) => {
            this.title = value
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 8 }) {
        Text('实现日期（年月日）')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Row() {
          Text(this.formatDateYMD(this.target.getTime()))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
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
        .border({ width: 1, color: $r('app.color.input_border') })
        .backgroundColor($r('app.color.dialog_input_surface'))
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 10 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor($r('app.color.dialog_button_secondary_bg'))
          .fontColor($r('app.color.dialog_button_secondary_text'))
          .onClick(() => {
            this.controllerTwo?.close()
          })
        Button('确定')
          .layoutWeight(1)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor($r('app.color.text_on_brand'))
          .onClick(async () => {
            const ok = await (this.onConfirm?.(this.title, this.target) ?? Promise.resolve(true))
            if (ok) {
              this.controllerTwo?.close()
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(18)
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
        .fontColor($r('app.color.text_primary'))
      Text(`确定删除「${this.planTitle ?? ''}」吗？`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
      Row({ space: 10 }) {
        // 按你的要求：取消更明显
        Button('取消')
          .layoutWeight(1)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor($r('app.color.text_on_brand'))
          .onClick(() => {
            this.controllerTwo?.close()
          })
        // 确定弱化
        Button('确定')
          .layoutWeight(1)
          .backgroundColor($r('app.color.dialog_button_secondary_bg'))
          .fontColor($r('app.color.dialog_button_secondary_text'))
          .onClick(() => {
            this.onConfirmDelete?.()
            this.controllerTwo?.close()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(18)
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
    this.refreshListFromDB()
  }

  private async refreshListFromDB() {
    const dbList = await furtherTimeDB.query()
    const next: FurtherTimeItem[] = []
    for (let i = 0; i < dbList.length; i++) {
      const row = dbList[i]
      if (row.id != null) {
        next.push({
          id: row.id,
          title: row.title,
          targetTime: row.targetTime,
          createdAt: row.createdAt
        })
      }
    }
    this.list = next
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
      customStyle: true,
      cornerRadius: 18,
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
      customStyle: true,
      cornerRadius: 18,
      width: '86%'
    })
    this.dialogController?.open()
  }

  private async confirmSave(): Promise<boolean> {
    if (this.dialogTitle.trim() === '') {
      AlertDialog.show({ title: '提示', message: '请输入计划名称' })
      return false
    }
    // 目标日期按当天 23:59:59 计算，避免早上就“到期”
    const d = new Date(this.dialogTarget)
    d.setHours(23, 59, 59, 999)
    if (this.editingId == null) {
      const item: FurtherTimeDBInfo = {
        id: null,
        title: this.dialogTitle.trim(),
        targetTime: d.getTime(),
        createdAt: Date.now()
      }
      await furtherTimeDB.insert(item)
    } else {
      let oldCreatedAt = Date.now()
      for (let i = 0; i < this.list.length; i++) {
        if (this.list[i].id === this.editingId) {
          oldCreatedAt = this.list[i].createdAt
          break
        }
      }
      await furtherTimeDB.update({
        id: this.editingId,
        title: this.dialogTitle.trim(),
        targetTime: d.getTime(),
        createdAt: oldCreatedAt
      })
    }
    await this.refreshListFromDB()
    this.editingId = null
    return true
  }

  private confirmDelete(item: FurtherTimeItem) {
    this.deleteDialogController = new CustomDialogController({
      builder: FurtherTimeDeleteDialog({
        planTitle: item.title,
        onConfirmDelete: () => {
          furtherTimeDB.delete(item.id).then(() => {
            this.refreshListFromDB()
          })
        }
      }),
      customStyle: true,
      cornerRadius: 18,
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
        .fillColor($r('app.color.subpage_nav_bar_fg'))
        .onClick(() => {
          router.back()
        })
      Text('未来倒计时')
        .fontWeight(FontWeight.Bold)
        .fontSize(18)
        .fontColor($r('app.color.subpage_nav_bar_fg'))
      Blank()
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Image($r('app.media.ic_user_jiahao'))
          .width(22)
          .fillColor($r('app.color.subpage_nav_bar_fg'))
      }
      .backgroundColor(Color.Transparent)
      .padding(6)
      .onClick(() => {
        this.openCreateDialog()
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.subpage_nav_bar_bg'))
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
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
          }
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.list_area_background'))
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
                      .fontColor($r('app.color.text_primary'))
                    Blank()
                    Text(this.remainingText(v.targetTime))
                      .fontSize(12)
                      .fontColor($r('app.color.brand_primary'))
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')

                  Text(`目标日期：${this.formatDateYMD(v.targetTime)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_meta_emphasis'))
                }
                .padding(this.cardPadding)
                .borderRadius(12)
                .backgroundColor($r('app.color.card_background'))
                .width('100%')
              }
              .onClick(() => {
                this.openEditDialog(v)
              })
              .swipeAction({ end: this.deleteSwipeAction(v) })
            }, (item: FurtherTimeItem) => item.id.toString())
          }
          .padding(this.listPadding)
          .backgroundColor($r('app.color.list_area_background'))
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
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [
        [$r('app.color.page_gradient_1'), 0.45],
        [$r('app.color.page_gradient_end'), 0.92]
      ]
    })
  }
}