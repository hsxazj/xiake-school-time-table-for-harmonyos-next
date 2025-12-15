import { hilog } from '@kit.PerformanceAnalysisKit';
import { ErrorType } from '../../models/CacheModels';

const DOMAIN: number = 0x0001;
const TAG: string = 'ErrorUtil';

// 定义HTTP响应接口
interface HttpResponse {
  status?: number;
}

// 定义错误对象接口
interface NetworkError {
  code?: string | number;  // 支持字符串和数字类型的错误码
  message?: string;
  response?: HttpResponse;
  request?: object;
}

// 解析后的错误信息接口
interface ParsedErrorInfo {
  code?: number;
  message?: string;
}

/**
 * 错误判断工具类
 * 职责: 区分网络错误和业务错误,判断是否需要降级到缓存
 */
export class ErrorUtil {
  /**
   * 判断是否为网络错误 (需要降级到缓存)
   *
   * 网络错误包括:
   * - 连接失败 (ECONNREFUSED)
   * - 超时 (ETIMEDOUT, ECONNABORTED, code: 2300028)
   * - DNS解析失败 (ENOTFOUND)
   * - 服务器5xx错误 (500, 502, 503, 504等)
   * - 完全没有响应 (网络断开)
   * - HarmonyOS网络错误码 (23xxxxx系列)
   *
   * 不包括:
   * - 业务错误 (服务器返回200但data.code≠200)
   * - 4xx客户端错误 (400, 401, 403, 404等)
   *
   * @param error 错误对象
   * @returns true表示网络错误,需要降级; false表示非网络错误
   */
  public static isNetworkError(error: Error | object | null): boolean {
    if (!error) {
      return false;
    }

    const err = error as NetworkError;

    // 详细调试日志
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] 完整错误对象: ${JSON.stringify(error)}`);
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] error.code 类型: ${typeof err.code}`);
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] error.code 值: ${err.code}`);
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] error.message: ${err.message}`);
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] error.response: ${err.response ? 'exists' : 'null'}`);
    hilog.info(DOMAIN, TAG, `🔍 [DEBUG] error.request: ${err.request ? 'exists' : 'null'}`);

    // 尝试从 error.message 中解析 JSON 格式的错误信息
    if (err.message) {
      try {
        // HarmonyOS 的 axios 可能将底层错误序列化到 message 中
        if (err.message.startsWith('{') && err.message.includes('code')) {
          const parsedError: ParsedErrorInfo = JSON.parse(err.message) as ParsedErrorInfo;
          if (parsedError.code && typeof parsedError.code === 'number') {
            hilog.info(DOMAIN, TAG, `🔍 [DEBUG] 从 message 解析到 code: ${parsedError.code}`);
            // 检查是否为 HarmonyOS 网络错误码
            if (parsedError.code >= 2300000 && parsedError.code < 2400000) {
              hilog.info(DOMAIN, TAG, `🌐 HarmonyOS网络错误 (从message解析): ${parsedError.code} - ${parsedError.message}`);
              return true;
            }
          }
        }
      } catch (parseError) {
        // JSON 解析失败，继续其他检查
        hilog.debug(DOMAIN, TAG, `解析 message JSON 失败，继续其他检查`);
      }
    }

    // 1. 检查 HarmonyOS 网络错误码 (23xxxxx 系列)
    if (typeof err.code === 'number') {
      // HarmonyOS 网络错误码范围
      // 2300028: 超时
      // 2300002: 连接失败
      // 2300003: URL格式错误
      // 2300006: SSL错误
      // 2300999: 未知错误
      const harmonyNetworkErrors = [
        2300028, // Timeout
        2300002, // Connection failed
        2300003, // URL error
        2300006, // SSL error
        2300007, // Protocol error
        2300999  // Unknown error
      ];

      if (harmonyNetworkErrors.includes(err.code)) {
        hilog.info(DOMAIN, TAG, `🌐 HarmonyOS网络错误: ${err.code} - ${err.message}`);
        return true;
      }

      // 检查是否是 23xxxxx 范围内的其他错误码
      if (err.code >= 2300000 && err.code < 2400000) {
        hilog.info(DOMAIN, TAG, `🌐 HarmonyOS网络错误 (范围检查): ${err.code}`);
        return true;
      }
    }

    // 2. 检查字符串形式的错误码 (axios/node 风格)
    if (typeof err.code === 'string') {
      const networkErrorCodes = [
        'ECONNREFUSED', // 连接被拒绝
        'ETIMEDOUT', // 超时
        'ECONNABORTED', // 连接中止
        'ENOTFOUND', // DNS解析失败
        'ENETUNREACH', // 网络不可达
        'EHOSTUNREACH', // 主机不可达
        'ECONNRESET', // 连接重置
        'EPIPE' // 管道破裂
      ];

      if (networkErrorCodes.includes(err.code)) {
        hilog.info(DOMAIN, TAG, `🌐 网络错误: ${err.code}`);
        return true;
      }
    }

    // 3. 检查HTTP响应状态码
    if (err.response) {
      const status = err.response.status;

      if (status) {
        // 5xx服务器错误 -> 网络错误
        if (status >= 500 && status < 600) {
          hilog.info(DOMAIN, TAG, `🌐 服务器错误: ${status}`);
          return true;
        }

        // 4xx客户端错误 -> 非网络错误
        if (status >= 400 && status < 500) {
          hilog.info(DOMAIN, TAG, `⚠️ 客户端错误 (非网络): ${status}`);
          return false;
        }

        // 2xx/3xx -> 非网络错误 (正常响应或重定向)
        hilog.info(DOMAIN, TAG, `✅ HTTP响应正常 (非网络错误): ${status}`);
        return false;
      }
    }

    // 4. 完全没有响应 -> 网络错误 (可能是网络断开)
    if (!err.response && err.request) {
      hilog.info(DOMAIN, TAG, `🌐 网络错误: 没有收到响应`);
      return true;
    }

    // 5. 检查错误消息中的关键词
    const errorMessage = err.message || JSON.stringify(err);
    const networkKeywords = [
      'network', '网络',
      'timeout', '超时', 'timed out',
      'connection', '连接',
      'unreachable', '不可达',
      'failed to fetch', '获取失败',
      'network request failed'
    ];

    for (const keyword of networkKeywords) {
      if (errorMessage.toLowerCase().includes(keyword.toLowerCase())) {
        hilog.info(DOMAIN, TAG, `🌐 网络错误 (关键词匹配): ${keyword}`);
        return true;
      }
    }

    // 默认判断为非网络错误
    hilog.info(DOMAIN, TAG, `⚠️ 非网络错误 (默认)`);
    return false;
  }

  /**
   * 获取详细的错误类型
   * @param error 错误对象
   * @returns 错误类型枚举
   */
  public static getErrorType(error: Error | object | null): ErrorType {
    if (ErrorUtil.isNetworkError(error)) {
      return ErrorType.NETWORK_ERROR;
    }

    const err = error as NetworkError;

    // 检查是否为业务错误 (有响应且状态码为2xx)
    if (err && err.response && err.response.status) {
      if (err.response.status >= 200 && err.response.status < 300) {
        return ErrorType.BUSINESS_ERROR;
      }
    }

    return ErrorType.UNKNOWN_ERROR;
  }

  /**
   * 格式化错误信息 (用于日志记录)
   * @param error 错误对象
   * @returns 格式化后的错误信息
   */
  public static formatError(error: Error | object | null): string {
    if (!error) {
      return '未知错误';
    }

    const errorType = ErrorUtil.getErrorType(error);
    const typeStr = errorType === ErrorType.NETWORK_ERROR ? '网络错误' :
      errorType === ErrorType.BUSINESS_ERROR ? '业务错误' : '未知错误';

    let message = `[${typeStr}] `;

    const err = error as NetworkError;

    if (err.code) {
      message += `错误码: ${err.code} `;
    }

    if (err.response?.status) {
      message += `HTTP状态: ${err.response.status} `;
    }

    if (err.message) {
      message += `消息: ${err.message}`;
    } else {
      message += `消息: ${JSON.stringify(err)}`;
    }

    return message;
  }
}
