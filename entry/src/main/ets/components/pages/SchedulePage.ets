import { ConfigApiService, CurrentSemesterStatus, SemesterInfo } from '../../services/api/ConfigApiService';
import { JwxtCourseService } from '../../services/api/JwxtCourseService';
import { JwxtCourse } from '../../models/JwxtCourseModels';
import { AppConfigManager } from '../../services/AppConfigManager';
import { UserInfoManager } from '../../common/utils/UserInfoManager';
import { CourseColorUtil } from '../../common/utils/CourseColorUtil';
import { CourseTimeUtil } from '../../common/utils/CourseTimeUtil';
import { CacheManager } from '../../common/utils/CacheManager';
import { ErrorUtil } from '../../common/utils/ErrorUtil';
import { CourseParser } from '../../common/utils/CourseParser';
import { curves, promptAction } from '@kit.ArkUI';

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
  isPlaceholder?: boolean; // 标识是否为空白占位块
  originalCourseTime?: string[]; // 保存原始时间信息，如["08:30-09:15", "09:25-10:10"]
}

// 扩展的课程接口，包含周次信息
interface ScheduleCourseWithWeeks extends ScheduleCourse {
  weeks?: string;
  showPop?: boolean; // 添加弹窗状态控制
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
  @State private isLoadingCourses: boolean = false;
  private configService: ConfigApiService = ConfigApiService.getInstance();
  private jwxtCourseService: JwxtCourseService = JwxtCourseService.getInstance();
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
  // 实际课程数据 - 使用教务系统接口数据
  @State private courseList: JwxtCourse[] = [];
  // 动画支持
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 80 }); // 从150减少到80，加快动画速度
  // 课程块可见性状态
  @State private courseBlockVisible: boolean[][] = [];
  // 课程弹窗状态管理
  @State private coursePopupStates: Map<string, boolean> = new Map();
  private promptAction = this.getUIContext().getPromptAction();

  async aboutToAppear(): Promise<void> {
    // 初始化 JwxtCourseService (必须在使用前初始化)
    const context = this.getUIContext().getHostContext();
    if (!context) {
      console.error('📋 [Schedule] 获取Context失败，无法初始化服务');
      return;
    }
    await this.jwxtCourseService.initialize(context);

    // 基于日期的初始化逻辑
    await this.initializeWithCurrentDate();
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

          Blank()

          // 回到本周按钮
          if (!this.isCurrentWeekShowing()) {
            Button('回到本周')
              .fontSize(14)
              .fontColor($r('app.color.schedule_primary_color'))
              .backgroundColor('#E3F2FD')
              .height(32)
              .borderRadius(16)
              .border({
                width: 1,
                color: $r('app.color.schedule_primary_color'),
                radius: 16
              })
              .padding({
                left: 12,
                right: 12,
                top: 0,
                bottom: 0
              })
              .transition(this.effect) // 应用与课程块相同的转场动画
              .onClick(async () => {
                await this.navigateToCurrentWeek();
              })
          }
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
          showClose: false,
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
          Text(this.currentMonth.substring(0, this.currentMonth.length - 1))
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
                .fontColor(this.isToday(dayIndex) ? $r('app.color.schedule_primary_color') : '#666666')
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

      // 处理空白占位块
      if (course.isPlaceholder) {
        // 渲染透明的占位块
        Column() {
          // 空内容
        }
        .width('95%')
        .height(`${length * 8.33}%`)
        .backgroundColor(Color.Transparent) // 完全透明
        .margin({ top: 1, bottom: 1 })

        // 注意：没有onClick事件，不可点击
      } else {
        // 渲染正常课程块
        Column() {
          // 课程名称
          Text(course.courseName)
            .fontSize(11)
            .fontColor(CourseColorUtil.getCourseTextColor(course.courseName, this.scheduleGrid.classList))
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .margin({ bottom: 2 })

          // 教室信息
          if (course.classroom && course.classroom.length > 0) {
            Text(course.classroom[0])
              .fontSize(9)
              .fontColor(CourseColorUtil.getCourseTextColor(course.courseName, this.scheduleGrid.classList))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .margin({ bottom: 1 })
          }

          // 教师信息
          if (course.teacher && course.teacher.length > 0) {
            Text(course.teacher[0])
              .fontSize(8)
              .fontColor(CourseColorUtil.getCourseTextColor(course.courseName, this.scheduleGrid.classList))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
          }
        }
        .transition(this.effect) // 应用转场动画
        .width('95%')
        .height(`${length * 8.33}%`)
        .backgroundColor(CourseColorUtil.getCourseBackgroundColor(course.courseName, this.scheduleGrid.classList))
        .border({
          width: 1,
          color: CourseColorUtil.getCourseBorderColor(course.courseName, this.scheduleGrid.classList),
          radius: 4
        })
        .padding(3)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 1, bottom: 1 })
        .onClick(() => {
          this.toggleCoursePopup(this.getCourseKey(dayIndex, courseIndex, course.courseName), true);
        })
        // 绑定弹窗
        .bindPopup(this.getCoursePopupState(dayIndex, courseIndex, course.courseName), {
          builder: this.CourseDetailPopup(course),
          placement: Placement.Top,
          enableArrow: true,
          mask: true,
          width: '80%',
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.toggleCoursePopup(this.getCourseKey(dayIndex, courseIndex, course.courseName), false);
            }
          }
        })
      }
    }
  }

  @Builder
  WeekPickerBuilder() {
    Column() {
      // 学期信息和切换按钮
      Row() {
        // 上一个学期按钮
        if (this.canGoToPreviousSemester()) {
          Button('< 上学期')
            .fontSize(14)
            .fontColor($r('app.color.schedule_primary_color'))
            .backgroundColor(Color.Transparent)
            .height(30)
            .onClick(async () => {
              await this.triggerCourseBlockExitAnimation();
              this.switchSemester('prev');
            })
        } else {
          // 不可切换时显示灰色按钮
          Button('< 上学期')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .backgroundColor(Color.Transparent)
            .height(30)
            .enabled(false)
        }

        Blank()

        // 当前学期信息
        Text(`${this.currentSemester?.academicYear || '2024'}学年第${this.currentSemester?.semester || 1}学期`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        // 下一个学期按钮
        if (this.canGoToNextSemester()) {
          Button('下学期 >')
            .fontSize(14)
            .fontColor($r('app.color.schedule_primary_color'))
            .backgroundColor(Color.Transparent)
            .height(30)
            .onClick(async () => {
              await this.triggerCourseBlockExitAnimation();
              this.switchSemester('next');
            })
        } else {
          // 不可切换时显示灰色按钮
          Button('下学期 >')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .backgroundColor(Color.Transparent)
            .height(30)
            .enabled(false)
        }
      }
      .width('100%')
      .padding({ bottom: 10 })

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
                .fontColor(this.isWeekSelectableForCurrentGrade(weekNum)
                  ? (this.currentWeek === weekNum ? $r('app.color.schedule_primary_color') : '#333333')
                  : '#CCCCCC') // 不可选的周数显示灰色
                .fontWeight(this.currentWeek === weekNum ? FontWeight.Medium : FontWeight.Normal)

              Blank()

              if (this.currentWeek === weekNum && this.isWeekSelectableForCurrentGrade(weekNum)) {
                Text('✓')
                  .fontSize(16)
                  .fontColor($r('app.color.schedule_primary_color'))
              }
            }
            .width('100%')
            .height(50)
            .padding({ left: 20, right: 20 })
            .onClick(async () => {
              await this.onWeekItemClick(weekNum);
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
   * 课程详细信息弹窗
   */
  @Builder
  CourseDetailPopup(course: ScheduleCourse) {
    Column() {
      // 课程名称
      Text(course.courseName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })
        .maxLines(2)
        .textAlign(TextAlign.Center)

      Divider()
        .color('#E0E0E0')
        .strokeWidth(1)
        .margin({ bottom: 8 })

      // 教师信息
      if (course.teacher && course.teacher.length > 0) {
        Row() {
          Text('教师：')
            .fontSize(14)
            .fontColor('#666666')
          Text(course.teacher[0])
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }

      // 教室信息
      if (course.classroom && course.classroom.length > 0) {
        Row() {
          Text('教室：')
            .fontSize(14)
            .fontColor('#666666')
          Text(course.classroom[0])
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }

      // 节次和时间信息
      Row() {
        Text('时间：')
          .fontSize(14)
          .fontColor('#666666')
        Text(`${course.section.join(',')}节 (${CourseTimeUtil.getTimeRange(course.originalCourseTime)})`)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 6 })
      .alignItems(VerticalAlign.Center)

      // 校区信息
      if (course.campus) {
        Row() {
          Text('校区：')
            .fontSize(14)
            .fontColor('#666666')
          Text(course.campus)
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(8)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
    .width('100%')
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
   * 处理课程列表（使用教务系统接口数据转换为课表格式）
   */
  private processCourseList(): void {
    // 将教务系统返回的 JwxtCourse[] 转换为 ScheduleCourse[] 格式
    const convertedCourses: ScheduleCourseWithWeeks[] = this.convertJwxtCourseToScheduleCourse(this.courseList);

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
   * 将JwxtCourse转换为ScheduleCourse格式
   *
   * JwxtCourse 已经是标准化格式，只需进行简单的字段映射
   */
  private convertJwxtCourseToScheduleCourse(courseList: JwxtCourse[]): ScheduleCourseWithWeeks[] {
    return courseList.map((course: JwxtCourse) => {
      // JwxtCourse 的数据已经通过 CourseParser 解析，可以直接使用
      const scheduleCourse: ScheduleCourseWithWeeks = {
        courseName: course.name,
        classroom: [course.classroom], // 将字符串转换为数组
        teacher: [course.teacher], // 将字符串转换为数组
        campus: course.campus || '', // 校区
        courseTime: CourseParser.parseCourseTime(course.sessions), // 解析课程时间
        weekday: course.dayOfWeek, // 星期 (已是数字1-7)
        section: course.sessions, // 节次数组 (已解析)
        courseId: [course.id], // 课程ID
        weeks: JSON.stringify(course.weeks), // 将周次数组转换为JSON字符串格式 (兼容现有过滤逻辑)
        originalCourseTime: [] // 教务系统接口不提供原始时间，使用空数组
      };
      return scheduleCourse;
    });
  }

  /**
   * 判断课程是否在当前周
   *
   * 使用 CourseParser 进行标准解析
   */
  private isCourseInCurrentWeek(course: ScheduleCourseWithWeeks, currentWeek: number): boolean {
    if (!course.weeks) {
      return true; // 如果没有周次信息,默认显示
    }

    // 使用 CourseParser 判断课程是否在当前周
    return CourseParser.isCourseInWeek(course.weeks, currentWeek);
  }

  /**
   * 计算课程布局（核心算法，参考show-list.vue的布局逻辑）
   */
  private calculateCourseLayout(): void {
    for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
      const originalCourses = this.scheduleGrid.nowClassList[dayIndex];

      // 在课程间插入空白占位块
      const coursesWithPlaceholders = this.insertPlaceholdersForGaps(originalCourses);

      // 更新课程列表
      this.scheduleGrid.nowClassList[dayIndex] = coursesWithPlaceholders;

      // 初始化当天的布局数据
      this.scheduleGrid.classNum[dayIndex] = [];
      this.scheduleGrid.classLength[dayIndex] = [];
      this.scheduleGrid.isContinue[dayIndex] = [];

      // 按节次排序（已经在insertPlaceholdersForGaps中排序过）
      const sortedCourses = coursesWithPlaceholders;

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
   * 加载课程数据 (使用教务系统接口)
   */
  private async loadCourseData(): Promise<void> {
    if (!this.currentSemester) {
      console.warn('📚 [Course] 当前学期信息为空，无法加载课程');
      return;
    }

    this.isLoadingCourses = true;

    try {
      console.info(`📚 [Course] 开始加载课程: ${this.currentSemester.academicYear}学年 第${this.currentSemester.semester}学期`);

      // 构建请求参数 - 只需要学年和学期
      const params = this.jwxtCourseService.buildCourseParams(
        this.currentSemester.academicYear,
        this.currentSemester.semester
      );

      console.info(`📚 [Course] 请求课程数据: ${JSON.stringify(params)}`);

      // 获取课程列表 (直接返回 JwxtCourse[])
      const courseList: JwxtCourse[] = await this.jwxtCourseService.getCourseList(params);

      // 将接口数据赋值给 courseList 状态变量
      this.courseList = courseList;

      // 处理课程数据，生成课表网格
      this.processWeekScheduleData();

      console.info(`📚 [Course] 成功加载${courseList.length}门课程`);

    } catch (error) {
      console.error('📚 [Course] 加载课程数据失败:', error);

      // 判断是否为网络错误
      if (ErrorUtil.isNetworkError(error)) {
        this.promptAction.showToast({
          message: '网络连接失败，请检查网络后重试',
          duration: 3000,
          bottom: '100vp'
        });
        console.warn('📚 [Course] 网络错误，已提示用户');
      } else {
        // 其他错误
        this.promptAction.showToast({
          message: `加载课程失败: ${error}`,
          duration: 3000,
          bottom: '100vp'
        });
      }

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
        // 检查是否可以继续右滑到上一周
        const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
        if (this.configService.canSwipeLeft(this.currentDate, userInfo.className)) {
          console.info(`📅 [Navigate] 右滑到上一周`)
          this.navigateToPreviousWeek();
        } else {
          // 显示暂无数据提示
          this.showNoDataToast();
        }

      } else if (elePosition === 'left') {
        // 左滑：显示下一周 (对应class-schedule-c的rightClick)  
        // 检查是否可以继续左滑到下一周
        if (this.configService.canSwipeRight(this.currentDate)) {
          console.info(`📅 [Navigate] 左滑到下一周`)
          this.navigateToNextWeek();
        } else {
          // 显示暂无数据提示
          this.showNoDataToast();
        }
      }
    }
  }

  /**
   * 判断指定周数是否对当前年级可选
   */
  private isWeekSelectableForCurrentGrade(weekNum: number): boolean {
    if (!this.currentSemester) {
      return true;
    }

    const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
    return this.configService.isWeekValidForGrade(this.currentSemester, weekNum, userInfo.className);
  }

  /**
   * 处理周数项点击事件
   */
  private async onWeekItemClick(weekNum: number): Promise<void> {
    // 只有年级有效的周数才可以点击
    if (this.isWeekSelectableForCurrentGrade(weekNum)) {
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
    } else {
      // 显示年级限制提示
      this.showGradeRestrictedToast();
    }
  }

  /**
   * 显示年级限制提示
   */
  private showGradeRestrictedToast(): void {
    this.promptAction.showToast({
      message: '该学期不在您的修读范围内',
      duration: 2000,
      bottom: '100vp'
    });
    console.info('📅 [Toast] 显示年级限制提示');
  }

  /**
   * 判断是否可以前往上一个学期
   */
  private canGoToPreviousSemester(): boolean {
    if (!this.currentSemester) {
      return false;
    }

    const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
    return this.configService.canSwitchSemester(this.currentSemester, 'prev', userInfo.className);
  }

  /**
   * 判断是否可以前往下一个学期
   */
  private canGoToNextSemester(): boolean {
    if (!this.currentSemester) {
      return false;
    }

    const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
    return this.configService.canSwitchSemester(this.currentSemester, 'next', userInfo.className);
  }

  /**
   * 显示暂无数据提示
   */
  private showNoDataToast(): void {
    this.promptAction.showToast({
      message: '暂无数据',
      duration: 2000,
      bottom: '100vp'
    });
    console.info('📅 [Toast] 显示暂无数据提示');
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
   * 修复：需要同时比较具体日期，而不仅仅是星期几
   */
  private isToday(dayIndex: number): boolean {
    if (!this.weekDates) {
      return false;
    }

    const today = new Date();

    // 计算当前周显示的对应日期
    const targetDate = new Date(this.weekDates.startDate);
    targetDate.setDate(this.weekDates.startDate.getDate() + dayIndex);

    // 比较年月日是否完全一致
    return today.getFullYear() === targetDate.getFullYear() &&
      today.getMonth() === targetDate.getMonth() &&
      today.getDate() === targetDate.getDate();
  }

  /**
   * 课程块点击事件（参考show-list.vue的showItem方法）
   */
  private onCourseBlockClick(course: ScheduleCourse, dayIndex: number, courseIndex: number): void {
    console.info(`📚 [Course Click] ${course.courseName} - ${course.teacher.join(',')}`);
    // 此方法现在由buildCourseBlock中的onClick直接处理弹窗逻辑
  }

  /**
   * 获取课程唯一标识
   */
  private getCourseKey(dayIndex: number, courseIndex: number, courseName: string): string {
    return `${dayIndex}-${courseIndex}-${courseName}`;
  }

  /**
   * 获取课程弹窗状态
   */
  private getCoursePopupState(dayIndex: number, courseIndex: number, courseName: string): boolean {
    // 空课程名表示占位块，不显示弹窗
    if (!courseName) {
      return false;
    }

    const courseKey = this.getCourseKey(dayIndex, courseIndex, courseName);
    return this.coursePopupStates.get(courseKey) || false;
  }

  /**
   * 切换课程弹窗状态
   */
  private toggleCoursePopup(courseKey: string, show: boolean): void {
    // 关闭所有其他弹窗，保证同时只显示一个
    this.coursePopupStates.forEach((value, key) => {
      if (key !== courseKey) {
        this.coursePopupStates.set(key, false);
      }
    });

    // 设置当前课程弹窗状态
    this.coursePopupStates.set(courseKey, show);

    console.info(`📚 [Popup] ${show ? '显示' : '隐藏'}课程弹窗: ${courseKey}`);
  }

  /**
   * 关闭所有弹窗
   */
  private closeAllPopups(): void {
    this.coursePopupStates.forEach((value, key) => {
      this.coursePopupStates.set(key, false);
    });
    console.info('📚 [Popup] 关闭所有课程弹窗');
  }

  /**
   * 创建空白占位课程块
   */
  private createPlaceholderCourse(startSection: number, endSection: number): ScheduleCourse {
    const sections: number[] = [];
    for (let i = startSection; i <= endSection; i++) {
      sections.push(i);
    }

    return {
      courseName: '', // 空字符串
      classroom: [],
      teacher: [],
      campus: '',
      courseTime: [[startSection, endSection]],
      weekday: 1, // 默认值，实际不使用
      section: sections,
      courseId: [],
      isPlaceholder: true // 关键标识
    };
  }

  /**
   * 检测课程间的节次间隙并插入空白占位块
   */
  private insertPlaceholdersForGaps(courses: ScheduleCourse[]): ScheduleCourse[] {
    if (courses.length === 0) {
      return courses;
    }

    // 按节次排序
    const sortedCourses = courses.sort((a, b) => a.section[0] - b.section[0]);
    const result: ScheduleCourse[] = [];

    // 处理第一门课程前的空白间隙
    const firstCourse = sortedCourses[0];
    const firstStart = firstCourse.section[0];

    // 如果第一门课不是从第1节开始，则填充前面的空白
    if (firstStart > 1) {
      for (let section = 1; section < firstStart; section++) {
        const placeholder = this.createPlaceholderCourse(section, section);
        result.push(placeholder);
      }
    }

    // 处理课程间的间隙
    for (let i = 0; i < sortedCourses.length; i++) {
      const currentCourse = sortedCourses[i];

      // 添加当前课程
      result.push(currentCourse);

      // 检查是否需要在下一门课之前插入空白块
      if (i < sortedCourses.length - 1) {
        const nextCourse = sortedCourses[i + 1];
        const currentEnd = currentCourse.section[currentCourse.section.length - 1];
        const nextStart = nextCourse.section[0];

        // 如果存在间隙（下一门课不是紧接着当前课的）
        if (nextStart - currentEnd > 1) {
          const gapStart = currentEnd + 1;
          const gapEnd = nextStart - 1;

          // 为间隙中的每个节次创建占位块
          for (let section = gapStart; section <= gapEnd; section++) {
            const placeholder = this.createPlaceholderCourse(section, section);
            result.push(placeholder);
          }
        }
      }
    }

    console.info(`📚 [Course Layout] 原始课程${courses.length}门，添加占位块后${result.length}个元素`);
    return result;
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

  /**
   * 判断当前是否显示真实的本周
   */
  private isCurrentWeekShowing(): boolean {
    const today = new Date();

    // 使用ConfigService计算今天对应的真实学期状态
    const todayStatus = this.configService.calculateCurrentSemesterStatus(today);

    if (!todayStatus || !todayStatus.currentSemester || !this.currentSemester) {
      return false;
    }

    // 比较学期和周数是否一致
    return todayStatus.currentSemester.academicYear === this.currentSemester.academicYear &&
      todayStatus.currentSemester.semester === this.currentSemester.semester &&
      todayStatus.currentWeek === this.currentWeek;
  }

  /**
   * 导航回到当前真实周
   */
  private async navigateToCurrentWeek(): Promise<void> {
    console.info('📅 [Navigate] 回到本周');

    // 先播放退场动画
    await this.triggerCourseBlockExitAnimation();

    // 重置为今天的日期
    const today = new Date();
    this.currentDate = new Date(today);

    // 重新计算基于今天的学期状态
    this.updateCurrentSemesterFromDate(this.currentDate);
    this.calculateWeekDatesFromCurrentDate();

    // 重新加载课程数据
    await this.loadCourseData();

    console.info(`📅 [Navigate] 已回到本周: ${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`);
  }
}