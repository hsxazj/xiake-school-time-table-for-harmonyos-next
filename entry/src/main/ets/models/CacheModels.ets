/**
 * 缓存数据包装类型
 * 包含数据本身、缓存时间戳和版本信息
 */
export interface CachedData<T> {
  data: T; // 实际缓存的数据
  cachedAt: number; // 缓存时间戳 (毫秒)
  version: string; // 数据版本 (用于后续缓存失效策略)
}

/**
 * 错误类型枚举
 * 用于区分不同类型的错误,判断是否需要降级到缓存
 */
export enum ErrorType {
  NETWORK_ERROR, // 网络错误/服务器崩溃 (需要降级)
  BUSINESS_ERROR, // 业务错误 (服务器返回200但data.code≠200, 不降级)
  UNKNOWN_ERROR // 未知错误
}

/**
 * 错误信息
 * 包含错误类型和原始错误对象
 */
export interface ErrorInfo {
  type: ErrorType; // 错误类型
  originalError: Error | object; // 原始错误对象
}
