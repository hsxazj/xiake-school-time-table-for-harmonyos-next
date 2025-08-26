import { ApiResponse, HttpService } from './HttpService';
import { DateUtil } from '../../common/utils/DateUtil';
import { ConfigApiResponseData, CurrentSemesterStatus, SemesterInfo, WeekDateRange } from '../../models/ConfigModels';

// 导出类型
export { CurrentSemesterStatus, SemesterInfo } from '../../models/ConfigModels';


export class ConfigApiService {
  private static instance: ConfigApiService;
  private semesterList: SemesterInfo[] = [];
  private currentStatus: CurrentSemesterStatus | null = null;
  private configData: ConfigApiResponseData | null = null;

  private constructor() {
  }

  public static getInstance(): ConfigApiService {
    if (!ConfigApiService.instance) {
      ConfigApiService.instance = new ConfigApiService();
    }
    return ConfigApiService.instance;
  }

  /**
   * 获取配置信息
   */
  public async getConfig(): Promise<ApiResponse<ConfigApiResponseData>> {
    try {
      const response = await HttpService.getInstance().get<Record<string, Object>>('/config');

      // 转换原始数据为Map结构
      const rawData = response.data as Record<string, Object>;
      const startMap = new Map<string, string[]>();
      const endMap = new Map<string, string[]>();

      if (rawData.start && typeof rawData.start === 'object') {
        const startData = rawData.start as Record<string, string[]>;
        Object.keys(startData).forEach((key: string) => {
          startMap.set(key, startData[key]);
        });
      }

      if (rawData.end && typeof rawData.end === 'object') {
        const endData = rawData.end as Record<string, string[]>;
        Object.keys(endData).forEach((key: string) => {
          endMap.set(key, endData[key]);
        });
      }

      // 构建完整的响应对象，包含新的字段
      const configResponse: ApiResponse<ConfigApiResponseData> = {
        msg: "操作成功",
        code: response.code || 200,
        data: { 
          start: startMap, 
          end: endMap,
          week: rawData.week as number,
          weekDayStr: rawData.weekDayStr as string,
          year: rawData.year as number,
          termCode: rawData.termCode as string
        }
      };

      // 存储配置数据
      this.configData = configResponse.data;

      // 处理学期数据
      this.processSemesterData(configResponse.data);

      return configResponse;
    } catch (error) {
      console.error('获取配置失败:', error);
      throw new Error('获取配置失败');
    }
  }

  /**
   * 计算当前学期状态 (完全参考class-schedule-c逻辑)
   */
  public calculateCurrentSemesterStatus(currentDate?: Date): CurrentSemesterStatus {
    const today = currentDate || new Date();

    // 先找到最近结束的学期，计算按该学期的周数
    let mostRecentEndedSemester: SemesterInfo | null = null;
    let latestEndDate = new Date(0); // 最早时间

    // 查找当前日期所在的学期，如果没有，找最近结束的学期
    for (const semester of this.semesterList) {
      // 使用更安全的日期解析方式
      const startDateParts = semester.startDate.split('-');
      const endDateParts = semester.endDate.split('-');

      const startDate = new Date(
        parseInt(startDateParts[0]),
        parseInt(startDateParts[1]) - 1, // 月份从0开始
        parseInt(startDateParts[2])
      );
      const endDate = new Date(
        parseInt(endDateParts[0]),
        parseInt(endDateParts[1]) - 1, // 月份从0开始
        parseInt(endDateParts[2])
      );

      // 使用DateUtil进行安全的日期比较
      if (DateUtil.isBetween(today, startDate, endDate)) {
        // 在学期中，计算当前周数
        const currentWeek = this.calculateWeekInSemester(semester.startDate, today);

        this.currentStatus = {
          isInSemester: true,
          isInHoliday: false,
          currentSemester: semester,
          currentWeek,
          statusText: `第${currentWeek}周`
        };

        console.info(`📅 [Current Status] 当前在${semester.academicYear}学年第${semester.semester}学期第${currentWeek}周`);
        return this.currentStatus;
      }

      // 记录最近结束的学期 - 使用DateUtil进行安全比较
      if (DateUtil.isAfter(today, endDate) && DateUtil.isAfter(endDate, latestEndDate)) {
        latestEndDate = endDate;
        mostRecentEndedSemester = semester;
      }
    }

    // 不在任何学期中，使用最近结束的学期来计算"假想周数"
    if (mostRecentEndedSemester) {
      const calculatedWeek = this.calculateWeekInSemester(mostRecentEndedSemester.startDate, today);

      console.info(`📅 [Week Debug] 最近结束学期: ${mostRecentEndedSemester.academicYear}学年第${mostRecentEndedSemester.semester}学期`);
      console.info(`📅 [Week Debug] 学期开始: ${mostRecentEndedSemester.startDate}, 当前日期: ${today.getFullYear()}-${String(today.getMonth() +
        1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`);
      console.info(`📅 [Week Debug] 计算出的周数: ${calculatedWeek}`);

      this.currentStatus = {
        isInSemester: false,
        isInHoliday: true,
        currentSemester: mostRecentEndedSemester, // 显示最近结束的学期
        currentWeek: calculatedWeek, // 显示超出的周数
        statusText: "假期中"
      };

      console.info(`📅 [Current Status] 当前在假期中，按${mostRecentEndedSemester.academicYear}学年第${mostRecentEndedSemester.semester}学期计算为第${calculatedWeek}周`);
      return this.currentStatus;
    }

    // 找不到任何相关学期，使用最早的未来学期作为参考
    let earliestFutureSemester: SemesterInfo | null = null;
    let earliestStartDate = new Date(9999, 0, 1); // 很远的未来时间

    for (const semester of this.semesterList) {
      const startDate = new Date(semester.startDate);
      if (DateUtil.isAfter(startDate, today) && DateUtil.isBefore(startDate, earliestStartDate)) {
        earliestStartDate = startDate;
        earliestFutureSemester = semester;
      }
    }

    this.currentStatus = {
      isInSemester: false,
      isInHoliday: true,
      currentSemester: earliestFutureSemester || undefined,
      currentWeek: 1,
      statusText: "假期中"
    };

    const semesterInfo = earliestFutureSemester
      ? `即将开始${earliestFutureSemester.academicYear}学年第${earliestFutureSemester.semester}学期`
      : '未找到相关学期';
    console.info(`📅 [Current Status] 当前在假期中，${semesterInfo}`);
    return this.currentStatus;
  }

