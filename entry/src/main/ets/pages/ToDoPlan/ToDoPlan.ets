import { toDoPlanDB, ToDoPlanDBInfo } from '../../database/ToDoPlanDB'
import dayjs from 'dayjs'

interface RouterParams {
  id?: number
}

@CustomDialog
export struct ToDoPlan {
  controllerTwo?: CustomDialogController
  list: ToDoPlanDBInfo[] = []
  @State title: string = ''
  @State event: string = '番茄钟'
  @State time1: string = '每天'
  @State time2: string = dayjs(Date.now()).format('YYYY-MM-DD')
  @State timess: string = ''
  @State timesss: string = '分钟'
  @State type: string = '倒计时'
  @State times: string = ''
  @State x1: boolean = true
  @State x2: boolean = false
  @State x3: boolean = false
  @State y1: boolean = true
  @State y2: boolean = false
  @State y3: boolean = false
  @State ID: number | null = null
  @StorageLink('PlanID') PlanID: number = -1
  @StorageLink('PlanChangedAt') planChangedAt: number = 0
  private planFormScroller: Scroller = new Scroller()

  private scrollDurationFieldIntoView(): void {
    setTimeout((): void => {
      this.planFormScroller.scrollEdge(Edge.Bottom)
    }, 280)
  }

  aboutToAppear(): void {
    if (this.PlanID != -1) {
      this.getDetail()
    }
  }

  async getDetail() {
    const list = await toDoPlanDB.query(this.PlanID)
    const detail = list[0]
    this.ID = detail.id
    this.title = detail.title
    this.event = detail.event
    this.type = detail.type
    if (detail.event == '番茄钟') {
      if (detail.type == '倒计时') {
        this.times = detail.times?.toString() as string
      } else if (detail.type == '正向计时') {
        this.x1 = false
        this.x2 = true
      } else if (detail.type == '不计时') {
        this.x1 = false
        this.x3 = true
      }
    } else if (detail.event == '养习惯') {
      this.event = detail.event
      this.y1 = false
      this.y2 = true
      this.time1 = detail.time as string
      this.timess = detail.timess?.toString() as string
      this.timesss = detail.timesss as string
      if (detail.type == '倒计时') {
        this.times = detail.times?.toString() as string
      } else if (detail.type == '正向计时') {
        this.x1 = false
        this.x2 = true
      } else if (detail.type == '不计时') {
        this.x1 = false
        this.x3 = true
      }
    } else if (detail.event == '定目标') {
      this.event = detail.event
      this.y1 = false
      this.y3 = true
      this.time2 = detail.time as string
      this.timess = detail.timess?.toString() as string
      this.timesss = detail.timesss as string
      if (detail.type == '倒计时') {
        this.times = detail.times?.toString() as string
      } else if (detail.type == '正向计时') {
        this.x1 = false
        this.x2 = true
      } else if (detail.type == '不计时') {
        this.x1 = false
        this.x3 = true
      }
    }
  }

