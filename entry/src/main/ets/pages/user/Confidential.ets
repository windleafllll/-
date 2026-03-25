import { accountDB, AccountDBInfo } from '../../database/AccountDB'
import { promptAction, router } from '@kit.ArkUI'

@Entry
@Component
struct Confidential {
  @StorageLink('id') user_id: number = 0
  @State selectedValue: string = '我的梦想是什么？'
  @State selected: number = 0
  @State issue: string = ''
  @State issue_answer: string = ''
  @State infomation: AccountDBInfo[] = []
  @State issue_old_answer: string = ''
  @State hasIssue: boolean = false
  @State pagePadding: number = 24

  async aboutToAppear() {
    this.infomation = await accountDB.query(this.user_id)
    if (this.infomation[0].issue_type != '' || this.infomation[0].issue_answer != '') {
      this.hasIssue = true
    }
  }

  private updateResponsiveLayout(width: number) {
    this.pagePadding = width >= 900 ? 72 : 24
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        if (this.hasIssue) {
          Text(this.infomation[0].issue_type)
            .fontSize(18)
          TextInput({ placeholder: '请输入密保答案', text: $$this.issue_old_answer })
            .width('100%')
          Button('确定')
            .width('100%')
            .onClick(() => {
              if (this.infomation[0].issue_answer == this.issue_old_answer) {
                this.hasIssue = false
              }
            })
        } else {
          Select([{ value: '我的梦想是什么？' }, { value: '我父亲的吗名字' }, { value: '我母亲的名字' },
            { value: '我妻子的名字' }, { value: '我的生日' }, { value: '自定义问题' }])
            .value($$this.selectedValue)
            .selected($$this.selected)
            .width('100%')
            .onSelect((index: number, value: string) => {
              this.selectedValue = value
            })
          if (this.selected == 5) {
            TextInput({ placeholder: '请输入您的密保问题', text: $$this.issue })
              .width('100%')
          }
          TextInput({ placeholder: '请输入您的密保答案', text: $$this.issue_answer })
            .width('100%')

          Button('确定')
            .width('100%')
            .onClick(async () => {
              if (this.selected == 5) {
                if (this.issue != '' && this.issue_answer != '') {
                  await accountDB.update({
                    id: this.user_id,
                    account: this.infomation[0].account,
                    password: this.infomation[0].password,
                    user_head: this.infomation[0].user_head,
                    user_name: this.infomation[0].user_name,
                    date_added: this.infomation[0].date_added,
                    last_login_time: this.infomation[0].last_login_time,
                    issue_type: this.issue,
                    issue_answer: this.issue_answer
                  })
                  promptAction.showToast({
                    message: '密保设置成功'
                  })
                  router.back()
                } else {
                  promptAction.showToast({
                    message: '问题或答案不能为空'
                  })
                }

              } else {
                if (this.issue_answer != '') {
                  await accountDB.update({
                    id: this.user_id,
                    account: this.infomation[0].account,
                    password: this.infomation[0].password,
                    user_head: this.infomation[0].user_head,
                    user_name: this.infomation[0].user_name,
                    date_added: this.infomation[0].date_added,
                    last_login_time: this.infomation[0].last_login_time,
                    issue_type: this.selectedValue,
                    issue_answer: this.issue_answer
                  })
                  promptAction.showToast({
                    message: '密保设置成功'
                  })
                  router.back()
                } else {
                  promptAction.showToast({
                    message: '答案不能为空'
                  })
                }
              }
            })
        }
      }
      .width('100%')
      .padding({ left: this.pagePadding, right: this.pagePadding, top: 16, bottom: 16 })
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .title('设置密保')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}