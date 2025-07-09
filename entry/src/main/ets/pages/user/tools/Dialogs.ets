@CustomDialog
export struct chooseNavigationBar {
  controllerTwo?: CustomDialogController
  @State bar: string[] = ['待办模块', '数据分析', '计划铺子', '历史记录时间轴模块', '未来倒计时模块', '番茄自习室模块']

  build() {
    Column({ space: 20 }) {
      Row({ space: 5 }) {
        Text('自定义主界面功能模块')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r('app.media.ic_user_dui'))
          .width(30)
          .onClick(() => {
            if (this.controllerTwo) {
              this.controllerTwo.close()
            }
          })
        Image($r('app.media.ic_user_cha'))
          .width(30)
          .onClick(() => {
            if (this.controllerTwo) {
              this.controllerTwo.close()
            }
          })
      }
      .width('100%')

      ForEach(this.bar, (v: string) => {
        Row() {
          Text(v)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: true })
        }
        .width('100%')
      })
    }
    .width('100%')
    .padding(15)
    .alignItems(HorizontalAlign.Start)
  }
}