  /**
   * 计算某个学期内的当前周数 (完全按照class-schedule-c的getWeek逻辑)
   */
  public calculateWeekInSemester(startDate: string, currentDate: Date): number {
    // 解析开始日期 - 完全按照class-schedule-c的方式
    const startDateArray = startDate.split("-"); // ["2025", "09", "08"]
    const semesterStartDate =
      new Date(startDateArray[1] + '-' + startDateArray[2] + '-' + startDateArray[0]); // "09-08-2025"

    // 解析当前日期 - 完全按照class-schedule-c的getNowTime和getWeek逻辑
    const currentYear = currentDate.getFullYear();
    const currentMonth = String(currentDate.getMonth() + 1).padStart(2, '0');
    const currentDay = String(currentDate.getDate()).padStart(2, '0');
    const nowTimeString = currentYear + '-' + currentMonth + '-' + currentDay; // "2025-08-23"

    const nowDateArray = nowTimeString.split("-"); // ["2025", "08", "23"]
    const todayDate = new Date(nowDateArray[1] + '-' + nowDateArray[2] + '-' + nowDateArray[0]); // "08-23-2025"

    // 计算相差天数 (完全按照class-schedule-c逻辑)
    const timeDifference = todayDate.getTime() - semesterStartDate.getTime();
    const daysDifference = Math.floor(timeDifference / (1000 * 60 * 60 * 24)); // iDays

    // 计算周数 (完全按照class-schedule-c的getWeek逻辑)
    let currentWeek: number;
    if (daysDifference < 0) {
      currentWeek = -1; // 天数差<0，周数统一设为-1
    } else if (0 <= daysDifference && daysDifference <= 6) {
      currentWeek = 1; // 0<=天数差<=6，在第一周
    } else {
      currentWeek = Math.ceil((daysDifference - 6) / 7) + 1; // 大于6多余的部分每多7天加1周
    }

    console.info(`📅 [Week Calculation] ${startDate} -> ${nowTimeString}, 相差${daysDifference}天, 第${currentWeek}周`);
    return currentWeek;
  }

  /**
   * 获取所有学期列表
   */
  public getSemesterList(): SemesterInfo[] {
    return this.semesterList;
  }

  /**
   * 获取当前状态
   */
  public getCurrentStatus(): CurrentSemesterStatus | null {
    return this.currentStatus;
  }

  /**
   * 根据学年和学期获取学期信息
   */
  public getSemesterInfo(academicYear: string, semester: number): SemesterInfo | null {
    return this.semesterList.find(sem => sem.academicYear === academicYear && sem.semester === semester) || null;
  }

