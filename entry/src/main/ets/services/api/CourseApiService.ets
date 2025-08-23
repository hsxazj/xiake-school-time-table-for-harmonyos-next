import { HttpService } from './HttpService';
import { ApiResponse } from '../../models/CollegeModels';

// 课程API请求参数
export interface CourseRequestParams {
  week: number;        // 第几周
  term: string;        // 学期代号：3为第一学期(秋季)，12为第二学期(春季)
  year: string;        // 学年，如"2024"
  classId?: string;    // 班级ID
  username?: string;   // 学生用户名
}

// 课程信息
export interface CourseInfo {
  courseId: string;
  courseName: string;
  teacher: string[];
  classroom: string[];
  weekday: string;     // 星期几，如"星期一"
  section: string;     // 节次，如"1,2"
  weeks: string;       // 周次，如"1-16"
  courseTime: string[]; // 具体上课时间
}

// 课程API响应
export interface CourseApiResponse {
  msg: string;
  code: number;
  data: CourseInfo[];
}

// 课程位置信息
export interface CoursePosition {
  week: number;
  day: number;
  timeSlot: number;
  course: CourseInfo;
}

export class CourseApiService {
  private static instance: CourseApiService;
  private httpService = HttpService.getInstance();
  private coursePositions: CoursePosition[] = [];

  private constructor() {}

  public static getInstance(): CourseApiService {
    if (!CourseApiService.instance) {
      CourseApiService.instance = new CourseApiService();
    }
    return CourseApiService.instance;
  }

  /**
   * 获取课程列表
   */
  public async getCourseList(params: CourseRequestParams): Promise<CourseApiResponse> {
    try {
      // 构建请求参数
      const requestParams = new Map<string, Object>();
      requestParams.set('week', params.week);
      requestParams.set('term', params.term);
      requestParams.set('year', params.year);
      
      if (params.classId) {
        requestParams.set('classId', params.classId);
      }
      
      if (params.username) {
        requestParams.set('username', params.username);
      }

      // 将Map转换为普通对象
      const paramsObj: Record<string, Object> = {};
      requestParams.forEach((value, key) => {
        paramsObj[key] = value;
      });

      const response = await this.httpService.get<CourseInfo[]>('/course', paramsObj);
      
      return {
        msg: "操作成功",
        code: response.code || 200,
        data: response.data
      };
    } catch (error) {
      console.error('获取课程列表失败:', error);
      throw new Error('获取课程列表失败');
    }
  }

  /**
   * 处理课程数据 - 将线性数据转换为位置列表
   * 参考class-schedule-c的数据处理逻辑
   */
  public processCourseData(courseList: CourseInfo[]): void {
    this.coursePositions = [];
    
    courseList.forEach(course => {
      // 解析周次范围
      const weekRanges = this.parseWeekRange(course.weeks);
      
      // 解析节次
      const timeSlots = this.parseSectionToTimeSlots(course.section);
      
      // 获取星期对应的数字
      const dayIndex = this.getWeekdayIndex(course.weekday);
      if (dayIndex === -1) return;

      // 为每个周次和时间段创建课程位置
      weekRanges.forEach(week => {
        timeSlots.forEach(timeSlot => {
          this.coursePositions.push({
            week: week,
            day: dayIndex,
            timeSlot: timeSlot,
            course: course
          });
        });
      });
    });

    console.info(`📚 [Course Processing] 处理了${courseList.length}门课程，生成${this.coursePositions.length}个课程位置`);
  }

  /**
   * 获取星期对应的索引
   */
  private getWeekdayIndex(weekday: string): number {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays.indexOf(weekday) + 1; // 1-7
  }

  /**
   * 解析周次范围，如"1-16"解析为[1,2,3,...,16]
   */
  private parseWeekRange(weeksStr: string): number[] {
    const weeks: number[] = [];
    
    if (!weeksStr) return weeks;
    
    // 处理多种格式: "1-16", "1,3,5-7", "单周1-15", "双周2-16"等
    const cleanWeeksStr = weeksStr.replace(/[单双周]/g, '');
    const parts = cleanWeeksStr.split(',');
    
    parts.forEach(part => {
      if (part.includes('-')) {
        const dashIndex = part.indexOf('-');
        const start = parseInt(part.substring(0, dashIndex).trim());
        const end = parseInt(part.substring(dashIndex + 1).trim());
        for (let i = start; i <= end; i++) {
          if (!weeks.includes(i)) {
            weeks.push(i);
          }
        }
      } else {
        const week = parseInt(part.trim());
        if (!isNaN(week) && !weeks.includes(week)) {
          weeks.push(week);
        }
      }
    });

    return weeks.sort((a, b) => a - b);
  }

  /**
   * 解析节次到时间段索引，如"1,2"解析为[0] (第1个时间段)
   * "3,4"解析为[1] (第2个时间段)
   */
  private parseSectionToTimeSlots(sectionStr: string): number[] {
    if (!sectionStr) return [];
    
    const sections = sectionStr.split(',').map(s => parseInt(s.trim()));
    const timeSlots: number[] = [];
    
    // 将节次转换为时间段索引 (每2节课为1个时间段)
    sections.forEach(section => {
      const timeSlotIndex = Math.floor((section - 1) / 2);
      if (!timeSlots.includes(timeSlotIndex)) {
        timeSlots.push(timeSlotIndex);
      }
    });

    return timeSlots;
  }

  /**
   * 根据学期信息构建课程请求参数
   */
  public buildCourseParams(academicYear: string, semester: number, week: number, classId?: string, username?: string): CourseRequestParams {
    return {
      week: week,
      term: semester === 1 ? '3' : '12', // 第一学期用3，第二学期用12
      year: academicYear,
      classId: classId,
      username: username
    };
  }

  /**
   * 获取指定位置的课程
   */
  public getCourseAt(week: number, day: number, timeSlot: number): CourseInfo | null {
    const position = this.coursePositions.find(pos => 
      pos.week === week && pos.day === day && pos.timeSlot === timeSlot
    );
    return position ? position.course : null;
  }

  /**
   * 获取指定周次的所有课程位置
   */
  public getWeekCourses(week: number): CoursePosition[] {
    return this.coursePositions.filter(pos => pos.week === week);
  }
}