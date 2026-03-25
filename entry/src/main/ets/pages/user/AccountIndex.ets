import { promptAction, router } from '@kit.ArkUI'
import { accountDB, AccountDBInfo } from '../../database/AccountDB'

@CustomDialog
struct CustomDialogExample {
  controllerTwo?: CustomDialogController
  @StorageLink('id') user_id: number = 0
  @State head: string = ''
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @State list: string[] =
    ['app.media.ic_user_head_1', 'app.media.ic_user_head_2', 'app.media.ic_user_head_3', 'app.media.ic_user_head_4',
      'app.media.ic_user_head_5', 'app.media.ic_user_head_6', 'app.media.ic_user_head_7', 'app.media.ic_user_head_8',
      'app.media.ic_user_head_9', 'app.media.ic_user_head_10', 'app.media.ic_user_head_11', 'app.media.ic_user_head_12',
      'app.media.ic_user_head_13', 'app.media.ic_user_head_14', 'app.media.ic_user_head_15',
      'app.media.ic_user_head_16',
      'app.media.ic_user_head_17', 'app.media.ic_user_head_18', 'app.media.ic_user_head_19',
      'app.media.ic_user_head_20',
      'app.media.ic_user_head_21',]

  build() {
    Column({ space: 20 }) {
      Text('更换头像')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      Scroll() {
        Column({ space: 5 }) {
          ForEach(this.list, (v: string) => {
            Row() {
              Image($r(v))
                .width(40)
              Radio({ value: 'head', group: 'head' })
                .onChange((isChecked: boolean) => {
                  if (isChecked == true) {
                    this.head = v
                  }
                })
            }
            .justifyContent(FlexAlign.SpaceAround)
            .width('70%')
          })
        }
      }
      .height('30%')
      .width('90%')

      Button('确定')
        .onClick(async () => {
          if (this.head == '') {
            promptAction.showToast({
              message: '您还未选择头像'
            })
          } else {
            if (this.controllerTwo != undefined) {
              this.userHead = this.head
              const a: AccountDBInfo[] = await accountDB.query(this.user_id)
              await accountDB.update({
                id: this.user_id,
                account: a[0].account,
                password: a[0].password,
                user_head: this.head,
                user_name: a[0].user_name,
                date_added: a[0].date_added,
                last_login_time: a[0].last_login_time,
                issue_type: a[0].issue_type,
                issue_answer: a[0].issue_answer
              })
              promptAction.showToast({
                message: '头像修改成功'
              })
              this.controllerTwo.close()
            }
          }
        })
    }
    .padding(20)
  }
}

@CustomDialog
struct CustomDialogUserName {
  controllerTwo?: CustomDialogController
  @StorageLink('id') user_id: number = 0
  @StorageLink('UserName') userName: string = 'root'
  @State name: string = ''

  build() {
    Column({ space: 20 }) {
      Text('修改名称')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '请输入您的新昵称', text: $$this.name })

      Button('确定')
        .onClick(async () => {
          if (this.name == '') {
            promptAction.showToast({
              message: '昵称不能为空'
            })
          } else {
            if (this.controllerTwo != undefined) {
              this.userName = this.name
              const a: AccountDBInfo[] = await accountDB.query(this.user_id)
              await accountDB.update({
                id: this.user_id,
                account: a[0].account,
                password: a[0].password,
                user_head: a[0].user_head,
                user_name: this.name,
                date_added: a[0].date_added,
                last_login_time: a[0].last_login_time,
                issue_type: a[0].issue_type,
                issue_answer: a[0].issue_answer
              })
              promptAction.showToast({
                message: '昵称修改成功'
              })
              this.controllerTwo.close()
            }
          }
        })
    }
    .padding(20)
  }
}

@Entry
@Component
struct AccountIndex {
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('UserName') userName: string = 'root'
  @StorageLink('isUserLogin') isLogin: string = '已登录'
  @State cardWidth: string = '45%'
  @State pagePadding: number = 20
  @State titleSize: number = 28
  dialogController: CustomDialogController | null = new CustomDialogController({ builder: CustomDialogExample() })
  dialogControllerName: CustomDialogController | null = new CustomDialogController({ builder: CustomDialogUserName() })

  private updateResponsiveLayout(width: number) {
    this.cardWidth = width >= 900 ? '48%' : '45%'
    this.pagePadding = width >= 900 ? 28 : 20
    this.titleSize = width >= 900 ? 32 : 28
  }

  build() {
    Navigation() {
      Column({ space: 10 }) {
        Image($r(this.userHead))
          .width(70)
          .onClick(() => {
            if (this.dialogController != null) {
              this.dialogController.open()
            }
          })
        Text(this.userName)
          .fontSize(this.titleSize)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            if (this.dialogControllerName != null) {
              this.dialogControllerName.open()
            }
          })
        Row({ space: 15 }) {
          Column() {
            Image($r('app.media.ic_user_remakepassword'))
              .width(40)
            Text('重置密码')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
          }
          .width(this.cardWidth)
          .backgroundColor(Color.White)
          .borderRadius(15)
          .padding(10)
          .onClick(() => {
            router.pushUrl({ url: 'pages/user/ResetPassword' })
          })

          Column() {
            Image($r('app.media.ic_user_issue'))
              .width(40)
            Text('密保问题')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
          }
          .width(this.cardWidth)
          .backgroundColor(Color.White)
          .borderRadius(15)
          .padding(10)
          .onClick(() => {
            router.pushUrl({ url: 'pages/user/Confidential' })
          })
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')

        Blank()
        Button('退出登录')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor('#ffc41414')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.isLogin = '未登录'
            this.userHead = 'app.media.ic_user_head_1'
            this.userName = 'root'
            promptAction.showToast({
              message: '退出成功'
            })
            router.back()
          })
      }
      .height('100%')
      .padding(this.pagePadding)
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .backgroundColor('#fff1f1f1')
    .title('个人信息')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}