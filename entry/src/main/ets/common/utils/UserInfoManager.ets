import { PreferencesUtil } from './PreferencesUtil';
import { UserApiService } from '../../services/api/UserApiService';
import { GetUserInfoResponse, SimpleUserInfo } from '../../models/UserModels';

// 用户学籍信息接口
export interface UserSchoolInfo {
  collegeId: string;
  collegeName: string;
  majorId: string;
  majorName: string;
  classId: string;
  className: string;
}

// 用户学籍信息管理类
export class UserInfoManager {
  private static instance: UserInfoManager;
  // 存储键常量
  private static readonly COLLEGE_ID_KEY = 'userCollegeId';
  private static readonly COLLEGE_NAME_KEY = 'userCollegeName';
  private static readonly MAJOR_ID_KEY = 'userMajorId';
  private static readonly MAJOR_NAME_KEY = 'userMajorName';
  private static readonly CLASS_ID_KEY = 'userClassId';
  private static readonly CLASS_NAME_KEY = 'userClassName';
  // 新增的用户登录相关存储键
  private static readonly TOKEN_KEY = 'token';
  private static readonly CURRENT_USER_KEY = 'currentUserInfo';
  private static readonly LOGIN_TIME_KEY = 'loginTime';
  private userApiService: UserApiService | null = null;

  private constructor() {
    // 无需存储PreferencesUtil实例，直接使用单例
  }

  public static getInstance(): UserInfoManager {
    if (!UserInfoManager.instance) {
      UserInfoManager.instance = new UserInfoManager();
    }
    return UserInfoManager.instance;
  }

  /**
   * 保存学院信息
   */
  public saveCollegeInfo(context: Context, collegeId: string, collegeName: string): void {
    const util = PreferencesUtil.getInstance();
    console.info(`📚 [UserInfo] 保存学院信息开始: ${collegeId} - ${collegeName}`);
    util.putValue(context, UserInfoManager.COLLEGE_ID_KEY, collegeId);
    util.putValue(context, UserInfoManager.COLLEGE_NAME_KEY, collegeName);
    console.info(`📚 [UserInfo] 保存学院信息完成: ${collegeId} - ${collegeName}`);
  }

  /**
   * 保存专业信息
   */
  public saveMajorInfo(context: Context, majorId: string, majorName: string): void {
    const util = PreferencesUtil.getInstance();
    console.info(`📚 [UserInfo] 保存专业信息开始: ${majorId} - ${majorName}`);
    util.putValue(context, UserInfoManager.MAJOR_ID_KEY, majorId);
    util.putValue(context, UserInfoManager.MAJOR_NAME_KEY, majorName);
    console.info(`📚 [UserInfo] 保存专业信息完成: ${majorId} - ${majorName}`);
  }

  /**
   * 保存班级信息
   */
  public saveClassInfo(context: Context, classId: string, className: string): void {
    const util = PreferencesUtil.getInstance();
    console.info(`📚 [UserInfo] 保存班级信息开始: ${classId} - ${className}`);
    util.putValue(context, UserInfoManager.CLASS_ID_KEY, classId);
    util.putValue(context, UserInfoManager.CLASS_NAME_KEY, className);
    console.info(`📚 [UserInfo] 保存班级信息完成: ${classId} - ${className}`);
  }

