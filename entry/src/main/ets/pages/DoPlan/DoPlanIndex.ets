import { promptAction, router, window } from '@kit.ArkUI'
import { toDoPlanDB } from '../../database/ToDoPlanDB'
import { avPlayerManager } from '../../manage/AVPlayerManage'
import { common } from '@kit.AbilityKit'
import { planDB } from '../../database/PlanDB'

interface RouterParams {
  id?: number
}

/** 与 onAreaChange 系统回调兼容：Length = string | number | Resource */
interface DoPlanOnAreaValue {
  width: string | number | Resource
  height: string | number | Resource
}

interface chooseMusic {
  id: number
  title: string
  isChoose: boolean
  src: string
}

function createDefaultNoiseList(): chooseMusic[] {
  return [
    { id: 0, title: '愉快海滩', isChoose: false, src: 'Pleasant_Beach.mp3' },
    { id: 1, title: '小溪', isChoose: false, src: 'Small_Rapid.mp3' },
    { id: 2, title: '鸟鸣', isChoose: false, src: 'Songbirds.mp3' },
    { id: 3, title: '气泡水', isChoose: false, src: 'Sparkling_Water.mp3' },
    { id: 4, title: '热带雨', isChoose: false, src: 'Tropical_Rain.mp3' }
  ]
}

