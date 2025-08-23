import { HttpService } from './HttpService';
import { ApiResponse } from '../../models/CollegeModels';

// 真实的/config API返回数据结构
export interface ConfigApiResponseData {
  start: Map<string, string[]>;
  end: Map<string, string[]>;
}

export interface ConfigApiResponse {
  msg: string;
  code: number;
  data: ConfigApiResponseData;
}

// 处理后的学期信息
export interface SemesterInfo {
  year: string;
  semester: number; // 1: 上学期(秋季), 2: 下学期(春季)
  startDate: string;
  endDate: string;
  totalWeeks: number;
}

// 当前状态信息
export interface CurrentSemesterStatus {
  isInSemester: boolean;
  isInHoliday: boolean;
  currentSemester?: SemesterInfo;
  currentWeek: number;
  statusText: string; // "第X周" 或 "假期中"
}

export interface WeekDateRange {
  startDate: Date;
  endDate: Date;
}

export class ConfigApiService {
  private static instance: ConfigApiService;
  private semesterList: SemesterInfo[] = [];
  private currentStatus: CurrentSemesterStatus | null = null;

  private constructor() {}

  public static getInstance(): ConfigApiService {
    if (!ConfigApiService.instance) {
      ConfigApiService.instance = new ConfigApiService();
    }
    return ConfigApiService.instance;
  }

  /**
   * 获取配置信息
   */
  public async getConfig(): Promise<ConfigApiResponse> {
    try {
      const response = await HttpService.getInstance().get<Record<string, Object>>('/config');
      
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
      const configResponse: ConfigApiResponse = {
        msg: "操作成功",
        code: response.code || 200,
        data: { start: startMap, end: endMap }
      };
      
      // 处理学期数据
      this.processSemesterData(configResponse.data);
      
      return configResponse;
    } catch (error) {
      console.error('获取配置失败:', error);
      throw new Error('获取配置失败');
    }
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
          
          // 判断是上学期还是下学期 (参考class-schedule-c: i % 2 === 0 ? "3" : "12")
          const semester = i % 2 === 0 ? 1 : 2; // 1: 秋季学期, 2: 春季学期
          
          this.semesterList.push({
            year,
            semester,
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
      console.info(`📚 [Semester] ${sem.year}年${sem.semester === 1 ? '秋季' : '春季'}学期: ${sem.startDate} ~ ${sem.endDate} (${sem.totalWeeks}周)`);
    });
  }

  /**
   * 计算当前学期状态 (完全参考class-schedule-c逻辑)
   */
  public calculateCurrentSemesterStatus(currentDate?: Date): CurrentSemesterStatus {
    const today = currentDate || new Date();
    
    // 查找当前日期所在的学期
    for (const semester of this.semesterList) {
      const startDate = new Date(semester.startDate);
      const endDate = new Date(semester.endDate);
      
      if (today >= startDate && today <= endDate) {
        // 在学期中，计算当前周数
        const currentWeek = this.calculateWeekInSemester(semester.startDate, today);
        
        this.currentStatus = {
          isInSemester: true,
          isInHoliday: false,
          currentSemester: semester,
          currentWeek,
          statusText: `第${currentWeek}周`
        };
        
        console.info(`📅 [Current Status] 当前在${semester.year}年${semester.semester === 1 ? '秋季' : '春季'}学期第${currentWeek}周`);
        return this.currentStatus;
      }
    }
    
    // 不在任何学期中，显示"假期中"
    this.currentStatus = {
      isInSemester: false,
      isInHoliday: true,
      currentWeek: 1,
      statusText: "假期中"
    };
    
    console.info(`📅 [Current Status] 当前在假期中`);
    return this.currentStatus;
  }

  /**
   * 计算某个学期内的当前周数 (参考class-schedule-c的getWeek逻辑)
   */
  public calculateWeekInSemester(startDate: string, currentDate: Date): number {
    // 解析开始日期 - 按照class-schedule-c的方式
    const startDateArray = startDate.split("-");
    const semesterStartDate = new Date(startDateArray[1] + '-' + startDateArray[2] + '-' + startDateArray[0]);
    
    // 解析当前日期
    const currentYear = currentDate.getFullYear();
    const currentMonth = String(currentDate.getMonth() + 1).padStart(2, '0');
    const currentDay = String(currentDate.getDate()).padStart(2, '0');
    const todayDate = new Date(currentMonth + '-' + currentDay + '-' + currentYear);
    
    // 计算相差天数
    const timeDifference = todayDate.getTime() - semesterStartDate.getTime();
    const daysDifference = Math.floor(timeDifference / (1000 * 60 * 60 * 24));
    
    // 计算周数 (完全按照class-schedule-c逻辑)
    let currentWeek: number;
    if (daysDifference < 0) {
      currentWeek = 1;
    } else if (0 <= daysDifference && daysDifference <= 6) {
      currentWeek = 1;
    } else {
      currentWeek = Math.ceil((daysDifference - 6) / 7) + 1;
    }
    
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
   * 根据年份和学期获取学期信息
   */
  public getSemesterInfo(year: string, semester: number): SemesterInfo | null {
    return this.semesterList.find(sem => sem.year === year && sem.semester === semester) || null;
  }

  /**
   * 获取上一个/下一个学期
   */
  public getAdjacentSemester(current: SemesterInfo, direction: 'prev' | 'next'): SemesterInfo | null {
    const currentIndex = this.semesterList.findIndex(sem => 
      sem.year === current.year && sem.semester === current.semester
    );
    
    if (currentIndex === -1) return null;
    
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
}