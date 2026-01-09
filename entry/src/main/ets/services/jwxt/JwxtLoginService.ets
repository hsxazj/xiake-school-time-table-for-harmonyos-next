/**
 * JWXT登录服务
 *
 * 用途：
 * - 实现完整的7步登录流程
 * - 调用JwxtLogoutService、JwxtHttpClient、JwxtCredentialsManager
 * - RSA密码加密
 * - 错误处理和日志记录
 *
 * 登录流程：
 * 1. 获取凭证
 * 2. logout清空旧Cookie
 * 3. 获取登录页HTML，提取csrftoken
 * 4. 获取RSA公钥
 * 5. 加密密码
 * 6. 构造表单
 * 7. 提交登录请求并验证结果
 *
 * 使用方法：
 * ```typescript
 * const loginService = JwxtLoginService.getInstance();
 * await loginService.login(context);
 * ```
 *
 * @since 2026-01-07
 */
import { JwxtHttpClient } from './JwxtHttpClient';
import { JwxtCredentialsManager } from './JwxtCredentialsManager';
import { JwxtConstants } from './JwxtConstants';
import { CookieManager } from './CookieManager';
import { buildRsaSpki, detectRsaKeySize } from './RsaSpki';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';
import { url } from '@kit.ArkTS';
import { GlobalContext } from '../../common/utils/GlobalContext';

const DOMAIN: number = 0x3003; // JWXT Login domain
const TAG: string = 'JwxtLoginService';

/**
 * RSA公钥接口
 * 教务系统返回的公钥格式
 */
interface JwxtPublicKey {
  /** RSA模数（Base64编码） */
  modulus: string;

  /** RSA指数（Base64编码） */
  exponent: string;
}

/**
 * JWXT登录服务类
 * 单例模式
 */
export class JwxtLoginService {
  private static instance: JwxtLoginService;
  private httpClient: JwxtHttpClient;
  private credentialsManager: JwxtCredentialsManager;
  private cookieManager: CookieManager;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
    this.credentialsManager = JwxtCredentialsManager.getInstance();
    this.cookieManager = CookieManager.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtLoginService初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtLoginService {
    if (!JwxtLoginService.instance) {
      JwxtLoginService.instance = new JwxtLoginService();
    }
    return JwxtLoginService.instance;
  }

