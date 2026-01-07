/**
 * JWXT获取考试信息服务
 *
 * 用途：
 * - 获取学生考试安排信息
 * - 调用JwxtHttpClient发送请求
 * - 数据字段映射和转换
 *
 * 使用方法：
 * ```typescript
 * const examService = JwxtGetExamService.getInstance();
 * const examList = await examService.getExam(2024, 1);
 * console.log('考试列表:', JSON.stringify(examList));
 * ```
 *
 * @since 2026-01-07
 */
import { JwxtHttpClient } from './JwxtHttpClient';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { url } from '@kit.ArkTS';
import { ExamInfo, JwxtExamResponse } from '../../models/ExamModels';

const DOMAIN: number = 0x3006; // JWXT GetExam domain
const TAG: string = 'JwxtGetExamService';

/**
 * JWXT获取考试信息服务类
 * 单例模式
 */
export class JwxtGetExamService {
  private static instance: JwxtGetExamService;
  private httpClient: JwxtHttpClient;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtGetExamService初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtGetExamService {
    if (!JwxtGetExamService.instance) {
      JwxtGetExamService.instance = new JwxtGetExamService();
    }
    return JwxtGetExamService.instance;
  }

  /**
   * 获取考试信息列表
   *
   * 流程：
   * 1. 构造请求参数（学年、学期代码等）
   * 2. 尝试通过POST表单获取JSON数据
   * 3. 如果失败则尝试GET请求
   * 4. 解析响应数据
   * 5. 映射字段到ExamInfo接口
   *
   * @param year 学年（例如2024）
   * @param term 学期（1-秋季学期，2-春季学期）
   * @returns Promise<ExamInfo[]> 考试信息列表
   * @throws Error 获取信息失败时抛出异常
   */
  public async getExam(year: number, term: number): Promise<ExamInfo[]> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [GetExam] 开始获取考试信息... year=%{public}d, term=%{public}d', year, term);

      // API路径
      const apiUrl: string = 'kwgl/kscx_cxXsksxxIndex.html?doType=query&gnmkdm=N358105';
      const referer: string = 'kwgl/kscx_cxXsksxxIndex.html?gnmkdm=N358105&layout=default';

      // 计算学期码（xqm）
      // 秋季学期(1): 3, 春季学期(2): 12
      const xqm = term ** 2 * 3;

      // 构造表单参数
      const form: url.URLSearchParams = new url.URLSearchParams();
      form.set('xnm', String(year));
      form.set('xqm', String(xqm));
      form.set('_search', 'false');
      form.set('nd', String(Date.now()));
      form.set('queryModel.showCount', '100');
      form.set('queryModel.currentPage', '1');
      form.set('queryModel.sortName', '');
      form.set('queryModel.sortOrder', 'asc');
      form.set('time', '0');

      hilog.info(DOMAIN, TAG, '📋 [GetExam] 请求参数: xnm=%{public}s, xqm=%{public}d', String(year), xqm);

      let data: ESObject | undefined = undefined;

      // 尝试POST表单请求
      try {
        hilog.info(DOMAIN, TAG, '🔄 [GetExam] 尝试POST表单请求...');
        data = await this.httpClient.postForm<ESObject>(apiUrl, form, referer);
        hilog.info(DOMAIN, TAG, '✅ [GetExam] POST表单请求成功');
      } catch (error) {
        hilog.warn(DOMAIN, TAG, '⚠️ [GetExam] POST表单请求失败，尝试GET请求...');
      }

      // 如果POST失败，尝试GET请求
      if (!data || typeof data !== 'object') {
        hilog.info(DOMAIN, TAG, '🔄 [GetExam] 尝试GET请求...');
        data = await this.httpClient.get<ESObject>(apiUrl, referer);
        hilog.info(DOMAIN, TAG, '✅ [GetExam] GET请求成功');
      }

      // 验证响应数据
      if (!data || typeof data !== 'object') {
        hilog.error(DOMAIN, TAG, '❌ [GetExam] 返回数据为空或类型错误');
        throw new Error('获取考试信息失败：返回格式异常');
      }

      hilog.info(DOMAIN, TAG, '✅ [GetExam] 原始数据获取成功');
      hilog.info(DOMAIN, TAG, '📊 [GetExam] 原始数据: %{public}s', JSON.stringify(data));

      // 解析数据（可能是数组，也可能是包含items的对象）
      const items: JwxtExamResponse[] = Array.isArray(data) ? data : (data.items ?? []);
      hilog.info(DOMAIN, TAG, '📋 [GetExam] 解析到 %{public}d 条考试记录', items.length);

      // 映射字段到ExamInfo接口
      const examList: ExamInfo[] = items.map((item: JwxtExamResponse): ExamInfo => {
        return {
          id: item.sjbh || '',
          name: item.kcmc || '',
          time: item.kssj || '',
          classroom: item.cdmc || '',
          seat: item.zwh || ''
        };
      });

      hilog.info(DOMAIN, TAG, '🎉 [GetExam] 考试信息获取成功，共 %{public}d 条记录', examList.length);

      // 打印每条考试信息
      examList.forEach((exam: ExamInfo, index: number) => {
        hilog.info(DOMAIN, TAG, '📝 [Exam %{public}d] %{public}s | %{public}s | %{public}s | 座位: %{public}s',
          index + 1, exam.name, exam.time, exam.classroom, exam.seat);
      });

      return examList;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [GetExam] 获取考试信息失败: %{public}s', JSON.stringify(error));

      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取考试信息失败');
      }
    }
  }
}
