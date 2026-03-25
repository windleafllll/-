import { promptAction, router, Theme, window } from '@kit.ArkUI'
import { toDoPlanDB } from '../../database/ToDoPlanDB'
import { avPlayerManager } from '../../manage/AVPlayerManage'
import { common } from '@kit.AbilityKit'
import { planDB } from '../../database/PlanDB'

interface RouterParams {
  id?: number
}

interface chooseMusic {
  id: number
  title: string
  isChoose: boolean
  src: string
}

@CustomDialog
struct CustomDialogExample {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 10 }) {
      Text('注意')
        .fontColor('#fa7330')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      Text('您的计划尚未完成，您是否要放弃此次计划')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
      Row() {
        Button('确定放弃')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(Color.Gray)
          .onClick(async () => {
            if (this.controllerTwo != undefined) {
              // 退出/放弃时，确保白噪音停止
              await avPlayerManager.stop()
              this.controllerTwo.close()
              router.back()
            }
          })
      }
    }
    .width('75%')
    .borderRadius(15)
    .backgroundColor('#d2ffffff')
    .padding(20)
  }
}

@CustomDialog
struct CustomDialogChooseNoise {
  controllerTwo?: CustomDialogController
  onSelectNoise?: (title: string, src: string) => Promise<void>
  @State list: chooseMusic[] = [
    {
      id: 0,
      title: '愉快海滩',
      isChoose: false,
      src: 'Pleasant_Beach.mp3'
    },
    {
      id: 1,
      title: '小溪',
      isChoose: false,
      src: 'Small_Rapid.mp3'
    },
    {
      id: 2,
      title: '鸟鸣',
      isChoose: false,
      src: 'Songbirds.mp3'
    },
    {
      id: 3,
      title: '气泡水',
      isChoose: false,
      src: 'Sparkling_Water.mp3'
    },
    {
      id: 4,
      title: '热带雨',
      isChoose: false,
      src: 'Tropical_Rain.mp3'
    },
  ]

