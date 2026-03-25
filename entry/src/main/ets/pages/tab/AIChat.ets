import { promptAction, router } from '@kit.ArkUI'
import { i } from '../../api/AIChatAPI';
import { aiChatDB, AIChatDBInfo } from '../../database/AIChatDB';
import inputMethod from '@ohos.inputMethod';
import { toDoPlanDB } from '../../database/ToDoPlanDB';

@Component
export struct AIChat {
  @State isCanDoPlan: boolean = false
  @State isDoPlan: boolean = false
  @State isButton: boolean = false
  @State inputText: string = ''
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @State message: string = ''
  @State isOver: boolean = false
  @State horizontalPadding: number = 20
  @State bubbleWidth: string = '75%'
  @State chat: AIChatDBInfo[] = [
    {
      id: null,
      spokesperson: 'AI',
      content: '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。',
      date_added: Date.now()
    }
  ]
  private chatScroller: Scroller = new Scroller()

  private scrollToBottom() {
    setTimeout(() => {
      this.chatScroller.scrollEdge(Edge.Bottom)
    }, 0)
  }

  private updateResponsiveLayout(width: number) {
    if (width >= 900) {
      this.horizontalPadding = 32
      this.bubbleWidth = '62%'
    } else {
      this.horizontalPadding = 20
      this.bubbleWidth = '75%'
    }
  }

  async aboutToAppear() {
    const a: AIChatDBInfo[] = await aiChatDB.query()
    if (a.length > 0) {
      this.chat = a
    } else {
      aiChatDB.insert(this.chat[0])
    }
    this.scrollToBottom()

  }

