import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { PreferencesUtil } from './PreferencesUtil';
import { ConfigApiResponseData } from '../../models/ConfigModels';
import { CourseInfo } from '../../models/CourseModels';
import { JwxtCourse } from '../../models/JwxtCourseModels';
import { ExamInfo } from '../../models/ExamModels';
import { GradeInfo } from '../../services/jwxt/JwxtGetGradeService';

const DOMAIN: number = 0x0001;
const TAG: string = 'CacheManager';

// 缓存key常量
const CACHE_KEY_PREFIX_SCHEDULE = 'cache_schedule_';
const CACHE_KEY_CONFIG = 'cache_config';
const CACHE_KEY_PREFIX_SEMESTER_COURSES = 'cache_semester_courses_'; // 学期课程缓存
const CACHE_KEY_PREFIX_EXAM = 'cache_exam_'; // 考试信息缓存
const CACHE_KEY_PREFIX_GRADE = 'cache_grade_'; // 成绩信息缓存

// 周课表缓存数据结构
interface CachedScheduleData {
  data: CourseInfo[];
  cachedAt: number;
  version: string;
}

// 学期课程缓存数据结构
interface CachedSemesterCoursesData {
  data: JwxtCourse[];
  cachedAt: number;
  version: string;
  academicYear: string;  // 学年，如 "2024"
  semester: number;      // 学期，1 或 2
}

// 考试信息缓存数据结构
interface CachedExamData {
  data: ExamInfo[];
  cachedAt: number;
  version: string;
  academicYear: number;  // 学年，如 2024
  semester: number;      // 学期，1 或 2
}

// 成绩信息缓存数据结构
interface CachedGradeData {
  data: GradeInfo[];
  cachedAt: number;
  version: string;
  academicYear: number;  // 学年，如 2024
  semester: number;      // 学期，1 或 2
}

// 配置数据结构接口
interface ConfigDataStructure {
  start: Record<string, string[]>;
  end: Record<string, string[]>;
}

interface CachedConfigData {
  data: ConfigDataStructure;
  cachedAt: number;
  version: string;
}

// 辅助函数: 构建课表缓存key
function buildScheduleCacheKey(year: string, term: string, week: number): string {
  return `${CACHE_KEY_PREFIX_SCHEDULE}${year}_${term}_${week}`;
}

/**
 * 缓存管理器
 * 职责: 统一管理应用缓存操作
 */
export class CacheManager {

  /**
   * 保存课表缓存（按需缓存，用于离线降级）
   * @param year 学年 (如 "2024")
   * @param term 学期代号 ("3"=第一学期, "12"=第二学期)
   * @param week 周次
   * @param data 课程数据列表
   */
  public static async saveScheduleCache(
    year: string,
    term: string,
    week: number,
    data: CourseInfo[]
  ): Promise<void> {
    try {
      const cacheKey = buildScheduleCacheKey(year, term, week);
      const cacheData: CachedScheduleData = {
        data: data,
        cachedAt: Date.now(),
        version: '1.0'
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, cacheKey, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存课表成功: ${cacheKey}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存课表失败: ${JSON.stringify(error)}`);
      // 错误静默处理,不抛出
    }
  }

  /**
   * 获取课表缓存（用于离线降级）
   * @param year 学年
   * @param term 学期代号
   * @param week 周次
   * @returns 课程数据列表,如果不存在则返回null
   */
  public static async getScheduleCache(
    year: string,
    term: string,
    week: number
  ): Promise<CourseInfo[] | null> {
    try {
      const cacheKey = buildScheduleCacheKey(year, term, week);
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, cacheKey, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 缓存不存在: ${cacheKey}`);
        return null;
      }

      const cached: CachedScheduleData = JSON.parse(cacheValue);
      hilog.info(DOMAIN, TAG, `📦 读取缓存成功: ${cacheKey}, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return cached.data;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取课表缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存配置缓存
   * @param data 配置数据
   */
  public static async saveConfigCache(data: ConfigApiResponseData): Promise<void> {
    try {
      // 将Map转换为普通对象以便JSON序列化
      const startObj: Record<string, string[]> = {};
      const endObj: Record<string, string[]> = {};

      data.start.forEach((value: string[], key: string) => {
        startObj[key] = value;
      });

      data.end.forEach((value: string[], key: string) => {
        endObj[key] = value;
      });

      const configData: ConfigDataStructure = {
        start: startObj,
        end: endObj
      };

      const cacheData: CachedConfigData = {
        data: configData,
        cachedAt: Date.now(),
        version: '1.0'
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, CACHE_KEY_CONFIG, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存配置成功`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存配置失败: ${JSON.stringify(error)}`);
      // 错误静默处理
    }
  }

  /**
   * 获取配置缓存
   * @returns 配置数据,如果不存在则返回null
   */
  public static async getConfigCache(): Promise<ConfigApiResponseData | null> {
    try {
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, CACHE_KEY_CONFIG, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 配置缓存不存在`);
        return null;
      }

      const cached: CachedConfigData = JSON.parse(cacheValue);

