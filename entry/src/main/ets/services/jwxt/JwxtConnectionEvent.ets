/**
 * 教务系统连接事件总线
 *
 * 用途:
 * - 当教务系统连接成功后,通知其他组件更新数据
 * - 组件订阅此事件,在收到通知后异步调用API更新缓存
 *
 * 工作原理:
 * 1. CookieManager 在成功保存 Cookie 后触发事件
 * 2. SchedulePage、ExamPage 等组件订阅此事件
 * 3. 组件收到事件后,在后台异步调用API更新缓存
 *
 * 使用方法:
 * ```typescript
 * // 订阅事件
 * jwxtConnectionBus.onConnectionSuccess(this.listener);
 *
 * // 取消订阅
 * jwxtConnectionBus.offConnectionSuccess(this.listener);
 *
 * // 触发事件
 * jwxtConnectionBus.emit(cookie, isLoggedIn);
 * ```
 *
 * @since 2026-01-09
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3005; // Jwxt Connection Event domain
const TAG: string = 'JwxtConnectionEvent';

/**
 * 教务系统连接监听器类型
 * @param cookie Cookie字符串
 * @param isConnected 是否已连接到教务系统
 */
export type JwxtConnectionListener = (cookie: string, isConnected: boolean) => void;

/**
 * 教务系统连接事件总线类
 * 实现观察者模式,用于通知组件教务系统连接状态变化
 */
class JwxtConnectionEventBus {
  private listeners: JwxtConnectionListener[] = [];

  /**
   * 注册监听器
   * @param fn 监听器函数
   */
  onConnectionSuccess(fn: JwxtConnectionListener): void {
    this.listeners.push(fn);
    hilog.info(DOMAIN, TAG, '📡 [Register] 注册监听器,当前监听器数量: %{public}d', this.listeners.length);
  }

  /**
   * 注销监听器
   * @param fn 监听器函数
   */
  offConnectionSuccess(fn: JwxtConnectionListener): void {
    const idx = this.listeners.indexOf(fn);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
      hilog.info(DOMAIN, TAG, '📡 [Unregister] 注销监听器,当前监听器数量: %{public}d', this.listeners.length);
    }
  }

  /**
   * 触发事件,通知所有监听器
   * @param cookie Cookie字符串
   * @param isConnected 是否已连接到教务系统
   */
  emit(cookie: string, isConnected: boolean): void {
    hilog.info(DOMAIN, TAG, '🔔 [Emit] 广播教务系统连接状态: isConnected=%{public}s, 监听器数量=%{public}d',
      isConnected, this.listeners.length);

    this.listeners.forEach((fn, index) => {
      try {
        fn(cookie, isConnected);
        hilog.info(DOMAIN, TAG, '✅ [Emit] 监听器[%{public}d] 执行成功', index);
      } catch (error) {
        hilog.error(DOMAIN, TAG, '❌ [Emit] 监听器[%{public}d] 执行失败: %{public}s',
          index, JSON.stringify(error));
      }
    });
  }
}

/**
 * 导出教务系统连接事件总线单例
 */
export const jwxtConnectionBus = new JwxtConnectionEventBus();
