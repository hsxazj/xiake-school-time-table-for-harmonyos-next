import { CourseInfo } from '../../models/CourseModels';

/**
 * 时间段接口
 */
interface TimeSlot {
  start: string;
  end: string;
}

/**
 * 课程时间工具类
 * 用于处理课程时间相关的计算和格式化
 */
export class CourseTimeUtil {
  
  /**
   * 获取课程时间范围字符串
   * 从courseTime数组中提取开始时间和结束时间
   * @param courseTime 课程时间数组，如["08:30-09:15", "09:25-10:10"]
   * @returns 时间范围字符串，如"08:30-10:10"
   */
  static getTimeRange(courseTime?: string[]): string {
    if (!courseTime || courseTime.length === 0) {
      return '';
    }

    const firstTime = courseTime[0];
    const lastTime = courseTime[courseTime.length - 1];

    const startTime = firstTime.split('-')[0];
    const endTime = lastTime.split('-')[1];

    return `${startTime}-${endTime}`;
  }

  /**
   * 验证课程时间格式是否正确
   * @param courseTime 课程时间数组
   * @returns 是否为有效格式
   */
  static isValidCourseTime(courseTime: string[]): boolean {
    if (!courseTime || courseTime.length === 0) {
      return false;
    }

    const timeRegex = /^\d{2}:\d{2}-\d{2}:\d{2}$/;
    return courseTime.every(time => timeRegex.test(time));
  }

  /**
   * 解析单个时间段
   * @param timeSlot 时间段字符串，如"08:30-09:15"
   * @returns TimeSlot 或 null
   */
  static parseTimeSlot(timeSlot: string): TimeSlot | null {
    if (!timeSlot || !timeSlot.includes('-')) {
      return null;
    }

    const parts = timeSlot.split('-');
    if (parts.length !== 2) {
      return null;
    }

    const result: TimeSlot = {
      start: parts[0].trim(),
      end: parts[1].trim()
    };
    return result;
  }

  /**
   * 获取课程总时长（分钟）
   * @param courseTime 课程时间数组
   * @returns 总时长（分钟），如果无法计算则返回0
   */
  static getTotalDuration(courseTime: string[]): number {
    if (!CourseTimeUtil.isValidCourseTime(courseTime)) {
      return 0;
    }

    let totalMinutes = 0;

    for (const timeSlot of courseTime) {
      const parsed = CourseTimeUtil.parseTimeSlot(timeSlot);
      if (parsed) {
        const startMinutes = CourseTimeUtil.timeToMinutes(parsed.start);
        const endMinutes = CourseTimeUtil.timeToMinutes(parsed.end);
        totalMinutes += (endMinutes - startMinutes);
      }
    }

    return totalMinutes;
  }

  /**
   * 将时间字符串转换为分钟数
   * @param time 时间字符串，如"08:30"
   * @returns 分钟数
   */
  private static timeToMinutes(time: string): number {
    const parts = time.split(':');
    if (parts.length !== 2) {
      return 0;
    }

    const hours = parseInt(parts[0], 10);
    const minutes = parseInt(parts[1], 10);

    return hours * 60 + minutes;
  }
}