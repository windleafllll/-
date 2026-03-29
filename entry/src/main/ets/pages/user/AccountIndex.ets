import { promptAction, router } from '@kit.ArkUI'

@Entry
@Component
struct AccountIndex {
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('UserName') userName: string = 'root'
  @StorageLink('isUserLogin') isLogin: string = '已登录'
  @StorageLink('HuaweiLoginInfo') huaweiLoginInfo: string = ''
  @StorageLink('CloudUserId') cloudUserId: string = ''
  @State pagePadding: number = 20
  @State titleSize: number = 28

  private updateResponsiveLayout(width: number) {
    this.pagePadding = width >= 900 ? 28 : 20
    this.titleSize = width >= 900 ? 32 : 28
  }

  private isRemoteAvatar(head: string): boolean {
    return head.startsWith('http://') || head.startsWith('https://')
  }

  build() {
    Navigation() {
      Column({ space: 10 }) {
        if (this.isRemoteAvatar(this.userHead)) {
          Image(this.userHead)
            .width(70)
            .height(70)
            .borderRadius(35)
            .backgroundColor($r('app.color.avatar_ring'))
        } else {
          Image($r(this.userHead))
            .width(70)
            .height(70)
            .borderRadius(35)
            .backgroundColor($r('app.color.avatar_ring'))
        }
        Text(this.userName)
          .fontSize(this.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Blank()
        Button('退出登录')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor($r('app.color.text_destructive'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            AlertDialog.show({
              title: '退出登录',
              message: '确定要退出当前账号吗？',
              primaryButton: {
                value: '取消',
                action: () => {
                }
              },
              secondaryButton: {
                value: '确定',
                action: () => {
                  this.isLogin = '未登录'
                  this.userHead = 'app.media.ic_user_head_1'
                  this.userName = 'root'
                  this.huaweiLoginInfo = ''
                  this.cloudUserId = ''
                  promptAction.showToast({
                    message: '退出成功'
                  })
                  router.back()
                }
              }
            })
          })
      }
      .height('100%')
      .padding(this.pagePadding)
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .backgroundColor($r('app.color.list_area_background'))
    .title('个人信息')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}