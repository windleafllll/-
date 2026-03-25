import { router } from '@kit.ArkUI'

interface MyselfUI {
  icon: ResourceStr,
  title: ResourceStr,
  url: string,
}

@Entry
@Component
struct UserIndex {
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  // 待后续开发完善后启用；当前先隐藏“季度卡”相关列表
  @State enableQuarterCard: boolean = false
  @State myselfUI: MyselfUI[] = [
    {
      icon: $r('app.media.ic_user_account'),
      title: '账号',
      url: 'pages/user/UserLogin'
    },
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

  build() {
    Navigation() {
      Column({ space: 5 }) {
        Text('我的')
        Column({ space: 20 }) {
          ForEach(this.myselfUI, (v: MyselfUI) => {
            // 待后续开发完善后启用；当前隐藏“季度卡开始往下的所有入口”
            if (!this.enableQuarterCard && v.title != '账号') {
              Blank()
            } else if (v.title == '账号') {
              Row({ space: 10 }) {
                Image(v.icon)
                  .width(25)
                Text(v.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text(this.isLogin)
                  .fontWeight(FontWeight.Medium)
                  .fontSize(13)
                  .fontColor(Color.Gray)
                Image($r('app.media.ic_user_jiantou'))
                  .width(25)
              }
              .width('100%')
              .onClick(() => {
                if (this.isLogin == '未登录') {
                  router.pushUrl({ url: v.url })
                } else {
                  router.pushUrl({ url: 'pages/user/AccountIndex' })
                }
              })
            } else if (v.title == '季度卡') {
              // enableQuarterCard==true 才会走到这里
              Row({ space: 10 }) {
                Image(v.icon)
                  .width(25)
                Column({ space: 3 }) {
                  Text(v.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                  Text('众多新颖高级功能，祝你养成专注好习惯')
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.ic_user_jiantou'))
                  .width(25)
              }
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: v.url })
              })
            } else {
              Row({ space: 10 }) {
                Image(v.icon)
                  .width(25)
                Text(v.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Image($r('app.media.ic_user_jiantou'))
                  .width(25)
              }
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: v.url })
              })
            }
          })
        }
        .backgroundColor(Color.White)
        .borderRadius(15)
        .padding(15)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .margin(15)
    }
    .backgroundColor('#fff1f1f1')
    .title('我的')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}