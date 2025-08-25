import { ConfigApiService, CurrentSemesterStatus, SemesterInfo } from '../../services/api/ConfigApiService';
import { CourseApiService, CourseInfo, CoursePosition } from '../../services/api/CourseApiService';
import { AppConfigManager } from '../../services/AppConfigManager';
import { UserInfoManager } from '../../common/constants/PreferencesUtil';
import { curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 周日期范围接口
interface WeekDateRange {
  startDate: Date;
  endDate: Date;
}

// 课程网格数据接口（参照class-schedule-c）
interface ScheduleCourse {
  courseName: string;
  classroom: string[];
  teacher: string[];
  campus: string;
  courseTime: number[][]; // [[1,2], [3,4]] 格式
  weekday: number; // 1-7 对应周一到周日
  section: number[]; // 节次数组
  courseId: string[];
}

// 扩展的课程接口，包含周次信息
interface ScheduleCourseWithWeeks extends ScheduleCourse {
  weeks?: string;
}

// 周课表网格布局数据
interface WeekScheduleGrid {
  nowClassList: ScheduleCourse[][]; // [周一[], 周二[], ...周日[]]
  classNum: number[][]; // 每天每门课开始的节次
  classLength: number[][]; // 每天每门课的长度
  isContinue: number[][]; // 课程是否连续（1=连续，0=不连续）
  classList: string[]; // 去重后的所有课程名
}

// 课程时间段配置接口
interface SectionsConfig {
  value1: number[];
  value2: number[];
  value3: number[];
  value4: number[];
  value5: number[];
  value6: number[];
}

// 课程颜色配置
interface CourseColors {
  backgroundColor: string;
  textColor: string;
  borderColor: string;
}

@Component
export struct SchedulePage {
  private pathStack: NavPathStack = new NavPathStack();
  @State private currentWeek: number = 1;
  @State private totalWeeks: number = 20;
  @State private currentMonth: string = '';
  @State private weekDates: WeekDateRange | null = null;
  @State private showWeekPicker: boolean = false;
  // 新增学期管理相关状态
  @State private currentStatus: CurrentSemesterStatus | null = null;
  @State private currentSemester: SemesterInfo | null = null;
  @State private semesterList: SemesterInfo[] = [];
  @State private displayStatusText: string = "第1周";
  // 新增基于日期的滑动状态
  @State private currentDate: Date = new Date(); // 当前显示的日期
  // 滑动手势状态
  @State private startTime: number = 0;
  @State private startPosition: number = 0;
  @State private endPosition: number = 0;
  // 新增课程数据相关状态
  @State private coursePositions: CoursePosition[] = [];
  @State private isLoadingCourses: boolean = false;
  private configService: ConfigApiService = ConfigApiService.getInstance();
  private courseService: CourseApiService = CourseApiService.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  // 参照class-schedule-c的sections配置
  private sections: SectionsConfig = {
    value1: [1, 2],
    value2: [3, 4],
    value3: [5, 6],
    value4: [7, 8],
    value5: [9, 10],
    value6: [11, 12],
  };
  private betweenHeight: number = 5; // 增加一大节课间隔高度
  private boxHeight: number = 25; // 增加一小节课高度
  // 周课表网格数据
  @State private scheduleGrid: WeekScheduleGrid = {
    nowClassList: [],
    classNum: [],
    classLength: [],
    isContinue: [],
    classList: []
  };
  // 课程颜色映射
  private courseColorMap: Map<string, CourseColors> = new Map();
  // 实际课程数据 - 移除模拟数据，使用接口数据
  @State private courseList: CourseInfo[] = [];
  // 动画支持
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 150 }); // 从250减少到150
  // 课程块可见性状态
  @State private courseBlockVisible: boolean[][] = [];

  aboutToAppear(): void {
    // 基于日期的初始化逻辑
    this.initializeWithCurrentDate();
  }

  build() {
    Stack() {
      Column() {
        // 顶部日期和周次tabbar
        Row() {
          // 周数可点击区域
          Row() {
            Text(this.displayStatusText || `第${this.currentWeek || 1}周`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentStatus?.isInHoliday ? '#FF9800' : '#333333') // 假期中用橙色
            Text('▼')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 4 })
          }
          .padding({
            left: 8,
            right: 8,
            top: 4,
            bottom: 4
          })
          .borderRadius(4)
          .onClick(() => {
            this.showWeekPicker = true;
          })
        }
        .width('100%')
        .padding({
          left: 6,
          right: 6,
          top: 15,
          bottom: 5
        })
        .backgroundColor(Color.White)
        .bindSheet($$this.showWeekPicker, this.WeekPickerBuilder(), {
          showClose:false,
          height: 500,
          dragBar: true,
          maskColor: 'rgba(0, 0, 0, 0.4)',
          onAppear: () => {
            console.log("周选择器显示");
          },
          onDisappear: () => {
            console.log("周选择器隐藏");
          }
        })

        // 课表内容区域 - 支持触摸滑动手势
        Column() {
          this.WeekScheduleContent()
        }
        .width('100%')
        .layoutWeight(1)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.touchStart(event);
          } else if (event.type === TouchType.Up) {
            this.touchEnd(event);
          }
          return true;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  WeekScheduleContent() {
    Column() {
      // 星期表头（参考show-list.vue的table-header结构）
      Row() {
        // 左上角月份显示区域
        Column() {
          Text(this.currentMonth.substring(0,this.currentMonth.length-1))
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 2 })
          Text('月')
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 2 })
        }
        .width(40)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .alignItems(HorizontalAlign.Center)

        // 星期标题和日期（参考show-list.vue的second-week-box）
        ForEach(this.weekDays, (day: string, dayIndex: number) => {
          Column() {
            // 星期
            Text(day)
              .fontSize(14)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 2 })

            // 显示对应的日期（参考class-schedule-c的timeList逻辑）
            if (this.weekDates) {
              Text(this.getDateForWeekDay(dayIndex))
                .fontSize(14)
                .fontColor(this.isToday(dayIndex) ? '#45CAD9' : '#666666')
                .backgroundColor(this.isToday(dayIndex) ? '#E3F2FD' : Color.Transparent)
                .borderRadius(8)
                .padding({
                  left: 4,
                  right: 4,
                  top: 2,
                  bottom: 2
                })
            }
          }
          .layoutWeight(1)
          .height(55)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Color.White)
        })
      }
      .width('100%')

      // 课表内容区域（参考show-list.vue的class-table结构）
      Scroll() {
        Row() {
          // 左侧时间轴（参考show-list.vue的class-time）
          this.buildTimeColumn()

          // 课程网格区域（参考show-list.vue的class-table）
          Row() {
            ForEach([0, 1, 2, 3, 4, 5, 6], (dayIndex: number) => {
              this.buildDayColumn(dayIndex)
            })
          }
          .layoutWeight(1)
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Top)
        }
        .height('100%')
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建时间列（参考show-list.vue的class-time结构）
   */
  @Builder
  buildTimeColumn() {
    Column() {
      // 直接显示1-12节，均匀分布
      ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], (num: number) => {
        Text(num.toString())
          .fontSize(12)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1) // 使用layoutWeight实现均匀分布
      })
    }
    .height('100%')
    .width(40)
    .backgroundColor(Color.White)
  }

  /**
   * 构建单天课程列（参考show-list.vue的网格布局算法）
   */
  @Builder
  buildDayColumn(dayIndex: number) {
    Column() {
      // 直接显示所有课程，不进行复杂的连续性判断
      ForEach(this.scheduleGrid.nowClassList[dayIndex] || [], (course: ScheduleCourse, courseIndex: number) => {
        this.buildCourseBlock(course,
          this.scheduleGrid.classLength[dayIndex] ? this.scheduleGrid.classLength[dayIndex][courseIndex] : 1, dayIndex,
          courseIndex)
      })
    }
    .backgroundColor(Color.White)
    .width(`${100 / 7}%`) // 7列等宽
    .alignItems(HorizontalAlign.Center)
    .padding(1) // 减少内边距
  }

  /**
   * 构建课程块（参考show-list.vue的class-table-item样式）
   */
  @Builder
  buildCourseBlock(course: ScheduleCourse, length: number, dayIndex: number, courseIndex: number) {
    // 所有课程一次性显示，只在动画状态控制显示/隐藏
    if (this.courseBlockVisible.length === 0 || 
        !this.courseBlockVisible[dayIndex] || 
        this.courseBlockVisible[dayIndex].length === 0 ||
        this.courseBlockVisible[dayIndex][courseIndex] !== false) {
      Column() {
        // 课程名称
        Text(course.courseName)
          .fontSize(11)
          .fontColor(this.getCourseTextColor(course.courseName))
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ bottom: 2 })

        // 教室信息
        if (course.classroom && course.classroom.length > 0) {
          Text(course.classroom[0])
            .fontSize(9)
            .fontColor(this.getCourseTextColor(course.courseName))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .margin({ bottom: 1 })
        }

        // 教师信息
        if (course.teacher && course.teacher.length > 0) {
          Text(course.teacher[0])
            .fontSize(8)
            .fontColor(this.getCourseTextColor(course.courseName))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
        }
      }
      .transition(this.effect) // 应用转场动画
      .width('95%')
      .height(`${length * 8.33}%`)
      .backgroundColor(this.getCourseBackgroundColor(course.courseName))
      .border({
        width: 1,
        color: this.getCourseBorderColor(course.courseName),
        radius: 4
      })
      .padding(3)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 1, bottom: 1 })
      .onClick(() => {
        this.onCourseBlockClick(course, dayIndex, courseIndex);
      })
    }
  }

  /**
   * 处理周课表数据（使用接口数据）
   */
  private processWeekScheduleData(): void {
    console.info('📅 [Schedule] 开始处理周课表数据...');

    // 初始化网格数据结构
    this.initializeScheduleGrid();

    // 处理课程数据
    this.processCourseList();

    // 计算课程布局
    this.calculateCourseLayout();

    console.info('📅 [Schedule] 周课表数据处理完成');
  }

  /**
   * 初始化课表网格结构
   */
  private initializeScheduleGrid(): void {
    // 7天的课程列表
    this.scheduleGrid.nowClassList = Array(7).fill(null).map(() => []);
    this.scheduleGrid.classNum = Array(7).fill(null).map(() => []);
    this.scheduleGrid.classLength = Array(7).fill(null).map(() => []);
    this.scheduleGrid.isContinue = Array(7).fill(null).map(() => []);
    this.scheduleGrid.classList = [];
    // 初始化课程块可见性状态
    this.courseBlockVisible = Array(7).fill(null).map(() => []);
  }

  /**
   * 处理课程列表（使用接口数据转换为课表格式）
   */
  private processCourseList(): void {
    // 将接口返回的CourseInfo[]转换为ScheduleCourse[]格式
    const convertedCourses = this.convertCourseInfoToScheduleCourse(this.courseList);

    // 过滤当前周的课程
    const weekCourses = convertedCourses.filter(course => {
      // 解析课程的周次信息，判断是否包含当前周
      return this.isCourseInCurrentWeek(course, this.currentWeek);
    });

    // 按周几分组
    for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
      const dayCourses = weekCourses.filter(course => course.weekday === dayIndex + 1);
      this.scheduleGrid.nowClassList[dayIndex] = dayCourses;
    }

    // 提取所有课程名（去重）
    const courseNameSet = new Set<string>();
    weekCourses.forEach(course => {
      courseNameSet.add(course.courseName);
    });
    this.scheduleGrid.classList = Array.from(courseNameSet);
    
    // 触发入场动画
    this.triggerCourseBlockEnterAnimation();

    console.info(`📚 [Course] 处理了${this.courseList.length}门课程，当前周有${weekCourses.length}门课程`);
  }

  /**
   * 将CourseInfo转换为ScheduleCourse格式
   */
  private convertCourseInfoToScheduleCourse(courseList: CourseInfo[]): ScheduleCourseWithWeeks[] {
    return courseList.map(course => {
      const scheduleCourse: ScheduleCourseWithWeeks = {
        courseName: course.courseName,
        classroom: [course.classroom], // 将字符串转换为数组
        teacher: [course.teacher], // 将字符串转换为数组
        campus: course.campus || '', // 使用接口数据中的campus字段
        courseTime: this.parseCourseTime(course.section),
        weekday: this.parseWeekday(course.weekday),
        section: this.parseSection(course.section),
        courseId: [course.courseId.toString()], // 转换为字符串数组
        weeks: course.weeks // 保存原始周次信息用于过滤
      };
      return scheduleCourse;
    });
  }

  /**
   * 判断课程是否在当前周
   */
  private isCourseInCurrentWeek(course: ScheduleCourseWithWeeks, currentWeek: number): boolean {
    if (!course.weeks) {
      return true;
    } // 如果没有周次信息，默认显示

    const weekRanges = this.parseWeekRange(course.weeks);
    return weekRanges.includes(currentWeek);
  }

  /**
   * 解析周次范围，适配接口格式 "[2,3,4,6,7,8,9,10,11]"
   */
  private parseWeekRange(weeksStr: string): number[] {
    const weeks: number[] = [];

    if (!weeksStr) {
      return weeks;
    }

    try {
      // 接口返回的格式是 "[2,3,4,6,7,8,9,10,11]"，需要解析为数组
      if (weeksStr.startsWith('[') && weeksStr.endsWith(']')) {
        const weekArray = JSON.parse(weeksStr) as number[];
        return weekArray.sort((a, b) => a - b);
      } else {
        // 处理传统格式: "1-16", "1,3,5-7"等
        const cleanWeeksStr = weeksStr.replace(/[单双周]/g, '');
        const parts = cleanWeeksStr.split(',');

        parts.forEach(part => {
          if (part.includes('-')) {
            const dashIndex = part.indexOf('-');
            const start = parseInt(part.substring(0, dashIndex).trim());
            const end = parseInt(part.substring(dashIndex + 1).trim());
            for (let i = start; i <= end; i++) {
              if (!weeks.includes(i)) {
                weeks.push(i);
              }
            }
          } else {
            const week = parseInt(part.trim());
            if (!isNaN(week) && !weeks.includes(week)) {
              weeks.push(week);
            }
          }
        });
      }
    } catch (error) {
      console.error('解析周次范围失败:', error, weeksStr);
    }

    return weeks.sort((a, b) => a - b);
  }

  /**
   * 解析课程时间为二维数组格式
   */
  private parseCourseTime(sectionStr: string): number[][] {
    const sections = this.parseSection(sectionStr);
    const result: number[][] = [];

    // 将连续的节次分组
    let currentGroup: number[] = [];
    for (let i = 0; i < sections.length; i++) {
      if (i === 0 || sections[i] === sections[i - 1] + 1) {
        currentGroup.push(sections[i]);
      } else {
        if (currentGroup.length > 0) {
          result.push([...currentGroup]);
        }
        currentGroup = [sections[i]];
      }
    }

    if (currentGroup.length > 0) {
      result.push(currentGroup);
    }

    return result;
  }

  /**
   * 计算课程布局（核心算法，参考show-list.vue的布局逻辑）
   */
  private calculateCourseLayout(): void {
    for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
      const dayCourses = this.scheduleGrid.nowClassList[dayIndex];

      // 初始化当天的布局数据
      this.scheduleGrid.classNum[dayIndex] = [];
      this.scheduleGrid.classLength[dayIndex] = [];
      this.scheduleGrid.isContinue[dayIndex] = [];

      // 按节次排序
      const sortedCourses = dayCourses.sort((a, b) => a.section[0] - b.section[0]);

      for (let courseIndex = 0; courseIndex < sortedCourses.length; courseIndex++) {
        const course = sortedCourses[courseIndex];

        // 计算课程开始节次
        this.scheduleGrid.classNum[dayIndex][courseIndex] = course.section[0];

        // 计算课程长度（节次数）
        this.scheduleGrid.classLength[dayIndex][courseIndex] = course.section.length;

        // 简化连续性判断：默认所有课程都应该显示
        this.scheduleGrid.isContinue[dayIndex][courseIndex] = 1;
      }
    }
  }

  /**
   * 解析周几字符串
   */
  private parseWeekday(weekdayStr: string): number {
    const weekdayMap: Record<string, number> = {
      '星期一': 1,
      '星期二': 2,
      '星期三': 3,
      '星期四': 4,
      '星期五': 5,
      '星期六': 6,
      '星期日': 7
    };
    return weekdayMap[weekdayStr] || 1;
  }

  /**
   * 解析节次字符串，适配接口格式 "1-2节"
   */
  private parseSection(sectionStr: string): number[] {
    if (!sectionStr) {
      return [1];
    } // 默认值

    // 移除"节"字符，处理 "1-2节" 格式
    const cleanSectionStr = sectionStr.replace(/节$/g, '');

    if (cleanSectionStr.includes('-')) {
      // "1-2" -> [1, 2]
      // "1-6" -> [1, 2, 3, 4, 5, 6]
      const parts = cleanSectionStr.split('-');
      if (parts.length === 2) {
        const start = parseInt(parts[0].trim());
        const end = parseInt(parts[1].trim());
        const sections: number[] = [];
        for (let i = start; i <= end; i++) {
          sections.push(i);
        }
        return sections;
      }
    } else if (cleanSectionStr.includes(',')) {
      // "1,2" -> [1, 2]
      return cleanSectionStr.split(',').map(s => parseInt(s.trim())).filter(n => !isNaN(n));
    } else {
      // "1" -> [1]
      const section = parseInt(cleanSectionStr.trim());
      return !isNaN(section) ? [section] : [1];
    }

    return [1]; // 默认值
  }

  /**
   * 基于当前日期初始化 - 找到最近的学期并计算当前周数
   */
  private async initializeWithCurrentDate(): Promise<void> {
    try {
      // 确保配置已加载
      await this.appConfigManager.initialize();
      this.semesterList = this.configService.getSemesterList();

      if (this.semesterList.length === 0) {
        console.error('📋 [Schedule] 没有学期数据');
        return;
      }

      // 使用今天的日期作为起始点
      const today = new Date();
      this.currentDate = new Date(today);

      // 找到最近的学期和计算周数
      this.updateCurrentSemesterFromDate(this.currentDate);

      // 计算当前日期对应的周日期范围
      this.calculateWeekDatesFromCurrentDate();

      // 加载课程数据
      await this.loadCourseData();

      console.info(`📅 [Schedule Init] 初始化完成: ${this.currentDate.getFullYear()}-${this.currentDate.getMonth() +
        1}-${this.currentDate.getDate()}`);

    } catch (error) {
      console.error('📋 [Schedule] 日期初始化失败:', error);
    }
  }

  /**
   * 加载课程数据
   */
  private async loadCourseData(): Promise<void> {
    if (!this.currentSemester) {
      console.warn('📚 [Course] 当前学期信息为空，无法加载课程');
      return;
    }

    this.isLoadingCourses = true;

    try {
      // 从首选项获取用户班级信息
      const userInfo = this.userInfoManager.getUserInfo();
      console.info(`📚 [Course] 当前用户信息: 学院=${userInfo.collegeName}, 专业=${userInfo.majorName}, 班级=${userInfo.className}`);

      const classId = userInfo.classId;

      if (!classId) {
        console.warn('📚 [Course] 用户未设置班级信息，无法获取课程数据');
        console.warn('📚 [Course] 请在设置页面选择学院、专业和班级');
        return;
      }

      // 构建请求参数 - 使用学期信息和用户班级ID
      const params = this.courseService.buildCourseParams(
        this.currentSemester.academicYear,
        this.currentSemester.semester,
        this.currentWeek, // 添加当前周数
        classId,
        undefined
      );

      console.info(`📚 [Course] 请求课程数据: ${JSON.stringify(params)}`);

      // 获取课程列表
      const courseResponse = await this.courseService.getCourseList(params);

      if (courseResponse.code === 200 && courseResponse.data) {
        // 将接口数据赋值给 courseList 状态变量
        this.courseList = courseResponse.data;

        // 处理课程数据，生成课表网格
        this.processWeekScheduleData();

        console.info(`📚 [Course] 成功加载${courseResponse.data.length}门课程`);
      } else {
        console.warn(`📚 [Course] 课程数据加载失败: ${courseResponse.msg}`);
        this.courseList = [];
        // 即使没有数据也要初始化空的网格
        this.processWeekScheduleData();
      }

    } catch (error) {
      console.error('📚 [Course] 加载课程数据失败:', error);
      this.courseList = [];
      // 即使出错也要初始化空的网格
      this.processWeekScheduleData();
    } finally {
      this.isLoadingCourses = false;
    }
  }

  /**
   * 根据给定日期找到最近的学期并计算周数
   * 直接使用ConfigApiService的calculateCurrentSemesterStatus逻辑
   */
  private updateCurrentSemesterFromDate(targetDate: Date): void {
    // 使用ConfigApiService的已有逻辑来计算状态
    const semesterStatus = this.configService.calculateCurrentSemesterStatus(targetDate);

    if (semesterStatus && semesterStatus.currentSemester) {
      this.currentSemester = semesterStatus.currentSemester;
      this.currentWeek = semesterStatus.currentWeek;
      this.totalWeeks = semesterStatus.currentSemester.totalWeeks;
      this.displayStatusText = semesterStatus.statusText;

      console.info(`📅 [Semester Update] ${semesterStatus.currentSemester.academicYear}学年第${semesterStatus.currentSemester.semester}学期 - ${semesterStatus.statusText} (周数: ${semesterStatus.currentWeek})`);
    }
  }

  /**
   * 根据当前日期计算周日期范围
   */
  private calculateWeekDatesFromCurrentDate(): void {
    // 找到当前日期所在周的周一
    const currentDate = new Date(this.currentDate);
    const dayOfWeek = currentDate.getDay();
    const daysToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

    const mondayOfWeek = new Date(currentDate);
    mondayOfWeek.setDate(currentDate.getDate() + daysToMonday);

    // 计算周日
    const sundayOfWeek = new Date(mondayOfWeek);
    sundayOfWeek.setDate(mondayOfWeek.getDate() + 6);

    this.weekDates = {
      startDate: mondayOfWeek,
      endDate: sundayOfWeek
    };

    this.currentMonth = this.configService.getMonthString(mondayOfWeek);
  }

  /**
   * 导航到上一周
   */
  private async navigateToPreviousWeek(): Promise<void> {
    // 先播放退场动画
    await this.triggerCourseBlockExitAnimation();
    
    // 当前日期减去7天
    const newDate = new Date(this.currentDate);
    newDate.setDate(this.currentDate.getDate() - 7);

    this.currentDate = newDate;
    this.updateCurrentSemesterFromDate(this.currentDate);
    this.calculateWeekDatesFromCurrentDate();

    // 重新加载课程数据（如果学期发生变化）
    await this.loadCourseData();

    console.info(`📅 [Navigate] 左滑到上一周: ${newDate.getFullYear()}-${newDate.getMonth() + 1}-${newDate.getDate()}`);
  }

  /**
   * 导航到下一周
   */
  private async navigateToNextWeek(): Promise<void> {
    // 先播放退场动画
    await this.triggerCourseBlockExitAnimation();
    
    // 当前日期加上7天
    const newDate = new Date(this.currentDate);
    newDate.setDate(this.currentDate.getDate() + 7);

    this.currentDate = newDate;
    this.updateCurrentSemesterFromDate(this.currentDate);
    this.calculateWeekDatesFromCurrentDate();

    // 重新加载课程数据（如果学期发生变化）
    await this.loadCourseData();

    console.info(`📅 [Navigate] 右滑到下一周: ${newDate.getFullYear()}-${newDate.getMonth() + 1}-${newDate.getDate()}`);
  }

  /**
   * 切换学期 (跳转到指定学期的第一周)
   */
  private async switchSemester(direction: 'prev' | 'next'): Promise<void> {
    if (!this.currentSemester) {
      return;
    }

    // 找到目标学期
    const rawTargetSemester = this.configService.getAdjacentSemester(this.currentSemester, direction);
    if (rawTargetSemester) {
      // 跳转到目标学期的开学日期
      const targetStartDate = new Date(rawTargetSemester.startDate);
      this.currentDate = targetStartDate;

      // 更新学期信息
      this.updateCurrentSemesterFromDate(this.currentDate);
      this.calculateWeekDatesFromCurrentDate();

      // 重新加载新学期的课程数据
      await this.loadCourseData();

      console.info(`📅 [Semester Switch] 切换到${rawTargetSemester.academicYear}学年第${rawTargetSemester.semester}学期`);
    }
  }

  /**
   * 获取星期对应的日期
   */
  private getDateForWeekDay(dayIndex: number): string {
    if (!this.weekDates) {
      return '';
    }

    const targetDate = new Date(this.weekDates.startDate);
    targetDate.setDate(this.weekDates.startDate.getDate() + dayIndex);

    const month = targetDate.getMonth() + 1;
    const day = targetDate.getDate();
    return `${month}/${day}`;
  }

  /**
   * 触摸开始 (参考class-schedule-c的touchStart方法)
   */
  private touchStart(event: TouchEvent): void {
    this.startTime = Date.now();
    this.startPosition = event.touches[0].x;
  }

  /**
   * 触摸结束 (参考class-schedule-c的touchEnd方法)
   */
  private touchEnd(event: TouchEvent): void {
    const endTime = Date.now();
    // 如果触摸时间超过2秒，忽略
    if (endTime - this.startTime > 2000) {
      return;
    }

    this.endPosition = event.changedTouches[0].x;

    // 当移动距离超过100时判断左滑右滑 (与class-schedule-c一致)
    if (Math.abs(this.endPosition - this.startPosition) > 100) {
      const elePosition = this.endPosition - this.startPosition > 0 ? "right" : "left";

      if (elePosition === 'right') {
        // 右滑：显示上一周 (对应class-schedule-c的leftClick)
        console.info(`📅 [Navigate] 右滑到上一周`)
        this.navigateToPreviousWeek();

      } else if (elePosition === 'left') {
        console.info(`📅 [Navigate] 左滑到下一周`)
        // 左滑：显示下一周 (对应class-schedule-c的rightClick)
        this.navigateToNextWeek();
      }
    }
  }

  /**
   * 生成周数列表
   */
  private getWeekNumbersList(): number[] {
    const weekNumbers: number[] = [];
    for (let i = 1; i <= this.totalWeeks; i++) {
      weekNumbers.push(i);
    }
    return weekNumbers;
  }

  @Builder
  WeekPickerBuilder() {
    Column() {
      // 学期信息和切换按钮
      Row() {
        // 上一个学期按钮
        Button('< 上学期')
          .fontSize(14)
          .fontColor('#45CAD9')
          .backgroundColor(Color.Transparent)
          .height(30)
          .onClick(async () => {
            await this.triggerCourseBlockExitAnimation();
            this.switchSemester('prev');
          })

        Blank()

        // 当前学期信息
        Text(`${this.currentSemester?.academicYear || '2024'}学年第${this.currentSemester?.semester || 1}学期`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        // 下一个学期按钮
        Button('下学期 >')
          .fontSize(14)
          .fontColor('#45CAD9')
          .backgroundColor(Color.Transparent)
          .height(30)
          .onClick(async () => {
            await this.triggerCourseBlockExitAnimation();
            this.switchSemester('next');
          })
      }
      .width('100%')
      .padding({  bottom: 10 })

      Divider()
        .color('#F0F0F0')
        .strokeWidth(0.5)
        .margin({ bottom: 10 })

      Text('选择周次')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })

      Scroll() {
        Column() {
          ForEach(this.getWeekNumbersList(), (weekNum: number) => {
            Row() {
              Text(`第${weekNum}周`)
                .fontSize(16)
                .fontColor(this.currentWeek === weekNum ? '#45CAD9' : '#333333')
                .fontWeight(this.currentWeek === weekNum ? FontWeight.Medium : FontWeight.Normal)

              Blank()

              if (this.currentWeek === weekNum) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#45CAD9')
              }
            }
            .width('100%')
            .height(50)
            .padding({ left: 20, right: 20 })
            .onClick(async () => {
              // 跳转到指定周：计算目标日期并更新
              if (this.currentSemester) {
                // 先播放退场动画
                await this.triggerCourseBlockExitAnimation();
                
                const semesterStartDate = new Date(this.currentSemester.startDate);
                const targetDate = new Date(semesterStartDate);
                targetDate.setDate(semesterStartDate.getDate() + (weekNum - 1) * 7);

                this.currentDate = targetDate;
                this.updateCurrentSemesterFromDate(this.currentDate);
                this.calculateWeekDatesFromCurrentDate();
                
                // 重新请求接口获取课程数据
                await this.loadCourseData();
              }
              this.showWeekPicker = false;
            })

            if (weekNum < this.totalWeeks) {
              Divider()
                .color('#F0F0F0')
                .strokeWidth(0.5)
            }
          })
        }
      }
      .layoutWeight(1) // 使用layoutWeight让列表占据剩余空间

      Row() {
        Button('取消')
          .width('80%')
          .height(45)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.showWeekPicker = false;
          })
      }
      .width('100%')
      .margin({ top: 20 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  /**
   * 获取课程颜色索引（参考class-schedule-c的颜色计算逻辑）
   */
  private getCourseColorIndex(courseName: string): number {
    let index = this.scheduleGrid.classList.indexOf(courseName);
    if (index === -1) {
      // 如果找不到，使用hash算法计算
      let hash = 0;
      for (let i = 0; i < courseName.length; i++) {
        hash = courseName.charCodeAt(i) + ((hash << 5) - hash);
      }
      index = Math.abs(hash);
    }

    // 如果index大于10，取余操作（参考show-list.vue逻辑）
    if (index > 10) {
      index = index % 10;
    }

    return index;
  }

  /**
   * 获取指定key的时间段数组
   */
  private getSectionNumbers(key: string): number[] {
    switch (key) {
      case 'value1':
        return this.sections.value1;
      case 'value2':
        return this.sections.value2;
      case 'value3':
        return this.sections.value3;
      case 'value4':
        return this.sections.value4;
      case 'value5':
        return this.sections.value5;
      case 'value6':
        return this.sections.value6;
      default:
        return [];
    }
  }

  /**
   * 检查是否是今天
   */
  private isToday(dayIndex: number): boolean {
    const today = new Date();
    const currentWeekday = (today.getDay() + 6) % 7; // 转换为周一=0的格式
    return dayIndex === currentWeekday;
  }

  /**
   * 课程块点击事件（参考show-list.vue的showItem方法）
   */
  private onCourseBlockClick(course: ScheduleCourse, dayIndex: number, courseIndex: number): void {
    console.info(`📚 [Course Click] ${course.courseName} - ${course.teacher.join(',')}`);

    // TODO: 显示课程详情弹窗（参考class-schedule-c的课程详情显示）
    // 可以显示课程名、教师、教室、时间等信息
  }

  /**
   * 获取课程背景颜色（参考show-list.vue的chooseColor方法）
   */
  private getCourseBackgroundColor(courseName: string): string {
    const colorIndex = this.getCourseColorIndex(courseName);
    const colors = [
      '#E3F2FD', '#F3E5F5', '#E8F5E8', '#FFF3E0',
      '#F1F8E9', '#FCE4EC', '#E0F2F1', '#FFF8E1',
      '#F9FBE7', '#E1F5FE', '#FAE8E4', '#F3E5AB',
      '#E8EAF6', '#FFEBEE', '#E0F7FA', '#FFF9C4',
      '#F1F8F0', '#FFEAA7', '#DDD6FE', '#FEF3C7'
    ];
    return colors[colorIndex % colors.length];
  }

  /**
   * 获取课程文字颜色（参考show-list.vue的chooseTxtColor方法）
   */
  private getCourseTextColor(courseName: string): string {
    const colorIndex = this.getCourseColorIndex(courseName);
    const colors = [
      '#1565C0', '#7B1FA2', '#2E7D32', '#EF6C00',
      '#558B2F', '#C2185B', '#00695C', '#F57F17',
      '#689F38', '#0277BD', '#D84315', '#F9A825',
      '#5E35B1', '#C62828', '#00838F', '#AFB42B',
      '#388E3C', '#FF8F00', '#512DA8', '#FBC02D'
    ];
    return colors[colorIndex % colors.length];
  }

  /**
   * 获取课程边框颜色（参考show-list.vue的borderColor方法）
   */
  private getCourseBorderColor(courseName: string): string {
    const colorIndex = this.getCourseColorIndex(courseName);
    const colors = [
      '#42A5F5', '#BA68C8', '#66BB6A', '#FF9800',
      '#8BC34A', '#E91E63', '#26A69A', '#FFEB3B',
      '#9CCC65', '#29B6F6', '#FF5722', '#FDD835',
      '#9575CD', '#F44336', '#00BCD4', '#CDDC39',
      '#4CAF50', '#FFC107', '#673AB7', '#FFEB3B'
    ];
    return colors[colorIndex % colors.length];
  }

  /**
   * 触发课程块入场动画（一次性全部显示）
   */
  private triggerCourseBlockEnterAnimation(): void {
    console.info('📅 [Animation] 开始触发课程块入场动画（一次性显示）');
    
    // 简单延迟后一次性显示所有课程
    setTimeout(() => {
      // 清空控制状态，让所有课程显示
      this.courseBlockVisible = [];
      console.info('📅 [Animation] 所有课程已显示');
    }, 50); // 从100减少到50，进一步加快显示速度
  }

  /**
   * 触发课程块退场动画
   */
  private triggerCourseBlockExitAnimation(): Promise<void> {
    return new Promise((resolve) => {
      console.info('📅 [Animation] 开始退场动画');
      
      // 初始化隐藏状态
      for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
        this.courseBlockVisible[dayIndex] = [];
        const courseCount = this.scheduleGrid.nowClassList[dayIndex]?.length || 0;
        
        for (let courseIndex = 0; courseIndex < courseCount; courseIndex++) {
          this.courseBlockVisible[dayIndex][courseIndex] = false;
        }
      }
      
      // 等待转场动画完成
      setTimeout(() => {
        console.info('📅 [Animation] 退场动画完成');
        resolve();
      }, 100); // 从200减少到100，进一步加快消失速度
    });
  }

}