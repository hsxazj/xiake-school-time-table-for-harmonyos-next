 // 1. 基础格式化
// DateUtil.formatDate(new Date(), DateUtil.FORMATS.DATE)
//  输出: "2024-01-15"

// 2. 中文格式
// DateUtil.formatDate(new Date(), DateUtil.FORMATS.DATETIME_CN)
//  输出: "2024年01月15日 14时30分"

//  3. 相对时间
// DateUtil.formatRelativeTime(Date.now() - 300000)
//  输出: "5分钟前"

//  4. 自定义格式
// DateUtil.formatDate(new Date(), 'yyyy年MM月dd日 EEEE HH:mm')
//  输出: "2024年01月15日 星期一 14:30"

//  5. 时间差计算
// const diff = DateUtil.timeDiff(startDate, endDate)
//  返回: { days: 1, hours: 2, minutes: 30, seconds: 45 }

//  6. 日期判断
// DateUtil.isToday(someDate)     // 是否为今天
// DateUtil.isYesterday(someDate) // 是否为昨天
// DateUtil.isThisWeek(someDate)  // 是否为本周

//  7. 时间比较
// DateUtil.isBefore(date1, date2)        // date1是否早于date2
// DateUtil.isAfter(date1, date2)         // date1是否晚于date2
// DateUtil.isEqual(date1, date2)         // 两个时间是否相等
// DateUtil.isBetween(date, start, end)   // 是否在时间范围内
// DateUtil.isSameDayAs(date1, date2)     // 是否为同一天
// DateUtil.min(date1, date2)             // 获取较早的日期
// DateUtil.max(date1, date2)             // 获取较晚的日期

//  8. 年份相关
// DateUtil.getDayOfYearPublic(date)      // 获取一年中的第几天
// DateUtil.isLeapYear(2024)              // 判断是否为闰年


// 声明接口类型以满足ArkTS类型检查

/**
 * 相对时间单位配置接口
 * @interface RelativeTimeUnit
 */
interface RelativeTimeUnit {
  /** 时间单位名称 */
  unit: string;
  /** 阈值（秒） */
  threshold: number;
  /** 除数（用于计算单位数量） */
  divisor: number;
}

/**
 * 本地化字符串接口
 * @interface LocaleStrings
 */
interface LocaleStrings {
  /** 刚刚 */
  justNow: string;
  /** 分钟前 */
  minutesAgo: string;
  /** 小时前 */
  hoursAgo: string;
  /** 天前 */
  daysAgo: string;
  /** 周前 */
  weeksAgo: string;
  /** 个月前 */
  monthsAgo: string;
  /** 年前 */
  yearsAgo: string;
  /** 后（未来时间） */
  in: string;
  /** 分钟 */
  minutes: string;
  /** 小时 */
  hours: string;
  /** 天 */
  days: string;
  /** 周 */
  weeks: string;
  /** 个月 */
  months: string;
  /** 年 */
  years: string;
  /** 昨天 */
  yesterday: string;
  /** 今天 */
  today: string;
  /** 明天 */
  tomorrow: string;
  /** 上午 */
  am: string;
  /** 下午 */
  pm: string;
}

/**
 * 预设日期格式接口
 * @interface DateFormats
 */
interface DateFormats {
  /** 基础日期格式: yyyy-MM-dd */
  DATE: string;
  /** 基础时间格式: HH:mm:ss */
  TIME: string;
  /** 基础日期时间格式: yyyy-MM-dd HH:mm:ss */
  DATETIME: string;
  /** 中文日期格式: yyyy年MM月dd日 */
  DATE_CN: string;
  /** 中文时间格式: HH时mm分ss秒 */
  TIME_CN: string;
  /** 中文日期时间格式: yyyy年MM月dd日 HH时mm分 */
  DATETIME_CN: string;
  /** 12小时制时间格式: hh:mm:ss a */
  TIME_12: string;
  /** 12小时制日期时间格式: yyyy-MM-dd hh:mm:ss a */
  DATETIME_12: string;
  /** ISO日期格式: yyyy-MM-dd */
  ISO_DATE: string;
  /** ISO时间格式: HH:mm:ss.SSS (SSS表示毫秒) */
  ISO_TIME: string;
  /** ISO日期时间格式: yyyy-MM-ddTHH:mm:ss.SSSZ */
  ISO_DATETIME: string;
  /** 友好日期格式: MM月dd日 */
  FRIENDLY_DATE: string;
  /** 友好时间格式: HH:mm */
  FRIENDLY_TIME: string;
  /** 友好日期时间格式: MM-dd HH:mm */
  FRIENDLY_DATETIME: string;
  /** 完整日期格式: yyyy年MM月dd日 EEEE */
  FULL_DATE: string;
  /** 完整日期时间格式: yyyy年MM月dd日 EEEE HH:mm:ss */
  FULL_DATETIME: string;
}

/**
 * 时间差计算结果接口
 * @interface TimeDifference
 */
interface TimeDifference {
  /** 天数 */
  days: number;
  /** 小时数 */
  hours: number;
  /** 分钟数 */
  minutes: number;
  /** 秒数 */
  seconds: number;
}