  @Builder
  NavigationTitle() {
    Row() {
      Image($r('app.media.ic_user_cha'))
        .width(20)
        .fillColor($r('app.color.text_on_brand'))
        .onClick(() => {
          this.controllerTwo?.close()
        })
      Text(this.PlanID != -1 ? '修改计划' : '新建计划')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_on_brand'))
      Image($r('app.media.ic_user_dui'))
        .width(20)
        .fillColor($r('app.color.text_on_brand'))
        .onClick(async () => {
          if (this.event == '番茄钟') {
            if (this.type == '倒计时') {
              if (this.title == '' || this.times == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            } else {
              if (this.title == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            }
          } else if (this.event == '养习惯') {
            if (this.type == '倒计时') {
              if (this.title == '' || this.times == '' || this.timess == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            } else {
              if (this.title == '' || this.timess == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            }
          } else if (this.event == '定目标') {
            if (this.type == '倒计时') {
              if (this.title == '' || this.times == '' || this.timess == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            } else {
              if (this.title == '' || this.timess == '') {
                AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                return
              }
            }
          }
          if (this.ID == null) {
            if (this.event == '番茄钟') {
              if (this.type == '倒计时') {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: null,
                  timess: null,
                  timesss: null,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: null,
                  timess: null,
                  timesss: null,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            } else if (this.event == '养习惯') {
              if (this.type == '倒计时') {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: this.time1,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: this.time1,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            } else if (this.event == '定目标') {
              if (this.type == '倒计时') {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: this.time2,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.insert({
                  id: null,
                  title: this.title,
                  event: this.event,
                  time: this.time2,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            }
          } else if (this.ID != null) {
            if (this.event == '番茄钟') {
              if (this.type == '倒计时') {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: null,
                  timess: null,
                  timesss: null,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: null,
                  timess: null,
                  timesss: null,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            } else if (this.event == '养习惯') {
              if (this.type == '倒计时') {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: this.time1,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: this.time1,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            } else if (this.event == '定目标') {
              if (this.type == '倒计时') {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: this.time2,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: Number(this.times),
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              } else {
                await toDoPlanDB.update({
                  id: this.ID,
                  title: this.title,
                  event: this.event,
                  time: this.time2,
                  timess: Number(this.timess),
                  timesss: this.timesss,
                  type: this.type,
                  times: null,
                  date_added: Date.now(),
                  sort_order: null
                })
                this.planChangedAt = Date.now()
                this.controllerTwo?.close()
              }
            }
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.brand_primary'))
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_user_cha'))
          .width(22)
          .fillColor($r('app.color.text_on_brand'))
          .onClick(() => {
            this.controllerTwo?.close()
          })
        Text(this.PlanID != -1 ? '修改计划' : '新建计划')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_brand'))
        Image($r('app.media.ic_user_dui'))
          .width(22)
          .fillColor($r('app.color.text_on_brand'))
          .onClick(async () => {
            if (this.event == '番茄钟') {
              if (this.type == '倒计时') {
                if (this.title == '' || this.times == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              } else {
                if (this.title == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              }
            } else if (this.event == '养习惯') {
              if (this.type == '倒计时') {
                if (this.title == '' || this.times == '' || this.timess == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              } else {
                if (this.title == '' || this.timess == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              }
            } else if (this.event == '定目标') {
              if (this.type == '倒计时') {
                if (this.title == '' || this.times == '' || this.timess == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              } else {
                if (this.title == '' || this.timess == '') {
                  AlertDialog.show({ title: '注意', message: '您的计划尚未完成，无法保存' })
                  return
                }
              }
            }
            if (this.ID == null) {
              if (this.event == '番茄钟') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: null,
                    timess: null,
                    timesss: null,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: null,
                    timess: null,
                    timesss: null,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              } else if (this.event == '养习惯') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: this.time1,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: this.time1,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              } else if (this.event == '定目标') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: this.time2,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.insert({
                    id: null,
                    title: this.title,
                    event: this.event,
                    time: this.time2,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              }
            } else if (this.ID != null) {
              if (this.event == '番茄钟') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: null,
                    timess: null,
                    timesss: null,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: null,
                    timess: null,
                    timesss: null,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              } else if (this.event == '养习惯') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: this.time1,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: this.time1,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              } else if (this.event == '定目标') {
                if (this.type == '倒计时') {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: this.time2,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: Number(this.times),
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                } else {
                  await toDoPlanDB.update({
                    id: this.ID,
                    title: this.title,
                    event: this.event,
                    time: this.time2,
                    timess: Number(this.timess),
                    timesss: this.timesss,
                    type: this.type,
                    times: null,
                    date_added: Date.now(),
                    sort_order: null
                  })
                  this.planChangedAt = Date.now()
                  this.controllerTwo?.close()
                }
              }
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor($r('app.color.brand_primary'))

      Scroll(this.planFormScroller) {
        Column({ space: 16 }) {
          Column({ space: 10 }) {
            Text('计划类型')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
            Row({ space: 8 }) {
              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Text('番茄钟')
                  .fontWeight(FontWeight.Medium)
                  .fontSize(15)
                  .fontColor($r('app.color.text_primary'))
              }
              .layoutWeight(1)
              .height(42)
              .borderRadius(10)
              .backgroundColor(this.y1 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
              .border({
                width: this.y1 ? 2 : 1,
                color: this.y1 ? $r('app.color.brand_primary') : $r('app.color.input_border')
              })
              .onClick(() => {
                if (this.y1) {
                  return
                }
                this.y1 = true
                this.y2 = false
                this.y3 = false
                this.event = '番茄钟'
                this.times = ''
                this.timess = ''
                this.timesss = '分钟'
              })

              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Text('养习惯')
                  .fontWeight(FontWeight.Medium)
                  .fontSize(15)
                  .fontColor($r('app.color.text_primary'))
              }
              .layoutWeight(1)
              .height(42)
              .borderRadius(10)
              .backgroundColor(this.y2 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
              .border({
                width: this.y2 ? 2 : 1,
                color: this.y2 ? $r('app.color.brand_primary') : $r('app.color.input_border')
              })
              .onClick(() => {
                if (this.y2) {
                  return
                }
                this.y2 = true
                this.y1 = false
                this.y3 = false
                this.event = '养习惯'
                this.times = ''
                this.timess = ''
                this.timesss = '分钟'
              })

              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Text('定目标')
                  .fontWeight(FontWeight.Medium)
                  .fontSize(15)
                  .fontColor($r('app.color.text_primary'))
              }
              .layoutWeight(1)
              .height(42)
              .borderRadius(10)
              .backgroundColor(this.y3 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
              .border({
                width: this.y3 ? 2 : 1,
                color: this.y3 ? $r('app.color.brand_primary') : $r('app.color.input_border')
              })
              .onClick(() => {
                if (this.y3) {
                  return
                }
                this.y3 = true
                this.y1 = false
                this.y2 = false
                this.event = '定目标'
                this.times = ''
                this.timess = ''
                this.timesss = '分钟'
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
          }
          .width('100%')
          .padding(14)
          .borderRadius(14)
          .backgroundColor($r('app.color.surface_muted'))
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text('事项名称')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
            TextInput({ placeholder: '最多 5 个字', text: $$this.title })
              .width('100%')
              .height(44)
              .maxLength(5)
              .borderRadius(10)
              .border({ width: 1, color: $r('app.color.input_border') })
              .padding({ left: 12, right: 12 })
              .backgroundColor($r('app.color.dialog_input_surface'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

      if (this.event == '养习惯') {
        Column({ space: 12 }) {
          Text('习惯目标')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row({ space: 10 }) {
            Text('我想')
              .fontColor($r('app.color.text_primary'))
            Select([{ value: '每天' }, { value: '每周' }, { value: '每月' }])
              .selected(0)
              .value(this.time1)
              .onSelect((index: number, value: string) => {
                this.time1 = value
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            Text('完成')
              .fontColor($r('app.color.text_primary'))
            TextInput({ text: $$this.timess })
              .type(InputType.Number)
              .layoutWeight(1)
              .height(40)
              .maxLength(3)
              .borderRadius(10)
              .border({ width: 1, color: $r('app.color.input_border') })
              .padding({ left: 10, right: 10 })
              .backgroundColor($r('app.color.dialog_input_surface'))
              .fontColor($r('app.color.text_primary'))
              .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
              .onFocus(() => {
                this.scrollDurationFieldIntoView()
              })
            Select([{ value: '分钟' }, { value: '次' }])
              .selected(0)
              .value(this.timesss)
              .onSelect((index: number, value: string) => {
                this.timesss = value
              })
          }
          .width('100%')

          Text('最后一步：设置单次专注时长')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.surface_muted'))
        .alignItems(HorizontalAlign.Start)
      } else if (this.event == '定目标') {
        Column({ space: 12 }) {
          Text('目标与期限')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row({ space: 10 }) {
            Text('我想在')
              .fontColor($r('app.color.text_primary'))
            CalendarPicker({ selected: new Date(this.time2) })
              .onChange((value: Date) => {
                this.time2 = dayjs(value).format('YYYY-MM-DD')
              })
            Text('之前')
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')

          Row({ space: 10 }) {
            Text('一共完成')
              .fontColor($r('app.color.text_primary'))
            TextInput({ text: $$this.timess })
              .type(InputType.Number)
              .layoutWeight(1)
              .height(40)
              .maxLength(3)
              .borderRadius(10)
              .border({ width: 1, color: $r('app.color.input_border') })
              .padding({ left: 10, right: 10 })
              .backgroundColor($r('app.color.dialog_input_surface'))
              .fontColor($r('app.color.text_primary'))
              .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
              .onFocus(() => {
                this.scrollDurationFieldIntoView()
              })
            Select([{ value: '分钟' }, { value: '次' }])
              .selected(0)
              .value(this.timesss)
              .onSelect((index: number, value: string) => {
                this.timesss = value
              })
          }
          .width('100%')

          Text('最后一步：设置单次专注时长')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.surface_muted'))
        .alignItems(HorizontalAlign.Start)
      }

      Column({ space: 10 }) {
        Text('计时方式')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row({ space: 8 }) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('倒计时')
              .fontWeight(FontWeight.Medium)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(10)
          .backgroundColor(this.x1 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
          .border({
            width: this.x1 ? 2 : 1,
            color: this.x1 ? $r('app.color.brand_primary') : $r('app.color.input_border')
          })
          .onClick(() => {
            if (this.x1) {
              return
            }
            this.x1 = true
            this.x2 = false
            this.x3 = false
            this.type = '倒计时'
          })

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('正向计时')
              .fontWeight(FontWeight.Medium)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(10)
          .backgroundColor(this.x2 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
          .border({
            width: this.x2 ? 2 : 1,
            color: this.x2 ? $r('app.color.brand_primary') : $r('app.color.input_border')
          })
          .onClick(() => {
            if (this.x2) {
              return
            }
            this.x2 = true
            this.x1 = false
            this.x3 = false
            this.type = '正向计时'
          })

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('不计时')
              .fontWeight(FontWeight.Medium)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(10)
          .backgroundColor(this.x3 ? $r('app.color.brand_primary_soft_bg') : $r('app.color.card_background'))
          .border({
            width: this.x3 ? 2 : 1,
            color: this.x3 ? $r('app.color.brand_primary') : $r('app.color.input_border')
          })
          .onClick(() => {
            if (this.x3) {
              return
            }
            this.x3 = true
            this.x1 = false
            this.x2 = false
            this.type = '不计时'
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(14)
      .borderRadius(14)
      .backgroundColor($r('app.color.surface_muted'))
      .alignItems(HorizontalAlign.Start)

      if (this.type == '倒计时') {
        Column({ space: 8 }) {
          Text('单次时长')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row({ space: 8 }) {
            TextInput({ text: $$this.times })
              .type(InputType.Number)
              .width('28%')
              .height(44)
              .maxLength(3)
              .borderRadius(10)
              .border({ width: 1, color: $r('app.color.input_border') })
              .padding({ left: 12, right: 12 })
              .backgroundColor($r('app.color.dialog_input_surface'))
              .fontColor($r('app.color.text_primary'))
              .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
              .onFocus(() => {
                this.scrollDurationFieldIntoView()
              })
            Text('分钟')
              .fontWeight(FontWeight.Bold)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 160 })
      }
      .width('100%')
      .constraintSize({ maxHeight: 480 })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(20)
    .clip(true)
  }
}