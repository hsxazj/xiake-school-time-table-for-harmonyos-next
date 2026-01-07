/**
 * JWXT教务系统常量配置
 *
 * 用途：
 * - 定义教务系统的BASE_URL（独立于全局API配置）
 * - 定义User-Agent和请求头常量
 * - 定义API路径常量
 *
 * @since 2026-01-07
 */

/**
 * API路径接口
 */
export interface ApiPaths {
  LOGIN_PAGE: string;
  PUBLIC_KEY: string;
  LOGOUT: string;
  INDEX: string;
  COURSE_PAGE: string;
  COURSE_API: string;
}

/**
 * 请求头接口
 */
export interface RequestHeaders {
  ACCEPT_JSON: string;
  ACCEPT_HTML: string;
  CONTENT_TYPE_FORM: string;
  X_REQUESTED_WITH: string;
}

export class JwxtConstants {
  /**
   * 教务系统基础URL
   * 福建工程学院教务系统移动端地址
   */
  static readonly BASE_URL: string = 'https://jwxtwx.fjut.edu.cn/jwglxt/';

  /**
   * 请求超时时间（毫秒）
   */
  static readonly TIMEOUT: number = 15000;

  /**
   * 模拟浏览器的User-Agent
   * 用于防止教务系统识别为非浏览器请求
   */
  static readonly USER_AGENT: string =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36';

  /**
   * API路径常量
   * 相对于BASE_URL的路径
   */
  static readonly API_PATHS: ApiPaths = {
    /** 登录页面 */
    LOGIN_PAGE: 'xtgl/login_slogin.html',
    /** 获取RSA公钥 */
    PUBLIC_KEY: 'xtgl/login_getPublicKey.html',
    /** 登出接口 */
    LOGOUT: 'logout',
    /** 主页索引 */
    INDEX: 'xtgl/index_initMenu.html',
    /** 课程查询页面 */
    COURSE_PAGE: 'kbcx/xskbcx_cxXsKb.html',
    /** 课程查询接口 */
    COURSE_API: 'kbcx/xskbcx_cxXsgrkb.html'
  };

  /**
   * 请求头常量
   */
  static readonly HEADERS: RequestHeaders = {
    /** JSON请求Accept */
    ACCEPT_JSON: 'application/json, text/javascript, */*; q=0.01',
    /** HTML请求Accept */
    ACCEPT_HTML: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
    /** 表单Content-Type */
    CONTENT_TYPE_FORM: 'application/x-www-form-urlencoded;charset=UTF-8',
    /** AJAX请求标识 */
    X_REQUESTED_WITH: 'XMLHttpRequest'
  };
}
