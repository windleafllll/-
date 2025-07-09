import { promptAction, router } from '@kit.ArkUI'
import { accountDB, AccountDBInfo } from '../../database/AccountDB'

@Entry
@Component
struct UserLogin {
  @State Account: string = ''
  @State FirstPassword: string = ''
  @State SecondPassword: string = ''
  @StorageLink('isUserLogin') isLogin: string = '未登录'

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
        TextInput({ placeholder: '请输入密码（长度5到20）', text: $$this.FirstPassword })
          .maxLength(20)
          .type(InputType.NEW_PASSWORD)
        TextInput({ placeholder: '请输再次入密码（长度5到20）', text: $$this.SecondPassword })
          .maxLength(20)
          .type(InputType.NEW_PASSWORD)
        Button('注册')
          .width('100%')
          .onClick(async () => {
            if (this.FirstPassword == this.SecondPassword && this.FirstPassword != '' && this.Account != '') {
              const a: AccountDBInfo[] = await accountDB.query(undefined, Number(this.Account))
              if (a.length > 0) {
                promptAction.showToast({
                  message: '该账号已被注册，请更换账号后重试'
                })
              } else {
                await accountDB.insert({
                  id: null,
                  account: Number(this.Account),
                  password: this.FirstPassword,
                  user_head: 'app.media.ic_user_head_1',
                  user_name: 'root',
                  date_added: Date.now(),
                  last_login_time: Date.now(),
                  issue_type: '',
                  issue_answer: ''
                })
                promptAction.showToast({
                  message: '注册成功'
                })
                router.back({ url: 'pages/user/UserLogin' })
              }
            } else {
              promptAction.showToast({
                message: '密码或账号有误，请仔细检查您的账号和密码'
              })
            }
          })
        Row() {
          Button('登录', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .onClick(() => {
              router.pushUrl({ url: 'pages/user/UserLogin' }, router.RouterMode.Single)
            })
          Button('忘记密码', { buttonStyle: ButtonStyleMode.TEXTUAL })
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