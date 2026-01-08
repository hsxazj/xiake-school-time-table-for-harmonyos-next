import axios, { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { API_CONFIG } from '../../common/constants/AppConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';


const DOMAIN = 0x1000; // App Config domain
const TAG = 'HttpService'; // 树洞功能启用状态存储键


export interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

// 扩展配置接口以包含自定义属性
interface CustomAxiosRequestConfig extends InternalAxiosRequestConfig {
  metadata?: RequestMetadata;
}

// 请求元数据接口
interface RequestMetadata {
  startTime: number;
}

// 错误响应数据接口
interface ErrorResponseData {
  message?: string;
  code?: number;
}

// 网络错误响应接口
interface NetworkErrorResponse {
  status?: number;
  data?: ErrorResponseData;
}

// 扩展 Error 接口以包含网络错误信息
interface NetworkErrorInfo extends Error {
  code?: string | number;
  response?: NetworkErrorResponse;
  request?: object;
  originalError?: AxiosError;
}

// 解析后的错误信息接口
interface ParsedErrorInfo {
  code?: number;
  message?: string;
}

// 请求配置接口
interface RequestConfig {
  method: string;
  url: string;
  data?: Record<string, Object>;
  headers?: Record<string, string>;
}

export class HttpService {
  private static instance: HttpService;
  private axiosInstance: AxiosInstance;

  private constructor() {
    // 创建axios实例
    this.axiosInstance = axios.create({
      baseURL: API_CONFIG.BASE_URL,
      timeout: API_CONFIG.TIMEOUT,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // 设置拦截器
    this.setupInterceptors();
  }

  public static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  /**
   * GET请求
   */
  public async get<REQ, RES>(url: string, params?: REQ): Promise<ApiResponse<RES>> {
    try {
      const response: AxiosResponse<ApiResponse<RES>> = await this.axiosInstance.get<ApiResponse<RES>>(url, { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * POST请求
   */
  public async post<REQ, RES>(
    url: string,
    data?: REQ
  ): Promise<ApiResponse<RES>> {
    try {
      const response: AxiosResponse<ApiResponse<RES>> = await this.axiosInstance.post<ApiResponse<RES>>(url, data);
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * PUT请求
   */
  public async put<REQ, RES>(
    url: string,
    data?: REQ
  ): Promise<ApiResponse<RES>> {
    try {
      const response: AxiosResponse<ApiResponse<RES>> = await this.axiosInstance.put<ApiResponse<RES>>(url, data);
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * DELETE请求
   */
  public async delete<REQ, RES>(url: string, params?: REQ): Promise<ApiResponse<RES>> {
    try {
      const response: AxiosResponse<ApiResponse<RES>> =
        await this.axiosInstance.delete<ApiResponse<RES>>(url, { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * 直接GET请求 - 用于特殊接口，不包装在ApiResponse中
   * 适用于像/getInfo这样直接返回完整数据的接口
   */
  public async getDirect<RES>(url: string): Promise<RES> {
    try {
      const response: AxiosResponse<RES> = await this.axiosInstance.get<RES>(url);
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * 通用请求方法 (保持向后兼容)
   */
  public async request<T>(
    method: string,
    url: string,
    data?: Record<string, Object>,
    includeToken: boolean = false
  ): Promise<ApiResponse<T>> {
    try {
      const config: RequestConfig = {
        method: method.toLowerCase(),
        url,
        data: data || {}
      };

      // 如果需要token但没有设置，手动添加
      if (includeToken) {
        const token = AppStorage.get<string>('token');
        if (token) {
          const headers: Record<string, string> = { 'authorization': token };
          config.headers = headers;
        }
      }

      const response: AxiosResponse<ApiResponse<T>> = await this.axiosInstance.request<ApiResponse<T>>(config);
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * 设置默认请求头
   */
  public setDefaultHeader(key: string, value: string): void {
    this.axiosInstance.defaults.headers.common[key] = value;
    hilog.info(DOMAIN,TAG,`🔧 [Header] Set default header: ${key}=${value}`);
  }

  /**
   * 移除默认请求头
   */
  public removeDefaultHeader(key: string): void {
    // ArkTS中使用undefined赋值替代delete操作
    this.axiosInstance.defaults.headers.common[key] = undefined;
    hilog.info(DOMAIN,TAG,`🗑️ [Header] Removed default header: ${key}`);
  }

  /**
   * 获取axios实例（用于高级用法）
   */
  public getAxiosInstance(): AxiosInstance {
    return this.axiosInstance;
  }

  /**
   * 登录专用POST请求 - 直接返回响应数据，不包装在ApiResponse中
   * 用于处理登录接口返回格式与标准ApiResponse不同的情况
   */
  public async postLogin<REQ, RES>(url: string, data?: REQ): Promise<RES> {
    try {
      const response: AxiosResponse<RES> = await this.axiosInstance.post<RES>(url, data);
      return response.data;
    } catch (error) {
      throw this.handleError(error as AxiosError);
    }
  }

  /**
   * 设置请求和响应拦截器
   */
  private setupInterceptors(): void {
    // 请求拦截器
    this.axiosInstance.interceptors.request.use(
      (config: InternalAxiosRequestConfig) => {
        // 添加请求开始时间
        const customConfig = config as CustomAxiosRequestConfig;
        const metadata: RequestMetadata = { startTime: Date.now() };
        customConfig.metadata = metadata;

        // 添加认证token
        const token = AppStorage.get<string>('token');
        if (token && config.headers) {
          config.headers['authorization'] = token;
        }

        // 打印请求日志
        hilog.info(DOMAIN,TAG,`[HTTP Request] ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`);
        if (config.data) {
          hilog.info(DOMAIN,TAG,`[Request Data]`, JSON.stringify(config.data));
        }
        if (config.params) {
          hilog.info(DOMAIN,TAG,`[Request Params]`, JSON.stringify(config.params));
        }
        hilog.info(DOMAIN,TAG,`[Request Time] ${new Date().toLocaleTimeString()}`);

        return config;
      },
      (error: AxiosError) => {
        console.error('[Request Error]', JSON.stringify(error));
        return Promise.reject(error);
      }
    );

    // 响应拦截器
    this.axiosInstance.interceptors.response.use(
      (response: AxiosResponse) => {
        // 打印响应日志
        const config = response.config as CustomAxiosRequestConfig;
        const duration = config.metadata?.startTime ? Date.now() - config.metadata.startTime : 0;

        hilog.info(DOMAIN,TAG,`[HTTP Response] ${response.status} ${config.method?.toUpperCase()} ${response.config.url}`);
        hilog.info(DOMAIN,TAG,`[Response Data]`, JSON.stringify(response.data));
        hilog.info(DOMAIN,TAG,`[Response Time] ${duration}ms`);
        hilog.info(DOMAIN,TAG,`[Response Size] ${JSON.stringify(response.data).length} bytes`);

        return response;
      },
      (error: AxiosError) => {
        // 打印错误日志
        const config = error.config as CustomAxiosRequestConfig;
        const duration = config?.metadata?.startTime ? Date.now() - config.metadata.startTime : 0;

        console.error(`[HTTP Error] ${error.response?.status || 'Network Error'} ${config?.method?.toUpperCase() ||
          'UNKNOWN'} ${config?.url || 'UNKNOWN'}`);
        console.error(`[Error Message] ${error.message}`);
        console.error(`⏱[Error Time] ${duration}ms`);

        if (error.response?.data) {
          console.error(`[Error Response]`, JSON.stringify(error.response.data));
        }

        // 统一错误处理
        if (error.response?.status === 401) {
          // Token过期，清除本地token
          AppStorage.setOrCreate('token', '');
          console.warn('[Auth] Token expired, cleared from storage');
        }

        return Promise.reject(error);
      }
    );
  }

  /**
   * 错误处理 - 创建 Error 对象并附加网络错误信息用于缓存降级判断
   */
  private handleError(error: AxiosError): Error {
    let errorMessage = '网络请求失败';

    // 创建自定义错误对象
    const networkError = new Error(errorMessage) as NetworkErrorInfo;

    // 附加 AxiosError 的关键信息
    networkError.originalError = error;
    networkError.code = error.code;
    networkError.request = error.request;

    if (error.response) {
      // 服务器响应错误
      const status = error.response.status;
      const data = error.response.data as ErrorResponseData;

      const errorResponse: NetworkErrorResponse = {
        status: status,
        data: data
      };
      networkError.response = errorResponse;

      switch (status) {
        case 400:
          errorMessage = data?.message || '请求参数错误';
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
          errorMessage = data?.message || `请求失败 (${status})`;
      }
    } else if (error.request) {
      // 网络错误 - 尝试提取 HarmonyOS 错误信息
      if (error.message) {
        try {
          // HarmonyOS 可能将错误序列化为 JSON
          if (error.message.startsWith('{')) {
            const parsedError: ParsedErrorInfo = JSON.parse(error.message) as ParsedErrorInfo;
            if (parsedError.code) {
              networkError.code = parsedError.code;
              errorMessage = parsedError.message || '网络连接失败';
            }
          } else {
            errorMessage = error.message;
          }
        } catch (parseError) {
          errorMessage = '网络连接失败，请检查网络设置';
        }
      } else {
        errorMessage = '网络连接失败，请检查网络设置';
      }
    } else {
      // 其他错误
      errorMessage = error.message || '未知错误';
    }

    // 更新错误消息
    networkError.message = errorMessage;

    console.error('[Error Handler]', errorMessage);
    console.error('[Error Code]', networkError.code);

    // 返回附加了网络信息的 Error 对象
    return networkError;
  }
}