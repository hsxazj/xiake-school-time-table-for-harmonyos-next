import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtLoginService } from '../services/jwxt/JwxtLoginService';
import { JwxtHttpClient } from '../services/jwxt/JwxtHttpClient';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private jwxtLoginService: JwxtLoginService = JwxtLoginService.getInstance();
  private jwxtHttpClient: JwxtHttpClient = JwxtHttpClient.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化配置信息
    this.initializeConfig();

    // 自动登录教务系统
    this.autoLoginJwxt();
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
      await this.appConfigManager.initialize(this.context);

      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 应用配置初始化完成');

    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 应用配置初始化失败: %{public}s', JSON.stringify(error));
      // 不阻塞应用启动，仅记录错误
    }
  }

  /**
   * 自动登录教务系统
   * 应用启动时自动执行，将Cookie保存到内存
   */
  private async autoLoginJwxt(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '🔐 [EntryAbility] 开始自动登录教务系统...');

      // 初始化HTTP客户端的Cookie管理
      await this.jwxtHttpClient.initialize(this.context);

      // 执行登录
      await this.jwxtLoginService.login(this.context);

      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 教务系统自动登录成功，Cookie已保存到内存');

    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 教务系统自动登录失败: %{public}s',
        error instanceof Error ? error.message : JSON.stringify(error));
      // 不阻塞应用启动，仅记录错误
    }
  }
}