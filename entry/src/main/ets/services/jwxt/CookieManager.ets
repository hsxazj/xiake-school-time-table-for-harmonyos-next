/**
 * Cookie管理器
 *
 * 用途：
 * - 在HarmonyOS/ArkTS环境中手动管理Cookie
 * - axios默认不会自动保存和发送Cookie，需要手动管理
 * - 使用Preferences持久化存储Cookie
 *
 * 工作原理：
 * 1. 响应拦截器：提取Set-Cookie响应头，保存到Preferences
 * 2. 请求拦截器：从Preferences读取Cookie，添加到请求头
 *
 * 使用方法：
 * ```typescript
 * const manager = CookieManager.getInstance();
 * await manager.saveCookie(host, setCookieValue);
 * const cookie = await manager.getCookie(host);
 * ```
 *
 * @since 2026-01-07
 */
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3004; // Cookie Manager domain
const TAG: string = 'CookieManager';

/**
 * Cookie管理器类
 * 单例模式
 */
export class CookieManager {
  private static instance: CookieManager;
  private preferencesStore: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME = 'jwxt_cookies';

  private constructor() {
    hilog.info(DOMAIN, TAG, '✅ CookieManager初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): CookieManager {
    if (!CookieManager.instance) {
      CookieManager.instance = new CookieManager();
    }
    return CookieManager.instance;
  }

  /**
   * 初始化Preferences存储
   * 必须在使用前调用一次
   *
   * @param context 应用上下文
   */
  public async initialize(context: Context): Promise<void> {
    try {
      if (!this.preferencesStore) {
        this.preferencesStore = await preferences.getPreferences(context, this.PREFERENCES_NAME);
        hilog.info(DOMAIN, TAG, '✅ Preferences存储初始化成功');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ Preferences存储初始化失败: %{public}s', JSON.stringify(error));
      throw new Error(`Cookie存储初始化失败: ${error}`);
    }
  }

  /**
   * 保存Cookie
   *
   * @param host 域名（如：jwxtwx.fjut.edu.cn）
   * @param setCookieValues Set-Cookie响应头值（可能是数组）
   */
  public async saveCookie(host: string, setCookieValues: string | string[]): Promise<void> {
    try {
      if (!this.preferencesStore) {
        hilog.warn(DOMAIN, TAG, '⚠️ Preferences未初始化，跳过保存Cookie');
        return;
      }

      // 处理数组情况
      const cookieArray = Array.isArray(setCookieValues) ? setCookieValues : [setCookieValues];

      // 打印每个 Set-Cookie 值
      hilog.info(DOMAIN, TAG, '🔍 [Save] 准备保存 %{public}d 个Set-Cookie响应头:', cookieArray.length);
      cookieArray.forEach((cookie, index) => {
        hilog.info(DOMAIN, TAG, '🔍 [Save] Set-Cookie[%{public}d]: %{public}s', index, cookie);
      });

      // 读取现有Cookie
      const existingCookieStr = await this.preferencesStore.get(host, '') as string;
      const existingCookies = new Map<string, string>();

      // 解析现有Cookie（跳过非 name=value 的部分，如 Path=xxx）
      if (existingCookieStr) {
        const pairs = existingCookieStr.split(';').map(s => s.trim());
        for (const pair of pairs) {
          const eqIndex = pair.indexOf('=');
          if (eqIndex > 0) {
            const name = pair.substring(0, eqIndex);
            const value = pair.substring(eqIndex + 1);
            // 跳过 Path、Domain、Expires 等属性
            if (name !== 'Path' && name !== 'Domain' && name !== 'Expires' &&
                name !== 'Max-Age' && name !== 'HttpOnly' && name !== 'Secure' &&
                name !== 'SameSite') {
              existingCookies.set(name, value);
            }
          }
        }
        hilog.info(DOMAIN, TAG, '🔍 [Save] 现有Cookie: %{public}s', existingCookieStr);
      }

      // 解析新Cookie，只提取 name=value 部分，忽略过期的Cookie
      for (const setCookie of cookieArray) {
        // 提取第一个分号之前的部分（name=value）
        const parts = setCookie.split(';').map(s => s.trim());
        const cookiePair = parts[0]; // "name=value"

        if (!cookiePair || !cookiePair.includes('=')) {
          continue;
        }

        // 检查是否是删除Cookie的标记
        const isDeleting = setCookie.includes('Max-Age=0') || setCookie.includes('Expires=') && new Date(setCookie.split('Expires=')[1]?.split(';')[0]) < new Date();

        const eqIndex = cookiePair.indexOf('=');
        const name = cookiePair.substring(0, eqIndex);
        const value = cookiePair.substring(eqIndex + 1);

        if (isDeleting) {
          // 删除过期的Cookie
          existingCookies.delete(name);
          hilog.info(DOMAIN, TAG, '🗑️ [Save] 删除过期Cookie: %{public}s', name);
        } else {
          // 添加或更新Cookie
          existingCookies.set(name, value);
          hilog.info(DOMAIN, TAG, '✅ [Save] 更新Cookie: %{public}s=%{public}s', name, value);
        }
      }

      // 构建最终的Cookie字符串
      const finalCookies: string[] = [];
      existingCookies.forEach((value, name) => {
        finalCookies.push(`${name}=${value}`);
      });
      const cookieStr = finalCookies.join('; ');

      // 保存到Preferences
      await this.preferencesStore.put(host, cookieStr);
      await this.preferencesStore.flush();

      hilog.info(DOMAIN, TAG, '💾 [Save] Cookie已保存: host=%{public}s, count=%{public}d',
        host, existingCookies.size);
      hilog.info(DOMAIN, TAG, '💾 [Save] 保存的完整Cookie字符串: %{public}s', cookieStr);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Save] 保存Cookie失败: %{public}s', JSON.stringify(error));
      // 不抛出异常，避免影响主流程
    }
  }

  /**
   * 获取Cookie
   *
   * @param host 域名
   * @returns Cookie字符串（格式：key1=value1; key2=value2）或空字符串
   */
  public async getCookie(host: string): Promise<string> {
    try {
      if (!this.preferencesStore) {
        hilog.warn(DOMAIN, TAG, '⚠️ Preferences未初始化，返回空Cookie');
        return '';
      }

      // 从Preferences读取
      const cookieStr = await this.preferencesStore.get(host, '') as string;

      if (!cookieStr) {
        hilog.info(DOMAIN, TAG, '📝 [Get] 未找到Cookie: host=%{public}s', host);
        return '';
      }

      hilog.info(DOMAIN, TAG, '🔍 [Get] 从存储读取的Cookie: %{public}s', cookieStr);
      hilog.info(DOMAIN, TAG, '✅ [Get] Cookie获取成功: host=%{public}s, length=%{public}d',
        host, cookieStr.length);

      return cookieStr;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Get] 获取Cookie失败: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  /**
   * 清除指定域名的Cookie
   *
   * @param host 域名
   */
  public async clearCookie(host: string): Promise<void> {
    try {
      if (!this.preferencesStore) {
        hilog.warn(DOMAIN, TAG, '⚠️ Preferences未初始化，跳过清除Cookie');
        return;
      }

      await this.preferencesStore.delete(host);
      await this.preferencesStore.flush();

      hilog.info(DOMAIN, TAG, '🗑️ [Clear] Cookie已清除: host=%{public}s', host);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Clear] 清除Cookie失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 清除所有Cookie
   */
  public async clearAllCookies(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        hilog.warn(DOMAIN, TAG, '⚠️ Preferences未初始化，跳过清除所有Cookie');
        return;
      }

      await this.preferencesStore.clear();
      await this.preferencesStore.flush();

      hilog.info(DOMAIN, TAG, '🗑️ [Clear All] 所有Cookie已清除');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Clear All] 清除所有Cookie失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 从URL提取域名
   *
   * @param url 完整URL或相对路径
   * @returns 域名（如：jwxtwx.fjut.edu.cn）
   */
  public extractHostFromUrl(url: string): string {
    try {
      // 如果是完整URL，使用正则提取域名
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // 正则提取: https://jwxtwx.fjut.edu.cn/path -> jwxtwx.fjut.edu.cn
        const match = url.match(/^https?:\/\/([^\/]+)/);
        if (match && match[1]) {
          return match[1];
        }
      }

      // 如果是相对路径，返回空字符串
      return '';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, '❌ [Extract] 提取域名失败: %{public}s', errorMsg);
      return '';
    }
  }
}
