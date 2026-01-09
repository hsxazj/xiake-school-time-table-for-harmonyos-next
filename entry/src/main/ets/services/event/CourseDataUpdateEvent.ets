/**
 * 课程数据更新事件总线
 *
 * 用途:
 * - 当课程数据成功更新并写入缓存后,通知其他组件刷新显示
 * - 用于 SchedulePage -> HomePage 的数据更新通知
 * - 确保 HomePage 显示的今日课程是最新的
 *
 * 工作原理:
 * 1. SchedulePage 在 refreshCourseFromApi() 成功后触发事件
 * 2. HomePage 订阅此事件,收到通知后重新加载今日课程
 * 3. 其他需要课程数据的组件也可以订阅此事件
 *
 * 使用方法:
 * ```typescript
 * // 订阅事件
 * courseDataUpdateBus.onCourseDataUpdate(this.listener);
 *
 * // 取消订阅
 * courseDataUpdateBus.offCourseDataUpdate(this.listener);
 *
 * // 触发事件
 * courseDataUpdateBus.emit(academicYear, semester, courseCount);
 * ```
 *
 * @since 2026-01-09
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3006; // Course Data Update Event domain
const TAG: string = 'CourseDataUpdateEvent';

/**
 * 课程数据更新事件参数
 */
export interface CourseDataUpdateParams {
  academicYear: string; // 学年,如 "2024"
  semester: number;     // 学期,1 或 2
  courseCount: number;  // 课程数量
}

/**
 * 课程数据更新监听器类型
 * @param params 更新参数
 */
export type CourseDataUpdateListener = (params: CourseDataUpdateParams) => void;

/**
 * 课程数据更新事件总线类
 * 实现观察者模式,用于通知组件课程数据已更新
 */
class CourseDataUpdateEventBus {
  private listeners: CourseDataUpdateListener[] = [];

  /**
   * 注册监听器
   * @param fn 监听器函数
   */
  onCourseDataUpdate(fn: CourseDataUpdateListener): void {
    this.listeners.push(fn);
    hilog.info(DOMAIN, TAG, '📡 [Register] 注册监听器,当前监听器数量: %{public}d', this.listeners.length);
  }

  /**
   * 注销监听器
   * @param fn 监听器函数
   */
  offCourseDataUpdate(fn: CourseDataUpdateListener): void {
    const idx = this.listeners.indexOf(fn);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
      hilog.info(DOMAIN, TAG, '📡 [Unregister] 注销监听器,当前监听器数量: %{public}d', this.listeners.length);
    }
  }

  /**
   * 触发事件,通知所有监听器课程数据已更新
   * @param academicYear 学年
   * @param semester 学期
   * @param courseCount 课程数量
   */
  emit(academicYear: string, semester: number, courseCount: number): void {
    const params: CourseDataUpdateParams = {
      academicYear,
      semester,
      courseCount
    };

    hilog.info(DOMAIN, TAG,
      '🔔 [Emit] 广播课程数据更新: %{public}s学年第%{public}d学期, 共%{public}d门课程, 监听器数量=%{public}d',
      academicYear, semester, courseCount, this.listeners.length);

    this.listeners.forEach((fn, index) => {
      try {
        fn(params);
        hilog.info(DOMAIN, TAG, '✅ [Emit] 监听器[%{public}d] 执行成功', index);
      } catch (error) {
        hilog.error(DOMAIN, TAG, '❌ [Emit] 监听器[%{public}d] 执行失败: %{public}s',
          index, JSON.stringify(error));
      }
    });
  }
}

/**
 * 导出课程数据更新事件总线单例
 */
export const courseDataUpdateBus = new CourseDataUpdateEventBus();
