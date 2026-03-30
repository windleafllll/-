import { promptAction } from '@kit.ArkUI'
import { themeManager } from '../manage/ThemeManager'
import { habitReminderManager } from '../manage/HabitReminderManager'
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
  @StorageLink('PlanChangedAt') planChangedAt: number = 0
  // 执行计划页面锁定：禁止 Tab 切换等“退出界面”行为
  @StorageLink('InPlanPage') inPlanPage: boolean = false
  @State private lastPlanChangedAt: number = -1

  onPageShow() {
    this.isPageShow = true
    themeManager.enableFullScreen()
    habitReminderManager.start()
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
          .fillColor($r('app.color.brand_primary'))
      } else {
        Image(normalImg)
          .width(20)
          .aspectRatio(1)
      }
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? $r('app.color.tab_text_selected') :
          $r('app.color.tab_text_normal'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .border({ width: { top: 1 }, color: $r('app.color.tab_bar_border') })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.inPlanPage) {
        promptAction.showToast({ message: '请点击结束计划按钮退出' })
        return
      }
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Column() {
      Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
        TabContent() {
          HomeTab()
        }
        .tabBar(this.TabBuilder('首页', 0, $r('app.media.ic_tab_shouye_filled'), $r('app.media.ic_tab_shouye')))

        TabContent() {
          DataAnalysis()
        }
        .tabBar(this.TabBuilder('数据分析', 1, $r('app.media.ic_home_shuju_filled'), $r('app.media.ic_home_shuju')))


        // TabContent() {
        //   AIChat()
        // }
        // .tabBar(this.TabBuilder('计划铺子', 2, $r('app.media.ic_home_puzi_filled'), $r('app.media.ic_home_puzi')))

        TabContent() {
          UserIndex()
        }
        .tabBar(this.TabBuilder('我的', 2, $r('app.media.ic_user_account_filled'), $r('app.media.ic_user_account')))
      }
      .barMode(BarMode.Fixed) // 默认值 Fixed
      .scrollable(false) // 限制滑动
      .padding({ bottom: this.bottomHeight, top: 40 })
      .linearGradient({
        direction: GradientDirection.Bottom,
        repeating: false,
        colors: [
          [$r('app.color.page_gradient_1'), 0.0],
          [$r('app.color.page_gradient_2'), 0.3],
          [$r('app.color.page_gradient_3'), 0.5],
          [$r('app.color.page_gradient_end'), 0.9]
        ]
      })

      if (this.planChangedAt != this.lastPlanChangedAt) {
        Blank()
          .onAppear(() => {
            this.lastPlanChangedAt = this.planChangedAt
            habitReminderManager.start()
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}