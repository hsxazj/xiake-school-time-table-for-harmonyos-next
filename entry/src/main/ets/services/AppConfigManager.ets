import { ConfigApiService, CurrentSemesterStatus } from './api/ConfigApiService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

const DOMAIN = 0x1000; // App Config domain
const TREE_HOLE_ENABLED_KEY = 'tree_hole_enabled'; // 树洞功能启用状态存储键

/**
 * 初始化结果接口
 */
export interface InitializeResult {
  usedCache: boolean;  // 是否使用了缓存数据
}

/**
 * 应用配置管理器 - 统一管理全局配置状态
 * 参照class-schedule-c的初始化流程
 */
export class AppConfigManager {
  private static instance: AppConfigManager;
  private configService: ConfigApiService;
  private isInitialized: boolean = false;
  private initPromise: Promise<InitializeResult> | null = null;
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
   * @returns InitializeResult 包含是否使用了缓存的信息
   */
  public async initialize(context?: Context): Promise<InitializeResult> {
    if (this.isInitialized) {
      const result: InitializeResult = { usedCache: false };
      return Promise.resolve(result);
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
  public async reinitialize(context?: Context): Promise<InitializeResult> {
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
   * 尝试从缓存快速初始化（不等待API请求）
   * 如果有缓存，使用缓存并在后台异步更新
   * 如果无缓存，返回 false 表示需要完整初始化
   *
   * @param context 应用上下文
   * @returns true表示缓存初始化成功，false表示需要完整初始化
   */
  public async tryInitializeFromCache(context?: Context): Promise<boolean> {
    // 如果已经初始化，直接返回成功
    if (this.isInitialized) {
      hilog.info(DOMAIN, 'AppConfig', '✅ [FastInit] 配置已初始化，直接使用');
      return true;
    }

    try {
      hilog.info(DOMAIN, 'AppConfig', '🚀 [FastInit] 尝试快速初始化（缓存优先）...');

      // Step 0: 加载树洞功能设置（如果有context）
      if (context) {
        this.loadTreeHoleSettings(context);
      }

      // Step 1: 尝试从缓存快速初始化
      const configResponse = await this.configService.getConfig();

      // 判断是否使用了缓存
      const usedCache = configResponse.msg === '缓存数据';

      if (!usedCache) {
        // 没有缓存，返回false表示需要完整初始化
        hilog.info(DOMAIN, 'AppConfig', '⚠️ [FastInit] 无缓存数据，需要完整初始化');
        return false;
      }

      // Step 2: 使用缓存计算当前学期状态
      const currentStatus = this.configService.calculateCurrentSemesterStatus();
      hilog.info(DOMAIN, 'AppConfig', `✅ [FastInit] 使用缓存初始化成功，当前状态: ${currentStatus.statusText}`);

      // Step 3: 标记为已初始化
      this.isInitialized = true;

      hilog.info(DOMAIN, 'AppConfig', '🎉 [FastInit] 快速初始化完成（使用缓存，后台自动更新中）');

      // Note: getConfig() 内部已经会自动在后台更新，这里不需要额外操作

      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'AppConfig', '❌ [FastInit] 快速初始化失败: %{public}s', JSON.stringify(error));
      return false;
    }
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

  private async performInitialization(context?: Context): Promise<InitializeResult> {
    try {
      hilog.info(DOMAIN, 'AppConfig', '🔄 [AppConfigManager] 开始初始化应用配置...');

      // Step 1: 获取配置数据
      const configResponse = await this.configService.getConfig();
      const usedCache = configResponse.msg === '缓存数据' || configResponse.msg === '离线数据';

      if (usedCache) {
        hilog.warn(DOMAIN, 'AppConfig', '⚠️ [AppConfigManager] 使用了缓存配置数据');
      } else {
        hilog.info(DOMAIN, 'AppConfig', '✅ [AppConfigManager] Config数据获取成功');
      }

      // Step 2: 计算当前学期状态
      const currentStatus = this.configService.calculateCurrentSemesterStatus();
      hilog.info(DOMAIN, 'AppConfig', `✅ [AppConfigManager] 当前状态: ${currentStatus.statusText}`);

      // Step 3: 输出学期信息供调试
      const semesterList = this.configService.getSemesterList();
      hilog.info(DOMAIN, 'AppConfig', `📚 [AppConfigManager] 共处理${semesterList.length}个学期数据`);

      // Step 4: 打印今日日期
      const today = new Date();
      const year = today.getFullYear();
      const month = String(today.getMonth() + 1).padStart(2, '0');
      const day = String(today.getDate()).padStart(2, '0');
      const todayString = `${year}-${month}-${day}`;
      hilog.info(DOMAIN, 'AppConfig', `📅 [AppConfigManager] 今日日期: ${todayString}`);

      this.isInitialized = true;
      hilog.info(DOMAIN, 'AppConfig', '🎉 [AppConfigManager] 应用配置初始化完成');

      return { usedCache };
    } catch (error) {
      hilog.error(DOMAIN, 'AppConfig', '❌ [AppConfigManager] 配置初始化失败: %{public}s', JSON.stringify(error));
      this.initPromise = null; // 允许重试
      throw new Error(`配置初始化失败: ${JSON.stringify(error)}`);
    }
  }
}