  /**
   * 批量保存完整的用户学籍信息（原子操作）
   */
  public saveCompleteUserInfo(context: Context | undefined, userInfo: UserSchoolInfo): void {
    const util = PreferencesUtil.getInstance();
    console.info(`📚 [UserInfo] 开始批量保存用户信息...`);

    try {
      // 获取同一个preferences实例，确保在同一个事务中操作
      const preferences = util.getPreferences(context);

      // 批量设置所有值
      preferences.putSync(UserInfoManager.COLLEGE_ID_KEY, userInfo.collegeId);
      preferences.putSync(UserInfoManager.COLLEGE_NAME_KEY, userInfo.collegeName);
      preferences.putSync(UserInfoManager.MAJOR_ID_KEY, userInfo.majorId);
      preferences.putSync(UserInfoManager.MAJOR_NAME_KEY, userInfo.majorName);
      preferences.putSync(UserInfoManager.CLASS_ID_KEY, userInfo.classId);
      preferences.putSync(UserInfoManager.CLASS_NAME_KEY, userInfo.className);

      // 一次性同步刷新所有数据
      preferences.flushSync();

      console.info(`📚 [UserInfo] 批量保存完成`);
      console.info(`📚 [UserInfo] 学院: ${userInfo.collegeId} - ${userInfo.collegeName}`);
      console.info(`📚 [UserInfo] 专业: ${userInfo.majorId} - ${userInfo.majorName}`);
      console.info(`📚 [UserInfo] 班级: ${userInfo.classId} - ${userInfo.className}`);
    } catch (error) {
      console.error(`📚 [UserInfo] 批量保存失败: ${error}`);
      // ArkTS不支持抛出任意类型，改为抛出Error对象
      throw new Error(`批量保存用户信息失败: ${error}`);
    }
  }