/**
 * 鸿蒙ArkTS日期时间格式化工具类
 *
 * 提供全面的日期时间处理功能，完全兼容ArkTS语法规范
 * 支持多种格式化方式、国际化、相对时间显示等功能
 *
 * @class DateUtil
 * @static
 */
export class DateUtil {
  /**
   * 常用日期时间格式预设
   *
   * @example
   * ```typescript
   * // 使用预设格式
   * DateUtil.formatDate(new Date(), DateUtil.FORMATS.DATE_CN)
   * // 输出: "2024年01月15日"
   *
   * DateUtil.formatDate(new Date(), DateUtil.FORMATS.TIME_12)
   * // 输出: "02:30:15 下午"
   * ```
   *
   * @static
   * @readonly
   */
  public static readonly FORMATS: DateFormats = {
    // 基础格式
    DATE: 'yyyy-MM-dd',
    TIME: 'HH:mm:ss',
    DATETIME: 'yyyy-MM-dd HH:mm:ss',

    // 中文格式
    DATE_CN: 'yyyy年MM月dd日',
    TIME_CN: 'HH时mm分ss秒',
    DATETIME_CN: 'yyyy年MM月dd日 HH时mm分',

    // 12小时制
    TIME_12: 'hh:mm:ss a',
    DATETIME_12: 'yyyy-MM-dd hh:mm:ss a',

    // ISO格式
    ISO_DATE: 'yyyy-MM-dd',
    ISO_TIME: 'HH:mm:ss.SSS', // SSS表示毫秒
    ISO_DATETIME: 'yyyy-MM-ddTHH:mm:ss.SSSD', // D表示年份中的天数

    // 友好格式
    FRIENDLY_DATE: 'MM月dd日',
    FRIENDLY_TIME: 'HH:mm',
    FRIENDLY_DATETIME: 'MM-dd HH:mm',

    // 完整格式
    FULL_DATE: 'yyyy年MM月dd日 EEEE',
    FULL_DATETIME: 'yyyy年MM月dd日 EEEE HH:mm:ss'
  };

  /**
   * 相对时间计算单位配置
   * 用于将时间差转换为友好的相对时间显示
   *
   * @private
   * @static
   * @readonly
   */
  private static readonly TIME_UNITS: RelativeTimeUnit[] = [
    { unit: 'second', threshold: 60, divisor: 1 },
    { unit: 'minute', threshold: 3600, divisor: 60 },
    { unit: 'hour', threshold: 86400, divisor: 3600 },
    { unit: 'day', threshold: 604800, divisor: 86400 },
    { unit: 'week', threshold: 2592000, divisor: 604800 },
    { unit: 'month', threshold: 31536000, divisor: 2592000 },
    { unit: 'year', threshold: 999999999, divisor: 31536000 }
  ];

  /**
   * 日期格式化正则表达式
   * 用于匹配和替换格式化字符串中的模式
   *
   * @private
   * @static
   * @readonly
   */
  private static readonly FORMAT_REGEX: RegExp = /(yyyy|yy|MMMM|MMM|MM|M|dd|d|DDD|DD|D|EEEE|EEE|EE|E|HH|H|hh|h|mm|m|ss|s|SSS|SS|S|a|z|Z)/g;

  /**
   * 格式化日期时间
   *
   * 支持多种输入类型和格式化选项，是本工具类的核心方法
   *
   * @param date 要格式化的日期，支持Date对象、时间戳(毫秒)、ISO8601字符串
   * @param format 格式字符串，支持预设格式或自定义格式，默认为完整日期时间格式
   * @param locale 本地化设置，支持'zh-CN'和'en-US'，默认为'zh-CN'
   * @returns 格式化后的日期时间字符串，解析失败时返回null
   *
   * @example 基础用法
   * ```typescript
   * const now = new Date();
   *
   * // 使用预设格式
   * DateUtil.formatDate(now, DateUtil.FORMATS.DATE)
   * // 输出: "2024-01-15"
   *
   * DateUtil.formatDate(now, DateUtil.FORMATS.DATETIME_CN)
   * // 输出: "2024年01月15日 14时30分"
   *
   * // 使用时间戳
   * DateUtil.formatDate(1705304400000, DateUtil.FORMATS.TIME)
   * // 输出: "14:30:00"
   *
   * // 使用ISO字符串
   * DateUtil.formatDate('2024-01-15T14:30:00.000Z', DateUtil.FORMATS.DATE_CN)
   * // 输出: "2024年01月15日"
   * ```
   *
   * @example 自定义格式
   * ```typescript
   * // 完全自定义格式
   * DateUtil.formatDate(now, 'yyyy年MM月dd日 EEEE HH:mm:ss')
   * // 输出: "2024年01月15日 星期一 14:30:25"
   *
   * // 12小时制带毫秒
   * DateUtil.formatDate(now, 'hh:mm:ss.SSS a')
   * // 输出: "02:30:25.123 下午"
   *
   * // 简化格式
   * DateUtil.formatDate(now, 'MM-dd HH:mm')
   * // 输出: "01-15 14:30"
   * ```
   *
   * @example 多语言支持
   * ```typescript
   * // 中文格式
   * DateUtil.formatDate(now, 'MMMM dd, yyyy', 'zh-CN')
   * // 输出: "一月 15, 2024"
   *
   * // 英文格式
   * DateUtil.formatDate(now, 'MMMM dd, yyyy', 'en-US')
   * // 输出: "January 15, 2024"
   * ```
   *
   * @static
   * @public
   */
  public static formatDate(
    date: Date | number | string,
    format: string = DateUtil.FORMATS.DATETIME,
    locale: string = 'zh-CN'
  ): string | null {
    if (!date) return null;

    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return null;

    // 如果是预设格式，优先使用系统API
    if (DateUtil.isPresetFormat(format)) {
      const systemResult = DateUtil.formatWithSystemAPI(dateObj, format, locale);
      if (systemResult) return systemResult;
    }

    // 使用自定义格式化
    return DateUtil.customFormat(dateObj, format, locale);
  }

