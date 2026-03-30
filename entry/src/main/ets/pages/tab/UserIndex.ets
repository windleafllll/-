import { router } from '@kit.ArkUI'
import { habitReminderManager, PublishedAgentReminderItem } from '../../manage/HabitReminderManager'
import { chooseNavigationBar } from '../user/tools/Dialogs'

@CustomDialog
struct PublishedAgentRemindersDialog {
  controllerTwo?: CustomDialogController
  @State items: PublishedAgentReminderItem[] = []
  @State loadError: string = ''
  @State loading: boolean = true

  aboutToAppear(): void {
    void this.reload()
  }

  private async reload(): Promise<void> {
    this.loading = true
    this.loadError = ''
    const r = await habitReminderManager.loadPublishedAgentReminders()
    this.items = r.items
    this.loadError = r.error
    this.loading = false
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('已发布的代理提醒')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Row() {
          Text('刷新')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand_primary'))
        }
        .padding({
          left: 8,
          right: 8,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          void this.reload()
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Row() {
          LoadingProgress()
            .width(28)
            .height(28)
            .color($r('app.color.brand_primary'))
          Text('正在同步并查询…')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 10 })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
        .justifyContent(FlexAlign.Center)
      } else if (this.loadError != '') {
        Text(`加载失败：${this.loadError}`)
          .fontSize(14)
          .fontColor($r('app.color.text_destructive'))
          .lineHeight(22)
          .width('100%')
      } else if (this.items.length == 0) {
        Text('当前没有已发布的有效代理提醒（或与计划同步后暂无待触发项）')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(22)
          .width('100%')
      } else {
        Text(`共 ${this.items.length} 条`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.items, (item: PublishedAgentReminderItem, index: number) => {
              Column({ space: 6 }) {
                Text(`${index + 1}. ${item.timeSummary}`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_meta_emphasis'))
                  .width('100%')

                Text(item.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')

                if (item.content != '') {
                  Text(item.content)
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                    .lineHeight(20)
                    .width('100%')
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({
                left: 12,
                right: 12,
                top: 12,
                bottom: 12
              })
              .borderRadius(12)
              .backgroundColor($r('app.color.surface_muted'))
              .border({ width: 1, color: $r('app.color.input_border') })
            }, (item: PublishedAgentReminderItem, index: number) => `agent_r_${item.id}_${index}`)
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxHeight: 360 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }

      Row() {
        Text('关闭')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_on_brand'))
      }
      .width('100%')
      .height(46)
      .justifyContent(FlexAlign.Center)
      .borderRadius(14)
      .clip(true)
      .backgroundColor($r('app.color.brand_primary'))
      .onClick(() => {
        this.controllerTwo?.close()
      })
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.card_background'))
    .border({ width: 1, color: $r('app.color.input_border') })
    .borderRadius(14)
  }
}

interface MyselfUI {
  icon: ResourceStr,
  title: ResourceStr,
  url: string,
}

@Component
export struct UserIndex {
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('UserName') userName: string = 'root'
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @State sectionWidth: string = '90%'
  @State sectionPadding: number = 15
  // 待后续开发完善后启用；当前先隐藏“季度卡”相关列表
  @State enableQuarterCard: boolean = false
  @State myselfUI: MyselfUI[] = [
    {
      icon: $r('app.media.ic_user_vipcard'),
      title: '季度卡',
      url: ''
    },
    {
      icon: $r('app.media.ic_user_yuncunchu'),
      title: '备份|恢复|云同步',
      url: 'pages/Setting/Cloud_synchronization'
    },
  ]
  @State ToolUI: MyselfUI[] = [
    {
      icon: $r('app.media.ic_user_furthertime'),
      title: '未来倒计时',
      url: 'pages/user/tools/FurtherTime'
    },
    {
      icon: $r('app.media.ic_user_historicalrecords'),
      title: '专注历史记录',
      url: 'pages/user/tools/HistoricalRecords'
    },
    {
      icon: $r('app.media.ic_user_studyroom'),
      title: '自习室 | 许愿墙',
      url: 'pages/user/tools/StudyRoom'
    },
  ]
  @State ToolsUI: MyselfUI[] = [
    {
      icon: $r('app.media.ic_user_bell'),
      title: '专注计时核心设计',
      url: 'pages/user/tools/BellIndex'
    },
    {
      icon: $r('app.media.ic_user_picture'),
      title: '海报背景和外观',
      url: ''
    },
    {
      icon: $r("app.media.ic_user_customise"),
      title: '自定义底栏模块',
      url: ''
    },
    {
      icon: $r("app.media.ic_user_paintplate"),
      title: '主题颜色搭配',
      url: ''
    },
    {
      icon: $r("app.media.ic_user_servicewidgets"),
      title: '桌面小组件选项',
      url: ''
    },
    {
      icon: $r("app.media.ic_user_settings"),
      title: '其他设置',
      url: ''
    },
  ]
  dialogChooseNavigationBar: CustomDialogController | null = new CustomDialogController({
    builder: chooseNavigationBar(),
    cornerRadius: 15,
    width: '80%'
  })
  dialogPublishedAgentReminders: CustomDialogController | null = new CustomDialogController({
    builder: PublishedAgentRemindersDialog(),
    customStyle: true,
    cornerRadius: 20,
    width: '82%'
  })

  private updateResponsiveLayout(width: number) {
    // 全屏铺满下，使用更大留白避免组件在平板显得“横向拉伸”
    this.sectionWidth = width >= 900 ? '94%' : '90%'
    this.sectionPadding = width >= 900 ? 20 : 15
  }

  private isRemoteAvatar(head: string): boolean {
    return head.startsWith('http://') || head.startsWith('https://')
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 5 }) {
          if (this.isLogin == '未登录') {
            Image($r('app.media.ic_user_account'))
              .width(42)
              .borderRadius(20)
              .backgroundColor($r('app.color.avatar_ring'))
            Text(this.isLogin)
              .fontWeight(FontWeight.Bold)
              .fontSize(25)
              .fontColor($r('app.color.text_on_gradient_primary'))
          } else {
            if (this.isRemoteAvatar(this.userHead)) {
              Image(this.userHead)
                .width(42)
                .height(42)
                .borderRadius(21)
                .backgroundColor($r('app.color.avatar_ring'))
            } else {
              Image($r(this.userHead))
                .width(42)
                .height(42)
                .borderRadius(21)
                .backgroundColor($r('app.color.avatar_ring'))
            }
            Text(this.userName)
              .fontWeight(FontWeight.Bold)
              .fontSize(25)
              .fontColor($r('app.color.text_on_gradient_primary'))
          }
        }
        .margin({ left: 15, right: 15 })
        .borderRadius(15)
        .backgroundImage($r('app.media.ic_user_backgroundimage'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .padding(30)
        .width(this.sectionWidth)

        //TODO 登录
        // .onClick(() => {
        //   if (this.isLogin == '未登录') {
        //     router.pushUrl({ url: 'pages/user/UserLogin' })
        //   } else {
        //     router.pushUrl({ url: 'pages/user/AccountIndex' })
        //   }
        // })

        Row() {
          ForEach(this.ToolUI, (v: MyselfUI) => {
            Column({ space: 8 }) {
              Image(v.icon)
                .width(20)
              Text(v.title)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .onClick(() => {
              router.pushUrl({ url: v.url })
            })
          })
        }
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(15)
        .justifyContent(FlexAlign.SpaceAround)
        .width(this.sectionWidth)
        .padding(this.sectionPadding)

        Row({ space: 10 }) {
          Image($r('app.media.ic_home_alarm'))
            .width(20)
          Text('已发布代理提醒')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Image($r('app.media.ic_user_jiantou'))
            .width(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(15)
        .width(this.sectionWidth)
        .padding(this.sectionPadding)
        .onClick(() => {
          if (this.dialogPublishedAgentReminders != null) {
            this.dialogPublishedAgentReminders.open()
          }
        })

        //TODO 云同步
        // Row({ space: 10 }) {
        //   Image($r('app.media.ic_user_yuncunchu'))
        //     .width(20)
        //   Text('备份|恢复|云同步')
        //     .fontSize(15)
        //     .fontWeight(FontWeight.Bold)
        //     .fontColor($r('app.color.text_primary'))
        //   Blank()
        //   Image($r('app.media.ic_user_jiantou'))
        //     .width(20)
        // }
        // .backgroundColor($r('app.color.card_background'))
        // .borderRadius(15)
        // .width(this.sectionWidth)
        // .padding(this.sectionPadding)
        // .onClick(() => {
        //   router.pushUrl({ url: 'pages/Setting/Cloud_synchronization' })
        // })

        Blank()

        // Column({ space: 5 }) {
        //   Column({ space: 20 }) {
        //     ForEach(this.myselfUI, (v: MyselfUI) => {
        //       // 待后续开发完善后启用；当前隐藏“季度卡开始往下的所有入口”
        //       if (!this.enableQuarterCard && v.title != '账号') {
        //         Blank()
        //       } else if (v.title == '季度卡') {
        //         Row({ space: 10 }) {
        //           Image(v.icon)
        //             .width(20)
        //           Column({ space: 3 }) {
        //             Text(v.title)
        //               .fontSize(15)
        //               .fontWeight(FontWeight.Bold)
        //             Text('众多新颖高级功能，祝你养成专注好习惯')
        //               .fontSize(11)
        //               .fontWeight(FontWeight.Bold)
        //               .fontColor(Color.Gray)
        //           }
        //           .alignItems(HorizontalAlign.Start)
        //
        //           Blank()
        //           Image($r('app.media.ic_user_jiantou'))
        //             .width(25)
        //         }
        //         .width('100%')
        //         .onClick(() => {
        //           router.pushUrl({ url: v.url })
        //         })
        //       } else {
        //         Row({ space: 10 }) {
        //           Image(v.icon)
        //             .width(20)
        //           Text(v.title)
        //             .fontSize(15)
        //             .fontWeight(FontWeight.Bold)
        //           Blank()
        //           Image($r('app.media.ic_user_jiantou'))
        //             .width(25)
        //         }
        //         .width('100%')
        //         .onClick(() => {
        //           router.pushUrl({ url: v.url })
        //         })
        //       }
        //     })
        //   }
        //   .backgroundColor(Color.White)
        //   .borderRadius(15)
        //   .padding(this.sectionPadding)
        //   .width('100%')
        // }
        // .alignItems(HorizontalAlign.Start)
        // .margin({ left: 15, right: 15 })
        //
        // Column({ space: 20 }) {
        //   ForEach(this.ToolsUI, (v: MyselfUI) => {
        //     if (v.title == '自定义底栏模块') {
        //       Row({ space: 10 }) {
        //         Image(v.icon)
        //           .width(20)
        //         Text(v.title)
        //           .fontSize(15)
        //           .fontWeight(FontWeight.Bold)
        //         Blank()
        //         Image($r('app.media.ic_user_jiantou'))
        //           .width(25)
        //       }
        //       .width('100%')
        //       .justifyContent(FlexAlign.Start)
        //       .onClick(() => {
        //         if (this.dialogChooseNavigationBar != null) {
        //           this.dialogChooseNavigationBar.open()
        //         }
        //       })
        //     } else if (v.title == '主题颜色搭配'){
        //
        //     }else {
        //       Row({ space: 10 }) {
        //         Image(v.icon)
        //           .width(20)
        //         Text(v.title)
        //           .fontSize(15)
        //           .fontWeight(FontWeight.Bold)
        //         Blank()
        //         Image($r('app.media.ic_user_jiantou'))
        //           .width(25)
        //       }
        //       .width('100%')
        //       .justifyContent(FlexAlign.Start)
        //       .onClick(() => {
        //         router.pushUrl({ url: v.url })
        //       })
        //     }
        //   })
        // }
        // .padding(15)
        // .backgroundColor(Color.White)
        // .borderRadius(15)
        // .width(this.sectionWidth)
        //
        // Column({ space: 20 }) {
        //   Row({ space: 10 }) {
        //     Image($r('app.media.ic_user_help'))
        //       .width(20)
        //     Text('帮助 | 常见问题')
        //       .fontSize(15)
        //       .fontWeight(FontWeight.Bold)
        //     Blank()
        //     Image($r('app.media.ic_user_jiantou'))
        //       .width(25)
        //   }
        //   .width('100%')
        //   .justifyContent(FlexAlign.Start)
        //   .onClick(() => {
        //
        //   })
        // }
        // .padding(15)
        // .backgroundColor(Color.White)
        // .borderRadius(15)
        // .width(this.sectionWidth)
      }
      .width('100%')
      .height('100%')
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
  }
}