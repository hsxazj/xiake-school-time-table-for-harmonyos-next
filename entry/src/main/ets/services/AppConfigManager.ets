import { ConfigApiService, CurrentSemesterStatus } from './api/ConfigApiService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

const DOMAIN = 0x1000; // App Config domain
const TREE_HOLE_ENABLED_KEY = 'tree_hole_enabled'; // 树洞功能启用状态存储键

/**
 * 应用配置管理器 - 统一管理全局配置状态
 * 参照class-schedule-c的初始化流程
 */
export class AppConfigManager {
  private static instance: AppConfigManager;
  private configService: ConfigApiService;
  private isInitialized: boolean = false;
  private initPromise: Promise<void> | null = null;
  private preferencesUtil: PreferencesUtil;
  private treeHoleEnabled: boolean = true; // 树洞功能默认启用

  private constructor() {
    this.configService = ConfigApiService.getInstance();
    this.preferencesUtil = PreferencesUtil.getInstance();
  }

  public static getInstance(): AppConfigManager {
    if (!AppConfigManager.instance) {
      AppConfigManager.instance = new AppConfigManager();
    }
    return AppConfigManager.instance;
  }

  /**
   * 初始化应用配置 (参照class-schedule-c的getKxTime逻辑)
   * 确保只初始化一次，支持多处调用
   */
  public async initialize(context?: Context): Promise<void> {
    if (this.isInitialized) {
      return Promise.resolve();
    }

    if (this.initPromise) {
      return this.initPromise;
    }

    this.initPromise = this.performInitialization(context);
    return this.initPromise;
  }

  /**
   * 获取当前学期状态
   */
  public getCurrentStatus(): CurrentSemesterStatus | null {
    if (!this.isInitialized) {
      hilog.warn(DOMAIN, 'AppConfig', '⚠️ [AppConfigManager] 配置未初始化');
      return null;
    }
    return this.configService.getCurrentStatus();
  }

  /**
   * 强制重新初始化配置
   */
  public async reinitialize(context?: Context): Promise<void> {
    hilog.info(DOMAIN, 'AppConfig', '🔄 [AppConfigManager] 强制重新初始化...');
    this.isInitialized = false;
    this.initPromise = null;
    return this.initialize(context);
  }

  /**
   * 检查是否已初始化
   */
  public isConfigInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 获取ConfigApiService实例 (向后兼容)
   */
  public getConfigService(): ConfigApiService {
    return this.configService;
  }

  /**
   * 等待初始化完成后执行回调
   */
  public async whenReady<T>(callback: () => T | Promise<T>, context?: Context): Promise<T> {
    await this.initialize(context);
    return callback();
  }

  /**
   * 获取树洞功能启用状态
   */
  public getTreeHoleEnabled(): boolean {
    return this.treeHoleEnabled;
  }

  /**
   * 设置树洞功能启用状态
   */
  public setTreeHoleEnabled(enabled: boolean, context: Context): void {
    this.treeHoleEnabled = enabled;
    // 保存到首选项
    this.preferencesUtil.putValue(context, TREE_HOLE_ENABLED_KEY, enabled);
    hilog.info(DOMAIN, 'AppConfig', `🎛️ [AppConfigManager] 树洞功能状态已更新: ${enabled}`);
  }

  /**
   * 从首选项加载树洞功能设置
   */
  private loadTreeHoleSettings(context: Context): void {
    try {
      // 从首选项获取树洞功能状态，默认为true（启用）
      const enabled = this.preferencesUtil.getValue(context, TREE_HOLE_ENABLED_KEY, true) as boolean;
      this.treeHoleEnabled = enabled;
      hilog.info(DOMAIN, 'AppConfig', `📱 [AppConfigManager] 加载树洞功能状态: ${enabled}`);
    } catch (error) {
      hilog.error(DOMAIN, 'AppConfig', `❌ [AppConfigManager] 加载树洞功能设置失败: ${JSON.stringify(error)}`);
      this.treeHoleEnabled = true; // 失败时使用默认值
    }
  }

  private async performInitialization(context?: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, 'AppConfig', '🔄 [AppConfigManager] 开始初始化应用配置...');

      // Step 0: 加载树洞功能设置（如果有context）
      if (context) {
        this.loadTreeHoleSettings(context);
      }

      // Step 1: 获取配置数据 (对应class-schedule-c的api.getKxTime())
      const configResponse = await this.configService.getConfig();
      hilog.info(DOMAIN, 'AppConfig', '✅ [AppConfigManager] Config数据获取成功');

      // Step 2: 计算当前学期状态 (对应class-schedule-c的getWeek逻辑)
      const currentStatus = this.configService.calculateCurrentSemesterStatus();
      hilog.info(DOMAIN, 'AppConfig', `✅ [AppConfigManager] 当前状态: ${currentStatus.statusText}`);

      // Step 3: 输出学期信息供调试
      const semesterList = this.configService.getSemesterList();
      hilog.info(DOMAIN, 'AppConfig', `📚 [AppConfigManager] 共处理${semesterList.length}个学期数据`);

      // Step 4: 打印今日日期 (参照class-schedule-c的getNowTime逻辑)
      const today = new Date();
      const year = today.getFullYear();
      const month = String(today.getMonth() + 1).padStart(2, '0');
      const day = String(today.getDate()).padStart(2, '0');
      const todayString = `${year}-${month}-${day}`;
      hilog.info(DOMAIN, 'AppConfig', `📅 [AppConfigManager] 今日日期: ${todayString}`);

      this.isInitialized = true;
      hilog.info(DOMAIN, 'AppConfig', '🎉 [AppConfigManager] 应用配置初始化完成');

    } catch (error) {
      hilog.error(DOMAIN, 'AppConfig', '❌ [AppConfigManager] 配置初始化失败: %{public}s', JSON.stringify(error));
      this.initPromise = null; // 允许重试
      throw new Error(`配置初始化失败: ${JSON.stringify(error)}`);
    }
  }
}