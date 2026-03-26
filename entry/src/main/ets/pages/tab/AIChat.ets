import { promptAction, router } from '@kit.ArkUI'
import { i } from '../../api/AIChatAPI';
import { aiChatDB, AIChatDBInfo } from '../../database/AIChatDB';
import inputMethod from '@ohos.inputMethod';
import { toDoPlanDB } from '../../database/ToDoPlanDB';

interface GeneratedPlanItem {
  title: string
  minutes: number
}

interface PlanJsonItem {
  title?: string
  minutes?: number
}

@CustomDialog
struct PlanGeneratingDialog {
  controllerTwo?: CustomDialogController

  build() {
    Column({ space: 14 }) {
      LoadingProgress()
        .color('#f6726e')
        .width(44)
        .height(44)

      Text('计划正在生成...')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('请稍等片刻')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#6B7280')
    }
    .padding(22)
    .width('70%')
    .borderRadius(14)
    .backgroundColor('#fff')
  }
}

@CustomDialog
struct PlanPickDialog {
  controllerTwo?: CustomDialogController
  plans: GeneratedPlanItem[] = []
  onConfirm?: (picked: GeneratedPlanItem[]) => Promise<void>
  @State checked: boolean[] = []

  aboutToAppear() {
    const next: boolean[] = []
    for (let i = 0; i < this.plans.length; i++) {
      next.push(false)
    }
    this.checked = next
  }

  private toggle(idx: number) {
    const next: boolean[] = []
    for (let i = 0; i < this.checked.length; i++) {
      next.push(this.checked[i])
    }
    if (idx >= 0 && idx < next.length) {
      next[idx] = !next[idx]
    }
    this.checked = next
  }

  private buildPicked(): GeneratedPlanItem[] {
    const picked: GeneratedPlanItem[] = []
    for (let i = 0; i < this.plans.length; i++) {
      if (this.checked[i]) {
        picked.push(this.plans[i])
      }
    }
    return picked
  }

  build() {
    Column({ space: 12 }) {
      Text('选择要添加的计划')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)

      if (this.plans.length === 0) {
        Text('没有解析到可用计划')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.Gray)
      } else {
        List({ space: 10 }) {
          ForEach(this.plans, (p: GeneratedPlanItem, idx: number) => {
            ListItem() {
              Row({ space: 10 }) {
                Checkbox({ name: idx.toString(), group: 'planPick' })
                  .select(this.checked[idx])
                  .onChange(() => {
                    this.toggle(idx)
                  })

                Column({ space: 4 }) {
                  Text(p.title)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#111827')
                    .maxLines(1)
                  Text(`${p.minutes} 分钟`)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#6B7280')
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
            }
          }, (p: GeneratedPlanItem) => p.title + '_' + p.minutes.toString())
        }
        .width('100%')
        .height(260)
      }

      Row({ space: 12 }) {
        Button('取消')
          .backgroundColor('#FFF1F0')
          .fontColor('#f6726e')
          .layoutWeight(1)
          .height(42)
          .borderRadius(12)
          .onClick(() => {
            this.controllerTwo?.close()
          })

        Button('添加')
          .backgroundColor('#f6726e')
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(42)
          .borderRadius(12)
          .onClick(async () => {
            const picked = this.buildPicked()
            await this.onConfirm?.(picked)
            this.controllerTwo?.close()
          })
      }
      .width('100%')
    }
    .padding(18)
    .width('88%')
    .borderRadius(14)
    .backgroundColor('#fff')
  }
}

@Component
export struct AIChat {
  @State isCanDoPlan: boolean = false
  @State isButton: boolean = false
  @State inputText: string = ''
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('PlanChangedAt') planChangedAt: number = 0
  @State message: string = ''
  @State isOver: boolean = false
  @State horizontalPadding: number = 20
  @State bubbleWidth: string = '75%'
  @State private generatedPlans: GeneratedPlanItem[] = []
  @State chat: AIChatDBInfo[] = [
    {
      id: null,
      spokesperson: 'AI',
      content: '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。',
      date_added: Date.now()
    }
  ]
  private chatScroller: Scroller = new Scroller()
  private planPickDialog: CustomDialogController | null = null
  private planGeneratingDialog: CustomDialogController | null = null

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