  /**
   * 格式化相对时间
   *
   * 将日期转换为相对于当前时间的友好显示格式，如"5分钟前"、"昨天 14:30"等
   * 支持智能判断显示今天、昨天、明天等特殊情况
   *
   * @param date 要格式化的日期
   * @param locale 本地化设置，默认为'zh-CN'
   * @param maxDays 超过多少天后显示绝对时间而非相对时间，默认7天
   * @returns 相对时间字符串，解析失败时返回null
   *
   * @example 基础用法
   * ```typescript
   * const now = Date.now();
   *
   * // 1分钟前
   * DateUtil.formatRelativeTime(now - 60 * 1000)
   * // 输出: "1分钟前"
   *
   * // 5小时前
   * DateUtil.formatRelativeTime(now - 5 * 60 * 60 * 1000)
   * // 输出: "5小时前"
   *
   * // 刚刚（1分钟内）
   * DateUtil.formatRelativeTime(now - 30 * 1000)
   * // 输出: "刚刚"
   * ```
   *
   * @example 特殊情况处理
   * ```typescript
   * // 今天的时间显示具体时刻
   * DateUtil.formatRelativeTime(todayEarlier)
   * // 输出: "今天 09:30"
   *
   * // 昨天的时间
   * DateUtil.formatRelativeTime(yesterday)
   * // 输出: "昨天 14:30"
   *
   * // 明天的时间（未来时间）
   * DateUtil.formatRelativeTime(tomorrow)
   * // 输出: "明天 10:00"
   * ```
   *
   * @example 自定义最大天数
   * ```typescript
   * // 超过3天显示绝对日期
   * DateUtil.formatRelativeTime(oldDate, 'zh-CN', 3)
   * // 超过3天输出: "2024-01-10"
   * // 3天内输出: "3天前"
   * ```
   *
   * @static
   * @public
   */
  public static formatRelativeTime(
    date: Date | number | string,
    locale: string = 'zh-CN',
    maxDays: number = 7
  ): string | null {
    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return null;

    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - dateObj.getTime()) / 1000);
    const absDiff = Math.abs(diffInSeconds);

    // 超过指定天数，返回绝对时间
    if (absDiff > maxDays * 86400) {
      return DateUtil.formatDate(dateObj, DateUtil.FORMATS.DATE, locale);
    }

    const strings = DateUtil.getLocaleStrings(locale);

    // 刚刚（1分钟内）
    if (absDiff < 60) {
      return strings.justNow;
    }

    // 处理特殊情况：昨天、今天、明天
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);

    if (DateUtil.isSameDay(dateObj, today)) {
      return `${strings.today} ${DateUtil.formatDate(dateObj, 'HH:mm', locale)}`;
    }
    if (DateUtil.isSameDay(dateObj, yesterday)) {
      return `${strings.yesterday} ${DateUtil.formatDate(dateObj, 'HH:mm', locale)}`;
    }
    if (DateUtil.isSameDay(dateObj, tomorrow)) {
      return `${strings.tomorrow} ${DateUtil.formatDate(dateObj, 'HH:mm', locale)}`;
    }

    // 使用相对时间单位
    for (let i = 0; i < DateUtil.TIME_UNITS.length; i++) {
      const timeUnit = DateUtil.TIME_UNITS[i];
      if (absDiff < timeUnit.threshold) {
        const value = Math.floor(absDiff / timeUnit.divisor);
        return DateUtil.formatRelativeTimeString(value, timeUnit.unit, diffInSeconds < 0, strings);
      }
    }

    return DateUtil.formatDate(dateObj, DateUtil.FORMATS.DATE, locale);
  }

  /**
   * 判断指定日期是否为今天
   *
   * @param date 要判断的日期
   * @returns 是否为今天
   *
   * @example
   * ```typescript
   * DateUtil.isToday(new Date())           // true
   * DateUtil.isToday(Date.now())           // true
   * DateUtil.isToday('2024-01-15')         // 根据当前日期判断
   * DateUtil.isToday(yesterdayDate)        // false
   * ```
   *
   * @static
   * @public
   */
  public static isToday(date: Date | number | string): boolean {
    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return false;
    return DateUtil.isSameDay(dateObj, new Date());
  }

  /**
   * 判断指定日期是否为昨天
   *
   * @param date 要判断的日期
   * @returns 是否为昨天
   *
   * @example
   * ```typescript
   * const yesterday = new Date();
   * yesterday.setDate(yesterday.getDate() - 1);
   *
   * DateUtil.isYesterday(yesterday)        // true
   * DateUtil.isYesterday(new Date())       // false
   * ```
   *
   * @static
   * @public
   */
  public static isYesterday(date: Date | number | string): boolean {
    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return false;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return DateUtil.isSameDay(dateObj, yesterday);
  }

  /**
   * 判断指定日期是否在本周内
   *
   * 以星期日为一周的开始计算
   *
   * @param date 要判断的日期
   * @returns 是否为本周
   *
   * @example
   * ```typescript
   * DateUtil.isThisWeek(new Date())        // true
   * DateUtil.isThisWeek(lastWeekDate)      // false
   * DateUtil.isThisWeek(nextWeekDate)      // false
   * ```
   *
   * @static
   * @public
   */
  public static isThisWeek(date: Date | number | string): boolean {
    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return false;

    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    return dateObj >= startOfWeek && dateObj <= endOfWeek;
  }

  /**
   * 计算两个日期之间的时间差
   *
   * 返回详细的时间差信息，包括天、小时、分钟、秒
   *
   * @param startDate 开始日期
   * @param endDate 结束日期，默认为当前时间
   * @returns 时间差对象，包含days、hours、minutes、seconds属性，解析失败时返回null
   *
   * @example
   * ```typescript
   * const start = new Date('2024-01-15 10:30:00');
   * const end = new Date('2024-01-16 14:45:30');
   *
   * const diff = DateUtil.timeDiff(start, end);
   * console.log(diff);
   * // 输出: { days: 1, hours: 4, minutes: 15, seconds: 30 }
   *
   * // 距离当前时间的差值
   * const diffFromNow = DateUtil.timeDiff(start);
   * console.log(diffFromNow);
   * // 输出: { days: 0, hours: 2, minutes: 30, seconds: 45 }
   * ```
   *
   * @example 实际应用场景
   * ```typescript
   * // 计算活动剩余时间
   * const eventEnd = new Date('2024-12-31 23:59:59');
   * const remaining = DateUtil.timeDiff(new Date(), eventEnd);
   * console.log(`活动还剩 ${remaining.days} 天 ${remaining.hours} 小时`);
   *
   * // 计算任务耗时
   * const taskStart = Date.now();
   * // ... 执行任务
   * const taskEnd = Date.now();
   * const duration = DateUtil.timeDiff(taskStart, taskEnd);
   * console.log(`任务耗时: ${duration.minutes}分${duration.seconds}秒`);
   * ```
   *
   * @static
   * @public
   */
  public static timeDiff(
    startDate: Date | number | string,
    endDate: Date | number | string = new Date()
  ): TimeDifference | null {
    const start = DateUtil.parseDate(startDate);
    const end = DateUtil.parseDate(endDate);

    if (!start || !end) return null;

    const diffInMs = Math.abs(end.getTime() - start.getTime());

    return {
      days: Math.floor(diffInMs / (1000 * 60 * 60 * 24)),
      hours: Math.floor((diffInMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
      minutes: Math.floor((diffInMs % (1000 * 60 * 60)) / (1000 * 60)),
      seconds: Math.floor((diffInMs % (1000 * 60)) / 1000)
    };
  }

  /**
   * 解析各种类型的日期输入为Date对象
   *
   * 统一处理Date对象、时间戳、字符串等不同格式的日期输入
   *
   * @param date 要解析的日期
   * @returns 解析后的Date对象，解析失败时返回null
   *
   * @private
   * @static
   */
  private static parseDate(date: Date | number | string): Date | null {
    if (!date) return null;

    let dateObj: Date;

    if (date instanceof Date) {
      dateObj = date;
    } else if (typeof date === 'number') {
      dateObj = new Date(date);
    } else {
      // 处理字符串格式的兼容性
      let dateString = date.toString();

      // 兼容不同的日期字符串格式
      if (dateString.includes('-') && !dateString.includes('T')) {
        dateString = dateString.replace(/-/g, '/');
      }

      const timestamp = Date.parse(dateString);
      if (isNaN(timestamp)) {
        console.error('Invalid date string:', date);
        return null;
      }
      dateObj = new Date(timestamp);
    }

    // 验证日期有效性
    if (isNaN(dateObj.getTime())) {
      console.error('Invalid date:', date);
      return null;
    }

    return dateObj;
  }

  /**
   * 检查给定格式是否为预设格式
   *
   * @param format 要检查的格式字符串
   * @returns 是否为预设格式
   *
   * @private
   * @static
   */
  private static isPresetFormat(format: string): boolean {
    return format === DateUtil.FORMATS.DATE ||
           format === DateUtil.FORMATS.TIME ||
           format === DateUtil.FORMATS.DATETIME ||
           format === DateUtil.FORMATS.TIME_12;
  }

  /**
   * 使用优化的系统API进行格式化
   *
   * 针对常用的预设格式进行优化处理，避免ArkTS结构化类型问题
   *
   * @param date Date对象
   * @param format 格式字符串
   * @param locale 本地化设置
   * @returns 格式化结果，失败时返回null
   *
   * @private
   * @static
   */
  private static formatWithSystemAPI(date: Date, format: string, locale: string): string | null {
    try {
      // 直接使用简化的格式化方式，避免结构化类型问题
      if (format === DateUtil.FORMATS.DATE) {
        return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
      } else if (format === DateUtil.FORMATS.TIME) {
        return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
      } else if (format === DateUtil.FORMATS.DATETIME) {
        const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
        const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
        return `${dateStr} ${timeStr}`;
      } else if (format === DateUtil.FORMATS.TIME_12) {
        const hour12 = DateUtil.get12Hour(date.getHours());
        const ampm = date.getHours() < 12 ? (locale === 'zh-CN' ? '上午' : 'AM') : (locale === 'zh-CN' ? '下午' : 'PM');
        return `${hour12.toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')} ${ampm}`;
      } else {
        return null;
      }
    } catch (error) {
      console.warn('System format failed:', error);
      return null;
    }
  }

  /**
   * 获取指定语言的本地化字符串
   *
   * @param locale 语言代码
   * @returns 本地化字符串对象
   *
   * @private
   * @static
   */
  private static getLocaleStrings(locale: string): LocaleStrings {
    if (locale === 'en-US') {
      return {
        justNow: 'just now',
        minutesAgo: 'minutes ago',
        hoursAgo: 'hours ago',
        daysAgo: 'days ago',
        weeksAgo: 'weeks ago',
        monthsAgo: 'months ago',
        yearsAgo: 'years ago',
        in: 'in',
        minutes: 'minutes',
        hours: 'hours',
        days: 'days',
        weeks: 'weeks',
        months: 'months',
        years: 'years',
        yesterday: 'yesterday',
        today: 'today',
        tomorrow: 'tomorrow',
        am: 'AM',
        pm: 'PM'
      };
    }

    // 默认返回中文
    return {
      justNow: '刚刚',
      minutesAgo: '分钟前',
      hoursAgo: '小时前',
      daysAgo: '天前',
      weeksAgo: '周前',
      monthsAgo: '个月前',
      yearsAgo: '年前',
      in: '后',
      minutes: '分钟',
      hours: '小时',
      days: '天',
      weeks: '周',
      months: '个月',
      years: '年',
      yesterday: '昨天',
      today: '今天',
      tomorrow: '明天',
      am: '上午',
      pm: '下午'
    };
  }

  /**
   * 自定义格式化核心逻辑
   *
   * 解析格式字符串并替换为实际的日期时间值
   *
   * @param date Date对象
   * @param format 格式字符串
   * @param locale 本地化设置
   * @returns 格式化后的字符串
   *
   * @private
   * @static
   */
  private static customFormat(date: Date, format: string, locale: string): string {
    const strings = DateUtil.getLocaleStrings(locale);

    // 创建格式映射
    const formatMap = new Map<string, string>();

    // 年份格式
    formatMap.set('yyyy', date.getFullYear().toString());
    formatMap.set('yy', date.getFullYear().toString().slice(-2));

    // 月份格式
    formatMap.set('MMMM', DateUtil.getMonthName(date.getMonth(), 'long', locale));
    formatMap.set('MMM', DateUtil.getMonthName(date.getMonth(), 'short', locale));
    formatMap.set('MM', (date.getMonth() + 1).toString().padStart(2, '0'));
    formatMap.set('M', (date.getMonth() + 1).toString());

    // 日期格式
    formatMap.set('dd', date.getDate().toString().padStart(2, '0'));
    formatMap.set('d', date.getDate().toString());

    // 年份中的天数格式
    const dayOfYear = DateUtil.getDayOfYear(date);
    formatMap.set('DDD', dayOfYear.toString().padStart(3, '0'));
    formatMap.set('DD', dayOfYear.toString().padStart(2, '0'));
    formatMap.set('D', dayOfYear.toString());

    // 星期格式
    formatMap.set('EEEE', DateUtil.getWeekdayName(date.getDay(), 'long', locale));
    formatMap.set('EEE', DateUtil.getWeekdayName(date.getDay(), 'short', locale));
    formatMap.set('EE', DateUtil.getWeekdayName(date.getDay(), 'short', locale));
    formatMap.set('E', DateUtil.getWeekdayName(date.getDay(), 'narrow', locale));

    // 小时格式
    formatMap.set('HH', date.getHours().toString().padStart(2, '0'));
    formatMap.set('H', date.getHours().toString());
    formatMap.set('hh', DateUtil.get12Hour(date.getHours()).toString().padStart(2, '0'));
    formatMap.set('h', DateUtil.get12Hour(date.getHours()).toString());

    // 分钟格式
    formatMap.set('mm', date.getMinutes().toString().padStart(2, '0'));
    formatMap.set('m', date.getMinutes().toString());

    // 秒钟格式
    formatMap.set('ss', date.getSeconds().toString().padStart(2, '0'));
    formatMap.set('s', date.getSeconds().toString());

    // 毫秒格式
    formatMap.set('SSS', date.getMilliseconds().toString().padStart(3, '0'));
    formatMap.set('SS', date.getMilliseconds().toString().padStart(3, '0').slice(0, 2));
    formatMap.set('S', Math.floor(date.getMilliseconds() / 100).toString());

    // 上午/下午标识
    formatMap.set('a', date.getHours() < 12 ? strings.am : strings.pm);

    // 时区信息（简化处理）
    formatMap.set('z', 'CST');
    formatMap.set('Z', '+0800');

    return format.replace(DateUtil.FORMAT_REGEX, (match) => {
      return formatMap.get(match) || match;
    });
  }

  /**
   * 生成相对时间描述字符串
   *
   * @param value 数值
   * @param unit 时间单位
   * @param isFuture 是否为未来时间
   * @param strings 本地化字符串
   * @returns 相对时间字符串
   *
   * @private
   * @static
   */
  private static formatRelativeTimeString(
    value: number,
    unit: string,
    isFuture: boolean,
    strings: LocaleStrings
  ): string {
    let unitString = '';
    if (unit === 'minute') unitString = strings.minutes;
    else if (unit === 'hour') unitString = strings.hours;
    else if (unit === 'day') unitString = strings.days;
    else if (unit === 'week') unitString = strings.weeks;
    else if (unit === 'month') unitString = strings.months;
    else if (unit === 'year') unitString = strings.years;

    if (isFuture) {
      return `${value}${unitString}${strings.in}`;
    } else {
      return `${value}${unitString}${strings.minutesAgo.includes('前') ? '前' : ' ago'}`;
    }
  }

  /**
   * 获取本地化的月份名称
   *
   * @param month 月份索引（0-11）
   * @param style 显示样式：'long'完整名称, 'short'缩写
   * @param locale 语言设置
   * @returns 月份名称
   *
   * @private
   * @static
   */
  private static getMonthName(month: number, style: 'long' | 'short', locale: string): string {
    if (locale === 'zh-CN') {
      if (style === 'long') {
        const months = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
        return months[month] || `${month + 1}月`;
      } else {
        return `${month + 1}月`;
      }
    } else {
      if (style === 'long') {
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return months[month] || `${month + 1}`;
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[month] || `${month + 1}`;
      }
    }
  }

  /**
   * 获取本地化的星期名称
   *
   * @param day 星期索引（0-6，0代表星期日）
   * @param style 显示样式：'long'完整名称, 'short'缩写, 'narrow'最短形式
   * @param locale 语言设置
   * @returns 星期名称
   *
   * @private
   * @static
   */
  private static getWeekdayName(day: number, style: 'long' | 'short' | 'narrow', locale: string): string {
    if (locale === 'zh-CN') {
      const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      return style === 'long' ? `星期${weekdays[day]}` : weekdays[day] || day.toString();
    } else {
      if (style === 'long') {
        const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        return weekdays[day] || day.toString();
      } else {
        const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        return weekdays[day] || day.toString();
      }
    }
  }

  /**
   * 将24小时制转换为12小时制
   *
   * @param hour 24小时制的小时数（0-23）
   * @returns 12小时制的小时数（1-12）
   *
   * @private
   * @static
   */
  private static get12Hour(hour: number): number {
    return hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  }

  /**
   * 计算指定日期是该年的第几天
   *
   * @param date 要计算的日期
   * @returns 年份中的天数（1-366）
   *
   * @example
   * ```typescript
   * // 1月1日是第1天
   * DateUtil.getDayOfYear(new Date('2024-01-01'))  // 1
   *
   * // 12月31日是第365天（非闰年）或第366天（闰年）
   * DateUtil.getDayOfYear(new Date('2024-12-31'))  // 366 (2024是闰年)
   * DateUtil.getDayOfYear(new Date('2023-12-31'))  // 365 (2023不是闰年)
   * ```
   *
   * @private
   * @static
   */
  private static getDayOfYear(date: Date): number {
    const start = new Date(date.getFullYear(), 0, 1); // 当年1月1日
    const diff = date.getTime() - start.getTime();
    const oneDay = 1000 * 60 * 60 * 24; // 一天的毫秒数
    return Math.floor(diff / oneDay) + 1;
  }

  /**
   * 比较两个日期的大小关系
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 比较结果：-1表示date1早于date2，0表示相等，1表示date1晚于date2，null表示解析失败
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-15');
   * const date2 = new Date('2024-01-16');
   *
   * DateUtil.compareDates(date1, date2)  // -1 (date1早于date2)
   * DateUtil.compareDates(date2, date1)  // 1  (date2晚于date1)
   * DateUtil.compareDates(date1, date1)  // 0  (相等)
   * ```
   *
   * @static
   * @public
   */
  public static compareDates(date1: Date | number | string, date2: Date | number | string): number | null {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return null;

    const time1 = dateObj1.getTime();
    const time2 = dateObj2.getTime();

    if (time1 < time2) return -1;
    if (time1 > time2) return 1;
    return 0;
  }

  /**
   * 判断两个日期时间是否完全相等
   *
   * 精确比较到毫秒级别
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否相等
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-15 14:30:25.123');
   * const date2 = new Date('2024-01-15 14:30:25.123');
   * const date3 = new Date('2024-01-15 14:30:25.124');
   *
   * DateUtil.isEqual(date1, date2)  // true
   * DateUtil.isEqual(date1, date3)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isEqual(date1: Date | number | string, date2: Date | number | string): boolean {
    return DateUtil.compareDates(date1, date2) === 0;
  }

  /**
   * 判断第一个日期是否早于第二个日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否早于
   *
   * @example
   * ```typescript
   * const yesterday = new Date('2024-01-14');
   * const today = new Date('2024-01-15');
   *
   * DateUtil.isBefore(yesterday, today)  // true
   * DateUtil.isBefore(today, yesterday)  // false
   * DateUtil.isBefore(today, today)      // false
   * ```
   *
   * @static
   * @public
   */
  public static isBefore(date1: Date | number | string, date2: Date | number | string): boolean {
    return DateUtil.compareDates(date1, date2) === -1;
  }

  /**
   * 判断第一个日期是否晚于第二个日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否晚于
   *
   * @example
   * ```typescript
   * const today = new Date('2024-01-15');
   * const tomorrow = new Date('2024-01-16');
   *
   * DateUtil.isAfter(tomorrow, today)  // true
   * DateUtil.isAfter(today, tomorrow)  // false
   * DateUtil.isAfter(today, today)     // false
   * ```
   *
   * @static
   * @public
   */
  public static isAfter(date1: Date | number | string, date2: Date | number | string): boolean {
    return DateUtil.compareDates(date1, date2) === 1;
  }

  /**
   * 判断第一个日期是否早于或等于第二个日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否早于或等于
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-15');
   * const date2 = new Date('2024-01-16');
   * const date3 = new Date('2024-01-15');
   *
   * DateUtil.isBeforeOrEqual(date1, date2)  // true (早于)
   * DateUtil.isBeforeOrEqual(date1, date3)  // true (相等)
   * DateUtil.isBeforeOrEqual(date2, date1)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isBeforeOrEqual(date1: Date | number | string, date2: Date | number | string): boolean {
    const result = DateUtil.compareDates(date1, date2);
    return result === -1 || result === 0;
  }

  /**
   * 判断第一个日期是否晚于或等于第二个日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否晚于或等于
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-16');
   * const date2 = new Date('2024-01-15');
   * const date3 = new Date('2024-01-16');
   *
   * DateUtil.isAfterOrEqual(date1, date2)  // true (晚于)
   * DateUtil.isAfterOrEqual(date1, date3)  // true (相等)
   * DateUtil.isAfterOrEqual(date2, date1)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isAfterOrEqual(date1: Date | number | string, date2: Date | number | string): boolean {
    const result = DateUtil.compareDates(date1, date2);
    return result === 1 || result === 0;
  }

  /**
   * 判断日期是否在指定范围内（包含边界）
   *
   * @param date 要判断的日期
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 是否在范围内
   *
   * @example
   * ```typescript
   * const checkDate = new Date('2024-01-15');
   * const start = new Date('2024-01-10');
   * const end = new Date('2024-01-20');
   *
   * DateUtil.isBetween(checkDate, start, end)  // true
   *
   * // 实际应用：判断是否在活动期间
   * const eventStart = new Date('2024-12-01');
   * const eventEnd = new Date('2024-12-31');
   * const now = new Date();
   *
   * if (DateUtil.isBetween(now, eventStart, eventEnd)) {
   *   console.log('活动进行中');
   * }
   * ```
   *
   * @static
   * @public
   */
  public static isBetween(
    date: Date | number | string,
    startDate: Date | number | string,
    endDate: Date | number | string
  ): boolean {
    return DateUtil.isAfterOrEqual(date, startDate) && DateUtil.isBeforeOrEqual(date, endDate);
  }

  /**
   * 判断两个日期是否为同一天（忽略时分秒）
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否为同一天
   *
   * @example
   * ```typescript
   * const morning = new Date('2024-01-15 08:30:00');
   * const evening = new Date('2024-01-15 20:45:30');
   * const nextDay = new Date('2024-01-16 08:30:00');
   *
   * DateUtil.isSameDayAs(morning, evening)  // true
   * DateUtil.isSameDayAs(morning, nextDay)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isSameDayAs(date1: Date | number | string, date2: Date | number | string): boolean {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return false;

    return DateUtil.isSameDay(dateObj1, dateObj2);
  }

  /**
   * 判断两个日期是否为同一周
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否为同一周
   *
   * @example
   * ```typescript
   * const monday = new Date('2024-01-15');    // 假设是周一
   * const friday = new Date('2024-01-19');    // 同一周的周五
   * const nextMonday = new Date('2024-01-22'); // 下周的周一
   *
   * DateUtil.isSameWeekAs(monday, friday)     // true
   * DateUtil.isSameWeekAs(monday, nextMonday) // false
   * ```
   *
   * @static
   * @public
   */
  public static isSameWeekAs(date1: Date | number | string, date2: Date | number | string): boolean {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return false;

    // 计算两个日期所在周的开始日期
    const getWeekStart = (date: Date): Date => {
      const start = new Date(date);
      start.setDate(date.getDate() - date.getDay());
      start.setHours(0, 0, 0, 0);
      return start;
    };

    const week1Start = getWeekStart(dateObj1);
    const week2Start = getWeekStart(dateObj2);

    return week1Start.getTime() === week2Start.getTime();
  }

  /**
   * 判断两个日期是否为同一月
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否为同一月
   *
   * @example
   * ```typescript
   * const early = new Date('2024-01-05');
   * const late = new Date('2024-01-25');
   * const nextMonth = new Date('2024-02-05');
   *
   * DateUtil.isSameMonthAs(early, late)       // true
   * DateUtil.isSameMonthAs(early, nextMonth)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isSameMonthAs(date1: Date | number | string, date2: Date | number | string): boolean {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return false;

    return dateObj1.getFullYear() === dateObj2.getFullYear() &&
           dateObj1.getMonth() === dateObj2.getMonth();
  }

  /**
   * 判断两个日期是否为同一年
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否为同一年
   *
   * @example
   * ```typescript
   * const spring = new Date('2024-03-15');
   * const winter = new Date('2024-12-15');
   * const nextYear = new Date('2025-03-15');
   *
   * DateUtil.isSameYearAs(spring, winter)    // true
   * DateUtil.isSameYearAs(spring, nextYear)  // false
   * ```
   *
   * @static
   * @public
   */
  public static isSameYearAs(date1: Date | number | string, date2: Date | number | string): boolean {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return false;

    return dateObj1.getFullYear() === dateObj2.getFullYear();
  }

  /**
   * 获取两个日期中较早的日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 较早的日期，解析失败时返回null
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-15');
   * const date2 = new Date('2024-01-20');
   *
   * const earlier = DateUtil.min(date1, date2);
   * console.log(DateUtil.formatDate(earlier, DateUtil.FORMATS.DATE));
   * // 输出: "2024-01-15"
   * ```
   *
   * @static
   * @public
   */
  public static min(date1: Date | number | string, date2: Date | number | string): Date | null {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return null;

    return dateObj1.getTime() <= dateObj2.getTime() ? dateObj1 : dateObj2;
  }

  /**
   * 获取两个日期中较晚的日期
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 较晚的日期，解析失败时返回null
   *
   * @example
   * ```typescript
   * const date1 = new Date('2024-01-15');
   * const date2 = new Date('2024-01-20');
   *
   * const later = DateUtil.max(date1, date2);
   * console.log(DateUtil.formatDate(later, DateUtil.FORMATS.DATE));
   * // 输出: "2024-01-20"
   * ```
   *
   * @static
   * @public
   */
  public static max(date1: Date | number | string, date2: Date | number | string): Date | null {
    const dateObj1 = DateUtil.parseDate(date1);
    const dateObj2 = DateUtil.parseDate(date2);

    if (!dateObj1 || !dateObj2) return null;

    return dateObj1.getTime() >= dateObj2.getTime() ? dateObj1 : dateObj2;
  }

  /**
   * 计算指定日期是该年的第几天
   *
   * @param date 要计算的日期
   * @returns 年份中的天数（1-366），解析失败时返回null
   *
   * @example
   * ```typescript
   * // 基础使用
   * DateUtil.getDayOfYearPublic(new Date('2024-01-01'))  // 1
   * DateUtil.getDayOfYearPublic(new Date('2024-02-01'))  // 32
   * DateUtil.getDayOfYearPublic(new Date('2024-12-31'))  // 366 (2024是闰年)
   *
   * // 实际应用：计算已过去的天数百分比
   * const today = new Date();
   * const dayOfYear = DateUtil.getDayOfYearPublic(today);
   * const isLeapYear = DateUtil.isLeapYear(today.getFullYear());
   * const totalDays = isLeapYear ? 366 : 365;
   * const percentage = (dayOfYear / totalDays * 100).toFixed(1);
   * console.log(`今年已过去 ${percentage}%`);
   * ```
   *
   * @static
   * @public
   */
  public static getDayOfYearPublic(date: Date | number | string): number | null {
    const dateObj = DateUtil.parseDate(date);
    if (!dateObj) return null;

    return DateUtil.getDayOfYear(dateObj);
  }

  /**
   * 判断指定年份是否为闰年
   *
   * @param year 年份
   * @returns 是否为闰年
   *
   * @example
   * ```typescript
   * DateUtil.isLeapYear(2024)  // true  (能被4整除且不是世纪年，或能被400整除)
   * DateUtil.isLeapYear(2023)  // false
   * DateUtil.isLeapYear(2000)  // true  (能被400整除)
   * DateUtil.isLeapYear(1900)  // false (能被100整除但不能被400整除)
   *
   * // 结合使用：获取当年总天数
   * const year = new Date().getFullYear();
   * const totalDays = DateUtil.isLeapYear(year) ? 366 : 365;
   * console.log(`${year}年共有 ${totalDays} 天`);
   * ```
   *
   * @static
   * @public
   */
  public static isLeapYear(year: number): boolean {
    return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
  }

  /**
   * 判断两个日期是否为同一天
   *
   * 只比较年月日，忽略时分秒
   *
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 是否为同一天
   *
   * @private
   * @static
   */
  private static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
  }
}


// const eventStart = new Date('2025-08-01');
// const eventEnd = new Date('2025-08-31');
// const now = new Date();

// if (DateUtil.isBetween(now, eventStart, eventEnd)) {
//   console.log('活动进行中 🎉');
// } else if (DateUtil.isBefore(now, eventStart)) {
//   console.log('活动未开始 ⏰');
// } else {
//   console.log('活动已结束 ✅');
// }

