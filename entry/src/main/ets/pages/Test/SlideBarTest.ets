import { ComposeListItem } from "@kit.ArkUI"

@Component
export struct SlideBarItem {
  @State hasDown: boolean = false

  build() {
    Column() {
      // 一级菜单项
      ComposeListItem({
        contentItem: {
          primaryText: '这是标题',
        },
        operateItem: {
          icon: { value: $r('app.media.ic_ai_aihead') }
        }
      })
        .onClick(() => {
          this.hasDown = !this.hasDown // 切换二级菜单展示状态
        })

      // 二级菜单内容
      if (this.hasDown) {
        // 二级菜单实现...
      }
    }
    .margin({ top: 30 })
  }
}


@Component
export struct SliderBarList {
  build() {
    Column() {
      List() {
        ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (item: number) => {
          ListItem() {
            SlideBarItem()
          }
        })
      }
      .width('90%')
      .height('90%')
      .alignListItem(ListItemAlign.Center)
      .borderRadius(20)
      .divider({ strokeWidth: '1px', color: 0xeaf0ef })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
  }
}

@Entry
@Component
struct Index {
  @Provide showSlideBar: boolean = false

  build() {
    SideBarContainer(SideBarContainerType.Overlay) {
      // 侧边栏内容
      SliderBarList()

      // 主内容区域
      Column() {
        // 主内容...
      }
      .width('100%')
      .height('100%')
    }
    .showSideBar(this.showSlideBar)
    .onChange((isShow: boolean) => {
      this.showSlideBar = isShow
    })
  }
}



