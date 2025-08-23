import { ValueType } from '@kit.ArkData';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';

const PREFERENCES_NAME: string = 'myPreferences';
let preference: dataPreferences.Preferences | null = null;

export class PreferencesUtil {
  private preferenceName: string = PREFERENCES_NAME;
  private groupId: string = "";

  setPreferenceName(preferenceName: string) {
    this.preferenceName = preferenceName;
  }

  setGroupId(groupId: string) {
    this.groupId = groupId;
  }

  getPreference(): dataPreferences.Preferences {
    let options: dataPreferences.Options = { name: this.preferenceName };
    console.debug(`name: ${this.preferenceName}, groupID: ${this.groupId}`);

    if (!this.groupId) options.dataGroupId = this.groupId;
    return dataPreferences.getPreferencesSync(getContext(this), options);
  }

  /**
   * 构造器
   */
  constructor(preferenceName: string = PREFERENCES_NAME, groupId: string) {
    this.preferenceName = preferenceName;
    this.groupId = groupId;

    preference = this.getPreference();
  }

  /**
   * 保存数据到首选项
   * @param key
   * @param value
   */
  putValue(key: string, value: ValueType, override: boolean = true) {
    try {
      if (!preference) {
        console.info('preference不存在');
        preference = this.getPreference();
      }

      if (preference.hasSync(key)) { // 判断当前key是否已存在
        console.info(`The key ${key} is contained.`);

        // 判断是否覆盖其值，为true则覆盖
        if (override) preference.putSync(key, value);
      } else {
        preference.putSync(key, value);
      }

      preference.flush((err: BusinessError) => {
        if (err) {
          console.error(`Failed to flush. Code:${err.code}, message:${err.message}`);
          return;
        }
        console.info('Succeeded in flushing.');
      });
    } catch (err) {
      console.error(`Save value by preferences error: ${err}`)
    }
  }

  /**
   * 获取数据到首选项
   * @param key
   * @param defaultValue 默认返回值
   * @returns string类型值
   */
  getValue(key: string, defaultValue: ValueType = ''): ValueType {
    let resValue: ValueType = '';
    try {
      if (!preference) {
        preference = this.getPreference();
      }

      resValue = preference.getSync(key, defaultValue).toString();
    } catch (err) {
      console.error('Get value by preferences error: ${err}')
    }

    return resValue;
  }

  /**
   * 从首选项按key移除数据
   * @param key
   */
  removeValue(key: string) {
    try {
      if (!preference) {
        preference = this.getPreference();
      }
      preference.deleteSync(key);

      preference.flush((err: BusinessError) => {
        if (err) {
          console.error(`Failed to flush. Code:${err.code}, message:${err.message}`);
          return;
        }
        console.info('Succeeded in flushing.');
      });
    } catch (err) {
      console.error('Remove value by preferences error: ${err}')
    }
  }

