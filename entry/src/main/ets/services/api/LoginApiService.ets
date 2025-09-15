import { HttpService } from './HttpService';
import { LoginForm, LoginRequest, LoginResponse } from '../../models/LoginModels';
import { RsaPkcs1Util } from '../../common/utils/RsaPkcs1Util';
import { RSA_PUBLIC_KEY } from '../../common/constants/AppConstants';
import { PreferencesUtil } from '../../common/utils/PreferencesUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const DOMAIN = 0x2000; // Login API domain

/**
 * 登录API服务类
 * 提供用户认证相关的API接口
 */
export class LoginApiService {
  private static instance: LoginApiService;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  public static getInstance(): LoginApiService {
    if (!LoginApiService.instance) {
      LoginApiService.instance = new LoginApiService();
    }
    return LoginApiService.instance;
  }

  /**
   * 用户登录
   * @param loginForm 登录表单数据（包含明文密码）
   * @param context 应用上下文（用于首选项存储）
   * @returns Promise<LoginResponse> 登录结果，包含token
   */
  public async login(loginForm: LoginForm, context?: common.UIAbilityContext): Promise<LoginResponse> {
    try {
      hilog.info(DOMAIN, 'LoginApi', `🔐 [Login] 开始登录: ${loginForm.username}`);

      // 1. RSA加密密码
      const encryptedPassword = await this.encryptPassword(loginForm.password);

      // 2. 构建请求参数
      const loginRequest: LoginRequest = {
        username: loginForm.username,
        password: encryptedPassword
      };

      hilog.info(DOMAIN, 'LoginApi', '🔐 [Login] 密码加密完成，发送登录请求');

      // 3. 发送登录请求
      // 使用专门的postLogin方法处理登录接口的特殊响应格式
      const response: LoginResponse = await this.httpService.postLogin<LoginRequest, LoginResponse>(
        '/login',
        loginRequest
      );

      hilog.info(DOMAIN, 'LoginApi', `📥 [Login] 收到响应: ${JSON.stringify(response)}`);

      // 4. 检查响应状态
      if (response.code === 200 && response.token) {
        hilog.info(DOMAIN, 'LoginApi', '✅ [Login] 登录成功');

        // 5. 保存token到AppStorage
        AppStorage.setOrCreate('token', response.token);
        hilog.info(DOMAIN, 'LoginApi', '💾 [Login] Token已保存到AppStorage');

        // 6. 将token持久化到首选项
        if (context) {
          try {
            const preferencesUtil = PreferencesUtil.getInstance();
            preferencesUtil.putValue(context, 'token', response.token);
            hilog.info(DOMAIN, 'LoginApi', '💾 [Login] Token已持久化到首选项');
          } catch (error) {
            hilog.error(DOMAIN, 'LoginApi', `⚠️ [Login] Token持久化失败: ${JSON.stringify(error)}`);
            // 不影响登录流程，继续执行
          }
        } else {
          hilog.warn(DOMAIN, 'LoginApi', '⚠️ [Login] 未提供context，Token未持久化');
        }

        return response;
      } else {
        const errorMsg = response.msg || '登录失败';
        hilog.error(DOMAIN, 'LoginApi', `❌ [Login] 登录失败: ${errorMsg}`);
        throw new Error(errorMsg);
      }
    } catch (error) {
      hilog.error(DOMAIN, 'LoginApi', `💥 [Login] 登录异常: ${JSON.stringify(error)}`);

      // 统一错误处理
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('登录过程中发生未知错误');
      }
    }
  }

  /**
   * 检查是否已登录（是否有有效token）
   * @returns boolean 是否已登录
   */
  public isLoggedIn(): boolean {
    const token = AppStorage.get<string>('token');
    const hasToken = !!(token && token.trim().length > 0);

    hilog.info(DOMAIN, 'LoginApi', `🔍 [Token] 检查登录状态: ${hasToken ? '已登录' : '未登录'}`);
    return hasToken;
  }

  /**
   * 用户退出登录
   * @param context 应用上下文（用于首选项存储）
   */
  public logout(context?: Context): void {
    hilog.info(DOMAIN, 'LoginApi', '🚪 [Logout] 用户退出登录');

    // 清除AppStorage中的token
    AppStorage.setOrCreate('token', '');
    hilog.info(DOMAIN, 'LoginApi', '🗑️ [Logout] AppStorage中的Token已清除');

    // 清除首选项中的token
    if (context) {
      try {
        const preferencesUtil = PreferencesUtil.getInstance();
        preferencesUtil.removeValue(context, 'token');
        hilog.info(DOMAIN, 'LoginApi', '🗑️ [Logout] 首选项中的Token已清除');
      } catch (error) {
        hilog.error(DOMAIN, 'LoginApi', `⚠️ [Logout] 清除首选项Token失败: ${JSON.stringify(error)}`);
      }
    } else {
      hilog.warn(DOMAIN, 'LoginApi', '⚠️ [Logout] 未提供context，首选项Token未清除');
    }
  }

  /**
   * 获取当前token
   * @returns string | undefined 当前token
   */
  public getCurrentToken(): string | undefined {
    return AppStorage.get<string>('token');
  }

  /**
   * RSA加密密码
   * @param plainPassword 明文密码
   * @returns Promise<string> 加密后的密码
   * @private
   */
  private async encryptPassword(plainPassword: string): Promise<string> {
    try {
      hilog.info(DOMAIN, 'LoginApi', '🔒 [Encrypt] 开始加密密码');

      const encryptedPassword = await RsaPkcs1Util.encrypt(RSA_PUBLIC_KEY, plainPassword);

      hilog.info(DOMAIN, 'LoginApi', '🔒 [Encrypt] 密码加密成功');
      return encryptedPassword;
    } catch (error) {
      hilog.error(DOMAIN, 'LoginApi', `💥 [Encrypt] 密码加密失败: ${JSON.stringify(error)}`);
      throw new Error('密码加密失败，请重试');
    }
  }
}