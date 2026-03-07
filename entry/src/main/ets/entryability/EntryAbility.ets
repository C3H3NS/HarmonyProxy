import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

const TAG = 'EntryAbility';
const DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground() {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
