import { router } from '@kit.ArkUI'
import { toDoPlanDB, ToDoPlanDBInfo } from '../../database/ToDoPlanDB'
import { ToDoPlan } from '../ToDoPlan/ToDoPlan'

@Component
export struct HomeTab {
  dialogToDoPlan: CustomDialogController | null = new CustomDialogController({
    builder: ToDoPlan(),
    cornerRadius: 15,
    width: '80%'
  })
  @State refreshing: boolean = true
  @StorageLink('PlanID') PlanID: number = -1
  @State list: ToDoPlanDBInfo[] = []
  @State text: string = ''
  @State backNumber: string[] =
    ['app.media.ic_home_back_1', 'app.media.ic_home_back_2', 'app.media.ic_home_back_3', 'app.media.ic_home_back_4',
      'app.media.ic_home_back_5', 'app.media.ic_home_back_6', 'app.media.ic_home_back_7', 'app.media.ic_home_back_8',
      'app.media.ic_home_back_9', 'app.media.ic_home_back_10']

  @Builder
  deleteButton(id: number) {
    Button() {
      Image($r('app.media.ic_user_cha'))
        .width(20)
    }
    .width(40)
    .height(40)
    .type(ButtonType.Circle)
    .margin(5)
    .backgroundColor('#a62dceff')
    .onClick(async () => {
      await this.deleteToDoPlan(id)
      this.queryToDoPlan()
    })
  }

  async queryToDoPlan() {
    this.list = await toDoPlanDB.query()
  }

  async deleteToDoPlan(id: number) {
    await toDoPlanDB.delete(id)
  }

  build() {
    Column({ space: 15 }) {
      Row({ space: 20 }) {

        Blank()

        Image($r('app.media.ic_user_jiahao'))
          .height(18)
          .onClick(() => {
            if (this.dialogToDoPlan != null) {
              this.PlanID = -1
              this.dialogToDoPlan.open()
            }
          })

        Image($r('app.media.ic_user_gengduo'))
          .height(18)
      }
      .width('100%')
      .padding({ left: 10, right: 10 })

      Refresh({ refreshing: $$this.refreshing }) {
        Scroll() {
          Column({ space: 10 }) {
            if (this.list.length > 0) {
              List({ space: 10 }) {
                ForEach(this.list, (v: ToDoPlanDBInfo) => {
                  ListItem() {
                    if (v.event == '番茄钟') {
                      Row({ space: 40 }) {
                        Column({ space: 15 }) {
                          Text(v.title)
                            .fontColor(Color.White)
                            .fontSize(20)
                            .fontWeight(FontWeight.Bold)
                          if (v.times) {
                            Text(v.times.toString() + '分钟')
                              .fontColor(Color.White)
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                          }
                        }
                        .alignItems(HorizontalAlign.Start)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })

                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage($r(this.backNumber[Math.floor(Math.random() * (10 - 0) + 0)]))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(15)
                      .borderRadius(15)
                      .width('100%')
                    } else if (v.event == '养习惯') {
                      Row({ space: 40 }) {
                        Column({ space: 15 }) {
                          Text(v.title)
                            .fontColor(Color.White)
                            .fontSize(20)
                            .fontWeight(FontWeight.Bold)
                          if (v.times) {
                            Text(v.times.toString() + '分钟')
                              .fontColor(Color.White)
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                          }
                        }
                        .alignItems(HorizontalAlign.Start)

                        Column() {
                          Text('计划 ' + v.time)
                            .fontColor(Color.White)
                            .fontSize(11)
                            .fontWeight(FontWeight.Medium)
                          Text('完成' + v.timess + v.timesss)
                            .fontColor(Color.White)
                            .fontSize(11)
                            .fontWeight(FontWeight.Medium)
                        }
                        .height(45)
                        .alignItems(HorizontalAlign.Start)
                        .justifyContent(FlexAlign.Start)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })

                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage($r(this.backNumber[Math.floor(Math.random() * (10 - 0) + 0)]))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(15)
                      .borderRadius(15)
                      .width('100%')
                    } else if (v.event == '定目标') {
                      Row({ space: 40 }) {
                        Column({ space: 15 }) {
                          Text(v.title)
                            .fontColor(Color.White)
                            .fontSize(20)
                            .fontWeight(FontWeight.Bold)
                          if (v.times) {
                            Text(v.times.toString() + '分钟')
                              .fontColor(Color.White)
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                          }
                        }
                        .alignItems(HorizontalAlign.Start)

                        Column() {
                          Text('计划 ' + v.time + ' 之前')
                            .fontColor(Color.White)
                            .fontSize(11)
                            .fontWeight(FontWeight.Medium)
                          Text('总共完成' + v.timess + v.timesss)
                            .fontColor(Color.White)
                            .fontSize(11)
                            .fontWeight(FontWeight.Medium)
                        }
                        .height(45)
                        .alignItems(HorizontalAlign.Start)
                        .justifyContent(FlexAlign.Start)

                        Button('开始', { buttonStyle: ButtonStyleMode.TEXTUAL })
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Bold)
                          .onClick(() => {
                            router.pushUrl({ url: 'pages/DoPlan/DoPlanIndex', params: { id: v.id } })
                          })
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundImage($r(this.backNumber[Math.floor(Math.random() * (10 - 0) + 0)]))
                      .backgroundImageSize({ width: '100%', height: '100%' })
                      .padding(15)
                      .borderRadius(15)
                      .width('100%')
                    }
                  }
                  .swipeAction({ end: this.deleteButton(v.id) })
                  .onClick(() => {
                    if (this.dialogToDoPlan != null) {
                      this.PlanID = v.id as number
                      this.dialogToDoPlan.open()
                    }
                  })
                })
              }
            } else {
              Row() {
                Text('请先点击 + 创建一个计划')
                  .fontColor(Color.Gray)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
              }
            }
          }
          .height('100%')
          .width('100%')
        }
      }
      .padding(15)
      .width('100%')
      .backgroundColor('#fff1f1f1')
      .onRefreshing(async () => {
        await this.queryToDoPlan()
        this.refreshing = false
      })
    }
  }
}