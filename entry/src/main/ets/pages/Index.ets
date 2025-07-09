import { themeManager } from '../manage/ThemeManager'
import { AIChat } from './tab/AIChat'
import { DataAnalysis } from './tab/DataAnalysis'
import { HomeTab } from './tab/HomeTab'
import { UserIndex } from './tab/UserIndex'

@Entry
@Component
struct Index {
  // @Provide 装饰器和 @Consume装饰器：与后代组件双向同步
  @Provide currentIndex: number = 0
  @Provide isPageShow: boolean = false
  @StorageLink('bottomHeight') bottomHeight: number = 10

  onPageShow() {
    this.isPageShow = true
    themeManager.enableFullScreen()
  }

  onPageHide() {
    this.isPageShow = false
    themeManager.disableFullScreen()
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      if (this.currentIndex === targetIndex) {
        Image(selectedImg)
          .width(20)
          .aspectRatio(1)
          .fillColor('#f6726e')
      } else {
        Image(normalImg)
          .width(20)
          .aspectRatio(1)
      }
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? '#f6726e' : '#0C273D')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .border({ width: { top: 1 }, color: '#eee' })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
      TabContent() {
        HomeTab()
      }
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.ic_tab_shouye_filled'), $r('app.media.ic_tab_shouye')))

      TabContent() {
        DataAnalysis()
      }
      .tabBar(this.TabBuilder('数据分析', 1, $r('app.media.ic_home_shuju_filled'), $r('app.media.ic_home_shuju')))

      TabContent() {
        AIChat()
      }
      .tabBar(this.TabBuilder('计划铺子', 2, $r('app.media.ic_home_puzi_filled'), $r('app.media.ic_home_puzi')))

      TabContent() {
        UserIndex()
      }
      .tabBar(this.TabBuilder('我的', 3, $r('app.media.ic_user_account_filled'), $r('app.media.ic_user_account')))
    }
    .barMode(BarMode.Fixed) // 默认值 Fixed
    .scrollable(false) // 限制滑动
    .padding({ bottom: this.bottomHeight, top: 40 })
    .linearGradient({
      direction: GradientDirection.Bottom, // 渐变方向
      repeating: false, // 渐变颜色是否重复
      colors: [['#f6726e', 0.0], ['#d4648a', 0.3], ['#bc62aa', 0.5], ['#fff1f1f1', 0.9]] // 数组末尾元素占比小于1时满足重复着色效果
    })
  }
}