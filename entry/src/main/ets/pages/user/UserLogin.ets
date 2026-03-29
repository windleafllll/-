import { promptAction, router } from '@kit.ArkUI'
import { authentication } from '@kit.AccountKit'
import { util } from '@kit.ArkTS'
import { hilog } from '@kit.PerformanceAnalysisKit'

interface HuaweiAuthProfileLike {
  nickName?: string
  avatarUri?: string
  authorizationCode?: string
  authorization_code?: string
  code?: string
  idToken?: string
  openId?: string
  openID?: string
  unionId?: string
  unionID?: string
}

interface HuaweiAuthResponseLike {
  data?: HuaweiAuthProfileLike
}

interface HuaweiIdTokenPayloadLike extends HuaweiAuthProfileLike {
  sub?: string
  openid?: string
  unionid?: string
}

interface BizErrorLike {
  code?: number
  message?: string
}

@Entry
@Component
struct UserLogin {
  @State pagePadding: number = 24
  @State isSubmitting: boolean = false
  @StorageLink('isUserLogin') isLogin: string = '未登录'
  @StorageLink('UserHead') userHead: string = 'app.media.ic_user_head_1'
  @StorageLink('UserName') userName: string = 'root'
  @StorageLink('id') user_id: number = 0
  @StorageLink('WishWallOpenAfterLogin') wishWallOpenAfterLogin: boolean = false
  @StorageLink('HuaweiLoginInfo') huaweiLoginInfo: string = ''
  @StorageLink('CloudUserId') cloudUserId: string = ''

  private updateResponsiveLayout(width: number) {
    this.pagePadding = width >= 900 ? 80 : 24
  }

  private decodeBase64Url(input: string): string {
    let base64 = input.replace(/-/g, '+').replace(/_/g, '/')
    while (base64.length % 4 !== 0) {
      base64 = `${base64}=`
    }
    return globalThis.atob(base64)
  }

  private extractCloudUserIdFromIdToken(idToken: string): string {
    if (idToken.length == 0) {
      return ''
    }
    try {
      const parts = idToken.split('.')
      if (parts.length < 2) {
        return ''
      }
      const payloadText = this.decodeBase64Url(parts[1])
      const payload = JSON.parse(payloadText) as HuaweiIdTokenPayloadLike
      if ((payload.openid ?? '').length > 0) {
        return payload.openid as string
      }
      if ((payload.unionid ?? '').length > 0) {
        return payload.unionid as string
      }
      return payload.sub ?? ''
    } catch (_) {
      return ''
    }
  }

  private matchJsonStringField(raw: string, key: string): string {
    const pattern = new RegExp(`"${key}"\\s*:\\s*"([^"]+)"`)
    const m = raw.match(pattern)
    if (m != null && m.length > 1) {
      return m[1]
    }
    return ''
  }

  private extractByRawResponse(raw: string, keys: string[]): string {
    for (let i = 0; i < keys.length; i++) {
      const v = this.matchJsonStringField(raw, keys[i])
      if (v.length > 0) {
        return v
      }
    }
    return ''
  }

  private async fetchProfileAfterLogin(): Promise<HuaweiAuthProfileLike> {
    try {
      const provider = new authentication.HuaweiIDProvider()
      const req = provider.createAuthorizationWithHuaweiIDRequest()
      req.scopes = ['profile']
      req.forceAuthorization = false
      req.state = util.generateRandomUUID()
      const controller = new authentication.AuthenticationController()
      const resp = await controller.executeRequest(req) as authentication.AuthorizationWithHuaweiIDResponse
      const data = resp.data as HuaweiAuthProfileLike
      return data
    } catch (_) {
      return {}
    }
  }

