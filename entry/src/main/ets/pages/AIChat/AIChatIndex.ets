// import { router } from '@kit.ArkUI'
// import { i } from '../../api/AIChatAPI';
// import { aiChatDB, AIChatDBInfo } from '../../database/AIChatDB';
// import inputMethod from '@ohos.inputMethod';
//
// @Entry
// @Component
// struct AIChatIndex {
//   @State isSideBarShow: boolean = false
//   @State currentIndex: number = 0
//   @State isButton: boolean = false
//   @State inputText: string = ''
//   @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
//   @State message: string = ''
//   @State isOver: boolean = false
//   @State chat: AIChatDBInfo[] = [
//     {
//       id: null,
//       spokesperson: 'AI',
//       content: '您好!很高兴与您交流。我是您的定制计划助手，请问有什么我可以帮助您的吗?比如制定一个健康计划、学习计划、财务计划或者旅行计划?请告诉我您的具体需求。',
//       date_added: Date.now()
//     }
//   ]
//
//   async aboutToAppear() {
//     const a: AIChatDBInfo[] = await aiChatDB.query()
//     if (a.length > 0) {
//       this.chat = a
//     } else {
//       aiChatDB.insert(this.chat[0])
//     }
//
//   }
//
//   @Builder
//   NavigationTitle() {
//     Row() {
//       Image($r('app.media.ic_ai_right'))
//         .width(20)
//         .onClick(() => {
//           this.isSideBarShow = !this.isSideBarShow
//         })
//       Text('计划铺子')
//         .fontSize(18)
//         .fontWeight(FontWeight.Bold)
//       Image($r('app.media.ai_add'))
//         .width(20)
//         .onClick(() => {
//           aiChatDB.delete()
//           this.chat = []
//         })
//     }
//     .width('100%')
//     .justifyContent(FlexAlign.SpaceBetween)
//     .padding(10)
//   }
//
//   build() {
//     SideBarContainer(SideBarContainerType.Overlay) {
//       // 侧边栏内容 - 菜单选项
//       this.SideBarContent()
//       // 主内容区 - 当前选中的内容
//       this.MainContent()
//     }
//     .showControlButton(false)
//     .showSideBar(this.isSideBarShow)
//     .sideBarWidth(280)
//     .minSideBarWidth(280)
//     .maxSideBarWidth(280)
//     .onChange((isShow: boolean) => {
//       this.isSideBarShow = isShow
//     })
//   }
//
//   // 侧边栏内容构建器
//   @Builder
//   SideBarContent() {
//     Column() {
//       Text('历史记录')
//       Column() {
//         this.MenuItem(0, $r('app.media.ic_ai_aihead'), '首页')
//
//         // 消息
//         this.MenuItem(1, $r('app.media.ic_ai_aihead'), '消息')
//
//         // 收藏
//         this.MenuItem(2, $r('app.media.ic_ai_aihead'), '收藏')
//
//         // 设置
//         this.MenuItem(3, $r('app.media.ic_ai_aihead'), '设置')
//
//         // 关于
//         this.MenuItem(4, $r('app.media.ic_ai_aihead'), '关于')
//       }
//       .margin({ top: 50 })
//
//     }
//     .width('100%')
//     .height('100%')
//     .backgroundColor('#FFFFFF')
//   }
//
//   @Builder
//   MainContent() {
//     Navigation() {
//       Scroll() {
//         List({ space: 30 }) {
//           ForEach(this.chat, (v: AIChatDBInfo) => {
//             if (v.spokesperson == 'AI') {
//               ListItem() {
//                 Row({ space: 10 }) {
//                   Image($r('app.media.ic_ai_aihead'))
//                     .width('10%')
//                   if (v.content == '') {
//                     LoadingProgress()
//                       .color(Color.Orange)
//                       .width(40)
//                   } else {
//                     Text(v.content)
//                       .width('75%')
//                       .padding(10)
//                       .borderRadius(20)
//                       .backgroundColor(Color.White)
//                   }
//                   Blank()
//
//                 }
//                 .alignItems(VerticalAlign.Top)
//                 .justifyContent(FlexAlign.SpaceBetween)
//                 .width('100%')
//               }
//             } else if (v.spokesperson == 'user') {
//               ListItem() {
//                 Row({ space: 10 }) {
//                   Text(v.content)
//                     .padding(10)
//                     .borderRadius(20)
//                     .backgroundColor(Color.White)
//                   Image($r(this.userHead))
//                     .width('10%')
//                 }
//                 .alignItems(VerticalAlign.Top)
//                 .justifyContent(FlexAlign.End)
//                 .width('100%')
//               }
//             }
//           })
//         }
//         .height('100%')
//         .padding(20)
//         .width('100%')
//       }
//       .width('100%')
//       .height('90%')
//
//       Row() {
//         TextInput({ text: $$this.inputText })
//           .width('75%')
//           .onChange((inputText: String) => {
//             if (inputText == '') {
//               this.isButton = false
//             } else {
//               this.isButton = true
//             }
//           })
//         Button('发送')
//           .onClick(async () => {
//             let inputMethodController = inputMethod.getController();
//             inputMethodController.stopInputSession();
//             this.isOver = false
//             this.message = ''
//             await aiChatDB.insert({
//               id: null,
//               spokesperson: 'user',
//               content: this.inputText,
//               date_added: Date.now()
//             })
//             this.chat.push({
//               id: null,
//               spokesperson: 'user',
//               content: this.inputText,
//               date_added: Date.now()
//             })
//             this.chat.push({
//               id: null,
//               spokesperson: 'AI',
//               content: '',
//               date_added: Date.now()
//             })
//             await i(this.inputText, (chunk) => {
//               this.message += chunk
//               this.chat[this.chat.length - 1] = {
//                 id: null,
//                 spokesperson: 'AI',
//                 content: this.message,
//                 date_added: Date.now()
//               }
//               // 实时更新消息
//             }, (isOver) => {
//               this.isOver = isOver
//               aiChatDB.insert({
//                 id: null,
//                 spokesperson: 'AI',
//                 content: this.message,
//                 date_added: Date.now()
//               })
//             }, async () => {
//               this.chat[this.chat.length - 1] = {
//                 id: null,
//                 spokesperson: 'AI',
//                 content: '服务器连接错误，请重试',
//                 date_added: Date.now()
//               }
//             })
//             this.inputText = ''
//           })
//           .enabled(this.isButton)
//       }
//       .justifyContent(FlexAlign.SpaceBetween)
//       .width('100%')
//       .padding(20)
//     }
//     .backgroundColor('#fff1f1f1')
//     .titleMode(NavigationTitleMode.Mini)
//     .title(this.NavigationTitle())
//     .mode(NavigationMode.Stack)
//     .hideBackButton(true)
//   }
//
//   // 菜单项构建器
//   @Builder
//   MenuItem(index: number, icon: Resource, title: string) {
//     Row() {
//       Image(icon)
//         .width(24)
//         .height(24)
//         .margin({ right: 16 })
//
//       Text(title)
//         .fontSize(16)
//         .fontColor(this.currentIndex === index ? '#FF4081' : '#333333')
//     }
//     .width('100%')
//     .padding({
//       left: 24,
//       right: 24,
//       top: 16,
//       bottom: 16
//     })
//     .backgroundColor(this.currentIndex === index ? '#F5F5F5' : '#FFFFFF')
//     .borderRadius(8)
//     .onClick(() => {
//       this.currentIndex = index
//       this.isSideBarShow = false
//     })
//   }
// }