/**
 * 考试信息数据模型
 *
 * 用途：
 * - 定义考试信息的数据结构
 * - 用于JWXT考试查询接口的响应数据
 *
 * @since 2026-01-07
 */

/**
 * 考试信息接口
 */
export interface ExamInfo {
  /** 考试编号 */
  id: string;

  /** 课程名称 */
  name: string;

  /** 考试时间 */
  time: string;

  /** 考场 */
  classroom: string;

  /** 座位号 */
  seat: string;
}

/**
 * JWXT原始响应数据接口（教务系统返回的字段）
 */
export interface JwxtExamResponse {
  /** 试卷编号 */
  sjbh: string;

  /** 课程名称 */
  kcmc: string;

  /** 考试时间 */
  kssj: string;

  /** 场地名称（考场） */
  cdmc: string;

  /** 座位号 */
  zwh: string;
}

/**
 * 获取考试列表请求参数
 */
export interface GetExamListRequest {
  /** 学年（如2024） */
  year: number;

  /** 学期（1-秋季学期，2-春季学期） */
  term: number;
}
