/**
 * 教务系统课程服务
 *
 * 参考: dev-doc/jwxt/api/getCourse.ts
 * 直接调用教务系统接口获取课程数据
 * 使用现有的 JwxtHttpClient（带有 Cookie 管理）
 *
 * @author AI Refactor
 * @date 2026-01-07
 */

import { JwxtHttpClient } from './JwxtHttpClient';
import { JwxtCourseParams, JwxtCourseRawData, JwxtCourseResponse, JwxtCourse } from '../../models/JwxtCourseModels';
import { CourseParser } from '../../common/utils/CourseParser';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { url } from '@kit.ArkTS';

const DOMAIN: number = 0x0002;
const TAG: string = 'JwxtCourseService';

/**
 * 教务系统课程服务
 *
 * 功能:
 * - 调用教务系统课程接口
 * - 解析课程数据 (使用 CourseParser)
 * - 数据格式转换
 */
export class JwxtCourseService {
  private static instance: JwxtCourseService;
  private httpClient: JwxtHttpClient;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
  }

  /**
   * 获取单例
   */
  public static getInstance(): JwxtCourseService {
    if (!JwxtCourseService.instance) {
      JwxtCourseService.instance = new JwxtCourseService();
    }
    return JwxtCourseService.instance;
  }

  /**
   * 初始化服务（必须在使用前调用）
   *
   * @param context 应用上下文
   */
  public async initialize(context: Context): Promise<void> {
    await this.httpClient.initialize(context);
    hilog.info(DOMAIN, TAG, '✅ JwxtCourseService 初始化完成');
  }

  /**
   * 获取课程列表
   *
   * 参考: dev-doc/jwxt/api/getCourse.ts 的 getCourse 函数
   *
   * @param params 课程请求参数 (学年、学期)
   * @returns 标准化的课程列表
   */
  public async getCourseList(params: JwxtCourseParams): Promise<JwxtCourse[]> {
    try {
      hilog.info(DOMAIN, TAG, `获取课程: ${params.year}学年 第${params.term}学期`);

      const apiUrl: string = 'kbcx/xskbcx_cxXsKb.html?gnmkdm=N2151';
      const referer: string = 'kbcx/xskbcx_cxXsKb.html?gnmkdm=N2151&layout=default';

      // 计算学期代号: term^2 * 3
      // 第一学期 (1): 1^2 * 3 = 3
      // 第二学期 (2): 2^2 * 3 = 12
      const xqm: number = Math.pow(params.term, 2) * 3;

      // 构造表单数据
      const form: url.URLSearchParams = new url.URLSearchParams();
      form.append('xnm', params.year);
      form.append('xqm', xqm.toString());

      // 发起 POST Form 请求
      let data: JwxtCourseResponse | JwxtCourseRawData[] = await this.httpClient.postForm<JwxtCourseResponse | JwxtCourseRawData[]>(
        apiUrl,
        form,
        referer
      );

      // 📊 日志: 打印原始响应数据
      hilog.info(DOMAIN, TAG, `========== 教务系统接口原始响应 ==========`);
      hilog.info(DOMAIN, TAG, `响应数据类型: ${typeof data}`);
      hilog.info(DOMAIN, TAG, `是否为数组: ${Array.isArray(data)}`);
      hilog.info(DOMAIN, TAG, `响应数据(JSON): ${JSON.stringify(data)}`);
      hilog.info(DOMAIN, TAG, `========================================`);

      // 如果第一次请求失败或格式异常,尝试 GET 请求
      if (!data || typeof data !== 'object') {
        hilog.warn(DOMAIN, TAG, 'POST 请求失败,尝试 GET 请求');
        data = await this.httpClient.get<JwxtCourseResponse>(apiUrl, referer);

        // 📊 日志: 打印 GET 请求的响应
        hilog.info(DOMAIN, TAG, `========== GET 请求响应 ==========`);
        hilog.info(DOMAIN, TAG, `GET 响应(JSON): ${JSON.stringify(data)}`);
        hilog.info(DOMAIN, TAG, `===================================`);
      }

      // 验证响应格式
      if (!data || typeof data !== 'object') {
        throw new Error('获取信息失败：返回格式异常');
      }

      // 提取课程列表
      const items: JwxtCourseRawData[] = Array.isArray(data) ? data : (data as JwxtCourseResponse).kbList ?? [];

      // 📊 日志: 打印提取的课程列表
      hilog.info(DOMAIN, TAG, `========== 提取的课程数据 ==========`);
      hilog.info(DOMAIN, TAG, `课程数量: ${items.length}`);
      if (items.length > 0) {
        hilog.info(DOMAIN, TAG, `第一门课程示例: ${JSON.stringify(items[0])}`);
        hilog.info(DOMAIN, TAG, `第一门课程字段:`);
        hilog.info(DOMAIN, TAG, `  - kch_id (课程号): ${items[0].kch_id}`);
        hilog.info(DOMAIN, TAG, `  - kcmc (课程名): ${items[0].kcmc}`);
        hilog.info(DOMAIN, TAG, `  - xm (教师): ${items[0].xm}`);
        hilog.info(DOMAIN, TAG, `  - cdmc (教室): ${items[0].cdmc}`);
        hilog.info(DOMAIN, TAG, `  - xqj (星期): ${items[0].xqj}`);
        hilog.info(DOMAIN, TAG, `  - jcs (节次): ${items[0].jcs}`);
        hilog.info(DOMAIN, TAG, `  - zcd (周次): ${items[0].zcd}`);
        hilog.info(DOMAIN, TAG, `  - xqmc (校区): ${items[0].xqmc}`);
      }
      hilog.info(DOMAIN, TAG, `====================================`);

      hilog.info(DOMAIN, TAG, `获取到 ${items.length} 门课程`);

      // 转换为标准格式
      const courses: JwxtCourse[] = items.map((item: JwxtCourseRawData) => this.convertRawDataToCourse(item));

      // 📊 日志: 打印转换后的数据
      hilog.info(DOMAIN, TAG, `========== 转换后的课程数据 ==========`);
      if (courses.length > 0) {
        hilog.info(DOMAIN, TAG, `第一门课程转换结果: ${JSON.stringify(courses[0])}`);
      }
      hilog.info(DOMAIN, TAG, `====================================`);

      return courses;

    } catch (error) {
      hilog.error(DOMAIN, TAG, `获取课程失败: ${error}`);
      throw new Error(`获取课程列表失败: ${error}`);
    }
  }

  /**
   * 将教务系统原始数据转换为标准课程格式
   *
   * 参考: dev-doc/jwxt/api/getCourse.ts 的数据映射逻辑
   *
   * @param raw 教务系统原始数据
   * @returns 标准化的课程数据
   */
  private convertRawDataToCourse(raw: JwxtCourseRawData): JwxtCourse {
    return {
      id: raw.kch_id,                                  // 课程号
      classroom: raw.cdmc || '',                       // 教室
      sessions: CourseParser.parseSessions(raw.jcs),   // 节次数组 (使用 CourseParser 解析)
      name: raw.kcmc || '',                            // 课程名称
      teacher: raw.xm || '',                           // 任课教师
      dayOfWeek: Number(raw.xqj) || 1,                 // 星期 (1-7)
      weeks: CourseParser.parseWeeks(raw.zcd),         // 周次数组 (使用 CourseParser 解析)
      campus: raw.xqmc                                 // 校区
    };
  }

  /**
   * 根据学期信息构建课程请求参数
   *
   * @param academicYear 学年 (如 "2024")
   * @param semester 学期 (1 或 2)
   * @returns 课程请求参数
   */
  public buildCourseParams(academicYear: string, semester: number): JwxtCourseParams {
    return {
      year: academicYear,
      term: semester
    };
  }
}
