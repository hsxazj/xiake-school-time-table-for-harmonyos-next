import { ApiResponse, HttpService } from './HttpService';
import { DateUtil } from '../../common/utils/DateUtil';
import { ConfigApiResponseData, CurrentSemesterStatus, SemesterInfo, WeekDateRange } from '../../models/ConfigModels';
import { CacheManager } from '../../common/utils/CacheManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 导出类型
export { CurrentSemesterStatus, SemesterInfo } from '../../models/ConfigModels';

const DOMAIN: number = 0x0002;
const TAG: string = 'ConfigApiService';

// 最远学期信息接口
interface FarthestSemesterInfo {
  semester: SemesterInfo | null;
  academicYear: string;
  semesterNumber: number;
  totalWeeks: number;
}


export class ConfigApiService {
  private static instance: ConfigApiService;
  private semesterList: SemesterInfo[] = [];
  private currentStatus: CurrentSemesterStatus | null = null;
  // 缓存最远学期信息，用于右滑极限判断
  private farthestSemester: SemesterInfo | null = null;
  private farthestAcademicYear: string = '';
  private farthestSemesterNumber: number = 0;
  private farthestTotalWeeks: number = 0;

  private constructor() {
  }

  public static getInstance(): ConfigApiService {
    if (!ConfigApiService.instance) {
      ConfigApiService.instance = new ConfigApiService();
    }
    return ConfigApiService.instance;
  }

  /**
   * 获取配置信息 (优先返回缓存,异步更新API)
   * 策略:
   * 1. 立即尝试读取缓存,如果有缓存则立即返回
   * 2. 异步发起API请求更新缓存
   * 3. 如果没有缓存,则等待API请求完成
   * @param context 上下文(可选,在卡片中必须传入 FormExtensionContext)
   */
  public async getConfig(context?: Context): Promise<ApiResponse<ConfigApiResponseData>> {
    try {
      // 1. 优先尝试读取缓存(传入context以支持卡片环境)
      const cached = await CacheManager.getConfigCache(context);

      if (cached) {
        hilog.info(DOMAIN, TAG, `✅ 优先使用缓存配置,异步更新中...`);

        // 处理学期数据
        this.processSemesterData(cached);

        // 异步发起API请求更新缓存 (不阻塞返回)
        this.updateConfigCacheInBackground(context);

        // 立即返回缓存数据
        return {
          code: 200,
          data: cached,
          msg: '缓存数据'
        };
      }

      // 2. 无缓存: 等待API请求完成
      hilog.info(DOMAIN, TAG, `⚠️ 无缓存,等待API请求...`);
      return await this.fetchAndCacheConfig(context);

    } catch (error) {
      // 3. 发生错误: 最后的降级尝试
      console.error('获取配置失败:', error);
      throw new Error('获取配置失败');
    }
  }

  /**
   * 后台异步更新配置缓存
   * 此方法不抛出异常,静默处理错误
   * @param context 上下文(可选,在卡片中必须传入 FormExtensionContext)
   */
  private updateConfigCacheInBackground(context?: Context): void {
    this.fetchAndCacheConfig(context)
      .then((response: ApiResponse<ConfigApiResponseData>) => {
        hilog.info(DOMAIN, TAG, `✅ 后台更新配置成功: ${response.msg}`);
        // 更新内存中的学期数据
        this.processSemesterData(response.data);
      })
      .catch((error: Error) => {
        hilog.warn(DOMAIN, TAG, `⚠️ 后台更新配置失败: ${error.message}`);
        // 静默处理错误,不影响用户体验
      });
  }

