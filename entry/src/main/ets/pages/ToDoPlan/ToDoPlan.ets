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
        .onClick(() => {
          this.controllerTwo?.close()
        })
      Text('添加待办')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
      Image($r('app.media.ic_user_dui'))
        .width(20)
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
                  date_added: Date.now()
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
    .padding(10)
    .backgroundColor('#fff5f5f5')
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Image($r('app.media.ic_user_cha'))
          .width(20)
          .onClick(() => {
            this.controllerTwo?.close()
          })
        Text('添加待办')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
        Image($r('app.media.ic_user_dui'))
          .width(20)
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
                    date_added: Date.now()
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
      .padding(10)
      .backgroundColor('#fff5f5f5')

      Row() {
        Toggle({ type: ToggleType.Button, isOn: $$this.y1 }) {
          Text('番茄钟')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onClick(() => {
          this.y2 = false
          this.y3 = false
          this.event = '番茄钟'
          this.times = ''
          this.timess = ''
          this.timesss = '分钟'
        })

        Toggle({ type: ToggleType.Button, isOn: $$this.y2 }) {
          Text('养习惯')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onClick(() => {
          this.y1 = false
          this.y3 = false
          this.event = '养习惯'
          this.times = ''
          this.timess = ''
          this.timesss = '分钟'
        })


        Toggle({ type: ToggleType.Button, isOn: $$this.y3 }) {
          Text('定目标')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onClick(() => {
          this.y2 = false
          this.y1 = false
          this.event = '定目标'
          this.times = ''
          this.timess = ''
          this.timesss = '分钟'
        })
      }
      .width('70%')
      .justifyContent(FlexAlign.SpaceAround)

      TextInput({ placeholder: '请输入事项名称', text: $$this.title })
        .width('70%')
        .height(35)
        .maxLength(5)
      if (this.event == '养习惯') {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Text('我想')
            Select([{ value: '每天' }, { value: '每周' }, { value: '每月' }])
              .selected(0)
              .value(this.time1)
              .onSelect((index: number, value: string) => {
                this.time1 = value
              })
          }

          Row({ space: 10 }) {
            Text('完成')
            TextInput({ text: $$this.timess })
              .type(InputType.Number)
              .width('20%')
              .height(35)
              .maxLength(3)
            Select([{ value: '分钟' }, { value: '次' }])
              .selected(0)
              .value(this.timesss)
              .onSelect((index: number, value: string) => {
                this.timesss = value
              })
          }

          Text('最后一步，设置单次专注的时长')
        }
      } else if (this.event == '定目标') {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Text('我想在')
            CalendarPicker({ selected: new Date(this.time2) })
              .onChange((value: Date) => {
                this.time2 = dayjs(value).format('YYYY-MM-DD')
              })
            Text('之前')
          }

          Row({ space: 10 }) {
            Text('一共完成')
            TextInput({ text: $$this.timess })
              .type(InputType.Number)
              .width('20%')
              .height(35)
              .maxLength(3)
            Select([{ value: '分钟' }, { value: '次' }])
              .selected(0)
              .value(this.timesss)
              .onSelect((index: number, value: string) => {
                this.timesss = value
              })
          }

          Text('最后一步，设置单次专注的时长')
        }
      }
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Button, isOn: $$this.x1 }) {
          Text('倒计时')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onChange((isOn: boolean) => {
          if (isOn == true) {
            this.x2 = false
            this.x3 = false
            this.type = '倒计时'
          }
        })

        Toggle({ type: ToggleType.Button, isOn: $$this.x2 }) {
          Text('正向计时')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onChange((isOn: boolean) => {
          if (isOn == true) {
            this.x1 = false
            this.x3 = false
            this.type = '正向计时'
          }
        })

        Toggle({ type: ToggleType.Button, isOn: $$this.x3 }) {
          Text('不计时')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }
        .onChange((isOn: boolean) => {
          if (isOn == true) {
            this.x2 = false
            this.x1 = false
            this.type = '不计时'
          }
        })
      }
      .width('70%')
      .justifyContent(FlexAlign.SpaceAround)

      if (this.type == '倒计时') {
        Row() {
          TextInput({ text: $$this.times })
            .type(InputType.Number)
            .width('20%')
            .height(35)
            .maxLength(3)
          Text('分钟')
            .fontWeight(FontWeight.Bold)
            .fontSize(15)
        }
      }
    }
    .backgroundColor('#fff1f1f1')
    .padding({ bottom: 30 })
  }
}