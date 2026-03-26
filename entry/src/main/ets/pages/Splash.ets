import { router } from '@kit.ArkUI'
import { themeManager } from '../manage/ThemeManager'

@Entry
@Component
struct Splash {
  private timerId: number = 0

  aboutToAppear() {
    themeManager.enableFullScreen()
    this.timerId = setTimeout(() => {
      // 进入主页面后禁止返回到开屏页：清空栈并替换当前页
      try {
        router.clear()
      } catch (e) {
      }
      router.replaceUrl({ url: 'pages/Index' })
    }, 2000)
  }

  aboutToDisappear() {
    if (this.timerId != 0) {
      clearTimeout(this.timerId)
      this.timerId = 0
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 16 }) {
        Image($r('app.media.ic_app_ui'))
          .width(140)
          .height(140)
          .objectFit(ImageFit.Contain)
          .borderRadius(70)

        Text('杨桃树')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)

        Text('专注 · 计划 · 成长')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E5E7EB')

        Row({ space: 8 }) {
          Text('测试版 App')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#f6726e')
            .padding({
              left: 10,
              right: 10,
              top: 4,
              bottom: 4
            })
            .backgroundColor('#FFF1F0')
            .borderRadius(999)
          Text('欢迎体验，如有建议欢迎反馈')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F9FAFB')
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width('88%')
      .padding({
        top: 30,
        bottom: 30,
        left: 20,
        right: 20
      })
      .borderRadius(20)
      .backgroundColor('#33000000')
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [['#f6726e', 0.0], ['#d4648a', 0.35], ['#8B5CF6', 1.0]]
    })
  }
}

