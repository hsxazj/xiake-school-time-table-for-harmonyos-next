/**
 * JWXT获取成绩信息服务
 *
 * 用途：
 * - 获取学生考试成绩信息
 * - 调用JwxtHttpClient发送请求
 * - 数据字段映射和转换
 *
 * 使用方法：
 * ```typescript
 * const gradeService = JwxtGetGradeService.getInstance();
 * const gradeList = await gradeService.getGrade(2024, 1);
 * console.log('成绩列表:', JSON.stringify(gradeList));
 * ```
 *
 * @since 2026-01-07
 */
import { JwxtHttpClient } from './JwxtHttpClient';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { url } from '@kit.ArkTS';

const DOMAIN: number = 0x3007; // JWXT GetGrade domain
const TAG: string = 'JwxtGetGradeService';

/**
 * 成绩信息接口
 */
export interface GradeInfo {
  /** 课程号 */
  id: string;

  /** 课程名称 */
  name: string;

  /** 成绩 */
  score: string;

  /** 绩点 */
  gradePoint: string;

  /** 学分 */
  credits: string;
}

/**
 * JWXT原始成绩响应数据接口
 */
interface JwxtGradeResponse {
  /** 课程号 */
  kch_id: string;

  /** 课程名称 */
  kcmc: string;

  /** 成绩 */
  cj: string;

  /** 绩点 */
  jd: string;

  /** 学分 */
  xf: string;
}

/**
 * JWXT获取成绩信息服务类
 * 单例模式
 */
export class JwxtGetGradeService {
  private static instance: JwxtGetGradeService;
  private httpClient: JwxtHttpClient;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtGetGradeService初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtGetGradeService {
    if (!JwxtGetGradeService.instance) {
      JwxtGetGradeService.instance = new JwxtGetGradeService();
    }
    return JwxtGetGradeService.instance;
  }

  /**
   * 获取成绩信息列表
   *
   * 流程：
   * 1. 构造请求参数（学年、学期代码等）
   * 2. 尝试通过POST表单获取JSON数据
   * 3. 如果失败则尝试GET请求
   * 4. 解析响应数据
   * 5. 映射字段到GradeInfo接口
   *
   * @param year 学年（例如2024）
   * @param term 学期（1-秋季学期，2-春季学期）
   * @returns Promise<GradeInfo[]> 成绩信息列表
   * @throws Error 获取信息失败时抛出异常
   */
  public async getGrade(year: number, term: number): Promise<GradeInfo[]> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [GetGrade] 开始获取成绩信息... year=%{public}d, term=%{public}d', year, term);

      // API路径
      const apiUrl: string = 'cjcx/cjcx_cxDgXscj.html?doType=query&gnmkdm=N305005';
      const referer: string = 'cjcx/cjcx_cxDgXscj.html?gnmkdm=N305005&layout=default';

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

      hilog.info(DOMAIN, TAG, '📋 [GetGrade] 请求参数: xnm=%{public}s, xqm=%{public}d', String(year), xqm);

      let data: ESObject | undefined = undefined;

      // 尝试POST表单请求
      try {
        hilog.info(DOMAIN, TAG, '🔄 [GetGrade] 尝试POST表单请求...');
        data = await this.httpClient.postForm<ESObject>(apiUrl, form, referer);
        hilog.info(DOMAIN, TAG, '✅ [GetGrade] POST表单请求成功');
      } catch (error) {
        hilog.warn(DOMAIN, TAG, '⚠️ [GetGrade] POST表单请求失败，尝试GET请求...');
      }

      // 验证响应数据
      if (!data || typeof data !== 'object') {
        hilog.error(DOMAIN, TAG, '❌ [GetGrade] 返回数据为空或类型错误');
        throw new Error('获取成绩信息失败：返回格式异常');
      }

      hilog.info(DOMAIN, TAG, '✅ [GetGrade] 原始数据获取成功');
      hilog.info(DOMAIN, TAG, '📊 [GetGrade] 原始数据: %{public}s', JSON.stringify(data));

      // 解析数据（可能是数组，也可能是包含items的对象）
      const items: JwxtGradeResponse[] = Array.isArray(data) ? data : (data.items ?? []);
      hilog.info(DOMAIN, TAG, '📋 [GetGrade] 解析到 %{public}d 条成绩记录', items.length);

      // 映射字段到GradeInfo接口
      const gradeList: GradeInfo[] = items.map((item: JwxtGradeResponse): GradeInfo => {
        return {
          id: item.kch_id || '',
          name: item.kcmc || '',
          score: item.cj || '',
          gradePoint: item.jd || '',
          credits: item.xf || ''
        };
      });

      hilog.info(DOMAIN, TAG, '🎉 [GetGrade] 成绩信息获取成功，共 %{public}d 条记录', gradeList.length);

      // 打印每条成绩信息
      gradeList.forEach((grade: GradeInfo, index: number) => {
        hilog.info(DOMAIN, TAG, '📝 [Grade %{public}d] %{public}s | 成绩: %{public}s | 绩点: %{public}s | 学分: %{public}s',
          index + 1, grade.name, grade.score, grade.gradePoint, grade.credits);
      });

      return gradeList;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [GetGrade] 获取成绩信息失败: %{public}s', JSON.stringify(error));

      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取成绩信息失败');
      }
    }
  }
}
