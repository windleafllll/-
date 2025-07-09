import { accountDB, AccountDBInfo } from '../../database/AccountDB'
import { promptAction, router } from '@kit.ArkUI'

@Entry
@Component
struct AbandonPassword {
  @State userAccount: string = ''
  @State isAccount: string = '账号'
  @State Account: AccountDBInfo[] = []
  @State issue_answer: string = ''
  @State firstPassword: string = ''
  @State secondPassword: string = ''

  build() {
    Navigation() {
      if (this.isAccount == '账号') {
        Column({ space: 20 }) {
          TextInput({ placeholder: '请输入您的账号', text: $$this.userAccount })
            .type(InputType.Number)
          Button('确定')
            .onClick(async () => {
              if (this.userAccount == '') {
                promptAction.showToast({
                  message: '账号不能为空'
                })
              } else {
                this.Account = await accountDB.query(undefined, Number(this.userAccount))
                if (this.Account.length <= 0) {
                  promptAction.showToast({
                    message: '输入的账号错误'
                  })
                } else {
                  if (this.Account[0].issue_type == '') {
                    promptAction.showToast({
                      message: '输入的账号还未设置密保，尚不能进行重置密码'
                    })
                  } else {
                    this.isAccount = '密保'
                  }
                }
              }
            })
        }
        .margin(20)
        .width('90%')
      } else if (this.isAccount == '密保') {
        Column({ space: 20 }) {
          Text(this.Account[0].issue_type)
          TextInput({ placeholder: '请回答密保问题', text: $$this.issue_answer })
          Button('提交')
            .onClick(() => {
              if (this.issue_answer == '') {
                promptAction.showToast({
                  message: '输入的答案不能为空'
                })
              } else {
                if (this.issue_answer == this.Account[0].issue_answer) {
                  promptAction.showToast({
                    message: '答案正确，即将开始重置密码'
                  })
                  this.isAccount = '重置密码'
                } else {
                  promptAction.showToast({
                    message: '回答错误'
                  })
                }
              }
            })
        }
        .margin(20)
        .width('90%')
      } else if (this.isAccount == '重置密码') {
        Column({ space: 20 }) {
          TextInput({ placeholder: '请输入新的密码', text: $$this.firstPassword })
          TextInput({ placeholder: '请再次输入新的密码', text: $$this.secondPassword })
          Button('确定')
            .onClick(async () => {
              if (this.firstPassword == this.secondPassword && this.firstPassword != '') {
                if (this.firstPassword == this.Account[0].password) {
                  promptAction.showToast({
                    message: '新密码不能与旧密码相同'
                  })
                } else {
                  await accountDB.update({
                    id: this.Account[0].id,
                    account: this.Account[0].account,
                    password: this.firstPassword,
                    user_head: this.Account[0].user_head,
                    user_name: this.Account[0].user_name,
                    date_added: this.Account[0].date_added,
                    last_login_time: this.Account[0].last_login_time,
                    issue_type: this.Account[0].issue_type,
                    issue_answer: this.Account[0].issue_answer
                  })
                  promptAction.showToast({
                    message: '重置密码成功，请重新登录'
                  })
                  router.back({ url: 'pages/user/UserLogin' })
                }
              } else {
                promptAction.showToast({
                  message: '两次输入的密码不同或密码不能为空'
                })
              }
            })
        }
        .margin(20)
        .width('90%')
      }
    }
    .title('忘记密码')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}