  /**
   * 从API获取配置并缓存
   * @param context 上下文(可选,在卡片中必须传入 FormExtensionContext)
   * @returns 配置响应数据
   */
  private async fetchAndCacheConfig(context?: Context): Promise<ApiResponse<ConfigApiResponseData>> {
    try {
      // 发起HTTP请求
      const response = await HttpService.getInstance().get<null, Record<string, Object>>('/config');

      // 转换原始数据为Map结构
      const rawData = response.data as Record<string, Record<string, string[]>>;
      const startMap = new Map<string, string[]>();
      const endMap = new Map<string, string[]>();

      if (rawData.start) {
        Object.keys(rawData.start).forEach((key: string) => {
          startMap.set(key, rawData.start[key]);
        });
      }

      if (rawData.end) {
        Object.keys(rawData.end).forEach((key: string) => {
          endMap.set(key, rawData.end[key]);
        });
      }

      // 构建完整的响应对象
      const configResponse: ApiResponse<ConfigApiResponseData> = {
        msg: "操作成功",
        code: response.code || 200,
        data: { start: startMap, end: endMap }
      };

      // 异步保存缓存 (不阻塞返回,传入context)
      if (configResponse.code === 200) {
        CacheManager.saveConfigCache(configResponse.data, context)
          .catch((err: Error) => {
            hilog.error(DOMAIN, TAG, `缓存配置失败: ${err.message}`);
          });
      }

      // 处理学期数据
      this.processSemesterData(configResponse.data);

      return configResponse;

    } catch (error) {
      // 无缓存或非网络错误: 抛出原始错误
      throw new Error('从api获取数据失败');
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
   * 计算某个学期内的当前周数
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
   * 判断是否可以前往上一周（右滑操作，向过去翻页）
   * @param currentDate 当前显示的日期
   * @param className 当前用户的班级名称
   * @returns true表示可以前往上一周，false表示已到极限
   */
  public canSwipeLeft(currentDate: Date, className?: string): boolean {
    if (this.semesterList.length === 0) {
      return false;
    }

    // 如果有班级信息，根据班级年级进行校验
    if (className) {
      const classGrade = this.extractGradeFromClassName(className);
      if (classGrade > 0) {
        // 找到该年级入学对应的最早学期
        const earliestValidDate = this.getEarliestValidDateForGrade(classGrade);

        // 计算前往上一周后的日期
        const previousWeekDate = new Date(currentDate);
        previousWeekDate.setDate(currentDate.getDate() - 7);

        if (previousWeekDate < earliestValidDate) {
          console.info(`📅 [Swipe Limit] 不能前往上一周：${classGrade}级学生在${previousWeekDate.toDateString()}之前尚未入学（最早入学日期：${earliestValidDate.toDateString()}）`);
          return false;
        }
      }
    }

    // 检查是否会早于最早学期的开始日期
    const earliestSemester = this.semesterList[0];
    const earliestStartDate = new Date(earliestSemester.startDate);

    const previousWeekDate = new Date(currentDate);
    previousWeekDate.setDate(currentDate.getDate() - 7);

    if (previousWeekDate < earliestStartDate) {
      console.info(`📅 [Swipe Limit] 不能前往上一周：上周日期(${previousWeekDate.toDateString()})早于最早学期开始日期(${earliestStartDate.toDateString()})`);
      return false;
    }

    console.info(`📅 [Swipe Check] 可以前往上一周：当前日期${currentDate.toDateString()}`);
    return true;
  }

  /**
   * 判断是否可以进入下一周（左滑操作，向未来翻页）
   * @param currentDate 当前显示的日期
   * @returns true表示可以进入下一周，false表示已到极限
   */
  public canSwipeRight(currentDate: Date): boolean {
    if (this.semesterList.length === 0 || !this.farthestSemester) {
      return false;
    }

    // 使用缓存的最远学期信息
    // 使用安全的日期解析方式，避免时区问题
    const endDateParts = this.farthestSemester.endDate.split('-');
    let latestEndDate = new Date(
      parseInt(endDateParts[0]),
      parseInt(endDateParts[1]) - 1, // 月份从0开始
      parseInt(endDateParts[2]),
      23, 59, 59, 999// 设置为当天的最后一刻
    );

    const startDateParts = this.farthestSemester.startDate.split('-');
    let latestStartDate = new Date(
      parseInt(startDateParts[0]),
      parseInt(startDateParts[1]) - 1, // 月份从0开始
      parseInt(startDateParts[2]),
      0, 0, 0, 0// 设置为当天的开始
    );

    // 情况1：检查下一周日期是否会超出最远学期结束日期
    const nextWeekDate = new Date(currentDate);
    nextWeekDate.setDate(currentDate.getDate() + 7);

    // 添加安全检查：如果日期解析明显有问题，则允许滑动
    const currentYear = currentDate.getFullYear();
    const endYear = latestEndDate.getFullYear();

    // 如果当前日期和结束日期的年份差异过大，可能是解析错误，允许滑动
    if (Math.abs(currentYear - endYear) > 2) {
      return true;
    }

    // 正常的滑动检查：检查下一周是否会超出范围
    if (nextWeekDate > latestEndDate) {
      if (currentDate >= latestStartDate && currentYear >= 2024 && currentYear <= 2026) {
      } else {
        return false;
      }
    }

    // 情况2：检查是否已经到达最后一学年的最后一学期的最后一周
    const currentStatus = this.calculateCurrentSemesterStatus(currentDate);
    if (currentStatus.currentSemester) {
      // 判断当前学期是否是最远学期
      const isLastSemester = (
        currentStatus.currentSemester.academicYear === this.farthestAcademicYear &&
          currentStatus.currentSemester.semester === this.farthestSemesterNumber
      );

      if (isLastSemester) {
        // 在最远学期中，检查是否是最后一周
        if (currentStatus.currentWeek >= this.farthestTotalWeeks) {
          console.info(`📅 [Swipe Limit] 不能进入下一周：当前是最远学期${this.farthestAcademicYear}学年第${this.farthestSemesterNumber}学期第${currentStatus.currentWeek}周（共${this.farthestTotalWeeks}周）`);
          return false;
        }
      }
    }

    console.info(`📅 [Swipe Check] 可以进入下一周：当前日期${currentDate.toDateString()}`);
    return true;
  }

  /**
   * 判断指定学期是否对指定年级有效
   * @param semester 学期信息
   * @param className 班级名称
   * @returns true表示该年级可以访问该学期，false表示不可访问
   */
  public isSemesterValidForGrade(semester: SemesterInfo, className?: string): boolean {
    if (!className) {
      return true; // 如果没有班级信息，默认允许访问
    }

    const classGrade = this.extractGradeFromClassName(className);
    if (classGrade === 0) {
      return true; // 如果无法提取年级，默认允许访问
    }

    // 25级学生在2025年入学，只能访问2025学年及之后的学期
    const enrollmentYear = 2000 + classGrade;
    const semesterYear = parseInt(semester.academicYear);

    const isValid = semesterYear >= enrollmentYear;

    if (!isValid) {
      console.info(`📅 [Semester Validation] ${classGrade}级学生不能访问${semester.academicYear}学年第${semester.semester}学期（入学年份：${enrollmentYear}）`);
    }

    return isValid;
  }

  /**
   * 判断是否可以切换到指定方向的学期
   * @param currentSemester 当前学期
   * @param direction 切换方向
   * @param className 班级名称
   * @returns true表示可以切换，false表示不可切换
   */
  public canSwitchSemester(currentSemester: SemesterInfo, direction: 'prev' | 'next', className?: string): boolean {
    const targetSemester = this.getAdjacentSemester(currentSemester, direction);

    if (!targetSemester) {
      return false; // 没有目标学期
    }

    // 如果是向前切换（上一个学期），需要检查年级限制
    if (direction === 'prev' && className) {
      return this.isSemesterValidForGrade(targetSemester, className);
    }

    return true;
  }

  /**
   * 判断指定学期的指定周数是否对年级有效
   * @param semester 学期信息
   * @param weekNum 周数
   * @param className 班级名称
   * @returns true表示该周数可选，false表示不可选
   */
  public isWeekValidForGrade(semester: SemesterInfo, weekNum: number, className?: string): boolean {
    // 首先检查学期是否对年级有效
    if (!this.isSemesterValidForGrade(semester, className)) {
      return false;
    }

    // 如果学期有效，所有周数都可选
    return true;
  }

  /**
   * 获取最远学期信息
   */
  public getFarthestSemesterInfo(): FarthestSemesterInfo {
    return {
      semester: this.farthestSemester,
      academicYear: this.farthestAcademicYear,
      semesterNumber: this.farthestSemesterNumber,
      totalWeeks: this.farthestTotalWeeks
    };
  }

  /**
   * 从班级名称中提取年级信息
   * @param className 班级名称，如"25软件工程1班"
   * @returns 年级数字，如25，如果无法提取则返回0
   */
  private extractGradeFromClassName(className: string): number {
    // 查找班级名称中的数字，通常年级在前面
    const gradeMatch = className.match(/(\d{2})/);
    if (gradeMatch) {
      const grade = parseInt(gradeMatch[1]);
      // 确保是合理的年级范围（20-30之间）
      if (grade >= 20 && grade <= 30) {
        return grade;
      }
    }

    console.warn(`📅 [Grade Extract] 无法从班级名称"${className}"中提取有效年级`);
    return 0;
  }

  /**
   * 根据年级获取该年级学生的最早有效入学日期
   * @param grade 年级，如25表示2025级
   * @returns 该年级的最早入学日期
   */
  private getEarliestValidDateForGrade(grade: number): Date {
    // 25级学生在2025年入学，对应2025学年第1学期
    const enrollmentYear = 2000 + grade;
    const academicYear = enrollmentYear.toString();

    // 查找该学年第1学期的开始日期
    const firstSemester = this.semesterList.find(sem =>
    sem.academicYear === academicYear && sem.semester === 1
    );

    if (firstSemester) {
      console.info(`📅 [Grade Validation] ${grade}级学生最早入学日期：${firstSemester.startDate}`);
      return new Date(firstSemester.startDate);
    }

    // 如果找不到对应学期，返回该年9月1日作为默认入学日期
    const defaultDate = new Date(enrollmentYear, 8, 1); // 9月1日（月份从0开始）
    console.info(`📅 [Grade Validation] ${grade}级学生使用默认入学日期：${defaultDate.toDateString()}`);
    return defaultDate;
  }

  /**
   * 处理学期数据
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

    // 缓存最远学期信息（最后一个学期）
    if (this.semesterList.length > 0) {
      this.farthestSemester = this.semesterList[this.semesterList.length - 1];
      this.farthestAcademicYear = this.farthestSemester.academicYear;
      this.farthestSemesterNumber = this.farthestSemester.semester;
      this.farthestTotalWeeks = this.farthestSemester.totalWeeks;

      console.info(`📚 [Farthest Semester] 最远学期: ${this.farthestAcademicYear}学年第${this.farthestSemesterNumber}学期，共${this.farthestTotalWeeks}周`);
    }

    console.info(`📚 [Semester Data] 处理了${this.semesterList.length}个学期数据`);
    this.semesterList.forEach(sem => {
      console.info(`📚 [Semester] ${sem.academicYear}学年第${sem.semester}学期: ${sem.startDate} ~ ${sem.endDate} (${sem.totalWeeks}周)`);
    });
  }
}