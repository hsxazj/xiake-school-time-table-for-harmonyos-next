import { CourseInfo, CoursePosition, CourseRequestParams } from '../../models/CourseModels';
import { ApiResponse, HttpService } from './HttpService';

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
  public async getCourseList(params: CourseRequestParams): Promise<ApiResponse<CourseInfo[]>> {
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