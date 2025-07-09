import { accountDB, AccountDBInfo } from '../../database/AccountDB'
import { promptAction, router } from '@kit.ArkUI'

@Entry
@Component
struct ResetPassword {
  @StorageLink('id') user_id: number = 0
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @State selected: number = -1
  @State selectedValue: string = '请选择重置密码的方式'
  @State oldPassword: string = ''
  @State firstPassword: string = ''
  @State secondPassword: string = ''
  @State information: AccountDBInfo[] = []
  @State issue_answer: string = ''

  async aboutToAppear() {
    this.information = await accountDB.query(this.user_id)
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Select([{ value: '通过旧密码重置密码' }, { value: '通过密保重置密码' }])
          .selected($$this.selected)
          .width('80%')
          .value($$this.selectedValue)
          .onSelect(async (index: number, value: string) => {
            if (index == 0) {
              this.selectedValue = value
            } else if (index == 1) {
              const a: AccountDBInfo[] = await accountDB.query(this.user_id)
              if (a[0].issue_type == '' || a[0].issue_answer == '') {
                promptAction.showToast({
                  message: '您还未设置密保问题，请先在个人信息页面设置完成密保问题后再重试'
                })
                this.selected = 0
                this.selectedValue = '通过旧密码重置密码'
              } else {
                this.selectedValue = value
              }
            }
          })
        if (this.selected == 0) {
          TextInput({ placeholder: '请输入旧密码', text: $$this.oldPassword })

          TextInput({ placeholder: '请输入新密码', text: $$this.firstPassword })

          TextInput({ placeholder: '请再次输入新密码', text: $$this.secondPassword })

          Button('确定修改')
            .onClick(async () => {
              const a: AccountDBInfo[] = await accountDB.query(this.user_id)
              if (a[0].password == this.oldPassword) {
                if (this.firstPassword == this.secondPassword) {
                  await accountDB.update({
                    id: this.user_id,
                    account: a[0].account,
                    password: this.firstPassword,
                    user_head: a[0].user_head,
                    user_name: a[0].user_name,
                    date_added: a[0].date_added,
                    last_login_time: a[0].last_login_time,
                    issue_type: a[0].issue_type,
                    issue_answer: a[0].issue_answer
                  })
                  promptAction.showToast({
                    message: '修改成功'
                  })
                  this.isLogin = '未登录'
                  router.back({ url: 'pages/user/userIndex' })
                } else {
                  promptAction.showToast({
                    message: '两次新密码输入不相同，请仔细检查后再继续'
                  })
                }
              } else {
                promptAction.showToast({
                  message: '旧密码输入错误'
                })
              }
            })
        } else if (this.selected == 1) {
          Text(this.information[0].issue_type)

          TextInput({ placeholder: '请输入密保问题答案', text: $$this.issue_answer })

          TextInput({ placeholder: '请输入新密码', text: $$this.firstPassword })

          TextInput({ placeholder: '请再次输入新密码', text: $$this.secondPassword })

          Button('确定修改')
            .onClick(async () => {
              const a: AccountDBInfo[] = await accountDB.query(this.user_id)
              if (a[0].issue_answer == this.issue_answer) {
                if (this.firstPassword == this.secondPassword) {
                  await accountDB.update({
                    id: this.user_id,
                    account: a[0].account,
                    password: this.firstPassword,
                    user_head: a[0].user_head,
                    user_name: a[0].user_name,
                    date_added: a[0].date_added,
                    last_login_time: a[0].last_login_time,
                    issue_type: a[0].issue_type,
                    issue_answer: a[0].issue_answer
                  })
                  promptAction.showToast({
                    message: '修改成功'
                  })
                  this.isLogin = '未登录'
                  router.back({ url: 'pages/user/userIndex' })
                } else {
                  promptAction.showToast({
                    message: '两次新密码输入不相同，请仔细检查后再继续'
                  })
                }
              } else {
                promptAction.showToast({
                  message: '密保问题回答错误'
                })
              }
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('70%')
    }
    .title('重置密码')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}