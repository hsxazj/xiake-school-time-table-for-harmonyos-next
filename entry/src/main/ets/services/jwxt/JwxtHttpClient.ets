/**
 * JWXT教务系统HTTP客户端
 *
 * 用途：
 * - 创建独立的axios实例
 * - 手动管理Cookie（HarmonyOS环境中axios不会自动管理Cookie）
 * - 提供GET、POST、POST表单、GET HTML等请求方法
 * - 统一错误处理和日志记录
 *
 * Cookie管理机制：
 * 1. 响应拦截器：提取Set-Cookie响应头，保存到CookieManager
 * 2. 请求拦截器：从CookieManager读取Cookie，添加到Cookie请求头
 *
 * 使用方法：
 * ```typescript
 * const client = JwxtHttpClient.getInstance();
 * await client.initialize(context);  // 初始化Cookie存储
 * const html = await client.getHtml('xtgl/login_slogin.html');
 * ```
 *
 * @since 2026-01-07
 */
import axios, { AxiosInstance, AxiosResponse, AxiosError, InternalAxiosRequestConfig, AxiosRequestHeaders } from '@ohos/axios';
import { JwxtConstants } from './JwxtConstants';
import { CookieManager } from './CookieManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { url } from '@kit.ArkTS';

const DOMAIN: number = 0x3000; // JWXT HTTP domain
const TAG: string = 'JwxtHttpClient';

/**
 * JWXT HTTP客户端类
 * 单例模式
 */
export class JwxtHttpClient {
  private static instance: JwxtHttpClient;
  private axiosInstance: AxiosInstance;
  private cookieManager: CookieManager;
  private isInitialized: boolean = false;

  private constructor() {
    // 创建axios实例
    this.axiosInstance = axios.create({
      baseURL: JwxtConstants.BASE_URL,
      timeout: JwxtConstants.TIMEOUT,
      // ⚠️ 移除 withCredentials: true，在HarmonyOS中无效
      validateStatus: (status: number) => status >= 200 && status < 400
    });

    // 获取CookieManager实例
    this.cookieManager = CookieManager.getInstance();

    hilog.info(DOMAIN, TAG, '✅ JwxtHttpClient初始化完成，BASE_URL: %{public}s', JwxtConstants.BASE_URL);
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtHttpClient {
    if (!JwxtHttpClient.instance) {
      JwxtHttpClient.instance = new JwxtHttpClient();
    }
    return JwxtHttpClient.instance;
  }

  /**
   * 初始化Cookie存储
   * 必须在使用前调用一次
   *
   * @param context 应用上下文
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      hilog.info(DOMAIN, TAG, '⚠️ 已初始化，跳过重复初始化');
      return;
    }

    try {
      // 初始化CookieManager
      await this.cookieManager.initialize(context);

      // 设置拦截器（依赖CookieManager）
      this.setupInterceptors();

      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, '✅ JwxtHttpClient完整初始化完成（含Cookie管理）');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', JSON.stringify(error));
      throw new Error('JwxtHttpClient初始化失败');
    }
  }

  /**
   * GET请求（返回JSON）
   *
   * @param url 相对路径（相对于BASE_URL）
   * @param referer 引用页（用于CSRF防护）
   * @returns Promise<T>
   */
  public async get<T>(url: string, referer?: string): Promise<T> {
    try {
      const headers: Record<string, string> = {
        'User-Agent': JwxtConstants.USER_AGENT,
        'Accept': JwxtConstants.HEADERS.ACCEPT_JSON
      };

      if (referer) {
        headers['Referer'] = this.makeReferer(referer);
      }

      const response: AxiosResponse<T> = await this.axiosInstance.get<T>(url, { headers });
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError, 'GET', url);
    }
  }

