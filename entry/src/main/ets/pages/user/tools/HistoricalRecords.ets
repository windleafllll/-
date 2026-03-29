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
    const a = await planDB.query()
    this.Plan = a.filter((v: PlanDBInfo) => dayjs(v.date_added).format('YYYY-MM-DD') == this.nowTime)
  }

  @Builder
  navigationTitle() {
    Row({ space: 10 }) {
      Image($r('app.media.ic_public_back'))
        .width(30)
        .fillColor($r('app.color.subpage_nav_bar_fg'))
        .onClick(() => {
          router.back()
        })
      Text(this.DayDate)
        .fontWeight(FontWeight.Bold)
        .fontSize(19)
        .fontColor($r('app.color.subpage_nav_bar_fg'))
      Text(this.YearDate)
        .fontWeight(FontWeight.Bold)
        .fontSize(11)
        .fontColor($r('app.color.subpage_nav_bar_fg'))
    }
    .alignItems(VerticalAlign.Bottom)
    .width('100%')
    .backgroundColor($r('app.color.subpage_nav_bar_bg'))
    .padding({ left: 15, right: 15 })
  }

  build() {
    Navigation() {
      Column() {
        Column() {
          CalendarPicker()
            .width('100%')
            .textStyle({
              color: $r('app.color.brand_primary'),
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
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 4,
          bottom: 8
        })

        Scroll() {
          Column({ space: 8 }) {
            Text('历史记录')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            if (this.Plan.length === 0) {
              Text('当天暂无专注记录')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .padding({ top: 4, bottom: 8 })
            }

            ForEach(this.Plan, (v: PlanDBInfo) => {
              Row() {
                Column({ space: 8 }) {
                  Text(v.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(2)
                  Text((v.times / 60).toFixed(1) + ' 分钟')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column({ space: 8 }) {
                  if (v.is_accomplish) {
                    Text('已完成')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.brand_primary'))
                  } else {
                    Text('未完成')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  Text(dayjs(v.date_added).format('HH:mm'))
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.End)
              }
              .borderRadius(14)
              .padding(14)
              .backgroundColor($r('app.color.card_background'))
              .border({ width: 1, color: $r('app.color.input_border') })
              .width('100%')
            }, (v: PlanDBInfo) => `${v.id ?? 0}_${v.date_added}_${v.title}`)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: 16,
            right: 16,
            top: 0,
            bottom: 24
          })
        }
        .width('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.list_area_background'))
    }
    .title(this.navigationTitle())
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      direction: GradientDirection.Bottom,
      repeating: false,
      colors: [
        [$r('app.color.page_gradient_1'), 0.45],
        [$r('app.color.page_gradient_end'), 0.92]
      ]
    })
  }
}