  build() {
    Column({ space: 20 }) {
      ForEach(this.list, (v: chooseMusic) => {
        if (v.isChoose == false) {
          Row() {
            Text(v.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          .padding(10)
          .width('70%')
          .borderRadius(15)
          .backgroundColor(Color.White)
          .onClick(async () => {
            // 先申请后台音频能力（setNoise 会调用 startBackgroundRunning），再开始播放
            await this.onSelectNoise?.(v.title, v.src)
            await avPlayerManager.playByRawSrc(v.src)
            this.list = [
              {
                id: 0,
                title: '愉快海滩',
                isChoose: false,
                src: 'Pleasant_Beach.mp3'
              },
              {
                id: 1,
                title: '小溪',
                isChoose: false,
                src: 'Small_Rapid.mp3'
              },
              {
                id: 2,
                title: '鸟鸣',
                isChoose: false,
                src: 'Songbirds.mp3'
              },
              {
                id: 3,
                title: '气泡水',
                isChoose: false,
                src: 'Sparkling_Water.mp3'
              },
              {
                id: 4,
                title: '热带雨',
                isChoose: false,
                src: 'Tropical_Rain.mp3'
              },
            ]
            this.list[v.id] = {
              id: v.id,
              title: v.title,
              isChoose: true,
              src: v.src
            }
          })
        } else {
          Row() {
            Text(v.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          .padding(10)
          .width('70%')
          .borderRadius(15)
          .backgroundColor('#ffbababa')
        }
      })
    }
    .width('100%')
    .backgroundColor('#fff1f1f1')
    .padding(20)
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
    cornerRadius: 15,
    width: '80%'
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
    cornerRadius: 15,
    width: '80%'
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
  @State contentHeight: string = '70%'
  @State actionHeight: string = '30%'
  @State noiseTitle: string = ''
  @State noiseSrc: string = ''
  @State noiseMarquee: string = ''
  @State noiseDotColor: string = '#ff8c8c8c'
  @State noiseBarPadding: number = 16
  @State noiseBarHeight: number = 44
  @State marqueeIntervalId: number = 0
  private marqueeOffset: number = 0
  // 执行计划页锁定：禁止除“结束计划”外的退出行为（至少拦截 Tab 切换）
  @StorageLink('InPlanPage') inPlanPage: boolean = true

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
    planDB.insert({
      id: null,
      title: this.title,
      times: this.timeRan,
      is_accomplish: this.isAccomplish,
      date_added: Date.now()
    })
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

  private updateResponsiveLayout(width: number, height: number) {
    if (width >= 900) {
      this.ringSize = '46%'
      this.controlIconSize = 46
    } else {
      this.ringSize = '70%'
      this.controlIconSize = 40
    }
    if (height >= 1100) {
      this.contentHeight = '72%'
      this.actionHeight = '28%'
    } else {
      this.contentHeight = '70%'
      this.actionHeight = '30%'
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
      this.noiseDotColor = '#ff8c8c8c'
      return
    }
    this.noiseDotColor = this.isAVPlayerRun ? '#ff00b877' : '#ff8c8c8c'
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
        if (this.type == '倒计时') {
          Column({ space: 10 }) {
            Text(this.title)
              .fontColor(Color.White)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
            Text(this.min.toString() + '分' + this.second.toString() + '秒')
              .fontColor(Color.White)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            Progress({ value: this.value, total: this.times * 60, type: ProgressType.Ring })
              .width(this.ringSize)
              .style({ strokeWidth: 5, enableScanEffect: true })
            if (this.isTimerRun) {
              Text('专注中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            } else {
              Text('暂停中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            }
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height(this.contentHeight)
        } else if (this.type == '正向计时') {
          Column({ space: 20 }) {
            Text(this.title)
              .fontColor(Color.White)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
            Text(this.min.toString() + '分' + this.second.toString() + '秒')
              .fontColor(Color.White)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            if (this.isTimerRun) {
              Text('专注中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            } else {
              Text('暂停中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            }
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height(this.contentHeight)
        } else if (this.type == '不计时') {
          Column({ space: 10 }) {
            Text(this.title)
              .fontColor(Color.White)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
            if (this.isTimerRun) {
              Text('专注中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            } else {
              Text('暂停中')
                .fontColor(Color.White)
                .fontSize(25)
                .fontWeight(FontWeight.Bold)
            }
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height(this.contentHeight)
        }
        // 底部操作区：状态栏 + 按钮区，使用 Column 垂直排列，避免叠层导致遮挡
        Column() {
          if (this.noiseTitle != '') {
            Row({ space: 10 }) {
              Row({ space: 6 }) {
                Circle()
                  .width(8)
                  .height(8)
                  .fill(this.noiseDotColor)
                Text(this.isAVPlayerRun ? '播放中' : '已暂停')
                  .fontColor(Color.White)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
              }

              Blank()
              Text(this.noiseMarquee == '' ? this.noiseTitle : this.noiseMarquee)
                .fontColor(Color.White)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
            .padding({
              left: this.noiseBarPadding,
              right: this.noiseBarPadding,
              top: 8,
              bottom: 8
            })
            .borderRadius(12)
            .backgroundColor('#33000000')
            .width('92%')
            .height(this.noiseBarHeight)
            .alignItems(VerticalAlign.Center)
          }

          Row() {
            Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
              if (this.isTimerRun == true) {
                Image($r('app.media.ic_home_zanting'))
                  .fillColor(Color.White)
                  .width(this.controlIconSize)
              } else {
                Image($r('app.media.ic_home_play'))
                  .fillColor(Color.White)
                  .width(this.controlIconSize)
              }
            }
            .onClick(() => {
              this.isTimerRun = !this.isTimerRun
            })

            Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
              Image($r('app.media.ic_doplan_music'))
                .width(this.controlIconSize)
            }
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

            Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
              Image($r('app.media.ic_doplan_musics'))
                .width(this.controlIconSize)
            }
            .onClick(() => {
              if (this.dialogChooseMusic != null) {
                this.dialogChooseMusic.open()
              }
            })

            Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
              if (this.isScreenOn) {
                Image($r('app.media.ic_doplan_sun'))
                  .width(this.controlIconSize)
              } else {
                Image($r('app.media.ic_doplan_sun'))
                  .width(this.controlIconSize)
                  .fillColor(Color.Gray)
              }
            }
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

            Button({ buttonStyle: ButtonStyleMode.TEXTUAL }) {
              Image($r('app.media.ic_home_stop'))
                .width(this.controlIconSize)
            }
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
          .layoutWeight(1)
        }
        .width('100%')
        .height(this.actionHeight)
      }
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number, value.height as number)
      })
    }
    .backgroundImage($r(this.backgroundNumber[Math.floor(Math.random() * (5 - 0) + 0)]))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideBackButton(true)
  }
}