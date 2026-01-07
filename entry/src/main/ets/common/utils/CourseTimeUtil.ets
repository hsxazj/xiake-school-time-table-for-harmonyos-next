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

  /**
   * 节次到时间的映射表
   * 标准课程时间表（福建工程学院）
   */
  private static readonly SESSION_TIME_MAP: Record<number, string> = {
    1: '08:00-08:45',
    2: '08:55-09:40',
    3: '10:00-10:45',
    4: '10:55-11:40',
    5: '14:00-14:45',
    6: '14:55-15:40',
    7: '16:00-16:45',
    8: '16:55-17:40',
    9: '19:00-19:45',
    10: '19:55-20:40',
    11: '20:50-21:35',
    12: '21:45-22:30'
  };

  /**
   * 将节次数组转换为时间字符串数组
   * @param sessions 节次数组，如 [1, 2, 3, 4]
   * @returns 时间字符串数组，如 ["08:00-08:45", "08:55-09:40", "10:00-10:45", "10:55-11:40"]
   */
  static sessionsToTimeStrings(sessions: number[]): string[] {
    if (!sessions || sessions.length === 0) {
      return [];
    }

    return sessions
      .filter(session => session >= 1 && session <= 12) // 过滤有效节次
      .map(session => CourseTimeUtil.SESSION_TIME_MAP[session])
      .filter(time => time !== undefined); // 过滤未定义的时间
  }

  /**
   * 格式化节次数组为节次字符串
   * @param sessions 节次数组，如 [1, 2]
   * @returns 节次字符串，如 "1-2节"
   */
  static formatSections(sessions: number[]): string {
    if (!sessions || sessions.length === 0) {
      return '';
    }

    if (sessions.length === 1) {
      return `${sessions[0]}节`;
    }

    // 检查是否连续
    const isConsecutive = sessions.every((val, index) =>
      index === 0 || val === sessions[index - 1] + 1
    );

    if (isConsecutive) {
      return `${sessions[0]}-${sessions[sessions.length - 1]}节`;
    }

    // 非连续节次，全部列出
    return sessions.map(s => `${s}节`).join(',');
  }
}