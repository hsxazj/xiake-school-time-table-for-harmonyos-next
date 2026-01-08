import { hilog } from '@kit.PerformanceAnalysisKit';
import { CourseInfo } from '../../models/CourseModels';
import { JwxtCourse } from '../../models/JwxtCourseModels';
import { CourseTimeUtil } from './CourseTimeUtil';
import { CacheManager } from './CacheManager';
import { AppConfigManager } from '../../services/AppConfigManager';

const DOMAIN: number = 0x0004;
const TAG: string = 'TodayCourseUtil';

/**
 * 今日课程参数
 */
export interface TodayParams {
  year: number; // 学年
  week: number; // 周次
  termCode: string; // 学期代号 ('3'=第一学期, '12'=第二学期)
  weekDay: string; // 星期几 ('星期一', '星期二', ...)
}

/**
 * 今日课程工具类
 * 用于封装今日课程的解析和筛选逻辑
 */
export class TodayCourseUtil {
  /**
   * 获取今日课程参数
   * 基于当前日期和学期配置计算
   * @returns 今日课程参数,如果无法获取则返回 null
   */
  public static getTodayParams(): TodayParams | null {
    try {
      const appConfigManager = AppConfigManager.getInstance();
      const today = new Date();
      const configService = appConfigManager.getConfigService();

      // 使用 ConfigService 直接计算今天对应的学期状态
      const todayStatus = configService.calculateCurrentSemesterStatus(today);

      if (!todayStatus || !todayStatus.currentSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [TodayCourseUtil] 未找到当前学期信息');
        return null;
      }

      // 获取今天是星期几
      const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
      const weekDayStr = weekdays[today.getDay()];

      // const params: TodayParams = {
      //   year: parseInt(todayStatus.currentSemester.academicYear),
      //   week: todayStatus.currentWeek,
      //   termCode: todayStatus.currentSemester.semester === 1 ? '3' : '12',
      //   weekDay: weekDayStr
      // };

      const params: TodayParams = {
        year: 2024,
        week: 2,
        termCode: '12',
        weekDay: '星期一'
      };

      hilog.info(DOMAIN, TAG, `✅ [TodayCourseUtil] 今日参数: ${JSON.stringify(params)}`);
      return params;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [TodayCourseUtil] 获取今日参数失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      return null;
    }
  }

  /**
   * 从学期课程中筛选今日课程
   * @param semesterCourses 学期课程列表
   * @param todayParams 今日参数
   * @returns 筛选后的今日课程列表
   */
  public static filterTodayCourses(
    semesterCourses: JwxtCourse[],
    todayParams: TodayParams
  ): JwxtCourse[] {
    if (!semesterCourses || semesterCourses.length === 0) {
      hilog.warn(DOMAIN, TAG, '⚠️ [TodayCourseUtil] 学期课程列表为空');
      return [];
    }

    const currentWeek = todayParams.week;
    const weekdayMap: Record<string, number> = {
      '星期一': 1,
      '星期二': 2,
      '星期三': 3,
      '星期四': 4,
      '星期五': 5,
      '星期六': 6,
      '星期日': 7
    };
    const currentDayOfWeek = weekdayMap[todayParams.weekDay];

    if (!currentDayOfWeek) {
      hilog.warn(DOMAIN, TAG, `⚠️ [TodayCourseUtil] 无效的星期: ${todayParams.weekDay}`);
      return [];
    }

    hilog.info(DOMAIN, TAG,
      `🔍 [TodayCourseUtil] 筛选条件: 第${currentWeek}周, ${todayParams.weekDay}(${currentDayOfWeek})`);

    // 筛选符合条件的课程
    const todayCourses = semesterCourses.filter(course => {
      // 条件1: 周次匹配 - 课程的 weeks 数组中包含当前周
      const isWeekMatch = course.weeks && course.weeks.includes(currentWeek);
      // 条件2: 星期匹配 - 课程的 dayOfWeek 等于当前星期几
      const isDayMatch = course.dayOfWeek === currentDayOfWeek;

      return isWeekMatch && isDayMatch;
    });

    hilog.info(DOMAIN, TAG, `✅ [TodayCourseUtil] 筛选到 ${todayCourses.length} 门今日课程`);
    return todayCourses;
  }

