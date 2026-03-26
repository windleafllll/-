import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
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

      PersistentStorage.persistProp('id', 0)

      PersistentStorage.persistProp('isCloud', false)

      PersistentStorage.persistProp('isVIP', false)

      PersistentStorage.persistProp('accessToken', '')

      PersistentStorage.persistProp('PlanID', 0)

      PersistentStorage.persistProp('ChooseGroup', '')

      // 日历提醒映射：用于修改/删除计划时能删除旧日历事件
      // 使用持久化存储，避免应用重启后无法清理历史提醒
      PersistentStorage.persistProp('HabitCalendarMap', '[]')
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