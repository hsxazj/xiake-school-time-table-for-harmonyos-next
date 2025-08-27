import { preferences } from '@kit.ArkData';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';

const PREFERENCES_NAME: string = 'SchoolTimeTablePreferences';
let preference: dataPreferences.Preferences | null = null;

export class PreferencesUtil {
  private preferenceName: string = PREFERENCES_NAME;
  private groupId: string = '';
  private static preferencesUtil: PreferencesUtil;

  public static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.preferencesUtil) {
      PreferencesUtil.preferencesUtil = new PreferencesUtil();
    }
    return PreferencesUtil.preferencesUtil;
  }

  getPreferences(context: Context | undefined): preferences.Preferences {
    // 构建options配置
    let options: preferences.Options = {
      name: this.preferenceName
    };
    
    // 只有在groupId不为空时才添加dataGroupId
    if (this.groupId && this.groupId.trim() !== '') {
      options.dataGroupId = this.groupId;
    }
    
    // 先从缓存里清掉旧的，防止拿错实例
    preferences.removePreferencesFromCacheSync(context, this.preferenceName);
    
    return preferences.getPreferencesSync(context, options);
  }

  setPreferenceName(preferenceName: string) {
    this.preferenceName = preferenceName;
  }

  setGroupId(groupId: string) {
    this.groupId = groupId;
  }

  /**
   * 保存数据到首选项
   * @param context 上下文
   * @param key 键
   * @param value 值
   * @param override 是否覆盖现有值
   */
  putValue(context: Context | undefined, key: string, value: preferences.ValueType, override: boolean = true) {
    try {
      const preferences = this.getPreferences(context);
      
      if (preferences.hasSync(key)) {
        console.info(`The key ${key} is contained.`);
        if (override) {
          preferences.putSync(key, value);
        }
      } else {
        preferences.putSync(key, value);
      }

      // 使用同步刷新确保数据立即写入
      preferences.flushSync();
      console.info(`Successfully saved ${key}: ${value}`);
    } catch (err) {
      console.error(`Save value by preferences error: ${err}`)
    }
  }

  /**
   * 获取数据
   * @param context 上下文
   * @param key 键
   * @param defaultValue 默认返回值
   * @returns 值
   */
  getValue(context: Context | undefined, key: string, defaultValue: preferences.ValueType = ''): preferences.ValueType {
    try {
      const preferences = this.getPreferences(context);
      return preferences.getSync(key, defaultValue);
    } catch (err) {
      console.error(`Get value by preferences error: ${err}`)
      return defaultValue;
    }
  }

  /**
   * 从首选项按key移除数据
   * @param context 上下文
   * @param key 键
   */
  removeValue(context: Context  | undefined, key: string) {
    try {
      const preferences = this.getPreferences(context);
      preferences.deleteSync(key);

      // 使用同步刷新确保数据立即写入
      preferences.flushSync();
      console.info(`Successfully removed ${key}`);
    } catch (err) {
      console.error(`Remove value by preferences error: ${err}`)
    }
  }

  /**
   * 清除所有数据
   * @param context 上下文
   */
  clearAll(context: Context | undefined) {
    try {
      const preferences = this.getPreferences(context);
      preferences.clearSync();
      
      // 使用同步刷新确保数据立即写入
      preferences.flushSync();
      console.info('Successfully cleared all data');
    } catch (err) {
      console.error(`Failed to clear all values, Cause: ${err}`);
    }
  }
}

export default new PreferencesUtil();