  /**
   * 获取学院ID
   */
  public getCollegeId(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.COLLEGE_ID_KEY, '') as string;
  }

  /**
   * 获取学院名称
   */
  public getCollegeName(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.COLLEGE_NAME_KEY, '') as string;
  }

  /**
   * 获取专业ID
   */
  public getMajorId(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.MAJOR_ID_KEY, '') as string;
  }

  /**
   * 获取专业名称
   */
  public getMajorName(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.MAJOR_NAME_KEY, '') as string;
  }

  /**
   * 获取班级ID
   */
  public getClassId(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.CLASS_ID_KEY, '') as string;
  }

  /**
   * 获取班级名称
   */
  public getClassName(context: Context | undefined): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.CLASS_NAME_KEY, '') as string;
  }

  /**
   * 检查是否已设置完整的学籍信息
   */
  public hasCompleteUserInfo(context: Context | undefined): boolean {
    const collegeId = this.getCollegeId(context);
    const majorId = this.getMajorId(context);
    const classId = this.getClassId(context);

    return !!(collegeId && majorId && classId);
  }

  /**
   * 获取完整的用户学籍信息
   */
  public getUserInfo(context: Context | undefined): UserSchoolInfo {
    const result: UserSchoolInfo = {
      collegeId: this.getCollegeId(context),
      collegeName: this.getCollegeName(context),
      majorId: this.getMajorId(context),
      majorName: this.getMajorName(context),
      classId: this.getClassId(context),
      className: this.getClassName(context)
    };
    return result;
  }

  /**
   * 清除所有用户信息
   */
  public clearUserInfo(context: Context | undefined): void {
    const util = PreferencesUtil.getInstance();
    util.removeValue(context, UserInfoManager.COLLEGE_ID_KEY);
    util.removeValue(context, UserInfoManager.COLLEGE_NAME_KEY);
    util.removeValue(context, UserInfoManager.MAJOR_ID_KEY);
    util.removeValue(context, UserInfoManager.MAJOR_NAME_KEY);
    util.removeValue(context, UserInfoManager.CLASS_ID_KEY);
    util.removeValue(context, UserInfoManager.CLASS_NAME_KEY);
    console.info('📚 [UserInfo] 清除用户学籍信息');
  }

  // ===== 新增的登录状态管理方法 =====

  /**
   * 检查用户是否已登录（检查token和用户信息）
   */
  public async checkLoginStatus(context: Context | undefined): Promise<boolean> {
    try {
      const token = this.getToken(context);
      if (!token) {
        console.info('👤 [UserInfoManager] 未找到token，用户未登录');
        return false;
      }

      // 尝试获取用户信息验证token有效性
      try {
        const userInfoResponse: GetUserInfoResponse = await this.getUserApiService().getUserInfo();
        const simpleUserInfo: SimpleUserInfo = this.getUserApiService().convertToSimpleUserInfo(userInfoResponse);

        // 保存最新的用户信息
        this.saveCurrentUserInfo(context, simpleUserInfo);

        console.info('👤 [UserInfoManager] 用户已登录且token有效');
        return true;
      } catch (error) {
        console.error('👤 [UserInfoManager] token验证失败:', error);
        this.clearLoginInfo(context);

        // 重新抛出错误，让调用方能够处理特定错误类型
        if (error instanceof Error) {
          throw error;
        } else {
          throw new Error(`Token验证失败: ${JSON.stringify(error)}`);
        }
      }
    } catch (error) {
      console.error('👤 [UserInfoManager] 登录状态检查失败:', error);
      return false;
    }
  }

  /**
   * 同步检查登录状态（仅检查本地存储）
   */
  public isLoggedInSync(context: Context | undefined): boolean {
    const token = this.getToken(context);
    // 如果有token，就认为用户已登录
    // 用户信息可能在异步获取中，不应该阻塞登录状态检测
    return !!(token && token.trim().length > 0);
  }

  /**
   * 保存登录token
   */
  public saveToken(context: Context | undefined, token: string): void {
    const util = PreferencesUtil.getInstance();
    util.putValue(context, UserInfoManager.TOKEN_KEY, token);

    // 记录登录时间
    const loginTime = new Date().toISOString();
    util.putValue(context, UserInfoManager.LOGIN_TIME_KEY, loginTime);

    console.info('👤 [UserInfoManager] token已保存');
  }

  /**
   * 获取登录token
   */
  public getToken(context: Context | undefined): string | null {
    // 优先从AppStorage获取（最新的token）
    const appStorageToken = AppStorage.get<string>('token');
    if (appStorageToken && appStorageToken.trim().length > 0) {
      return appStorageToken;
    }

    // 如果AppStorage中没有，从PreferencesUtil获取
    const util = PreferencesUtil.getInstance();
    const token = util.getValue(context, UserInfoManager.TOKEN_KEY, '') as string;
    return token || null;
  }

  /**
   * 保存当前用户信息
   */
  public saveCurrentUserInfo(context: Context | undefined, userInfo: SimpleUserInfo): void {
    const util = PreferencesUtil.getInstance();
    util.putValue(context, UserInfoManager.CURRENT_USER_KEY, JSON.stringify(userInfo));
    console.info('👤 [UserInfoManager] 当前用户信息已保存');
  }

  /**
   * 获取当前用户信息
   */
  public getCurrentUserInfo(context: Context | undefined): SimpleUserInfo | null {
    try {
      const util = PreferencesUtil.getInstance();
      const userInfoStr = util.getValue(context, UserInfoManager.CURRENT_USER_KEY, '') as string;
      if (!userInfoStr) {
        return null;
      }
      return JSON.parse(userInfoStr) as SimpleUserInfo;
    } catch (error) {
      console.error('👤 [UserInfoManager] 解析当前用户信息失败:', error);
      return null;
    }
  }

  /**
   * 获取登录时间
   */
  public getLoginTime(context: Context | undefined): string | null {
    const util = PreferencesUtil.getInstance();
    const loginTime = util.getValue(context, UserInfoManager.LOGIN_TIME_KEY, '') as string;
    return loginTime || null;
  }

  /**
   * 清除登录信息（保留学籍信息）
   */
  public clearLoginInfo(context: Context | undefined): void {
    const util = PreferencesUtil.getInstance();
    util.removeValue(context, UserInfoManager.TOKEN_KEY);
    util.removeValue(context, UserInfoManager.CURRENT_USER_KEY);
    util.removeValue(context, UserInfoManager.LOGIN_TIME_KEY);
    console.info('👤 [UserInfoManager] 登录信息已清除');
  }

  /**
   * 清除所有信息（包括学籍信息和登录信息）
   */
  public clearAllInfo(context: Context | undefined): void {
    this.clearUserInfo(context);
    this.clearLoginInfo(context);
    console.info('👤 [UserInfoManager] 所有用户信息已清除');
  }

  /**
   * 获取UserApiService实例（懒加载）
   */
  private getUserApiService(): UserApiService {
    if (!this.userApiService) {
      this.userApiService = UserApiService.getInstance();
    }
    return this.userApiService;
  }
}