  /**
   * 获取上一个/下一个学期
   */
  public getAdjacentSemester(current: SemesterInfo, direction: 'prev' | 'next'): SemesterInfo | null {
    const currentIndex = this.semesterList.findIndex(sem =>
    sem.academicYear === current.academicYear && sem.semester === current.semester
    );

    if (currentIndex === -1) {
      return null;
    }

    const targetIndex = direction === 'prev' ? currentIndex - 1 : currentIndex + 1;
    return this.semesterList[targetIndex] || null;
  }

  /**
   * 计算指定周的日期范围
   */
  public calculateWeekDates(startDate: string, weekNum: number): WeekDateRange {
    const semesterStart = new Date(startDate);

    // 计算该周的开始日期 (周一)
    const daysToAdd = (weekNum - 1) * 7;
    const weekStart = new Date(semesterStart);
    weekStart.setDate(semesterStart.getDate() + daysToAdd);

    // 找到该周的周一
    const dayOfWeek = weekStart.getDay();
    const daysToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    weekStart.setDate(weekStart.getDate() + daysToMonday);

    // 计算该周的结束日期 (周日)
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);

    return {
      startDate: weekStart,
      endDate: weekEnd
    };
  }

  /**
   * 格式化日期为字符串
   */
  public formatDateString(date: Date): string {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}月${day}日`;
  }

  /**
   * 获取月份
   */
  public getMonthString(date: Date): string {
    const month = date.getMonth() + 1;
    return `${month}月`;
  }

  /**
   * 向后兼容的方法 - 计算当前周数
   */
  public calculateCurrentWeek(startDate: string, currentDate?: Date): number {
    const status = this.calculateCurrentSemesterStatus(currentDate);
    return status.currentWeek;
  }

  /**
   * 获取当前周数 (从配置API返回的新字段)
   */
  public getCurrentWeekFromConfig(): number | undefined {
    return this.configData?.week;
  }

  /**
   * 获取当前星期字符串 (从配置API返回的新字段)
   */
  public getCurrentWeekDayString(): string | undefined {
    return this.configData?.weekDayStr;
  }

  /**
   * 获取当前年份 (从配置API返回的新字段)
   */
  public getCurrentYear(): number | undefined {
    return this.configData?.year;
  }

  /**
   * 获取学期代码 (从配置API返回的新字段)
   */
  public getTermCode(): string | undefined {
    return this.configData?.termCode;
  }

  /**
   * 处理学期数据 (参考class-schedule-c逻辑)
   */
  private processSemesterData(data: ConfigApiResponseData): void {
    this.semesterList = [];

    // 获取所有年份的数组
    const startYears = Array.from(data.start.keys());
    const endYears = Array.from(data.end.keys());

    // 合并年份并去重
    const allYears: string[] = [];
    startYears.forEach((year: string) => {
      if (!allYears.includes(year)) {
        allYears.push(year);
      }
    });
    endYears.forEach((year: string) => {
      if (!allYears.includes(year)) {
        allYears.push(year);
      }
    });

    // 处理每个年份的学期数据
    allYears.forEach((year: string) => {
      const startDates = data.start.get(year) || [];
      const endDates = data.end.get(year) || [];

      for (let i = 0; i < startDates.length; i++) {
        if (endDates[i]) {
          const startDate = new Date(startDates[i]);
          const endDate = new Date(endDates[i]);

          // 计算学期总周数
          const totalWeeks = Math.ceil((endDate.getTime() - startDate.getTime()) / (7 * 24 * 60 * 60 * 1000));

          // 确定学年和学期
          let academicYear: string;
          let semesterNumber: number;

          if (i % 2 === 0) {
            // 第一个日期是第一学期（秋季学期，9月开始）
            academicYear = year; // 学年以9月所在的年份命名
            semesterNumber = 1;
          } else {
            // 第二个日期是第二学期（春季学期，2-3月开始）
            // 春季学期属于同一学年，不是前一学年
            academicYear = year; // 同一学年
            semesterNumber = 2;
          }

          this.semesterList.push({
            academicYear,
            semester: semesterNumber,
            startDate: startDates[i],
            endDate: endDates[i],
            totalWeeks
          });
        }
      }
    });

    // 按开始日期排序
    this.semesterList.sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime());

    console.info(`📚 [Semester Data] 处理了${this.semesterList.length}个学期数据`);
    this.semesterList.forEach(sem => {
      console.info(`📚 [Semester] ${sem.academicYear}学年第${sem.semester}学期: ${sem.startDate} ~ ${sem.endDate} (${sem.totalWeeks}周)`);
    });
  }
}