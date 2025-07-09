import dayjs from 'dayjs'
import { planDB, PlanDBInfo } from '../../../database/PlanDB'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct HistoricalRecords {
  @State DayDate: string = dayjs(Date.now()).format('MM月DD日')
  @State YearDate: string = dayjs(Date.now()).format('YYYY')
  @State Plan: PlanDBInfo[] = []
  @State nowTime: string = dayjs(Date.now()).format('YYYY-MM-DD')

  async aboutToAppear() {
    await this.QueryPlan()
  }

  async QueryPlan() {
    this.Plan = []
    let a = await planDB.query()
    a.forEach((v: PlanDBInfo) => {
      if (dayjs(v.date_added).format('YYYY-MM-DD') == this.nowTime) {
        this.Plan.push(v)
      }
    })
  }

  @Builder
  navigationTitle() {
    Row({ space: 10 }) {
      Image($r('app.media.ic_public_back'))
        .width(30)
        .fillColor(Color.White)
        .onClick(()=>{
          router.back()
        })
      Text(this.DayDate)
        .fontWeight(FontWeight.Bold)
        .fontSize(19)
        .fontColor(Color.White)
      Text(this.YearDate)
        .fontWeight(FontWeight.Bold)
        .fontSize(11)
        .fontColor(Color.White)
    }
    .alignItems(VerticalAlign.Bottom)
    .width('100%')
    .backgroundColor('#f6726e')
    .padding({ left: 15, right: 15 })
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        CalendarPicker()
          .textStyle({
            color: '#f6726e',
            font: {
              size: 15,
              weight: FontWeight.Bold
            }
          })
          .onChange((Value: Date) => {
            this.nowTime = dayjs(Value).format('YYYY-MM-DD')
            this.DayDate = dayjs(Value).format('MM月DD日')
            this.YearDate = dayjs(Value).format('YYYY')
            this.QueryPlan()
          })
        Scroll() {
          Column({ space: 15 }) {
            Text('历史记录：')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#f6726e')
            ForEach(this.Plan, (v: PlanDBInfo) => {
              Row() {
                Column({ space: 20 }) {
                  Text(v.title)
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#f6726e')
                  Text((v.times / 60).toFixed(1) + '分钟')
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Column({ space: 20 }) {
                  if (v.is_accomplish) {
                    Text('已完成')
                      .fontSize(11)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#f6726e')
                  } else {
                    Text('未完成')
                      .fontSize(11)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#f6726e')
                  }
                  Text(dayjs(v.date_added).format('HH点mm分'))
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.End)
              }
              .borderRadius(15)
              .padding(10)
              .backgroundColor('#1df6726e')
              .width('100%')
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ bottom: 30 })
      }
      .padding(10)
      .backgroundColor('#fff1f1f1')
      .width('100%')
      .height('100%')
    }
    .title(this.navigationTitle())
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      direction: GradientDirection.Bottom, // 渐变方向
      repeating: false, // 渐变颜色是否重复
      colors: [['#f6726e', 0.5], ['#fff1f1f1', 0.9]] // 数组末尾元素占比小于1时满足重复着色效果
    })
  }
}