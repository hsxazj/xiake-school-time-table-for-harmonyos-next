import { PreferencesUtil } from "./PreferencesUtil";

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
  public saveCompleteUserInfo(context: Context, userInfo: UserSchoolInfo): void {
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
  public getCollegeId(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.COLLEGE_ID_KEY, '') as string;
  }

  /**
   * 获取学院名称
   */
  public getCollegeName(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.COLLEGE_NAME_KEY, '') as string;
  }

  /**
   * 获取专业ID
   */
  public getMajorId(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.MAJOR_ID_KEY, '') as string;
  }

  /**
   * 获取专业名称
   */
  public getMajorName(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.MAJOR_NAME_KEY, '') as string;
  }

  /**
   * 获取班级ID
   */
  public getClassId(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.CLASS_ID_KEY, '') as string;
  }

  /**
   * 获取班级名称
   */
  public getClassName(context: Context): string {
    const util = PreferencesUtil.getInstance();
    return util.getValue(context, UserInfoManager.CLASS_NAME_KEY, '') as string;
  }

  /**
   * 检查是否已设置完整的学籍信息
   */
  public hasCompleteUserInfo(context: Context): boolean {
    const collegeId = this.getCollegeId(context);
    const majorId = this.getMajorId(context);
    const classId = this.getClassId(context);

    return !!(collegeId && majorId && classId);
  }

  /**
   * 获取完整的用户学籍信息
   */
  public getUserInfo(context: Context): UserSchoolInfo {
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
  public clearUserInfo(context: Context): void {
    const util = PreferencesUtil.getInstance();
    util.removeValue(context, UserInfoManager.COLLEGE_ID_KEY);
    util.removeValue(context, UserInfoManager.COLLEGE_NAME_KEY);
    util.removeValue(context, UserInfoManager.MAJOR_ID_KEY);
    util.removeValue(context, UserInfoManager.MAJOR_NAME_KEY);
    util.removeValue(context, UserInfoManager.CLASS_ID_KEY);
    util.removeValue(context, UserInfoManager.CLASS_NAME_KEY);
    console.info('📚 [UserInfo] 清除用户学籍信息');
  }
}