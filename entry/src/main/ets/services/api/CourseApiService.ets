import { CourseInfo, CoursePosition, CourseRequestParams, TodayCourseRequestParams } from '../../models/CourseModels';
import { ApiResponse, HttpService } from './HttpService';
import { CacheManager } from '../../common/utils/CacheManager';
import { ErrorUtil } from '../../common/utils/ErrorUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 导出类型
export { CourseInfo, CoursePosition } from '../../models/CourseModels';

const DOMAIN: number = 0x0001;
const TAG: string = 'CourseApiService';

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
   * 获取课程列表 (支持缓存和降级)
   */
  public async getCourseList(params: CourseRequestParams): Promise<ApiResponse<CourseInfo[]>> {
    try {
      // 1. 发起HTTP请求
      const response = await this.httpService.get<CourseRequestParams, CourseInfo[]>('/course', params);

      // 2. 请求成功: 异步缓存数据 (不阻塞返回)
      if (response.code === 200 && params.week && params.year && params.term) {
        CacheManager.saveScheduleCache(params.year, params.term, params.week, response.data)
          .catch((err: Error) => {
            hilog.error(DOMAIN, TAG, `缓存课表失败: ${err.message}`);
          });
      }

      return {
        msg: "操作成功",
        code: response.code || 200,
        data: response.data
      };
    } catch (error) {
      // 3. 网络错误: 尝试降级到缓存
      if (ErrorUtil.isNetworkError(error) && params.week && params.year && params.term) {
        hilog.warn(DOMAIN, TAG, `网络错误,尝试读取缓存: ${ErrorUtil.formatError(error)}`);

        const cached = await CacheManager.getScheduleCache(params.year, params.term, params.week);
        if (cached) {
          hilog.info(DOMAIN, TAG, `✅ 使用缓存数据: ${params.year}学年 学期${params.term} 第${params.week}周`);
          return {
            code: 200,
            data: cached,
            msg: '离线数据'
          };
        } else {
          hilog.warn(DOMAIN, TAG, `⚠️ 缓存不存在,无法降级`);
        }
      }

      // 4. 无缓存或非网络错误: 抛出原始错误
      console.error('获取课程列表失败:', error);
      throw new Error('获取课程列表失败');
    }
  }

  /**
   * 获取今日课程列表 (使用getCourseFilter接口，支持缓存降级)
   */
  public async getTodayCourseList(classId: string, year: number, term: string, weeks: number,
    weekday: string): Promise<ApiResponse<CourseInfo[]>> {
    try {
      // 构建请求参数，使用接口类型
      const params: TodayCourseRequestParams = {
        classId: classId,
        year: year,
        term: term,
        weeks: weeks,
        weekday: weekday
      };

      const response =
        await this.httpService.get<TodayCourseRequestParams, CourseInfo[]>('/course/getCourseFilter', params);

      return {
        msg: "操作成功",
        code: response.code || 200,
        data: response.data
      };
    } catch (error) {
      // 网络错误: 尝试从当周缓存中筛选今日课程
      if (ErrorUtil.isNetworkError(error)) {
        hilog.warn(DOMAIN, TAG, `获取今日课程网络错误,尝试从缓存筛选: ${ErrorUtil.formatError(error)}`);

        const yearStr = year.toString();
        const termStr = term.toString();

        // 从缓存读取当周完整课程数据
        const cached = await CacheManager.getScheduleCache(yearStr, termStr, weeks);
        if (cached && cached.length > 0) {
          // 根据 weekday 筛选今日课程
          const todayCourses = cached.filter((course: CourseInfo) => course.weekday === weekday);
          hilog.info(DOMAIN, TAG,
            `✅ 从缓存筛选今日课程成功: ${yearStr}学年 学期${termStr} 第${weeks}周 ${weekday}, 课程数: ${todayCourses.length}`);

          return {
            code: 200,
            data: todayCourses,
            msg: '离线数据'
          };
        } else {
          hilog.warn(DOMAIN, TAG, `⚠️ 当周缓存不存在,无法降级`);
        }
      }

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