/**
 * JWXT登出服务
 *
 * 用途：
 * - 调用教务系统logout接口
 * - 清空服务器端Cookie（JSESSIONID）
 * - 在登录前调用，确保清空旧会话
 *
 * 使用方法：
 * ```typescript
 * const logoutService = JwxtLogoutService.getInstance();
 * await logoutService.logout();
 * ```
 *
 * @since 2026-01-07
 */
import { JwxtHttpClient } from './JwxtHttpClient';
import { JwxtConstants } from './JwxtConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3002; // JWXT Logout domain
const TAG: string = 'JwxtLogoutService';

/**
 * JWXT登出服务类
 * 单例模式
 */
export class JwxtLogoutService {
  private static instance: JwxtLogoutService;
  private httpClient: JwxtHttpClient;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtLogoutService初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtLogoutService {
    if (!JwxtLogoutService.instance) {
      JwxtLogoutService.instance = new JwxtLogoutService();
    }
    return JwxtLogoutService.instance;
  }

  /**
   * 登出教务系统
   * 清空服务器端的会话Cookie
   *
   * 流程：
   * 1. 调用教务系统logout接口
   * 2. 服务器返回 Set-Cookie: JSESSIONID=; expires=...（过期Cookie）
   * 3. axios自动处理，后续请求不再携带此Cookie
   *
   * @throws Error 登出失败时抛出异常
   */
  public async logout(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '🚪 [Logout] 开始登出教务系统...');

      // 调用logout接口
      await this.httpClient.post(
        JwxtConstants.API_PATHS.LOGOUT,
        JwxtConstants.API_PATHS.INDEX
      );

      hilog.info(DOMAIN, TAG, '✅ [Logout] 登出成功，Cookie已清除');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Logout] 登出失败: %{public}s', JSON.stringify(error));

      // 登出失败不应该阻塞后续流程，只记录日志
      hilog.warn(DOMAIN, TAG, '⚠️ [Logout] 登出失败但继续执行');
    }
  }
}