      // 将普通对象转换回Map
      const startMap = new Map<string, string[]>();
      const endMap = new Map<string, string[]>();

      Object.keys(cached.data.start).forEach((key: string) => {
        startMap.set(key, cached.data.start[key]);
      });

      Object.keys(cached.data.end).forEach((key: string) => {
        endMap.set(key, cached.data.end[key]);
      });

      hilog.info(DOMAIN, TAG, `📦 读取配置缓存成功, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return {
        start: startMap,
        end: endMap
      };
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取配置缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存学期课程缓存（整个学期的所有课程）
   * @param academicYear 学年，如 "2024"
   * @param semester 学期，1 或 2
   * @param courses 课程列表
   */
  public static async saveSemesterCourses(
    academicYear: string,
    semester: number,
    courses: JwxtCourse[]
  ): Promise<void> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_SEMESTER_COURSES}${academicYear}_${semester}`;
      const cacheData: CachedSemesterCoursesData = {
        data: courses,
        cachedAt: Date.now(),
        version: '1.0',
        academicYear: academicYear,
        semester: semester
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, cacheKey, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存学期课程成功: ${academicYear}学年第${semester}学期, 共${courses.length}门课程`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存学期课程失败: ${JSON.stringify(error)}`);
      // 错误静默处理,不抛出
    }
  }

  /**
   * 获取学期课程缓存
   * @param academicYear 学年，如 "2024"
   * @param semester 学期，1 或 2
   * @returns 课程列表，如果不存在则返回null
   */
  public static async getSemesterCourses(
    academicYear: string,
    semester: number
  ): Promise<JwxtCourse[] | null> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_SEMESTER_COURSES}${academicYear}_${semester}`;
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, cacheKey, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 学期课程缓存不存在: ${academicYear}学年第${semester}学期`);
        return null;
      }

      const cached: CachedSemesterCoursesData = JSON.parse(cacheValue);
      hilog.info(DOMAIN, TAG, `📦 读取学期课程缓存成功: ${academicYear}学年第${semester}学期, 共${cached.data.length}门课程, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return cached.data;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取学期课程缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存考试信息缓存
   * @param academicYear 学年，如 2024
   * @param semester 学期，1 或 2
   * @param examList 考试信息列表
   */
  public static async saveExamCache(
    academicYear: number,
    semester: number,
    examList: ExamInfo[]
  ): Promise<void> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_EXAM}${academicYear}_${semester}`;
      const cacheData: CachedExamData = {
        data: examList,
        cachedAt: Date.now(),
        version: '1.0',
        academicYear: academicYear,
        semester: semester
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, cacheKey, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存考试信息成功: ${academicYear}学年第${semester}学期, 共${examList.length}条考试信息`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存考试信息失败: ${JSON.stringify(error)}`);
      // 错误静默处理,不抛出
    }
  }

  /**
   * 获取考试信息缓存
   * @param academicYear 学年，如 2024
   * @param semester 学期，1 或 2
   * @returns 考试信息列表，如果不存在则返回null
   */
  public static async getExamCache(
    academicYear: number,
    semester: number
  ): Promise<ExamInfo[] | null> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_EXAM}${academicYear}_${semester}`;
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, cacheKey, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 考试信息缓存不存在: ${academicYear}学年第${semester}学期`);
        return null;
      }

      const cached: CachedExamData = JSON.parse(cacheValue);
      hilog.info(DOMAIN, TAG, `📦 读取考试信息缓存成功: ${academicYear}学年第${semester}学期, 共${cached.data.length}条考试信息, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return cached.data;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取考试信息缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存成绩信息缓存
   * @param academicYear 学年，如 2024
   * @param semester 学期，1 或 2
   * @param gradeList 成绩信息列表
   */
  public static async saveGradeCache(
    academicYear: number,
    semester: number,
    gradeList: GradeInfo[]
  ): Promise<void> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_GRADE}${academicYear}_${semester}`;
      const cacheData: CachedGradeData = {
        data: gradeList,
        cachedAt: Date.now(),
        version: '1.0',
        academicYear: academicYear,
        semester: semester
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, cacheKey, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存成绩信息成功: ${academicYear}学年第${semester}学期, 共${gradeList.length}条成绩信息`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存成绩信息失败: ${JSON.stringify(error)}`);
      // 错误静默处理,不抛出
    }
  }

  /**
   * 获取成绩信息缓存
   * @param academicYear 学年，如 2024
   * @param semester 学期，1 或 2
   * @returns 成绩信息列表，如果不存在则返回null
   */
  public static async getGradeCache(
    academicYear: number,
    semester: number
  ): Promise<GradeInfo[] | null> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX_GRADE}${academicYear}_${semester}`;
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, cacheKey, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 成绩信息缓存不存在: ${academicYear}学年第${semester}学期`);
        return null;
      }

      const cached: CachedGradeData = JSON.parse(cacheValue);
      hilog.info(DOMAIN, TAG, `📦 读取成绩信息缓存成功: ${academicYear}学年第${semester}学期, 共${cached.data.length}条成绩信息, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return cached.data;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取成绩信息缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }
}
