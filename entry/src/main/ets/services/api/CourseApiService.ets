import { CourseInfo, CoursePosition, CourseRequestParams, TodayCourseRequestParams } from '../../models/CourseModels';
import { ApiResponse, HttpService } from './HttpService';

// 导出类型
export { CourseInfo, CoursePosition } from '../../models/CourseModels';

export class CourseApiService {
  private static instance: CourseApiService;
  private httpService = HttpService.getInstance();

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
  public async getCourseList(params: CourseRequestParams): Promise<ApiResponse<CourseInfo[]>> {
    try {

      const response = await this.httpService.get<CourseRequestParams,CourseInfo[]>('/course', params);

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
   * 获取今日课程列表 (使用getCourseFilter接口)
   */
  public async getTodayCourseList(classId: string, year: number, term: string, weeks: number, weekday: string): Promise<ApiResponse<CourseInfo[]>> {
    try {
      // 构建请求参数，使用接口类型
      const params: TodayCourseRequestParams = {
        classId: classId,
        year: year,
        term: term,
        weeks: weeks,
        weekday: weekday
      };

      const response = await this.httpService.get<TodayCourseRequestParams,CourseInfo[]>('/course/getCourseFilter', params);

      return {
        msg: "操作成功",
        code: response.code || 200,
        data: response.data
      };
    } catch (error) {
      console.error('获取今日课程失败:', error);
      throw new Error('获取今日课程失败');
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