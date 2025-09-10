import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConfigManager } from '../services/AppConfigManager';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 从首选项中加载token到AppStorage
    this.loadTokenFromPreferences();

    // 初始化配置信息
    this.initializeConfig();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/OpenPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  /**
   * 初始化应用配置 (参照class-schedule-c的getKxTime逻辑)
   */
  private async initializeConfig(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '🔄 [EntryAbility] 开始初始化应用配置...');

      // 使用AppConfigManager统一管理配置初始化
      await this.appConfigManager.initialize();

      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 应用配置初始化完成');

    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 应用配置初始化失败: %{public}s', JSON.stringify(error));
      // 不阻塞应用启动，仅记录错误
    }
  }

  /**
   * 从首选项中加载token到AppStorage
   */
  private loadTokenFromPreferences(): void {
    try {
      hilog.info(DOMAIN, 'testTag', '🔄 [EntryAbility] 开始加载token...');
      
      const preferencesUtil = PreferencesUtil.getInstance();
      const savedToken = preferencesUtil.getValue(this.context, 'token', '');
      
      if (savedToken && typeof savedToken === 'string' && savedToken.trim() !== '') {
        // 将token存储到AppStorage中
        AppStorage.setOrCreate('token', savedToken);
        hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] Token加载成功');
      } else {
        hilog.info(DOMAIN, 'testTag', '📝 [EntryAbility] 未找到有效的token');
        // 确保AppStorage中没有旧的token
        AppStorage.setOrCreate('token', '');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] Token加载失败: %{public}s', JSON.stringify(error));
      // 发生错误时确保AppStorage中没有旧的token
      AppStorage.setOrCreate('token', '');
    }
  }
}