import axios, { AxiosResponse } from '@ohos/axios';
import { accountDB } from '../../database/AccountDB';
import { promptAction } from '@kit.ArkUI';

interface a {
  phone: string,
  passwd: string
}

interface b {
  code: number;
  msg?: string;
  resTime?: Date;
  result?: 登录Vo;
  tips?: string;
}

/**
 * 登录VO
 */
interface 登录Vo {
  accessToken?: string;
  avatar?: string;
  nickname?: string;
  renewalToken?: string;
}


@Entry
@Component
struct TestPage {
  @StorageLink('id') user_id: number = 0

  build() {
    Navigation() {
      Button()
        .onClick(async () => {
          const res =
            await axios.post<null, AxiosResponse<b, null>, a>('https://guardian-api.itheima.net/user/login/passwd',
              { phone: '120666666666', passwd: '888itcast.CN764%...' })
          AlertDialog.show({ message: JSON.stringify(res, null, 2) })
        })
      Button()
        .onClick(async () => {
          // const res = await AIChat({ sentence: '你好' })
          // AlertDialog.show({ message: res.data.data })
        })
      Button('000000000')
        .onClick(async () => {
          try {
            await accountDB.update({
              id: this.user_id,
              account: 1,
              password: '1',
              user_head: 'app.media.ic_user_head_1',
              user_name: 'root',
              date_added: Date.now(),
              last_login_time: Date.now(),
              issue_type: '111',
              issue_answer: '111'
            })
            // const a = await accountDB.query()
            promptAction.showToast({
              message: '成功'
            })
          } catch (error) {
            promptAction.showToast({
              message: '失败' + error
            })
          }
        })
    }
    .title('测试')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}