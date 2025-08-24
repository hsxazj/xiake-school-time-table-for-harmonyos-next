import { HttpService } from './HttpService';

// 课程API请求参数
export interface CourseRequestParams {
  week: number; // 第几周
  term: string; // 学期代号：3为第一学期(秋季)，12为第二学期(春季)
  year: string; // 学年，如"2024"
  classId?: string; // 班级ID
  username?: string; // 学生用户名
}

// 课程信息
export interface CourseInfo {
  courseId: number; // 课程ID为数字
  courseName: string;
  teacher: string; // 教师为字符串，不是数组
  classroom: string; // 教室为字符串，不是数组
  weekday: string; // 星期几，如"星期一"
  section: string; // 节次，如"1-2节"
  weeks: string; // 周次，如"[2,3,4,6,7,8,9,10,11]"
  courseTime: string[]; // 具体上课时间
  campus: string; // 校区
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

  private constructor() {
  }

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
   * 根据学期信息构建课程请求参数
   */
  public buildCourseParams(academicYear: string, semester: number, week: number, classId?: string,
    username?: string): CourseRequestParams {
    return {
      week: week,
      term: semester === 1 ? '3' : '12', // 第一学期用3，第二学期用12
      year: academicYear,
      classId: classId,
      username: username
    };
  }
}