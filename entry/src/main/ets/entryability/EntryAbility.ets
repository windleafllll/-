import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import agconnect from '@hw-agconnect/api-ohos';
import '@hw-agconnect/core-ohos';
import { cloudCommon } from '@kit.CloudFoundationKit';

interface BizErrorLike {
  code?: number
  message?: string
}

export default class EntryAbility extends UIAbility {
  private async requestReminderPermissionOnLaunch(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.PUBLISH_AGENT_REMINDER'])
    } catch (e) {
      const biz = e as BizErrorLike
      hilog.error(0x0000, 'testTag', `request reminder permission failed code=${biz.code ?? -1}, msg=${biz.message ?? 'unknown'}`)
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    try {
      agconnect.instance().init(this.context)
      hilog.info(0x0000, 'testTag', 'AGConnect init success')
    } catch (e) {
      const biz = e as BizErrorLike
      hilog.error(0x0000, 'testTag', `AGConnect init failed code=${biz.code ?? -1}, msg=${biz.message ?? 'unknown'}`)
    }
    try {
      cloudCommon.init({})
      hilog.info(0x0000, 'testTag', 'CloudFoundation init success')
    } catch (e) {
      const biz = e as BizErrorLike
      hilog.error(0x0000, 'testTag', `CloudFoundation init failed code=${biz.code ?? -1}, msg=${biz.message ?? 'unknown'}`)
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Splash', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');

      PersistentStorage.persistProp('isUserLogin', '未登录')

      PersistentStorage.persistProp('UserHead', 'app.media.ic_user_head_1')

      PersistentStorage.persistProp('UserName', 'root')

      PersistentStorage.persistProp('HuaweiLoginInfo', '')

      PersistentStorage.persistProp('CloudUserId', '')

      PersistentStorage.persistProp('id', 0)

      PersistentStorage.persistProp('isCloud', false)

      PersistentStorage.persistProp('isVIP', false)

      PersistentStorage.persistProp('accessToken', '')

      PersistentStorage.persistProp('PlanID', 0)

      PersistentStorage.persistProp('ChooseGroup', '')

      // 应用启动后主动请求代理提醒权限（首次打开会弹窗）
      this.requestReminderPermissionOnLaunch()
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}