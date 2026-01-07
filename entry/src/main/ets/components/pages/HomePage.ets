
import { CourseInfo } from '../../models/CourseModels';
import { CourseColorUtil } from '../../common/utils/CourseColorUtil';
import { CourseTimeUtil } from '../../common/utils/CourseTimeUtil';
import { CacheManager } from '../../common/utils/CacheManager';
import { curves } from '@kit.ArkUI';
import { AppConfigManager } from '../../services/AppConfigManager';
import { FormService } from '../../services/FormService';
import { JwxtGetInfoService } from '../../services/jwxt/JwxtGetInfoService';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface TodayParm {
  year: number;
  week: number;
  termCode: string;
  weekDay: string;
}

const DOMAIN: number = 0x0003;
const TAG = 'HomePage';

@Component
export struct HomePage {
  @Consume('NavStack') pathStack: NavPathStack;
  // pathStack: NavPathStack = new NavPathStack();
  @State private todayCourses: CourseInfo[] = [];
  @State private isLoading: boolean = false;
  @State private studentName: string = '同学'; // 学生姓名
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  // 今日课程参数缓存
  private todayParams: TodayParm | null = null;
  // 动画支持 - 与周课程页保持一致
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 150 });
  // 课程颜色相关状态 - 与SchedulePage保持一致
  @State private courseColorsList: string[] = [];

  aboutToAppear(): void {
    this.loadUserInfo();
    this.loadTodayCourses();
    this.loadStudentName();
  }

  onPageShow(): void {
    // 页面每次显示时重新初始化今日参数，确保不受其他页面影响
    console.info('📱 [HomePage] 页面显示，重新初始化今日参数');
    this.initTodayParams();
    // 重新加载今日课程以防有变化
    this.loadTodayCourses();
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(`你好,${this.studentName}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
          top: 8,
          bottom: 8,
          left: 4,
          right: 4
        })
        .borderRadius(8)

        Blank()
      }
      .width('100%')
      .padding({
        left: 5,
        right: 5,
        top: 50,
        bottom: 20
      })

      // 今日课程区域（拉长并删除查看更多）
      Column() {
        Text('今日课程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 15 })

        // 课程列表区域 - 增加高度
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 50, bottom: 50 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        } else if (this.todayCourses.length > 0) {
          List() {
            ForEach(this.todayCourses, (course: CourseInfo) => {
              ListItem() {
                this.CourseCard(course)
              }
            })
          }
          .borderRadius(24)
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          Column() {
            Text('今日无课😋')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 50, bottom: 50 })
            Text('去做点喜欢的事☝️🤓')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White) // 今日课程区域使用稍深的灰蓝色
      .borderRadius(24)
      .shadow({
        radius: 10,
        color: '#80000000', // 半透明黑
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 20 })
      .layoutWeight(1) // 让今日课程区域占用更多空间

      Blank()
    }
    .width('90%')
    .height('100%')
    .backgroundColor(Color.White) // 背景改为白色
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  CourseCard(courseInfo: CourseInfo) {
    Column() {
      Text(courseInfo.courseName || '')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(CourseColorUtil.getCourseTextColor(courseInfo.courseName, this.courseColorsList))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.teacher || '')
        .fontSize(14)
        .fontColor(CourseColorUtil.getCourseTextColor(courseInfo.courseName, this.courseColorsList))
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(`${courseInfo.section} (${CourseTimeUtil.getTimeRange(courseInfo.courseTime)})`)
        .fontSize(14)
        .fontColor(CourseColorUtil.getCourseTextColor(courseInfo.courseName, this.courseColorsList))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.classroom || '')
        .fontSize(14)
        .fontColor(CourseColorUtil.getCourseTextColor(courseInfo.courseName, this.courseColorsList))
        .alignSelf(ItemAlign.Start)

    }
    .width('100%')
    .backgroundColor(CourseColorUtil.getCourseBackgroundColor(courseInfo.courseName, this.courseColorsList))
    .borderRadius(24)
    .border({
      width: 1,
      color: CourseColorUtil.getCourseBorderColor(courseInfo.courseName, this.courseColorsList),
      radius: 24
    })
    .padding({
      left: 16,
      right: 16,
      top: 16,
      bottom: 16
    })
    .margin({ bottom: 12 })
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 2
    })
    .alignItems(HorizontalAlign.Start)
    .transition(this.effect) // 应用转场动画
  }

  private async loadTodayCourses(): Promise<void> {
    this.isLoading = true;

    try {
      // 等待配置管理器初始化
      await this.appConfigManager.initialize();

      // 如果还没有缓存今日课程参数，则初始化
      if (!this.todayParams) {
        this.initTodayParams();
      }

      if (!this.todayParams) {
        hilog.warn(DOMAIN, TAG, '⚠️ [Today Course] 无法获取今日课程参数');
        this.todayCourses = [];
        return;
      }

      hilog.info(DOMAIN, TAG, `🔍 [Today Course] 使用参数: year=${this.todayParams.year}, week=${this.todayParams.week}, weekDay=${this.todayParams.weekDay}, term=${this.todayParams.termCode}`);

      // 1. 从缓存获取整个学期的课程数据
      const semester = this.todayParams.termCode === '3' ? 1 : 2;
      const academicYear = this.todayParams.year.toString();

      hilog.info(DOMAIN, TAG, `📦 [Today Course] 尝试从缓存加载: ${academicYear}学年第${semester}学期`);

      const semesterCourses = await CacheManager.getSemesterCourses(academicYear, semester);

      if (!semesterCourses || semesterCourses.length === 0) {
        hilog.warn(DOMAIN, TAG, '⚠️ [Today Course] 缓存中无学期课程数据');
        this.todayCourses = [];
        return;
      }

      hilog.info(DOMAIN, TAG, `✅ [Today Course] 从缓存获取到 ${semesterCourses.length} 门课程`);

      // 2. 筛选今日课程
      const currentWeek = this.todayParams.week;
      const weekdayMap: Record<string, number> = {
        '星期一': 1,
        '星期二': 2,
        '星期三': 3,
        '星期四': 4,
        '星期五': 5,
        '星期六': 6,
        '星期日': 7
      };
      const currentDayOfWeek = weekdayMap[this.todayParams.weekDay];

      if (!currentDayOfWeek) {
        hilog.warn(DOMAIN, TAG, `⚠️ [Today Course] 无效的星期: ${this.todayParams.weekDay}`);
        this.todayCourses = [];
        return;
      }

      hilog.info(DOMAIN, TAG, `🔍 [Today Course] 筛选条件: 第${currentWeek}周, ${this.todayParams.weekDay}(${currentDayOfWeek})`);

      // 筛选符合条件的课程
      const todayCourses = semesterCourses.filter(course => {
        // 条件1: 周次匹配 - 课程的 weeks 数组中包含当前周
        const isWeekMatch = course.weeks && course.weeks.includes(currentWeek);
        // 条件2: 星期匹配 - 课程的 dayOfWeek 等于当前星期几
        const isDayMatch = course.dayOfWeek === currentDayOfWeek;

        return isWeekMatch && isDayMatch;
      });

      hilog.info(DOMAIN, TAG, `✅ [Today Course] 筛选到 ${todayCourses.length} 门今日课程`);

      // 3. 转换为 CourseInfo 格式
      const courseInfoList: CourseInfo[] = todayCourses.map((course): CourseInfo => {
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
          weekday: this.todayParams!.weekDay,
          section: section,
          weeks: weeks,
          courseTime: courseTime,
          campus: course.campus || ''
        };
        return courseInfo;
      });

      // 4. 按节次排序 (按第一节课的节次升序)
      courseInfoList.sort((a, b) => {
        const aFirstSession = a.section.match(/\d+/);
        const bFirstSession = b.section.match(/\d+/);
        const aNum = aFirstSession ? parseInt(aFirstSession[0]) : 0;
        const bNum = bFirstSession ? parseInt(bFirstSession[0]) : 0;
        return aNum - bNum;
      });

      // 5. 更新状态
      this.todayCourses = courseInfoList;

      hilog.info(DOMAIN, TAG, `🎉 [Today Course] 今日课程加载完成，共${this.todayCourses.length}门课程`);

      // 打印详细课程信息用于调试
      if (this.todayCourses.length > 0) {
        this.todayCourses.forEach((course, index) => {
          hilog.info(DOMAIN, TAG, `  课程${index + 1}: ${course.courseName} | ${course.section} | ${course.classroom} | ${course.teacher}`);
        });
      }

    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [Today Course] 加载今日课程失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      this.todayCourses = [];
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 初始化今日课程参数缓存
   * 修复：直接基于当前日期计算，不依赖可能被课表页面滑动影响的全局状态
   */
  private initTodayParams(): void {
    // 直接基于今天的日期计算学期状态，避免受课表页面滑动影响
    const today = new Date();
    const configService = this.appConfigManager.getConfigService();

    // 使用ConfigService直接计算今天对应的学期状态
    const todayStatus = configService.calculateCurrentSemesterStatus(today);

    if (!todayStatus || !todayStatus.currentSemester) {
      console.warn('未找到当前学期信息');
      return;
    }

    // 获取今天是星期几
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    const weekDayStr = weekdays[today.getDay()];

    // 缓存今日课程参数 - 基于真实的今天，不受其他页面影响
    this.todayParams = {
      year: parseInt(todayStatus.currentSemester.academicYear),
      week: todayStatus.currentWeek,
      termCode: todayStatus.currentSemester.semester === 1 ? '3' : '12',
      weekDay: weekDayStr
    };

    console.info(`✅ [Today Params Cache] 基于真实今日计算参数: ${JSON.stringify(this.todayParams)}`);
  }

  private loadUserInfo(): void {
    // TODO 获取
  }

  /**
   * 加载学生姓名
   */
  private async loadStudentName(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [HomePage] 开始加载学生姓名...');
      const studentInfo = await this.jwxtGetInfoService.getInfo();
      this.studentName = studentInfo.name;
      hilog.info(DOMAIN, TAG, '✅ [HomePage] 学生姓名加载成功: %{public}s', this.studentName);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [HomePage] 加载学生姓名失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      // 保持默认值"同学"
    }
  }
}