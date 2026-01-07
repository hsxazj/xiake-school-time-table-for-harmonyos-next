/**
 * 教务系统 HTTP 服务
 *
 * 参考: dev-doc/jwxt/http.ts 和 dev-doc/jwxt/client.ts
 * 用于直接调用福建工程学院教务系统接口
 *
 * @author AI Refactor
 * @date 2026-01-07
 */

import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'JwxtHttpService';

/**
 * 教务系统配置
 */
export interface JwxtConfig {
  baseURL: string;      // 教务系统基础 URL
  timeout: number;      // 超时时间 (ms)
}

/**
 * 请求配置接口
 */
interface RequestConfig {
  params?: Record<string, string | number>;
  headers?: Record<string, string>;
}

/**
 * 教务系统 HTTP 服务类
 *
 * 功能:
 * - 封装教务系统接口调用
 * - Cookie 管理 (用于会话保持)
 * - 请求/响应日志记录
 * - 错误处理
 */
export class JwxtHttpService {
  private static instance: JwxtHttpService;
  private axiosInstance: AxiosInstance;
  private config: JwxtConfig;

  private constructor() {
    // 默认配置
    this.config = {
      baseURL: 'https://jwxtwx.fjut.edu.cn/jwglxt/',  // 福建工程学院教务系统
      timeout: 15000
    };

    // 创建 axios 实例
    this.axiosInstance = axios.create({
      baseURL: this.config.baseURL,
      timeout: this.config.timeout,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      }
    });
  }

  /**
   * 获取单例
   */
  public static getInstance(): JwxtHttpService {
    if (!JwxtHttpService.instance) {
      JwxtHttpService.instance = new JwxtHttpService();
    }
    return JwxtHttpService.instance;
  }

  /**
   * 设置教务系统配置
   */
  public setConfig(config: Partial<JwxtConfig>): void {
    if (config.baseURL) {
      this.config.baseURL = config.baseURL;
      this.axiosInstance.defaults.baseURL = config.baseURL;
    }
    if (config.timeout) {
      this.config.timeout = config.timeout;
      this.axiosInstance.defaults.timeout = config.timeout;
    }
  }

  /**
   * GET 请求
   */
  public async get<T>(url: string, params?: Record<string, string | number>, referer?: string): Promise<T> {
    try {
      hilog.info(DOMAIN, TAG, `[JWXT GET] ${url}`);

      const config: RequestConfig = {
        params: params
      };

      if (referer) {
        config.headers = {
          'Referer': `${this.config.baseURL}${referer}`
        };
      }

      const response: AxiosResponse<T> = await this.axiosInstance.get(url, config);

      // 📊 日志: 打印 GET 响应
      hilog.info(DOMAIN, TAG, `[GET Response] status=${response.status}, data type=${typeof response.data}`);

      return response.data;
    } catch (error) {
      const errMsg = `GET ${url} 失败: ${error}`;
      hilog.error(DOMAIN, TAG, errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * POST Form 请求 (application/x-www-form-urlencoded)
   */
  public async postForm<T>(
    url: string,
    data: Record<string, string | number>,
    referer?: string
  ): Promise<T> {
    try {
      hilog.info(DOMAIN, TAG, `[JWXT POST] ${url}`);

      // 手动构造 form data 字符串
      const formPairs: string[] = [];
      Object.keys(data).forEach((key: string) => {
        const value: string = String(data[key]);
        formPairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
      });
      const formData: string = formPairs.join('&');

      const headers: Record<string, string> = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };

      if (referer) {
        headers['Referer'] = `${this.config.baseURL}${referer}`;
      }

      const config: RequestConfig = {
        headers: headers
      };

      const response: AxiosResponse<T> = await this.axiosInstance.post(url, formData, config);

      // 📊 日志: 打印 POST 响应
      hilog.info(DOMAIN, TAG, `[POST Response] status=${response.status}, data type=${typeof response.data}`);

      return response.data;
    } catch (error) {
      const errMsg = `POST ${url} 失败: ${error}`;
      hilog.error(DOMAIN, TAG, errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * 获取文本内容 (用于获取 HTML 页面)
   */
  public async getText(url: string, referer?: string): Promise<string> {
    try {
      hilog.info(DOMAIN, TAG, `[JWXT GET TEXT] ${url}`);

      const headers: Record<string, string> = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
      };

      if (referer) {
        headers['Referer'] = `${this.config.baseURL}${referer}`;
      }

      const config: RequestConfig = {
        headers: headers
      };

      const response: AxiosResponse<string> = await this.axiosInstance.get(url, config);

      // 📊 日志: 打印 TEXT 响应
      hilog.info(DOMAIN, TAG, `[getText Response] status=${response.status}, length=${response.data.length}`);

      return response.data;
    } catch (error) {
      const errMsg = `GET TEXT ${url} 失败: ${error}`;
      hilog.error(DOMAIN, TAG, errMsg);
      throw new Error(errMsg);
    }
  }
}
