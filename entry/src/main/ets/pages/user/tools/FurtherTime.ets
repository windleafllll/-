import { router } from '@kit.ArkUI'

@Entry
@Component
struct FurtherTime {
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
      Image($r('app.media.ic_user_jiahao'))
        .width(30)
        .fillColor(Color.White)
    }
    .width('100%')
    .backgroundColor('#f6726e')
    .padding({ left: 15, right: 15 })
  }

  build() {
    Navigation() {
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