  /**
   * 登录教务系统
   *
   * 流程: 清空旧Cookie → 初始化Cookie管理 → 获取CSRF → 获取公钥 → 加密密码 → 提交表单
   *
   * @param context 应用上下文（用于获取凭证和初始化Cookie存储）
   * @throws Error 登录失败时抛出异常
   */
  public async login(context: Context | undefined): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '🔐 [Login] 开始登录教务系统...');

      // 步骤0: 清空旧Cookie，确保使用全新会话
      await this.cookieManager.clearAllCookies();
      hilog.info(DOMAIN, TAG, '🗑️ [Login] 步骤0: 已清空旧Cookie');

      // 步骤1: 初始化HttpClient的Cookie管理（必须在任何请求前调用）
      await this.httpClient.initialize(context);
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤1: Cookie管理已初始化');

      // 步骤2: 获取凭证
      const credentials = this.credentialsManager.getCredentials(context);
      if (!credentials) {
        throw new Error('请先设置学号和密码');
      }
      const sid = credentials.sid;
      const password = credentials.password;
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤2: 凭证获取成功');

      // 步骤3: 获取登录页HTML，提取csrftoken
      const html = await this.httpClient.getHtml(
        JwxtConstants.API_PATHS.LOGIN_PAGE,
        JwxtConstants.API_PATHS.LOGIN_PAGE
      );
      const csrfToken = this.extractCsrfToken(html);
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤3: csrftoken提取成功');

      // 步骤4: 获取RSA公钥
      const pubkey = await this.httpClient.get<JwxtPublicKey>(
        JwxtConstants.API_PATHS.PUBLIC_KEY,
        JwxtConstants.API_PATHS.LOGIN_PAGE
      );
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤4: RSA公钥获取成功');

      // 步骤5: RSA加密密码
      const encrypted = await this.encryptPassword(
        password,
        pubkey.modulus,
        pubkey.exponent
      );
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤5: 密码加密成功');

      // 步骤6: 构造表单
      const form: url.URLSearchParams = new url.URLSearchParams();
      form.append('csrftoken', csrfToken);
      form.append('yhm', sid); // 用户名（学号）
      form.append('mm', encrypted); // 加密后的密码
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤6: 表单构造完成');

      // 步骤7: 提交登录请求
      const resp = await this.httpClient.postForm<string>(
        JwxtConstants.API_PATHS.LOGIN_PAGE,
        form,
        JwxtConstants.API_PATHS.LOGIN_PAGE
      );
      hilog.info(DOMAIN, TAG, '✅ [Login] 步骤7: 登录请求已提交');

      // 步骤8: 验证登录结果
      this.validateLoginResponse(resp);

      hilog.info(DOMAIN, TAG, '🎉 [Login] 登录成功！Cookie已自动保存');

      const uiCtx = GlobalContext.getInstance().getObject('UIContext') as UIContext;
      if (uiCtx) {
        uiCtx.getPromptAction().showToast({ message: '已连接至教务系统', duration: 1500 });
      }

    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Login] 登录失败: %{public}s', JSON.stringify(error));

      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('登录过程中发生未知错误');
      }
    }
  }

  /**
   * 从HTML中提取csrftoken
   *
   * 正则表达式匹配: id="csrftoken" ... value="xxx"
   *
   * @param html 登录页HTML
   * @returns string csrftoken值
   * @throws Error 提取失败时抛出异常
   */
  private extractCsrfToken(html: string): string {
    try {
      // 匹配 id="csrftoken" 或 id='csrftoken' 标签中的 value 属性
      const regex = /id=["']csrftoken["'][^>]*value=["']([^"']+)["']/i;
      const match = html.match(regex);

      if (match && match[1]) {
        const token = match[1];
        hilog.info(DOMAIN, TAG, '✅ [CSRF] csrftoken提取成功，长度: %{public}d', token.length);
        return token;
      }

      throw new Error('未能从HTML中提取csrftoken');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [CSRF] csrftoken提取失败: %{public}s', JSON.stringify(error));
      throw new Error('提取csrftoken失败');
    }
  }

  /**
   * 使用RSA公钥加密密码
   *
   * 流程：
   * 1. 解码 Base64 的 modulus 和 exponent 为 Uint8Array
   * 2. 使用官方 Asn1BerWriter 构造 X.509 SPKI DER 格式
   * 3. 动态判断密钥位长 (RSA1024/RSA2048)
   * 4. 调用 convertKey 生成公钥对象
   * 5. 使用 PKCS#1 填充加密密码
   *
   * @param password 明文密码
   * @param modulus RSA模数（Base64编码）
   * @param exponent RSA指数（Base64编码）
   * @returns Promise<string> Base64编码的加密密文
   * @throws Error 加密失败时抛出异常
   */
  private async encryptPassword(
    password: string,
    modulus: string,
    exponent: string
  ): Promise<string> {
    try {
      hilog.info(DOMAIN, TAG, '🔒 [Encrypt] 开始RSA加密密码...');

      // 步骤1: 解码 Base64 的 modulus 和 exponent 为 Uint8Array
      const nBytes = new Uint8Array(buffer.from(modulus, 'base64').buffer);
      const eBytes = new Uint8Array(buffer.from(exponent, 'base64').buffer);

      hilog.info(DOMAIN, TAG, '🔒 [Encrypt] 公钥参数: n=%{public}d bytes, e=%{public}d bytes',
        nBytes.length, eBytes.length);

      // 步骤2: 使用官方 API 构造 X.509 SPKI DER 格式
      const spkiDer = buildRsaSpki(nBytes, eBytes);

      hilog.info(DOMAIN, TAG, '🔒 [Encrypt] SPKI DER长度: %{public}d bytes', spkiDer.length);

      // 步骤3: 动态判断密钥位长
      const keySize = detectRsaKeySize(nBytes);
      hilog.info(DOMAIN, TAG, '🔒 [Encrypt] 检测到密钥位长: %{public}s', keySize);

      // 步骤4: 创建密钥生成器并转换公钥
      const keyGen = cryptoFramework.createAsyKeyGenerator(keySize);
      const pubKeyBlob: cryptoFramework.DataBlob = { data: spkiDer };
      const keyPair = await keyGen.convertKey(pubKeyBlob, null);

      if (!keyPair.pubKey) {
        throw new Error('公钥生成失败');
      }

      hilog.info(DOMAIN, TAG, '✅ [Encrypt] RSA公钥生成成功');

      // 步骤5: 创建加密器（PKCS#1 填充）
      const cipher = cryptoFramework.createCipher(`${keySize}|PKCS1`);
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPair.pubKey, null);

      // 步骤6: 加密密码
      const plainBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(buffer.from(password, 'utf-8').buffer)
      };
      const cipherBlob = await cipher.doFinal(plainBlob);

      // 步骤7: 返回 Base64 密文
      const encrypted = buffer.from(cipherBlob.data).toString('base64');

      hilog.info(DOMAIN, TAG, '✅ [Encrypt] 密码加密完成，密文长度: %{public}d', encrypted.length);
      return encrypted;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, '❌ [Encrypt] RSA加密失败: %{public}s', errorMsg);
      throw new Error(`密码加密失败: ${errorMsg}`);
    }
  }

  /**
   * 验证登录响应
   *
   * 检查响应中是否包含错误信息
   *
   * @param resp 登录响应（可能是字符串或对象）
   * @throws Error 登录失败时抛出异常
   */
  private validateLoginResponse(resp: string | object): void {
    const respText = typeof resp === 'string' ? resp : JSON.stringify(resp);

    // 检查常见的错误信息
    if (respText.includes('用户名或密码不正确')) {
      throw new Error('用户名或密码错误');
    }
    if (respText.includes('验证码错误')) {
      throw new Error('验证码错误');
    }
    if (respText.includes('用户登录')) {
      throw new Error('登录失败，请稍后重试');
    }

    hilog.info(DOMAIN, TAG, '✅ [Validate] 登录响应验证通过');
  }
}
