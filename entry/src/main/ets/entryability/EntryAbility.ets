import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtLoginService } from '../services/jwxt/JwxtLoginService';
import { JwxtHttpClient } from '../services/jwxt/JwxtHttpClient';
import { JwxtGetInfoService } from '../services/jwxt/JwxtGetInfoService';
import { StudentInfoManager } from '../services/StudentInfoManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private studentInfoManager: StudentInfoManager = StudentInfoManager.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 1. 从首选项加载学生信息到内存（如果有缓存）
    this.loadStudentInfoFromCache();

    // 2. 初始化配置信息（不阻塞）
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
      await this.appConfigManager.initialize(this.context);

      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 应用配置初始化完成');

    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 应用配置初始化失败: %{public}s', JSON.stringify(error));
      // 不阻塞应用启动，仅记录错误
    }
  }

  /**
   * 从首选项加载学生信息到内存（AppStorage）
   * 应用启动时优先使用缓存
   */
  private async loadStudentInfoFromCache(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '📂 [EntryAbility] 开始加载学生信息缓存...');

      const loaded = await this.studentInfoManager.loadStudentInfoToMemory(this.context);

      if (loaded) {
        hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 学生信息缓存加载成功');
      } else {
        hilog.info(DOMAIN, 'testTag', '📭 [EntryAbility] 无学生信息缓存');
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'testTag', `❌ [EntryAbility] 加载学生信息缓存失败: ${errorMsg}`);
      // 不阻塞应用启动
    }
  }
}