  /**
   * 清除所有数据
   */
  clearAll() {
    try {
      if (!preference) {
        preference = this.getPreference();
      }

      preference.clearSync();
      preference.flush((err: BusinessError) => {
        if (err) {
          console.error(`Failed to flush. Code:${err.code}, message:${err.message}`);
          return;
        }
        console.info('Succeeded in flushing.');
      });

    } catch (err) {
      console.error(`Failed to put value, Cause: ${err}`);
    }
  }

}

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
  private preferencesUtil: PreferencesUtil;

  // 存储键常量
  private static readonly COLLEGE_ID_KEY = 'userCollegeId';
  private static readonly COLLEGE_NAME_KEY = 'userCollegeName';
  private static readonly MAJOR_ID_KEY = 'userMajorId';
  private static readonly MAJOR_NAME_KEY = 'userMajorName';
  private static readonly CLASS_ID_KEY = 'userClassId';
  private static readonly CLASS_NAME_KEY = 'userClassName';

  private constructor() {
    this.preferencesUtil = new PreferencesUtil(PREFERENCES_NAME, "");
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
  public saveCollegeInfo(collegeId: string, collegeName: string): void {
    this.preferencesUtil.putValue(UserInfoManager.COLLEGE_ID_KEY, collegeId);
    this.preferencesUtil.putValue(UserInfoManager.COLLEGE_NAME_KEY, collegeName);
    console.info(`📚 [UserInfo] 保存学院信息: ${collegeId} - ${collegeName}`);
  }

  /**
   * 保存专业信息
   */
  public saveMajorInfo(majorId: string, majorName: string): void {
    this.preferencesUtil.putValue(UserInfoManager.MAJOR_ID_KEY, majorId);
    this.preferencesUtil.putValue(UserInfoManager.MAJOR_NAME_KEY, majorName);
    console.info(`📚 [UserInfo] 保存专业信息: ${majorId} - ${majorName}`);
  }

  /**
   * 保存班级信息
   */
  public saveClassInfo(classId: string, className: string): void {
    this.preferencesUtil.putValue(UserInfoManager.CLASS_ID_KEY, classId);
    this.preferencesUtil.putValue(UserInfoManager.CLASS_NAME_KEY, className);
    console.info(`📚 [UserInfo] 保存班级信息: ${classId} - ${className}`);
  }

  /**
   * 获取学院ID
   */
  public getCollegeId(): string {
    return this.preferencesUtil.getValue(UserInfoManager.COLLEGE_ID_KEY, '') as string;
  }

  /**
   * 获取学院名称
   */
  public getCollegeName(): string {
    return this.preferencesUtil.getValue(UserInfoManager.COLLEGE_NAME_KEY, '') as string;
  }

  /**
   * 获取专业ID
   */
  public getMajorId(): string {
    return this.preferencesUtil.getValue(UserInfoManager.MAJOR_ID_KEY, '') as string;
  }

  /**
   * 获取专业名称
   */
  public getMajorName(): string {
    return this.preferencesUtil.getValue(UserInfoManager.MAJOR_NAME_KEY, '') as string;
  }

  /**
   * 获取班级ID
   */
  public getClassId(): string {
    const classId = this.preferencesUtil.getValue(UserInfoManager.CLASS_ID_KEY, '') as string;
    return classId;
  }

  /**
   * 获取班级名称
   */
  public getClassName(): string {
    return this.preferencesUtil.getValue(UserInfoManager.CLASS_NAME_KEY, '') as string;
  }

  /**
   * 检查是否已设置完整的学籍信息
   */
  public hasCompleteUserInfo(): boolean {
    const collegeId = this.getCollegeId();
    const majorId = this.getMajorId();
    const classId = this.getClassId();
    
    return !!(collegeId && majorId && classId);
  }

  /**
   * 获取完整的用户学籍信息
   */
  public getUserInfo(): UserSchoolInfo {
    const result: UserSchoolInfo = {
      collegeId: this.getCollegeId(),
      collegeName: this.getCollegeName(),
      majorId: this.getMajorId(),
      majorName: this.getMajorName(),
      classId: this.getClassId(),
      className: this.getClassName()
    };
    return result;
  }

  /**
   * 清除所有用户信息
   */
  public clearUserInfo(): void {
    this.preferencesUtil.removeValue(UserInfoManager.COLLEGE_ID_KEY);
    this.preferencesUtil.removeValue(UserInfoManager.COLLEGE_NAME_KEY);
    this.preferencesUtil.removeValue(UserInfoManager.MAJOR_ID_KEY);
    this.preferencesUtil.removeValue(UserInfoManager.MAJOR_NAME_KEY);
    this.preferencesUtil.removeValue(UserInfoManager.CLASS_ID_KEY);
    this.preferencesUtil.removeValue(UserInfoManager.CLASS_NAME_KEY);
    console.info('📚 [UserInfo] 清除用户学籍信息');
  }
}

export default new PreferencesUtil(PREFERENCES_NAME, "");
