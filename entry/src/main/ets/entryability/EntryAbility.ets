import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConfigManager } from '../services/AppConfigManager';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { UserInfoManager } from '../common/utils/UserInfoManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 验证token和用户信息
    this.verifyTokenAndUserInfo();

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
   * 验证token和用户信息
   * 如果token存在，尝试获取用户信息验证token有效性
   * 如果返回403错误，则清除token和用户信息
   */
  private async verifyTokenAndUserInfo(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '🔄 [EntryAbility] 开始验证token和用户信息...');

      // 首先加载token到AppStorage
      this.loadTokenFromPreferences();

      // 检查是否存在token
      const token = this.userInfoManager.getToken(this.context);
      if (!token) {
        hilog.info(DOMAIN, 'testTag', '📝 [EntryAbility] 未找到token，跳过验证');
        return;
      }

      hilog.info(DOMAIN, 'testTag', '🔍 [EntryAbility] 发现token，开始验证有效性...');

      // 尝试验证token
      try {
        const isValid = await this.userInfoManager.checkLoginStatus(this.context);
        if (isValid) {
          hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] Token验证成功，用户信息已更新');
        } else {
          hilog.warn(DOMAIN, 'testTag', '⚠️ [EntryAbility] Token验证失败，已清除登录信息');
        }
      } catch (error) {
        hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] Token验证过程中发生错误: %{public}s', JSON.stringify(error));

        // 检查是否为403错误
        if (error instanceof Error) {
          const errorMsg = error.message;
          if (errorMsg.includes('403') || errorMsg.includes('unauthorized') || errorMsg.includes('Unauthorized')) {
            hilog.warn(DOMAIN, 'testTag', '🔒 [EntryAbility] 检测到403错误，清除token和用户信息');
            this.userInfoManager.clearLoginInfo(this.context);
            AppStorage.setOrCreate('token', '');
          }
        } else {
          const errorStr = JSON.stringify(error);
          if (errorStr.includes('403') || errorStr.includes('unauthorized') || errorStr.includes('Unauthorized')) {
            hilog.warn(DOMAIN, 'testTag', '🔒 [EntryAbility] 检测到403错误，清除token和用户信息');
            this.userInfoManager.clearLoginInfo(this.context);
            AppStorage.setOrCreate('token', '');
          }
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] token验证失败: %{public}s', JSON.stringify(error));
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