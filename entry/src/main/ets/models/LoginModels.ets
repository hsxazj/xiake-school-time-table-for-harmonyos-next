// 登录相关数据模型

/**
 * 登录请求参数接口
 */
export interface LoginRequest {
  /** 用户名/学号 */
  username: string;
  /** RSA加密后的密码 */
  password: string;
}

/**
 * 登录响应数据接口
 */
export interface LoginResponse {
  /** 响应消息 */
  msg: string;
  /** 状态码，200为成功 */
  code: number;
  /** 认证token */
  token: string;
}

/**
 * 登录表单数据接口
 */
export interface LoginForm {
  /** 用户名/学号 */
  username: string;
  /** 明文密码 */
  password: string;
}

/**
 * 登录状态枚举
 */
export enum LoginStatus {
  /** 空闲状态 */
  IDLE = 'idle',
  /** 登录中 */
  LOADING = 'loading',
  /** 登录成功 */
  SUCCESS = 'success',
  /** 登录失败 */
  FAILED = 'failed'
}