  private async loginByHuaweiId(): Promise<void> {
    if (this.isSubmitting) {
      return
    }
    this.isSubmitting = true
    try {
      const provider = new authentication.HuaweiIDProvider()
      const loginRequest = provider.createLoginWithHuaweiIDRequest()
      loginRequest.forceLogin = true
      loginRequest.state = util.generateRandomUUID()

      const authController = new authentication.AuthenticationController()
      const authResponse = await authController.executeRequest(loginRequest) as authentication.LoginWithHuaweiIDResponse

      if (authResponse.state && authResponse.state !== loginRequest.state) {
        hilog.error(0x0000, 'UserLogin', 'state check failed')
        promptAction.showToast({ message: '登录状态校验失败，请重试' })
        return
      }

      const loginData = authResponse.data as HuaweiAuthProfileLike
      const rawResp = JSON.stringify(authResponse)
      const profileData = await this.fetchProfileAfterLogin()
      const nickName: string = profileData.nickName ?? loginData.nickName ?? '华为用户'
      const avatarUri: string = profileData.avatarUri ?? loginData.avatarUri ?? ''
      const authorizationCodeFromData: string =
        loginData.authorizationCode ?? loginData.authorization_code ?? loginData.code ?? ''
      const authorizationCode = authorizationCodeFromData.length > 0
        ? authorizationCodeFromData
        : this.extractByRawResponse(rawResp, ['authorizationCode', 'authorization_code', 'authCode', 'code'])
      const idTokenFromData: string = loginData.idToken ?? ''
      const idToken = idTokenFromData.length > 0
        ? idTokenFromData
        : this.extractByRawResponse(rawResp, ['idToken', 'id_token'])
      const openIdFromData: string = loginData.openId ?? loginData.openID ?? ''
      const unionIdFromData: string = loginData.unionId ?? loginData.unionID ?? ''
      const openId = openIdFromData.length > 0
        ? openIdFromData
        : this.extractByRawResponse(rawResp, ['openId', 'openid'])
      const unionId = unionIdFromData.length > 0
        ? unionIdFromData
        : this.extractByRawResponse(rawResp, ['unionId', 'unionid'])
      const cloudUserIdFromLocal = openId.length > 0
        ? openId
        : (unionId.length > 0 ? unionId : this.extractCloudUserIdFromIdToken(idToken))
      const cloudUserId = cloudUserIdFromLocal

      this.isLogin = '已登录'
      this.user_id = Date.now()
      this.userName = nickName
      this.cloudUserId = cloudUserId
      if (avatarUri.length > 0) {
        this.userHead = avatarUri
      } else {
        this.userHead = 'app.media.ic_user_head_1'
      }
      this.huaweiLoginInfo = JSON.stringify({
        nickName: nickName,
        avatarUri: avatarUri,
        authorizationCode: authorizationCode,
        idToken: idToken,
        openId: openId,
        unionId: unionId,
        cloudUserId: cloudUserId,
        hasAuthorizationCode: authorizationCode.length > 0 ? 'Y' : 'N',
        rawResponsePreview: rawResp.slice(0, 600),
        loginAt: Date.now()
      })

      promptAction.showToast({ message: '华为账号登录成功' })
      if (this.wishWallOpenAfterLogin) {
        router.pushUrl({ url: 'pages/user/tools/StudyRoom' }, router.RouterMode.Single)
      } else {
        router.back({ url: 'pages/Index' })
      }
    } catch (e) {
      const biz = e as BizErrorLike
      const code: number = biz.code ?? -1
      const message: string = biz.message ?? '未知错误'
      hilog.error(0x0000, 'UserLogin', `Huawei login failed code=${code}, msg=${message}`)
      promptAction.showToast({ message: `华为账号登录失败(${code})` })
    } finally {
      this.isSubmitting = false
    }
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Row() {
          Image($r('app.media.ic_user_Starfruit'))
            .width(56)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('25%')

        Text('使用华为账号登录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)

        Text('登录后可在多设备保持一致的账号身份')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)

        Button(this.isSubmitting ? '登录中...' : '使用华为账号登录')
          .width('100%')
          .height(44)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor($r('app.color.text_on_brand'))
          .enabled(!this.isSubmitting)
          .onClick(async () => {
            await this.loginByHuaweiId()
          })
      }
      .width('100%')
      .padding({
        left: this.pagePadding,
        right: this.pagePadding,
        top: 20,
        bottom: 20
      })
      .onAreaChange((_, value) => {
        this.updateResponsiveLayout(value.width as number)
      })
    }
    .backgroundColor($r('app.color.list_area_background'))
    .title('华为账号登录')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}