  private findLastAiText(): string {
    for (let i = this.chat.length - 1; i >= 0; i--) {
      const it = this.chat[i]
      if (it.spokesperson === 'AI' && it.content && it.content.length > 0) {
        return it.content
      }
    }
    return ''
  }

  private extractPlanJsonArray(raw: string): string {
    // 尝试截取 JSON 数组：从第一个 '[' 到最后一个 ']'
    const start = raw.indexOf('[')
    const end = raw.lastIndexOf(']')
    if (start >= 0 && end > start) {
      return raw.substring(start, end + 1)
    }
    return ''
  }

  private parsePlans(raw: string): GeneratedPlanItem[] {
    const json = this.extractPlanJsonArray(raw)
    if (!json) {
      return []
    }
    try {
      const arr = JSON.parse(json) as PlanJsonItem[]
      const res: GeneratedPlanItem[] = []
      for (let i = 0; i < arr.length; i++) {
        const item = arr[i]
        const title = item?.title
        const minutes = item?.minutes
        if (typeof title === 'string' && typeof minutes === 'number' && title.length > 0 && minutes > 0) {
          res.push({ title, minutes })
        }
      }
      return res
    } catch (e) {
      return []
    }
  }

  private openPlanPickDialog(plans: GeneratedPlanItem[]) {
    this.planPickDialog = new CustomDialogController({
      builder: PlanPickDialog({
        plans: plans,
        onConfirm: async (picked: GeneratedPlanItem[]) => {
          if (picked.length === 0) {
            promptAction.showToast({ message: '请先勾选计划' })
            return
          }
          for (let i = 0; i < picked.length; i++) {
            const p = picked[i]
            await toDoPlanDB.insert({
              id: null,
              title: p.title,
              event: '番茄钟',
              time: null,
              timess: null,
              timesss: null,
              type: '倒计时',
              times: p.minutes,
              date_added: Date.now(),
              sort_order: null
            })
          }
          // 触发首页实时刷新
          this.planChangedAt = Date.now()
          promptAction.showToast({ message: '已添加到首页' })
        }
      }),
      cancel: () => {
      },
      cornerRadius: 14,
      width: '88%',
      customStyle: true
    })
    this.planPickDialog.open()
  }

  private openGeneratingDialog() {
    if (this.planGeneratingDialog != null) {
      // 旧的先关掉，避免重复弹
      try {
        this.planGeneratingDialog.close()
      } catch (e) {
      }
    }
    this.planGeneratingDialog = new CustomDialogController({
      builder: PlanGeneratingDialog({}),
      cancel: () => {
      },
      customStyle: true,
      autoCancel: false
    })
    this.planGeneratingDialog.open()
  }

  private closeGeneratingDialog() {
    try {
      this.planGeneratingDialog?.close()
    } catch (e) {
    }
    this.planGeneratingDialog = null
  }

  private async generatePlansFromLastAiText(): Promise<void> {
    const lastAi = this.findLastAiText()
    if (lastAi == '' ||
      lastAi ==
        '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。' ||
      lastAi == '服务器连接错误，请重试') {
      promptAction.showToast({ message: '没有可用的 AI 内容' })
      this.isCanDoPlan = false
      this.closeGeneratingDialog()
      return
    }

    const prompt = [
      '请你阅读下面这段文字里的计划内容，并总结成可执行的计划列表。',
      '要求：只输出 JSON，不要输出任何多余文字。',
      'JSON 格式必须为数组：[{ "title": "最多四个字", "minutes": 25 }...]',
      'minutes 必须是正整数（分钟）。',
      '如果无法提取计划，请返回空数组 []。',
      '',
      '原文：',
      lastAi
    ].join('\n')

    let collected: string = ''
    await i(prompt,
      (chunk) => {
        collected += chunk
      },
      async (_isOver) => {
        const plans = this.parsePlans(collected)
        this.generatedPlans = plans
        this.closeGeneratingDialog()
        this.openPlanPickDialog(plans)
      },
      async () => {
        this.closeGeneratingDialog()
        promptAction.showToast({ message: '服务器连接错误，请重试' })
      }
    )
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
          Button('一键生成计划', { buttonStyle: ButtonStyleMode.TEXTUAL })
            .fontColor('#f6726e')
            .onClick(async () => {
              this.openGeneratingDialog()
              await this.generatePlansFromLastAiText()
              this.isCanDoPlan = false
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