  @Builder
  NavigationTitle() {
    Row() {
      Image($r('app.media.ic_public_delete'))
        .width(20)
        .onClick(() => {
          aiChatDB.delete()
          this.chat = []
          aiChatDB.insert({
            id: null,
            spokesperson: 'AI',
            content: '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。',
            date_added: Date.now()
          })
          this.chat.push({
            id: null,
            spokesperson: 'AI',
            content: '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。',
            date_added: Date.now()
          })
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .padding(10)
  }

  build() {
    Navigation() {
      Column() {
        Scroll(this.chatScroller) {
          List({ space: 30 }) {
            ForEach(this.chat, (v: AIChatDBInfo) => {
              if (v.spokesperson == 'AI') {
                ListItem() {
                  Row({ space: 10 }) {
                    Image($r('app.media.ic_ai_aihead'))
                      .width('10%')
                    if (v.content == '') {
                      LoadingProgress()
                        .color(Color.Orange)
                        .width(40)
                    } else {
                      Text(v.content)
                        .width(this.bubbleWidth)
                        .padding(10)
                        .borderRadius(20)
                        .backgroundColor(Color.White)
                    }
                    Blank()

                  }
                  .alignItems(VerticalAlign.Top)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .width('100%')
                }
              } else if (v.spokesperson == 'user') {
                ListItem() {
                  Row({ space: 10 }) {
                    Row() {
                      Text(v.content)
                        .padding(10)
                        .borderRadius(20)
                        .backgroundColor(Color.White)
                    }
                    .justifyContent(FlexAlign.End)
                    .width(this.bubbleWidth)

                    Image($r(this.userHead))
                      .width('10%')
                  }
                  .alignItems(VerticalAlign.Top)
                  .justifyContent(FlexAlign.End)
                  .width('100%')
                }
              }
            })
          }
          .padding({ left: this.horizontalPadding, right: this.horizontalPadding })
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)

      Row() {
        Toggle({ type: ToggleType.Button, isOn: $$this.isDoPlan }) {
          Text('制定计划')
            .fontWeight(FontWeight.Medium)
            .fontSize(15)
        }

        Blank()
        Button('一键制定计划', { buttonStyle: ButtonStyleMode.TEXTUAL })
          .fontColor('#f6726e')
          .enabled(this.isCanDoPlan)
          .onClick(() => {
            let a = this.chat[this.chat.length - 1].content
            if (a == '' || a ==
              '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。' ||
              a == '服务器连接错误，请重试') {
              promptAction.showToast({
                message: '一键创建计划错误'
              })
              this.isCanDoPlan = false
            } else {
              let b: string [] = a.split('.')
              b.forEach((v: string) => {
                if (v.includes('分钟')) {
                  let c: string[] = v.split('分钟')
                  let d: string[] = c[0].split('：')
                  toDoPlanDB.insert({
                    id: null,
                    title: d[0],
                    event: '番茄钟',
                    time: null,
                    timess: null,
                    timesss: null,
                    type: '倒计时',
                    times: Number(d[1]),
                    date_added: Date.now()
                  })
                }
              })
              promptAction.showToast({
                message: '一键创建计划成功'
              })
              this.isCanDoPlan = false
            }
          })
      }
      .padding({ left: this.horizontalPadding, right: this.horizontalPadding, bottom: 5 })
      .width('100%')

      Row() {
        // 多行输入：内容变多后自动换行并增高
        TextArea({ text: $$this.inputText })
          .width('75%')
          .maxLines(6)
          .borderRadius(12)
          .padding(10)
          .onChange((inputText: String) => {
            if (inputText == '') {
              this.isButton = false
            } else {
              this.isButton = true
            }
          })
        Button('发送')
          .backgroundColor('#00b877')
          .alignSelf(ItemAlign.End)
          .onClick(async () => {
            let inputMethodController = inputMethod.getController();
            inputMethodController.stopInputSession();
            this.isOver = false
            this.message = ''
            await aiChatDB.insert({
              id: null,
              spokesperson: 'user',
              content: this.inputText,
              date_added: Date.now()
            })
            this.chat.push({
              id: null,
              spokesperson: 'user',
              content: this.inputText,
              date_added: Date.now()
            })
            this.chat.push({
              id: null,
              spokesperson: 'AI',
              content: '',
              date_added: Date.now()
            })
            this.scrollToBottom()
            if (this.isDoPlan) {
              await i(this.inputText +
                '，必须严格按照以下规则来制定计划：1.计划内容只能包括标题和持续时间，标题最多为四个字，持续时间必须为分钟,标题和持续时间之间只能用：隔开。',
                (chunk) => {
                  this.message += chunk
                  this.chat[this.chat.length - 1] = {
                    id: null,
                    spokesperson: 'AI',
                    content: this.message,
                    date_added: Date.now()
                  }
                  // 实时更新消息
                  this.scrollToBottom()
                }, (isOver) => {
                  this.isOver = isOver
                  aiChatDB.insert({
                    id: null,
                    spokesperson: 'AI',
                    content: this.message,
                    date_added: Date.now()
                  })
                  this.scrollToBottom()
                }, async () => {
                  this.chat[this.chat.length - 1] = {
                    id: null,
                    spokesperson: 'AI',
                    content: '服务器连接错误，请重试',
                    date_added: Date.now()
                  }
                  this.scrollToBottom()
                })
              this.isCanDoPlan = true
            } else {
              await i(this.inputText, (chunk) => {
                this.message += chunk
                this.chat[this.chat.length - 1] = {
                  id: null,
                  spokesperson: 'AI',
                  content: this.message,
                  date_added: Date.now()
                }
                // 实时更新消息
                this.scrollToBottom()
              }, (isOver) => {
                this.isOver = isOver
                aiChatDB.insert({
                  id: null,
                  spokesperson: 'AI',
                  content: this.message,
                  date_added: Date.now()
                })
                this.scrollToBottom()
              }, async () => {
                this.chat[this.chat.length - 1] = {
                  id: null,
                  spokesperson: 'AI',
                  content: '服务器连接错误，请重试',
                  date_added: Date.now()
                }
                this.scrollToBottom()
              })
              this.isCanDoPlan = false
            }
            this.isDoPlan = false
            this.inputText = ''
          })
          .enabled(this.isButton)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({ left: this.horizontalPadding, right: this.horizontalPadding })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .titleMode(NavigationTitleMode.Mini)
    .title(this.NavigationTitle())
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
  }
}