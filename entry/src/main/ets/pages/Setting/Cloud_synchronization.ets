import { router } from '@kit.ArkUI'

@CustomDialog
struct HelpDialog {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 20 }) {
      Text('帮助')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 20 }) {
        Text('1.在老设备点击【备份至服务器】')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text('2.在新设备点击【恢复至本机】')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text('注意：请确保操作的客户端均为最新版本，建议可前往设备的应用商店检查是否最新版本')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Button('好的')
        .fontColor('#F37E6A')
        .backgroundColor('#FFF1F0')
        .width('70%')
        .onClick(() => {
          if (this.controllerTwo) {
            this.controllerTwo.close()
          }
        })
    }
    .padding({ top: 20, bottom: 20 })
    .width('70%')
  }
}

@CustomDialog
struct VIPDialog {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 10 }) {
      Text('提示')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 20 }) {
        Text('您可以开通季度卡来使用此项高级功能')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text('更可享受更多新颖高级功能，祝您养成专注好习惯')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Button('去季度卡页面看看')
        .fontColor('#F37E6A')
        .backgroundColor('#FFF1F0')
        .width('70%')
        .onClick(() => {
          router.pushUrl({ url: '' })
        })

      Button('取消', { buttonStyle: ButtonStyleMode.TEXTUAL })
        .fontColor('#ffa9a9a9')
        .width('70%')
        .onClick(() => {
          if (this.controllerTwo) {
            this.controllerTwo.close()
          }
        })
    }
    .padding({ top: 20, bottom: 20 })
    .width('70%')
  }
}


@Entry
@Component
struct Cloud_synchronization {
  dialogHelp: CustomDialogController | null = new CustomDialogController({
    builder: HelpDialog()
  })
  dialogVIP: CustomDialogController | null = new CustomDialogController({
    builder: VIPDialog()
  })
  @StorageLink('isCloud') isClouds: boolean = false
  @StorageLink('isVIP') isVip: boolean = false

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Column({ space: 15 }) {
          Text('备份 | 恢复')
            .fontWeight(FontWeight.Bold)
            .fontSize(14)
          Row({ space: 20 }) {
            Image($r('app.media.ic_public_cloud_upload'))
              .width(40)
              .fillColor(Color.White)
            Text('备份至服务器')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .backgroundColor('#858CFF')
          .padding(15)
          .borderRadius(15)
          .width('100%')

          Row({ space: 20 }) {
            Image($r('app.media.ic_public_cloud_download'))
              .width(40)
              .fillColor(Color.White)
            Text('恢复至本机')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .padding(15)
          .backgroundColor('#58C7FF')
          .borderRadius(15)
          .width('100%')

          Row() {
            Text('如何将全部数据到入至新设备？')
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
          }
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(15)
          .width('100%')
          .onClick(() => {
            if (this.dialogHelp != null) {
              this.dialogHelp.open()
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#fff1f1f1')
        .width('100%')
        .padding(20)
        .borderRadius(15)

        Column({ space: 15 }) {
          Row({ space: 5 }) {
            Text('同步')
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
            Image($r('app.media.ic_user_vipcard'))
              .width(20)
          }

          Row({ space: 20 }) {
            Image($r('app.media.ic_public_cloud_synchronise'))
              .width(40)
              .fillColor(Color.White)
            Column({ space: 5 }) {
              Text('自动同步近期数据')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              if (this.isClouds) {
                Text('已开启')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              } else {
                Text('未开启')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              }
            }
            .alignItems(HorizontalAlign.Start)

            Toggle({ type: ToggleType.Switch, isOn: $$this.isClouds })
              .onChange((isOn: boolean) => {
                if (isOn == true) {
                  if (!this.isVip) {
                    if (this.dialogVIP != null) {
                      this.dialogVIP.open()
                      this.isClouds = false
                    }
                  }
                }
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor('#858CFF')
          .padding(15)
          .borderRadius(15)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#fff1f1f1')
        .width('100%')
        .padding(20)
        .borderRadius(15)
      }
      .padding(20)
    }
    .title('云同步')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}