  /**
   * 将 JwxtCourse 转换为 CourseInfo 显示格式
   * @param courses 教务系统课程列表
   * @param weekDay 星期几
   * @returns CourseInfo 列表
   */
  public static convertToDisplayFormat(
    courses: JwxtCourse[],
    weekDay: string
  ): CourseInfo[] {
    return courses.map((course): CourseInfo => {
      // 转换节次数组为时间字符串数组
      const courseTime = CourseTimeUtil.sessionsToTimeStrings(course.sessions);
      // 格式化节次字符串
      const section = CourseTimeUtil.formatSections(course.sessions);
      // 格式化周次为字符串
      const weeks = JSON.stringify(course.weeks);

      const courseInfo: CourseInfo = {
        courseId: parseInt(course.id) || 0,
        courseName: course.name,
        teacher: course.teacher,
        classroom: course.classroom,
        weekday: weekDay,
        section: section,
        weeks: weeks,
        courseTime: courseTime,
        campus: course.campus || ''
      };
      return courseInfo;
    });
  }

  /**
   * 按节次排序课程列表
   * @param courses 课程列表
   * @returns 排序后的课程列表
   */
  public static sortBySession(courses: CourseInfo[]): CourseInfo[] {
    return courses.sort((a, b) => {
      const aFirstSession = a.section.match(/\d+/);
      const bFirstSession = b.section.match(/\d+/);
      const aNum = aFirstSession ? parseInt(aFirstSession[0]) : 0;
      const bNum = bFirstSession ? parseInt(bFirstSession[0]) : 0;
      return aNum - bNum;
    });
  }

  /**
   * 加载今日课程(完整流程)
   * @returns 今日课程列表,如果失败则返回空数组
   */
  public static async loadTodayCourses(context?: Context): Promise<CourseInfo[]> {
    try {
      // 1. 获取今日参数
      const todayParams = TodayCourseUtil.getTodayParams();
      if (!todayParams) {
        hilog.warn(DOMAIN, TAG, '⚠️ [TodayCourseUtil] 无法获取今日课程参数');
        return [];
      }

      hilog.info(DOMAIN, TAG,
        `🔍 [TodayCourseUtil] 加载课程: year=${todayParams.year}, week=${todayParams.week}, weekDay=${todayParams.weekDay}, term=${todayParams.termCode}`);

      // 2. 从缓存获取整个学期的课程数据
      const semester = todayParams.termCode === '3' ? 1 : 2;
      const academicYear = todayParams.year.toString();

      hilog.info(DOMAIN, TAG, `📦 [TodayCourseUtil] 尝试从缓存加载: ${academicYear}学年第${semester}学期`);

      const semesterCourses = await CacheManager.getSemesterCourses(academicYear, semester, context);

      if (!semesterCourses || semesterCourses.length === 0) {
        hilog.warn(DOMAIN, TAG, '⚠️ [TodayCourseUtil] 缓存中无学期课程数据');
        return [];
      }

      hilog.info(DOMAIN, TAG, `✅ [TodayCourseUtil] 从缓存获取到 ${semesterCourses.length} 门课程`);

      // 3. 筛选今日课程
      const todayCourses = TodayCourseUtil.filterTodayCourses(semesterCourses, todayParams);

      // 4. 转换为 CourseInfo 格式
      const courseInfoList = TodayCourseUtil.convertToDisplayFormat(todayCourses, todayParams.weekDay);

      // 5. 按节次排序
      const sortedCourses = TodayCourseUtil.sortBySession(courseInfoList);

      hilog.info(DOMAIN, TAG, `🎉 [TodayCourseUtil] 今日课程加载完成，共${sortedCourses.length}门课程`);

      // 打印详细课程信息用于调试
      if (sortedCourses.length > 0) {
        sortedCourses.forEach((course, index) => {
          hilog.info(DOMAIN, TAG,
            `  课程${index + 1}: ${course.courseName} | ${course.section} | ${course.classroom} | ${course.teacher}`);
        });
      }

      return sortedCourses;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [TodayCourseUtil] 加载今日课程失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      return [];
    }
  }
}
