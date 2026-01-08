/**
 * JWXT凭证管理器
 *
 * 用途：
 * - 使用PreferencesUtil存储学号和密码
 * - 提供保存、获取、清除、检查凭证的方法
 * - 日志记录（脱敏处理）
 *
 * 使用方法：
 * ```typescript
 * const manager = JwxtCredentialsManager.getInstance();
 * manager.saveCredentials(context, '学号', '密码');
 * const credentials = manager.getCredentials(context);
 * ```
 *
 * ⚠️ 安全提示：
 * - 当前使用PreferencesUtil明文存储，存在安全风险
 * - 后续可考虑加密存储或使用更安全的存储方案
 *
 * @since 2026-01-07
 */
import { PreferencesUtil } from '../../common/utils/PreferencesUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3001; // JWXT Credentials domain
const TAG: string = 'JwxtCredentialsManager';

/**
 * 凭证接口
 */
export interface JwxtCredentials {
  /** 学号 */
  sid: string;

  /** 密码（明文） */
  password: string;
}

/**
 * JWXT凭证管理器类
 * 单例模式
 */
export class JwxtCredentialsManager {
  private static instance: JwxtCredentialsManager;
  /** 学号存储键 */
  private static readonly SID_KEY: string = 'jwxt_student_id';
  /** 密码存储键 */
  private static readonly PASSWORD_KEY: string = 'jwxt_password';
  private preferencesUtil: PreferencesUtil;

  private constructor() {
    this.preferencesUtil = PreferencesUtil.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtCredentialsManager初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtCredentialsManager {
    if (!JwxtCredentialsManager.instance) {
      JwxtCredentialsManager.instance = new JwxtCredentialsManager();
    }
    return JwxtCredentialsManager.instance;
  }

  /**
   * 保存凭证
   *
   * @param context 应用上下文
   * @param sid 学号
   * @param password 密码（明文）
   */
  public saveCredentials(context: Context, sid: string, password: string): void {
    try {
      // 保存学号
      this.preferencesUtil.putValue(context, JwxtCredentialsManager.SID_KEY, sid);
      // 保存密码
      this.preferencesUtil.putValue(context, JwxtCredentialsManager.PASSWORD_KEY, password);

      // 日志记录（脱敏处理）
      const maskedSid = this.maskString(sid);
      hilog.info(DOMAIN, TAG, '💾 [Save] 凭证已保存: 学号=%{public}s', maskedSid);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Save] 保存凭证失败: %{public}s', JSON.stringify(error));
      throw new Error(`保存凭证失败: ${error}`);
    }
  }

  /**
   * 获取凭证
   *
   * @param context 应用上下文
   * @returns JwxtCredentials 或 null（无凭证）
   */
  public getCredentials(context: Context | undefined): JwxtCredentials | null {
    try {
      const sid = this.preferencesUtil.getValue(context, JwxtCredentialsManager.SID_KEY, '') as string;
      const password = this.preferencesUtil.getValue(context, JwxtCredentialsManager.PASSWORD_KEY, '') as string;

      // 检查是否有效
      if (!sid || !password || sid.trim() === '' || password.trim() === '') {
        hilog.info(DOMAIN, TAG, '📝 [Get] 未找到有效凭证');
        return null;
      }

      // 日志记录（脱敏处理）
      const maskedSid = this.maskString(sid);
      hilog.info(DOMAIN, TAG, '✅ [Get] 获取凭证成功: 学号=%{public}s', maskedSid);

      return { sid, password };
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Get] 获取凭证失败: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 清除凭证
   *
   * @param context 应用上下文
   */
  public clearCredentials(context: Context): void {
    try {
      this.preferencesUtil.removeValue(context, JwxtCredentialsManager.SID_KEY);
      this.preferencesUtil.removeValue(context, JwxtCredentialsManager.PASSWORD_KEY);

      hilog.info(DOMAIN, TAG, '🗑️ [Clear] 凭证已清除');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Clear] 清除凭证失败: %{public}s', JSON.stringify(error));
      throw new Error(`清除凭证失败: ${error}`);
    }
  }

  /**
   * 检查是否有凭证
   *
   * @param context 应用上下文
   * @returns boolean
   */
  public hasCredentials(context: Context | undefined): boolean {
    const credentials = this.getCredentials(context);
    const hasCredentials = credentials !== null;

    hilog.info(DOMAIN, TAG, '🔍 [Check] 凭证检查: %{public}s', hasCredentials ? '有凭证' : '无凭证');
    return hasCredentials;
  }

  /**
   * 脱敏处理字符串（用于日志）
   * 示例: "202012345" -> "2020***45"
   *
   * @param str 原始字符串
   * @returns 脱敏后的字符串
   */
  private maskString(str: string): string {
    if (str.length <= 4) {
      return '***';
    }
    const start = str.slice(0, 4);
    const end = str.slice(-2);
    return `${start}***${end}`;
  }
}