  /**
   * POST表单请求
   *
   * @param url 相对路径
   * @param form url.URLSearchParams表单数据
   * @param referer 引用页
   * @returns Promise<T>
   */
  public async postForm<T>(url: string, form: url.URLSearchParams, referer?: string): Promise<T> {
    try {
      const headers: AxiosRequestHeaders = {} as AxiosRequestHeaders;
      headers['User-Agent'] = JwxtConstants.USER_AGENT;
      headers['Accept'] = JwxtConstants.HEADERS.ACCEPT_JSON;
      headers['Content-Type'] = JwxtConstants.HEADERS.CONTENT_TYPE_FORM;
      headers['X-Requested-With'] = JwxtConstants.HEADERS.X_REQUESTED_WITH;

      if (referer) {
        headers['Referer'] = this.makeReferer(referer);
      }

      const response: AxiosResponse<T> = await this.axiosInstance.post<T>(url, form.toString(), { headers });
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError, 'POST_FORM', url);
    }
  }

  /**
   * GET HTML页面
   *
   * @param url 相对路径
   * @param referer 引用页
   * @returns Promise<string> HTML内容
   */
  public async getHtml(url: string, referer?: string): Promise<string> {
    try {
      const headers: Record<string, string> = {
        'User-Agent': JwxtConstants.USER_AGENT,
        'Accept': JwxtConstants.HEADERS.ACCEPT_HTML
      };

      if (referer) {
        headers['Referer'] = this.makeReferer(referer);
      }

      const response: AxiosResponse<string> = await this.axiosInstance.get<string>(url, { headers });
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError, 'GET_HTML', url);
    }
  }

  /**
   * POST请求（用于logout等）
   *
   * @param url 相对路径
   * @param referer 引用页
   * @returns Promise<void>
   */
  public async post(url: string, referer?: string): Promise<void> {
    try {
      const headers: AxiosRequestHeaders = {} as AxiosRequestHeaders;
      headers['User-Agent'] = JwxtConstants.USER_AGENT;

      if (referer) {
        headers['Referer'] = this.makeReferer(referer);
      }

      await this.axiosInstance.post(url, '', { headers });
    } catch (error) {
      throw this.handleError(error as AxiosError, 'POST', url);
    }
  }

  /**
   * 设置请求和响应拦截器
   * ⚠️ 必须在initialize()之后调用，因为依赖CookieManager
   */
  private setupInterceptors(): void {
    // 请求拦截器 - 自动添加Cookie
    this.axiosInstance.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        // 提取域名
        const fullUrl = config.baseURL + (config.url || '');
        const host = this.cookieManager.extractHostFromUrl(fullUrl);

        hilog.info(DOMAIN, TAG, '🔍 [Request] 完整URL: %{public}s', fullUrl);
        hilog.info(DOMAIN, TAG, '🔍 [Request] 提取的域名: %{public}s', host);

        if (host) {
          // 从CookieManager获取Cookie
          const cookieStr = await this.cookieManager.getCookie();

          if (cookieStr) {
            // 添加到请求头
            if (!config.headers) {
              config.headers = {} as AxiosRequestHeaders;
            }
            config.headers['Cookie'] = cookieStr;
            hilog.info(DOMAIN, TAG, '🍪 [Request] 已添加Cookie到请求头: %{public}s', host);
            hilog.info(DOMAIN, TAG, '🍪 [Request] Cookie内容: %{public}s', cookieStr);
          } else {
            hilog.warn(DOMAIN, TAG, '⚠️ [Request] 未获取到Cookie: %{public}s', host);
          }
        } else {
          hilog.warn(DOMAIN, TAG, '⚠️ [Request] 无法提取域名: %{public}s', fullUrl);
        }

        hilog.info(DOMAIN, TAG, '🚀 [Request] %{public}s %{public}s', config.method?.toUpperCase(), config.url);
        return config;
      },
      (error: AxiosError) => {
        hilog.error(DOMAIN, TAG, '❌ [Request Error] %{public}s', JSON.stringify(error));
        return Promise.reject(error);
      }
    );

    // 响应拦截器 - 自动保存Cookie
    this.axiosInstance.interceptors.response.use(
      async (response: AxiosResponse) => {
        // 提取Set-Cookie响应头
        const setCookie = response.headers['set-cookie'];

        if (setCookie) {
          // 提取域名
          const fullUrl = response.config.baseURL + (response.config.url || '');
          const host = this.cookieManager.extractHostFromUrl(fullUrl);

          if (host) {
            // 保存到CookieManager
            await this.cookieManager.saveCookie(host, setCookie);
            hilog.info(DOMAIN, TAG, '🍪 [Response] Cookie已保存: %{public}s', host);
          }
        }

        hilog.info(DOMAIN, TAG, '✅ [Response] %{public}d %{public}s', response.status, response.config.url);
        return response;
      },
      (error: AxiosError) => {
        hilog.error(DOMAIN, TAG, '❌ [Response Error] %{public}s %{public}s',
          error.response?.status || 'Network Error', error.config?.url || 'UNKNOWN');
        return Promise.reject(error);
      }
    );

    hilog.info(DOMAIN, TAG, '✅ Cookie拦截器已设置');
  }

  /**
   * 生成完整的Referer URL
   *
   * @param pathOrReferer 相对路径或完整URL
   * @returns 完整的Referer URL
   */
  private makeReferer(pathOrReferer: string): string {
    if (pathOrReferer.startsWith('http')) {
      return pathOrReferer;
    }
    const path = pathOrReferer.startsWith('/') ? pathOrReferer.slice(1) : pathOrReferer;
    return JwxtConstants.BASE_URL + path;
  }

  /**
   * 统一错误处理
   *
   * @param error AxiosError对象
   * @param method 请求方法
   * @param url 请求URL
   * @returns Error对象
   */
  private handleError(error: AxiosError, method: string, url: string): Error {
    let errorMessage = '网络请求失败';

    if (error.response) {
      // 服务器响应错误
      const status = error.response.status;
      switch (status) {
        case 400:
          errorMessage = '请求参数错误';
          break;
        case 401:
          errorMessage = '未授权，请重新登录';
          break;
        case 403:
          errorMessage = '禁止访问';
          break;
        case 404:
          errorMessage = '请求的资源不存在';
          break;
        case 500:
          errorMessage = '服务器内部错误';
          break;
        default:
          errorMessage = `请求失败 (${status})`;
      }
    } else if (error.request) {
      // 网络错误
      errorMessage = '网络连接失败，请检查网络设置';
    } else {
      // 其他错误
      errorMessage = error.message || '未知错误';
    }

    hilog.error(DOMAIN, TAG, '💥 [Error] %{public}s %{public}s: %{public}s', method, url, errorMessage);

    return new Error(errorMessage);
  }
}
