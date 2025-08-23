import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { STORAGE_KEYS } from '../../common/constants/AppConstants';
import { UserSelection } from '../../models/CollegeModels';

export class StorageService {
  private static instance: StorageService;
  private preferencesMap: Map<string, preferences.Preferences> = new Map();

  private constructor() {}

  public static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }

  private async getPreferences(storeName: string = 'app_storage'): Promise<preferences.Preferences> {
    if (!this.preferencesMap.has(storeName)) {
      try {
        const context = getContext() as common.UIAbilityContext;
        const prefs = await preferences.getPreferences(context, storeName);
        this.preferencesMap.set(storeName, prefs);
        return prefs;
      } catch (error) {
        console.error('Failed to get preferences:', error);
        throw new Error('Failed to get preferences');
      }
    }
    return this.preferencesMap.get(storeName)!;
  }

  public async setItem(key: string, value: string | number | boolean): Promise<boolean> {
    try {
      const prefs = await this.getPreferences();
      if (typeof value === 'string') {
        await prefs.put(key, value);
      } else if (typeof value === 'number') {
        await prefs.put(key, value);
      } else if (typeof value === 'boolean') {
        await prefs.put(key, value);
      }
      await prefs.flush();
      return true;
    } catch (error) {
      console.error(`Failed to set item ${key}:`, error);
      return false;
    }
  }

  public async getStringItem(key: string, defaultValue: string): Promise<string> {
    try {
      const prefs = await this.getPreferences();
      const result = await prefs.get(key, defaultValue);
      return result as string;
    } catch (error) {
      console.error(`Failed to get item ${key}:`, error);
      return defaultValue;
    }
  }

  public async getNumberItem(key: string, defaultValue: number): Promise<number> {
    try {
      const prefs = await this.getPreferences();
      const result = await prefs.get(key, defaultValue);
      return result as number;
    } catch (error) {
      console.error(`Failed to get item ${key}:`, error);
      return defaultValue;
    }
  }

  public async getBooleanItem(key: string, defaultValue: boolean): Promise<boolean> {
    try {
      const prefs = await this.getPreferences();
      const result = await prefs.get(key, defaultValue);
      return result as boolean;
    } catch (error) {
      console.error(`Failed to get item ${key}:`, error);
      return defaultValue;
    }
  }

  public async removeItem(key: string): Promise<boolean> {
    try {
      const prefs = await this.getPreferences();
      await prefs.delete(key);
      await prefs.flush();
      return true;
    } catch (error) {
      console.error(`Failed to remove item ${key}:`, error);
      return false;
    }
  }

  public async clear(): Promise<boolean> {
    try {
      const prefs = await this.getPreferences();
      await prefs.clear();
      await prefs.flush();
      return true;
    } catch (error) {
      console.error('Failed to clear storage:', error);
      return false;
    }
  }

  public async saveUserSelection(selection: UserSelection): Promise<boolean> {
    try {
      const tasks: Promise<boolean>[] = [
        this.setItem(STORAGE_KEYS.COLLEGE_ID, selection.collegeId),
        this.setItem(STORAGE_KEYS.COLLEGE_NAME, selection.collegeName),
        this.setItem(STORAGE_KEYS.MAJOR_ID, selection.majorId),
        this.setItem(STORAGE_KEYS.MAJOR_NAME, selection.majorName),
        this.setItem(STORAGE_KEYS.CLASS_ID, selection.classId),
        this.setItem(STORAGE_KEYS.CLASS_NAME, selection.className),
        this.setItem(STORAGE_KEYS.LOGIN_STATUS, true)
      ];
      
      const success = await Promise.all(tasks);
      return success.every(result => result);
    } catch (error) {
      console.error('Failed to save user selection:', error);
      return false;
    }
  }

  public async getUserSelection(): Promise<UserSelection | null> {
    try {
      const collegeId = await this.getNumberItem(STORAGE_KEYS.COLLEGE_ID, 0);
      const collegeName = await this.getStringItem(STORAGE_KEYS.COLLEGE_NAME, '');
      const majorId = await this.getNumberItem(STORAGE_KEYS.MAJOR_ID, 0);
      const majorName = await this.getStringItem(STORAGE_KEYS.MAJOR_NAME, '');
      const classId = await this.getNumberItem(STORAGE_KEYS.CLASS_ID, 0);
      const className = await this.getStringItem(STORAGE_KEYS.CLASS_NAME, '');

      if (collegeId && majorId && classId) {
        return {
          collegeId,
          collegeName,
          majorId,
          majorName,
          classId,
          className
        };
      }
      return null;
    } catch (error) {
      console.error('Failed to get user selection:', error);
      return null;
    }
  }

  public async setToken(token: string): Promise<boolean> {
    return this.setItem(STORAGE_KEYS.TOKEN, token);
  }

  public async getToken(): Promise<string> {
    return this.getStringItem(STORAGE_KEYS.TOKEN, '');
  }

  public async removeToken(): Promise<boolean> {
    return this.removeItem(STORAGE_KEYS.TOKEN);
  }

  public async isLoggedIn(): Promise<boolean> {
    return this.getBooleanItem(STORAGE_KEYS.LOGIN_STATUS, false);
  }
}