import { promptAction, router } from '@kit.ArkUI'
import { accountDB, AccountDBInfo } from '../../database/AccountDB'

@Entry
@Component
struct UserLogin {
  @State Account: string = ''
  @State password: string = ''
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('UserName') userName: string = 'root'
  @StorageLink('id') user_id: number = 0
  @State Information: AccountDBInfo[] = []

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Row() {
          Image($r('app.media.ic_user_Starfruit'))
            .width(50)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('20%')

        TextInput({ placeholder: '请输入账号', text: $$this.Account })
          .type(InputType.Number)
        TextInput({ placeholder: '请输入密码（长度5到20）', text: $$this.password })
          .maxLength(20)
          .type(InputType.NEW_PASSWORD)
        Button('登录')
          .width('100%')
          .onClick(async () => {
            this.Information = await accountDB.query(undefined, Number(this.Account))
            if (this.Information.length == 0) {
              promptAction.showToast({
                message: '账号或密码错误'
              })
            } else if (this.Information[0].password == this.password) {
              this.isLogin = '已登录'
              this.user_id = this.Information[0].id as number
              this.userHead = this.Information[0].user_head
              this.userName = this.Information[0].user_name
              await accountDB.update({
                id: this.user_id,
                account: this.Information[0].account,
                password: this.Information[0].password,
                user_head: this.Information[0].user_head,
                user_name: this.Information[0].user_name,
                date_added: this.Information[0].date_added,
                last_login_time: Date.now(),
                issue_type: this.Information[0].issue_type,
                issue_answer: this.Information[0].issue_answer
              })
              router.back({ url: 'pages/Index' })
              promptAction.showToast({
                message: '登陆成功'
              })
            } else {
              promptAction.showToast({
                message: '账号或密码错误'
              })
            }
          })
        Row() {
          Button('注册', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .onClick(() => {
              router.pushUrl({ url: 'pages/user/UserRegister' }, router.RouterMode.Single)
            })
          Button('忘记密码', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .onClick(() => {
              router.pushUrl({ url: 'pages/user/AbandonPassword' })
            })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }
      .width('70%')
    }
    .backgroundColor('#fff1f1f1')
    .title('账户登录')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}