@CustomDialog
struct CustomDialogExample {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 20 }) {
      Row({ space: 12 }) {
        Column()
          .width(4)
          .height(40)
          .borderRadius(2)
          .backgroundColor($r('app.color.brand_warning'))

        Column({ space: 8 }) {
          Text('计划尚未完成')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text('确定要放弃本次专注吗？退出后本次进度将不会计入完成记录。')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .lineHeight(22)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row({ space: 12 }) {
        Row() {
          Text('继续专注')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.dialog_button_secondary_text'))
        }
        .layoutWeight(1)
        .height(46)
        .justifyContent(FlexAlign.Center)
        .borderRadius(14)
        .backgroundColor($r('app.color.dialog_button_secondary_bg'))
        .border({ width: 1, color: $r('app.color.input_border') })
        .clip(true)
        .onClick(() => {
          this.controllerTwo?.close()
        })

        Row() {
          Text('确定放弃')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_destructive'))
        }
        .layoutWeight(1)
        .height(46)
        .justifyContent(FlexAlign.Center)
        .borderRadius(14)
        .backgroundColor($r('app.color.delete_icon_button_bg'))
        .border({ width: 1, color: $r('app.color.text_destructive') })
        .clip(true)
        .onClick(async () => {
          if (this.controllerTwo != undefined) {
            await avPlayerManager.stop()
            this.controllerTwo.close()
            router.back()
          }
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(22)
    .borderRadius(18)
    .backgroundColor($r('app.color.noise_dialog_panel'))
    .border({ width: 1, color: $r('app.color.noise_dialog_border') })
  }
}

@CustomDialog
struct CustomDialogChooseNoise {
  controllerTwo?: CustomDialogController
  onSelectNoise?: (title: string, src: string) => Promise<void>
  @State list: chooseMusic[] = createDefaultNoiseList()

  private markSelected(selectedId: number): void {
    const next: chooseMusic[] = []
    for (let i = 0; i < this.list.length; i++) {
      const v = this.list[i]
      next.push({
        id: v.id,
        title: v.title,
        isChoose: v.id === selectedId,
        src: v.src
      })
    }
    this.list = next
  }

  build() {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text('专注背景音')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('点选即可试听，当前播放项会高亮显示')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(20)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.list, (v: chooseMusic) => {
            Row({ space: 12 }) {
              Column() {
                Text('♪')
                  .fontSize(17)
                  .fontColor(v.isChoose ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
              }
              .width(40)
              .height(40)
              .borderRadius(20)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(v.isChoose ? $r('app.color.noise_dialog_icon_selected') :
                $r('app.color.noise_dialog_icon_bg'))

              Text(v.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)

              if (v.isChoose) {
                Text('播放中')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.brand_primary'))
              }
            }
            .width('100%')
            .padding({
              left: 14,
              right: 14,
              top: 12,
              bottom: 12
            })
            .borderRadius(14)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(v.isChoose ? $r('app.color.noise_dialog_row_selected') :
              $r('app.color.noise_dialog_row'))
            .border({
              width: v.isChoose ? 2 : 1,
              color: v.isChoose ? $r('app.color.brand_primary') : $r('app.color.noise_dialog_border')
            })
            .onClick(async () => {
              await this.onSelectNoise?.(v.title, v.src)
              await avPlayerManager.playByRawSrc(v.src)
              this.markSelected(v.id)
              this.controllerTwo?.close()
            })
          }, (v: chooseMusic) => `noise_${v.id}`)
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: 340 })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Row() {
        Text('取消')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.dialog_button_secondary_text'))
      }
      .width('100%')
      .height(46)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(23)
      .backgroundColor($r('app.color.noise_dialog_close_bg'))
      .border({ width: 1, color: $r('app.color.noise_dialog_border') })
      .clip(true)
      .onClick(() => {
        this.controllerTwo?.close()
      })
    }
    .width('100%')
    .padding(22)
    .borderRadius(18)
    .backgroundColor($r('app.color.noise_dialog_panel'))
    .border({ width: 1, color: $r('app.color.noise_dialog_border') })
  }
}

@Entry
@Component
struct DoPlanIndex {
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogExample(),
    cancel: () => {
      this.isTimerRun = true
    },
    customStyle: true,
    cornerRadius: 20,
    width: '82%'
  })
  dialogChooseMusic: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogChooseNoise({
      onSelectNoise: async (title: string, src: string): Promise<void> => {
        await this.setNoise(title, src)
      }
    }),
    cancel: () => {
      // 用户仅打开/关闭选择框不改变状态
    },
    customStyle: true,
    cornerRadius: 20,
    width: '76%'
  })
  @State list: string[] =
    ['Songbirds.mp3', 'Tropical_Rain.mp3', 'Pleasant_Beach.mp3', 'Small_Rapid.mp3', 'Sparkling_Water.mp3']
  @State backgroundNumber: string[] =
    ['app.media.ic_doplan_back_1', 'app.media.ic_doplan_back_2', 'app.media.ic_doplan_back_3',
      'app.media.ic_doplan_back_4',
      'app.media.ic_doplan_back_5',]
  // 页面参数
  @State routerParams: RouterParams = {}
  @State type: string = ''
  @State times: number = 0
  @State value: number = 0
  @State intervalID1: number = 0
  @State intervalID2: number = 0
  @State title: string = ''
  @State min: number = 0
  @State second: number = 0
  @State isAccomplish: boolean = true
  @State isTimerRun: boolean = true
  @State isAVPlayerRun: boolean = false
  @State isScreenOn: boolean = false
  @State timeRan: number = 0
  @State ringSize: string = '70%'
  @State controlIconSize: number = 40
  @State noiseTitle: string = ''
  @State noiseSrc: string = ''
  @State noiseMarquee: string = ''
  @State noiseBarPadding: number = 16
  @State noiseBarHeight: number = 44
  @State marqueeIntervalId: number = 0
  private marqueeOffset: number = 0
  // 执行计划页锁定：禁止除“结束计划”外的退出行为（至少拦截 Tab 切换）
  @StorageLink('InPlanPage') inPlanPage: boolean = true
  @StorageLink('PlanChangedAt') planChangedAt: number = 0

  aboutToAppear(): void {
    this.inPlanPage = true
    const params = router.getParams() as RouterParams
    if (params) {
      this.routerParams = params
      this.getDetail()
    }
    if (this.type != '不计时') {
      this.intervalID1 = setInterval(async () => {
        if (this.isTimerRun) {
          if (this.type == '倒计时') {
            this.value = this.value - 1
            if (this.min != 0 || this.second != 0) {
              if (this.second <= 0) {
                this.second = 59
                this.min = this.min - 1
              } else {
                this.second = this.second - 1
              }
            } else {
              this.isAccomplish = true
              clearInterval(this.intervalID1)
              await avPlayerManager.stop()
              this.isAVPlayerRun = true
              avPlayerManager.playByRawSrc('winner.mp3')
            }
          } else if (this.type == '正向计时') {
            if (this.second == 59) {
              this.second = 0
              this.min = this.min + 1
            } else {
              this.second = this.second + 1
            }
          }
        }
      }, 1000)
    }
    this.intervalID2 = setInterval(() => {
      this.timeRan = this.timeRan + 1
    }, 1000)
  }

  // 拦截系统返回键/返回手势：仅允许点击“结束计划”退出
  onBackPress(): boolean {
    promptAction.showToast({ message: '请点击结束计划按钮退出' })
    return true
  }

  async aboutToDisappear(): Promise<void> {
    this.inPlanPage = false
    // 离开页面时不做后台保活：直接停止白噪音
    // Plan.times 存实际专注秒数；未完成且不足 1 秒不写库，避免秒退产生无效条
    if (this.timeRan > 0 || this.isAccomplish) {
      planDB.insert({
        id: null,
        title: this.title,
        times: this.timeRan,
        is_accomplish: this.isAccomplish,
        date_added: Date.now(),
        todo_plan_id: this.routerParams.id ?? null
      })
      // 养习惯提醒内容依赖 PlanDB 的完成记录；更新 PlanChangedAt 触发重算日历提醒
      this.planChangedAt = Date.now()
    }
    clearInterval(this.intervalID1)
    clearInterval(this.intervalID2)
    if (this.marqueeIntervalId != 0) {
      clearInterval(this.marqueeIntervalId)
      this.marqueeIntervalId = 0
    }
    await avPlayerManager.stop()
    this.isAVPlayerRun = false
    this.noiseTitle = ''
    this.noiseSrc = ''
    this.noiseMarquee = ''
    this.keepScreenOn(false)
  }

  async keepScreenOn(status: boolean) {
    let windowClass = await window.getLastWindow(getContext(this) as common.BaseContext) //获取窗口实例
    await windowClass.setWindowKeepScreenOn(status) //设置窗口常亮或取消
    this.isScreenOn = await windowClass.getWindowProperties().isKeepScreenOn //查看屏幕常亮状态
  }

  async getDetail() {
    const list = await toDoPlanDB.query(this.routerParams.id)
    const detail = list[0]
    this.title = detail.title
    this.type = detail.type
    this.times = detail.times as number
    if (this.type == '倒计时') {
      this.min = this.times
      this.value = this.times * 60
      this.isAccomplish = false
    }
  }

  private parseLayoutWidth(w: string | number | Resource): number {
    if (typeof w === 'number') {
      return w
    }
    if (typeof w === 'string') {
      const n = Number.parseFloat(w)
      return Number.isNaN(n) ? 0 : n
    }
    return 0
  }

  private updateResponsiveLayout(width: number) {
    if (width >= 900) {
      this.ringSize = '46%'
      this.controlIconSize = 46
    } else {
      this.ringSize = '70%'
      this.controlIconSize = 40
    }
    this.noiseBarPadding = width >= 900 ? 24 : 16
    this.noiseBarHeight = width >= 900 ? 48 : 44
  }

  private async setNoise(title: string, src: string) {
    this.noiseTitle = title
    this.noiseSrc = src
    this.isAVPlayerRun = true
    this.updateNoiseBar()
    this.startMarqueeIfNeeded()
  }

  private updateNoiseBar() {
    if (this.noiseTitle == '') {
      this.noiseMarquee = ''
      return
    }
  }

  private startMarqueeIfNeeded() {
    if (this.marqueeIntervalId != 0) {
      clearInterval(this.marqueeIntervalId)
      this.marqueeIntervalId = 0
    }
    this.marqueeOffset = 0
    const title = this.noiseTitle
    const windowLen = 12
    if (title.length <= windowLen) {
      this.noiseMarquee = title
      return
    }
    const pad = '   '
    const full = title + pad + title + pad
    this.noiseMarquee = full.substring(0, windowLen)
    this.marqueeIntervalId = setInterval(() => {
      if (this.noiseTitle == '') {
        return
      }
      this.marqueeOffset = (this.marqueeOffset + 1) % title.length
      const start = this.marqueeOffset
      const slice = full.substring(start, start + windowLen)
      this.noiseMarquee = slice
    }, 220)
  }

  build() {
    Navigation() {
      Column() {
        Column() {
          if (this.type == '倒计时') {
            Column({ space: 14 }) {
              Text(this.title)
                .fontColor($r('app.color.text_on_gradient_primary'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)
                .width('100%')
              Text(this.min.toString() + '分' + this.second.toString() + '秒')
                .fontColor($r('app.color.text_on_gradient_subtle'))
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
              Stack({ alignContent: Alignment.Center }) {
                Circle()
                  .width(this.ringSize)
                  .height(this.ringSize)
                  .fill($r('app.color.splash_overlay_card'))
                Progress({ value: this.value, total: this.times * 60, type: ProgressType.Ring })
                  .width(this.ringSize)
                  .color($r('app.color.brand_primary'))
                  .backgroundColor($r('app.color.avatar_ring'))
                  .style({ strokeWidth: 6, enableScanEffect: true })
              }
              .width(this.ringSize)
              .aspectRatio(1)

              Text(this.isTimerRun ? '专注中' : '暂停中')
                .fontColor(this.isTimerRun ? $r('app.color.brand_primary') : $r('app.color.text_on_gradient_muted'))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .width('88%')
            .constraintSize({ maxWidth: 340 })
          } else if (this.type == '正向计时') {
            Column({ space: 16 }) {
              Text(this.title)
                .fontColor($r('app.color.text_on_gradient_primary'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)
                .width('100%')
              Text(this.min.toString() + '分' + this.second.toString() + '秒')
                .fontColor($r('app.color.text_on_gradient_subtle'))
                .fontSize(28)
                .fontWeight(FontWeight.Medium)
              Text(this.isTimerRun ? '专注中' : '暂停中')
                .fontColor(this.isTimerRun ? $r('app.color.brand_primary') : $r('app.color.text_on_gradient_muted'))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .width('88%')
            .constraintSize({ maxWidth: 340 })
          } else if (this.type == '不计时') {
            Column({ space: 14 }) {
              Text(this.title)
                .fontColor($r('app.color.text_on_gradient_primary'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)
                .width('100%')
              Text(this.isTimerRun ? '专注中' : '暂停中')
                .fontColor(this.isTimerRun ? $r('app.color.brand_primary') : $r('app.color.text_on_gradient_muted'))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .width('88%')
            .constraintSize({ maxWidth: 340 })
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')

        Column({ space: 12 }) {
          if (this.noiseTitle != '') {
            Row({ space: 10 }) {
              Row({ space: 6 }) {
                Circle()
                  .width(8)
                  .height(8)
                  .fill(this.isAVPlayerRun ? $r('app.color.brand_primary') : $r('app.color.text_hint'))
                Text(this.isAVPlayerRun ? '播放中' : '已暂停')
                  .fontColor(this.isAVPlayerRun ? $r('app.color.brand_primary') : $r('app.color.text_on_gradient_muted'))
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
              }

              Blank()
              Text(this.noiseMarquee == '' ? this.noiseTitle : this.noiseMarquee)
                .fontColor($r('app.color.text_on_gradient_primary'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
            .padding({
              left: this.noiseBarPadding,
              right: this.noiseBarPadding,
              top: 8,
              bottom: 8
            })
            .width('92%')
            .height(this.noiseBarHeight)
            .alignItems(VerticalAlign.Center)
          }

          Row() {
              Button({ type: ButtonType.Circle }) {
                if (this.isTimerRun == true) {
                  Image($r('app.media.ic_home_zanting'))
                    .fillColor($r('app.color.brand_primary'))
                    .width(this.controlIconSize - 14)
                    .height(this.controlIconSize - 14)
                } else {
                  Image($r('app.media.ic_home_play'))
                    .fillColor($r('app.color.brand_primary'))
                    .width(this.controlIconSize - 14)
                    .height(this.controlIconSize - 14)
                }
              }
              .width(this.controlIconSize + 8)
              .height(this.controlIconSize + 8)
              .backgroundColor($r('app.color.doplan_control_circle_bg'))
              .border({ width: 1, color: $r('app.color.doplan_control_circle_border') })
              .onClick(() => {
                this.isTimerRun = !this.isTimerRun
              })

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_doplan_music'))
                  .fillColor($r('app.color.brand_primary'))
                  .width(this.controlIconSize - 14)
                  .height(this.controlIconSize - 14)
              }
              .width(this.controlIconSize + 8)
              .height(this.controlIconSize + 8)
              .backgroundColor($r('app.color.doplan_control_circle_bg'))
              .border({ width: 1, color: $r('app.color.doplan_control_circle_border') })
              .onClick(async () => {
                if (this.noiseSrc == '') {
                  promptAction.showToast({ message: '请先选择一个白噪音' })
                  if (this.dialogChooseMusic != null) {
                    this.dialogChooseMusic.open()
                  }
                  return
                }
                if (this.isAVPlayerRun) {
                  avPlayerManager.pause()
                  this.isAVPlayerRun = false
                } else {
                  await avPlayerManager.playByRawSrc(this.noiseSrc)
                  this.isAVPlayerRun = true
                }
                this.updateNoiseBar()
              })

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_doplan_musics'))
                  .fillColor($r('app.color.brand_primary'))
                  .width(this.controlIconSize - 14)
                  .height(this.controlIconSize - 14)
              }
              .width(this.controlIconSize + 8)
              .height(this.controlIconSize + 8)
              .backgroundColor($r('app.color.doplan_control_circle_bg'))
              .border({ width: 1, color: $r('app.color.doplan_control_circle_border') })
              .onClick(() => {
                if (this.dialogChooseMusic != null) {
                  this.dialogChooseMusic.open()
                }
              })

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_doplan_sun'))
                  .width(this.controlIconSize - 14)
                  .height(this.controlIconSize - 14)
                  .fillColor(this.isScreenOn ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
              }
              .width(this.controlIconSize + 8)
              .height(this.controlIconSize + 8)
              .backgroundColor($r('app.color.doplan_control_circle_bg'))
              .border({
                width: 1,
                color: this.isScreenOn ? $r('app.color.doplan_control_circle_border') : $r('app.color.input_border')
              })
              .onClick(() => {
                if (this.isScreenOn) {
                  this.keepScreenOn(false)
                  promptAction.showToast({
                    message: '关闭屏幕常亮'
                  })
                } else {
                  this.keepScreenOn(true)
                  promptAction.showToast({
                    message: '打开屏幕常亮'
                  })
                }
              })

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_home_stop'))
                  .fillColor($r('app.color.text_destructive'))
                  .width(this.controlIconSize - 14)
                  .height(this.controlIconSize - 14)
              }
              .width(this.controlIconSize + 8)
              .height(this.controlIconSize + 8)
              .backgroundColor($r('app.color.delete_icon_button_bg'))
              .border({ width: 1, color: $r('app.color.text_destructive') })
              .onClick(async () => {
                this.isAVPlayerRun = false
                this.noiseTitle = ''
                this.noiseSrc = ''
                this.noiseMarquee = ''
                await avPlayerManager.stop()
                if (this.isAccomplish == false) {
                  if (this.dialogController != null) {
                    this.isTimerRun = false
                    this.dialogController.open()
                  }
                } else {
                  router.back()
                }
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            .padding({ bottom: 28, top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .onAreaChange((oldValue: DoPlanOnAreaValue, newValue: DoPlanOnAreaValue) => {
        this.updateResponsiveLayout(this.parseLayoutWidth(newValue.width))
      })
    }
    .backgroundImage($r(this.backgroundNumber[Math.floor(Math.random() * (5 - 0) + 0)]))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideBackButton(true)
  }
}