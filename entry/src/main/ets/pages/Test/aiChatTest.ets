import { i } from '../../api/AIChatAPI'
import { http } from '@kit.NetworkKit'

@Entry
@Component
struct AiChatTest {
  @StorageLink('accessToken') accessToken: string | undefined = ''
  @State message: string = 'AI:'

  build() {
    Navigation() {
      Button()
        .onClick(async () => {
        })
      Text('密钥是：' + this.accessToken)

      Button('ai对话测试')
      // .onClick(() => {
      //   i('你好', (chunk) => {
      //     this.message += chunk; // 实时更新消息
      //   })
      // })

      Text(this.message)
    }
    .title('ai测试')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}