/**
 * Cookie管理器
 *
 * 用途：
 * - 在HarmonyOS/ArkTS环境中手动管理Cookie
 * - axios默认不会自动保存和发送Cookie，需要手动管理
 * - 使用内存存储Cookie（应用重启后需要重新登录）
 *
 * 工作原理：
 * 1. 响应拦截器：提取Set-Cookie响应头，保存到内存Map
 * 2. 请求拦截器：从内存Map读取Cookie，添加到请求头
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
import { hilog } from '@kit.PerformanceAnalysisKit';
import { jwxtConnectionBus } from './JwxtConnectionEvent';

const DOMAIN: number = 0x3004; // Cookie Manager domain
const TAG: string = 'CookieManager';

/**
 * Cookie管理器类
 * 单例模式，使用内存存储
 */
export class CookieManager {
  private static instance: CookieManager;
  private cookieStore: Map<string, string> = new Map(); // 内存存储

  private constructor() {
    hilog.info(DOMAIN, TAG, '✅ CookieManager初始化完成（内存模式）');
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
   * 通知所有订阅者Cookie状态已改变
   * @param host 域名
   */
  private notify(host: string): void {
    const cookieStr = this.cookieStore.get(host) ?? '';
    // 检查是否包含 JSESSIONID，判断是否已连接到教务系统
    const isConnected = cookieStr.includes('JSESSIONID');
    jwxtConnectionBus.emit(cookieStr, isConnected);
    hilog.info(DOMAIN, TAG, '🔔 [Notify] 已广播Cookie状态变更, isConnected=%{public}s', isConnected);
  }

  /**
   * 保存Cookie
   *
   * @param host 域名（如：jwxtwx.fjut.edu.cn）
   * @param setCookieValues Set-Cookie响应头值（可能是数组）
   */
  public async saveCookie(host: string, setCookieValues: string | string[]): Promise<void> {
    try {
      // 处理数组情况
      const cookieArray = Array.isArray(setCookieValues) ? setCookieValues : [setCookieValues];

      // 打印每个 Set-Cookie 值
      hilog.info(DOMAIN, TAG, '🔍 [Save] 准备保存 %{public}d 个Set-Cookie响应头:', cookieArray.length);
      cookieArray.forEach((cookie, index) => {
        hilog.info(DOMAIN, TAG, '🔍 [Save] Set-Cookie[%{public}d]: %{public}s', index, cookie);
      });

      // 读取现有Cookie
      const existingCookieStr = this.cookieStore.get(host) || '';
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
        const isDeleting = setCookie.includes('Max-Age=0') ||
          setCookie.includes('Expires=') && new Date(setCookie.split('Expires=')[1]?.split(';')[0]) < new Date();

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

      // 保存到内存Map
      this.cookieStore.set(host, cookieStr);

      hilog.info(DOMAIN, TAG, '💾 [Save] Cookie已保存到内存: host=%{public}s, count=%{public}d',
        host, existingCookies.size);
      hilog.info(DOMAIN, TAG, '💾 [Save] 保存的完整Cookie字符串: %{public}s', cookieStr);

      // 触发事件通知
      this.notify(host);
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
  public async getCookie(): Promise<string> {
    const host = 'jwxtwx.fjut.edu.cn'
    const cookieStr = this.cookieStore.get(host) || '';

    if (!cookieStr) {
      hilog.info(DOMAIN, TAG, '📝 [Get] 未找到Cookie: host=%{public}s', host);
      return '';
    }

    hilog.info(DOMAIN, TAG, '✅ [Get] Cookie获取成功: host=%{public}s, length=%{public}d',
      host, cookieStr.length);
    hilog.info(DOMAIN, TAG, '✅ [Get] Cookie内容: %{public}s', cookieStr);

    return cookieStr;
  }

  /**
   * 清除指定域名的Cookie
   *
   * @param host 域名
   */
  public async clearCookie(host: string): Promise<void> {
    this.cookieStore.delete(host);
    hilog.info(DOMAIN, TAG, '🗑️ [Clear] Cookie已清除: host=%{public}s', host);
  }

  /**
   * 清除所有Cookie
   */
  public async clearAllCookies(): Promise<void> {
    this.cookieStore.clear();
    hilog.info(DOMAIN, TAG, '🗑️ [Clear All] 所有Cookie已清除');
    // 触发事件，通知所有订阅者Cookie已清空
    jwxtConnectionBus.emit('', false);
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
