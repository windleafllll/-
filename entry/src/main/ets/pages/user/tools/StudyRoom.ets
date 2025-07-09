import { ItemRestriction, router, SegmentButton, SegmentButtonOptions, SegmentButtonTextItem } from '@kit.ArkUI'

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
          SegmentButton({
            options: this.tabOptions,
            selectedIndexes: $tabSelectedIndexes,
            onItemClicked: (choose: number) => {
              this.Choose = choose
            }
          })
            .width('50%')
          Column({ space: 40 }) {
            if (this.Choose == 0) {
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
            } else if (this.Choose == 1) {
              Button('我要许愿 | 还原')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#f6726e')
                .backgroundColor(Color.White)
                .width('35%')
            }
          }
          .height('100%')
          .padding({ top: 60 })
        }
      }
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