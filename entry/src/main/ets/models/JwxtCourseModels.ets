/**
 * 教务系统课程数据模型
 *
 * 参考: dev-doc/jwxt/api/getCourse.ts
 * 对应教务系统原始接口返回的数据结构
 *
 * @author AI Refactor
 * @date 2026-01-07
 */

/**
 * 教务系统课程原始数据
 * 来自接口: kbcx/xskbcx_cxXsKb.html?gnmkdm=N2151
 */
export interface JwxtCourseRawData {
  kch_id: string;    // 课程号 (注意: 可能重复)
  cdmc: string;      // 教室
  jcs: string;       // 节次 (如 "1-2")
  kcmc: string;      // 课程名称
  xm: string;        // 任课教师
  xqj: string;       // 星期 (1-7)
  zcd: string;       // 周次 (如 "1-16周" 或 "1-8周(单)")
  xqmc?: string;     // 校区名称
}

/**
 * 教务系统课程接口响应
 */
export interface JwxtCourseResponse {
  kbList: JwxtCourseRawData[];     // 课程列表
  xsxx?: Record<string, string>;   // 学生信息 (可选)
}

/**
 * 教务系统课程标准化数据
 * (与 CourseParser 配合使用的格式)
 */
export interface JwxtCourse {
  id: string;            // 课程号
  classroom: string;     // 教室
  sessions: number[];    // 节次数组 (如 [1, 2])
  name: string;          // 课程名称
  teacher: string;       // 任课教师
  dayOfWeek: number;     // 星期 (1-7)
  weeks: number[];       // 周次数组 (如 [1, 2, 3, ..., 16])
  campus?: string;       // 校区
}

/**
 * 教务系统课程请求参数
 */
export interface JwxtCourseParams {
  year: string;    // 学年 (如 "2024")
  term: number;    // 学期 (1 或 2)
}
