/**
 * JWXT获取个人信息服务
 *
 * 用途：
 * - 获取学生个人信息（姓名、学号、班级、学院等）
 * - 调用JwxtHttpClient发送请求
 * - 数据字段映射和转换
 *
 * 使用方法：
 * ```typescript
 * const infoService = JwxtGetInfoService.getInstance();
 * const studentInfo = await infoService.getInfo();
 * console.log('学生信息:', JSON.stringify(studentInfo));
 * ```
 *
 * @since 2026-01-07
 */
import { JwxtHttpClient } from './JwxtHttpClient';
import { JwxtConstants } from './JwxtConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { url } from '@kit.ArkTS';

const DOMAIN: number = 0x3005; // JWXT GetInfo domain
const TAG: string = 'JwxtGetInfoService';

/**
 * 学生个人信息接口
 */
export interface StudentInfo {
  /** 姓名 */
  name: string;

  /** 班级 */
  class_name: string;

  /** 出生日期 */
  birthday: string;

  /** 邮箱 */
  email: string;

  /** 学院 */
  college: string;

  /** 年级 */
  grade: string;

  /** QQ号码 */
  qq: string;

  /** 入学日期 */
  enrollment_date: string;

  /** 手机号码 */
  phone: string;

  /** 性别 */
  gender: string;

  /** 学号 */
  student_id: string;

  /** 专业 */
  major: string;
}

/**
 * JWXT原始响应数据接口（教务系统返回的字段）
 */
interface JwxtInfoResponse {
  xm: string; // 姓名
  bh_id: string; // 班级
  csrq: string; // 出生日期
  dzyx: string; // 电子邮箱
  jg_id: string; // 机构（学院）
  njdm_id: string; // 年级代码
  qqhm: string; // QQ号码
  rxrq: string; // 入学日期
  sjhm: string; // 手机号码
  xbm: string; // 性别码
  xh: string; // 学号
  zyh_id: string; // 专业号
}

/**
 * JWXT获取个人信息服务类
 * 单例模式,包含内存缓存(应用生命周期内有效)
 */
export class JwxtGetInfoService {
  private static instance: JwxtGetInfoService;
  private httpClient: JwxtHttpClient;
  // 内存缓存(应用关闭后自动清除,无需时间限制)
  private cachedStudentInfo: StudentInfo | null = null;

  private constructor() {
    this.httpClient = JwxtHttpClient.getInstance();
    hilog.info(DOMAIN, TAG, '✅ JwxtGetInfoService初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): JwxtGetInfoService {
    if (!JwxtGetInfoService.instance) {
      JwxtGetInfoService.instance = new JwxtGetInfoService();
    }
    return JwxtGetInfoService.instance;
  }

  /**
   * 获取学生个人信息(带内存缓存)
   *
   * 流程：
   * 1. 检查内存缓存是否存在
   * 2. 如果缓存存在,直接返回
   * 3. 否则请求API并缓存结果
   *
   * @returns Promise<StudentInfo> 学生个人信息
   * @throws Error 获取信息失败时抛出异常
   */
  public async getInfo(): Promise<StudentInfo> {
    // 检查缓存是否存在
    if (this.cachedStudentInfo) {
      hilog.info(DOMAIN, TAG, '✅ [GetInfo] 使用内存缓存，姓名: %{public}s', this.cachedStudentInfo.name);
      return this.cachedStudentInfo;
    }

    try {
      hilog.info(DOMAIN, TAG, '📝 [GetInfo] 开始从教务系统获取学生个人信息...');

      // API路径
      const apiUrl: string = 'xsxxxggl/xsxxwh_cxCkDgxsxx.html?gnmkdm=N100801';
      const referer: string = 'xsxxxggl/xsxxwh_cxCkDgxsxx.html?gnmkdm=N100801&layout=default';
      let data: JwxtInfoResponse | undefined = undefined;

      hilog.info(DOMAIN, TAG, '🔄 [GetInfo] 尝试GET请求...');
      data = await this.httpClient.get<JwxtInfoResponse>(apiUrl, referer);
      hilog.info(DOMAIN, TAG, '✅ [GetInfo] GET请求成功');

      // 验证响应数据
      if (!data || typeof data !== 'object') {
        hilog.error(DOMAIN, TAG, '❌ [GetInfo] 返回数据为空或类型错误');
        throw new Error('获取信息失败：返回格式异常');
      }

      hilog.info(DOMAIN, TAG, '✅ [GetInfo] 原始数据获取成功');

      // 映射字段到StudentInfo接口
      const studentInfo: StudentInfo = {
        name: data.xm || '',
        class_name: data.bh_id || '',
        birthday: data.csrq || '',
        email: data.dzyx || '',
        college: data.jg_id || '',
        grade: data.njdm_id || '',
        qq: data.qqhm || '',
        enrollment_date: data.rxrq || '',
        phone: data.sjhm || '',
        gender: data.xbm || '',
        student_id: data.xh || '',
        major: data.zyh_id || ''
      };

      // 保存到内存缓存
      this.cachedStudentInfo = studentInfo;

      hilog.info(DOMAIN, TAG, '🎉 [GetInfo] 学生信息获取成功并已缓存');
      hilog.info(DOMAIN, TAG, '👤 [GetInfo] 姓名: %{public}s, 学号: %{public}s, 班级: %{public}s, 入学年份: %{public}s',
        studentInfo.name, studentInfo.student_id, studentInfo.class_name, studentInfo.grade);

      return studentInfo;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [GetInfo] 获取学生信息失败: %{public}s', JSON.stringify(error));

      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error('获取学生信息失败');
      }
    }
  }

  /**
   * 清除内存缓存
   */
  public clearCache(): void {
    this.cachedStudentInfo = null;
    hilog.info(DOMAIN, TAG, '🗑️ [GetInfo] 内存缓存已清除');
  }
}
