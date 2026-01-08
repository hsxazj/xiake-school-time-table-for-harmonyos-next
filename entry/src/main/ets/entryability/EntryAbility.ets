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
  private jwxtLoginService: JwxtLoginService = JwxtLoginService.getInstance();
  private jwxtHttpClient: JwxtHttpClient = JwxtHttpClient.getInstance();
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  private studentInfoManager: StudentInfoManager = StudentInfoManager.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 1. 从首选项加载学生信息到内存（如果有缓存）
    this.loadStudentInfoFromCache();

    // 2. 初始化配置信息（不阻塞）
    this.initializeConfig();

    // 3. 自动登录教务系统（不阻塞）
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
   * 自动登录教务系统并获取学生信息
   * 应用启动时自动执行，将Cookie保存到内存，获取学生信息到首选项和AppStorage
   */
  private async autoLoginJwxt(): Promise<void> {
    try {
      // 设置登录状态为进行中
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'loading');
      hilog.info(DOMAIN, 'testTag', '🔐 [EntryAbility] 开始自动登录教务系统...');

      // 初始化HTTP客户端的Cookie管理
      await this.jwxtHttpClient.initialize(this.context);

      // 执行登录
      await this.jwxtLoginService.login(this.context);

      // 设置登录状态为成功
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'success');
      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 教务系统自动登录成功，Cookie已保存到内存');

      // ✅ 登录成功后，获取学生信息并保存
      try {
        hilog.info(DOMAIN, 'testTag', '📝 [EntryAbility] 开始获取学生信息...');
        const studentInfo = await this.jwxtGetInfoService.getInfo(this.context);
        hilog.info(DOMAIN, 'testTag', `✅ [EntryAbility] 学生信息获取成功: ${studentInfo.name} (${studentInfo.student_id})`);
      } catch (infoError) {
        // 获取学生信息失败不影响应用启动
        const errorMsg = infoError instanceof Error ? infoError.message : String(infoError);
        hilog.error(DOMAIN, 'testTag', `⚠️ [EntryAbility] 获取学生信息失败: ${errorMsg}`);
      }

    } catch (error) {
      // 设置登录状态为失败
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'failed');
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 教务系统自动登录失败: %{public}s',
        error instanceof Error ? error.message : JSON.stringify(error));
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