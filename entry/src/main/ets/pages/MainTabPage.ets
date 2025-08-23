import {
  ConfigApiService,
  SemesterInfo,
  CurrentSemesterStatus,
  ConfigApiResponse
} from '../services/api/ConfigApiService';
import { 
  CourseApiService, 
  CourseInfo, 
  CourseRequestParams,
  CoursePosition
} from '../services/api/CourseApiService';
import { AppConfigManager } from '../services/AppConfigManager';
import { UserInfoManager, UserSchoolInfo } from '../common/constants/PreferencesUtil';
import { ApiResponse } from '../models/CollegeModels';

// 定义接口
interface UserInfo {
  avatar: string;
  username: string;
  studentId: string;
  college: string;
  major: string;
  className: string;
}

interface MenuItemType {
  icon: string;
  title: string;
  desc: string;
}

interface WeekDateRange {
  startDate: Date;
  endDate: Date;
}

// 课程数据接口（用于模拟数据）
interface MockCourseInfo {
  name: string;
  location: string;
  teacher: string;
  color: string;
}

@Entry
@Component
struct MainTabPage {
  @State currentTabIndex: number = 0;

  @Builder
  TabBuilder(title: string, targetIndex: number) {
    Column() {
      Text(this.getTabIcon(targetIndex))
        .fontSize(22)
        .fontColor(this.currentTabIndex === targetIndex ? '#45CAD9' : '#999999')
        .margin({ bottom: 4 })
      Text(title)
        .fontColor(this.currentTabIndex === targetIndex ? '#45CAD9' : '#999999')
        .fontSize(12)
        .fontWeight(this.currentTabIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private getTabIcon(index: number): string {
    const icons = ['🏠', '📅', '👤'];
    return icons[index] || '';
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: new TabsController() }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder('首页', 0))

      TabContent() {
        SchedulePage()
      }
      .tabBar(this.TabBuilder('课表', 1))

      TabContent() {
        MinePage()
      }
      .tabBar(this.TabBuilder('我的', 2))
    }
    .width('100%')
    .height('100%')
    .barBackgroundColor('#FFFFFF')
    .barMode(BarMode.Fixed)
    .vertical(false)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
  }
}

@Component
struct HomePage {
  @State private username: string = '';
  @State private collegeName: string = '';

  aboutToAppear(): void {
    // 这里可以加载用户信息
    this.username = '同学';
    this.collegeName = '计算机学院';
  }

  build() {
    Column() {
      // 顶部问候语
      Row() {
        Column() {
          Text(`你好，${this.username}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 4 })
          Text(`${this.collegeName}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 消息图标
        Text('🔔')
          .fontSize(24)
          .onClick(() => {
            // 消息点击事件
          })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 50,
        bottom: 20
      })

      // 功能区域
      Column() {
        // 今日课程卡片
        Column() {
          Row() {
            Text('今日课程')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Blank()
            Text('查看更多 >')
              .fontSize(14)
              .fontColor('#45CAD9')
              .onClick(() => {
                // 跳转到课表页
              })
          }
          .width('100%')
          .margin({ bottom: 15 })

          // 课程列表
          Column() {
            Text('暂无今日课程')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 20, bottom: 20 })
          }
          .width('100%')
          .height(100)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetY: 2
        })
        .margin({ bottom: 20 })

        // 快捷功能
        Column() {
          Text('快捷功能')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 15 })

          Grid() {
            GridItem() {
              this.FunctionCard('📅', '我的课表', '#E3F2FD')
            }

            GridItem() {
              this.FunctionCard('⭐', '课程评价', '#F3E5F5')
            }

            GridItem() {
              this.FunctionCard('📢', '系统通知', '#E8F5E8')
            }

            GridItem() {
              this.FunctionCard('❓', '问题反馈', '#FFF3E0')
            }
          }
          .rowsTemplate('1fr 1fr')
          .columnsTemplate('1fr 1fr')
          .rowsGap(15)
          .columnsGap(15)
          .height(200)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetY: 2
        })
      }
      .width('90%')
      .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FunctionCard(icon: string, title: string, bgColor: string) {
    Column() {
      Text(icon)
        .fontSize(32)
        .margin({ bottom: 8 })
      Text(title)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(bgColor)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 处理点击事件
    })
  }
}

@Component
struct SchedulePage {
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
  private timeSlots: string[] = ['8:00', '9:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];
  // 模拟多周课程数据
  private allWeeksData: Record<number, Record<number, Record<number, MockCourseInfo | null>>> = this.initMockData();

  private initMockData(): Record<number, Record<number, Record<number, MockCourseInfo | null>>> {
    const mockData: Record<number, Record<number, Record<number, MockCourseInfo | null>>> = {};
    
    // 初始化第1周数据
    mockData[1] = {};
    mockData[1][1] = {}; // 周一
    mockData[1][1][1] = {
      name: '高等数学',
      location: '教学楼A101',
      teacher: '张教授',
      color: '#E8F5E8'
    };
    mockData[1][1][2] = {
      name: '线性代数',
      location: '教学楼A102',
      teacher: '李教授',
      color: '#E3F2FD'
    };
    
    // 其他模拟数据可以根据需要添加
    return mockData;
  }

  aboutToAppear(): void {
    // 基于日期的初始化逻辑
    this.initializeWithCurrentDate();
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
      
      console.info(`📅 [Schedule Init] 初始化完成: ${this.currentDate.getFullYear()}-${this.currentDate.getMonth()+1}-${this.currentDate.getDate()}`);
      
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
        // 处理课程数据
        this.courseService.processCourseData(courseResponse.data);
        this.coursePositions = this.courseService.getWeekCourses(this.currentWeek);
        console.info(`📚 [Course] 成功加载${courseResponse.data.length}门课程`);
      } else {
        console.warn(`📚 [Course] 课程数据加载失败: ${courseResponse.msg}`);
        this.coursePositions = [];
      }
      
    } catch (error) {
      console.error('📚 [Course] 加载课程数据失败:', error);
      this.coursePositions = [];
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
  private navigateToPreviousWeek(): void {
    // 当前日期减去7天
    const newDate = new Date(this.currentDate);
    newDate.setDate(this.currentDate.getDate() - 7);
    
    this.currentDate = newDate;
    this.updateCurrentSemesterFromDate(this.currentDate);
    this.calculateWeekDatesFromCurrentDate();
    
    // 重新加载课程数据（如果学期发生变化）
    this.loadCourseData();
    
    console.info(`📅 [Navigate] 左滑到上一周: ${newDate.getFullYear()}-${newDate.getMonth()+1}-${newDate.getDate()}`);
  }

  /**
   * 导航到下一周  
   */
  private navigateToNextWeek(): void {
    // 当前日期加上7天
    const newDate = new Date(this.currentDate);
    newDate.setDate(this.currentDate.getDate() + 7);
    
    this.currentDate = newDate;
    this.updateCurrentSemesterFromDate(this.currentDate);
    this.calculateWeekDatesFromCurrentDate();
    
    // 重新加载课程数据（如果学期发生变化）
    this.loadCourseData();
    
    console.info(`📅 [Navigate] 右滑到下一周: ${newDate.getFullYear()}-${newDate.getMonth()+1}-${newDate.getDate()}`);
  }

  /**
   * 切换学期 (跳转到指定学期的第一周)
   */
  private switchSemester(direction: 'prev' | 'next'): void {
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
      this.loadCourseData();
      
      console.info(`📅 [Semester Switch] 切换到${rawTargetSemester.academicYear}学年第${rawTargetSemester.semester}学期`);
    }
  }

  /**
   * 获取星期对应的日期
   */
  private getDateForWeekDay(dayIndex: number): string {
    if (!this.weekDates) return '';
    
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
        this.navigateToPreviousWeek();
      } else if (elePosition === 'left') {
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

          // 日期范围显示
          if (this.weekDates) {
            Text(`${this.configService.formatDateString(this.weekDates.startDate)} - ${this.configService.formatDateString(this.weekDates.endDate)}`)
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 15,
          bottom: 5
        })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })

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
      .backgroundColor('#F5F5F5')

      // 周选择器弹窗
      if (this.showWeekPicker) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showWeekPicker = false;
          })

        Column() {
          Blank()

          this.buildWeekPickerContent()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildWeekPickerContent() {
    Column() {
      // 学期信息和切换按钮
      Row() {
        // 上一个学期按钮
        Button('< 上学期')
          .fontSize(14)
          .fontColor('#45CAD9')
          .backgroundColor(Color.Transparent)
          .height(30)
          .onClick(() => {
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
          .onClick(() => {
            this.switchSemester('next');
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 10 })

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
            .onClick(() => {
              // 跳转到指定周：计算目标日期并更新
              if (this.currentSemester) {
                const semesterStartDate = new Date(this.currentSemester.startDate);
                const targetDate = new Date(semesterStartDate);
                targetDate.setDate(semesterStartDate.getDate() + (weekNum - 1) * 7);
                
                this.currentDate = targetDate;
                this.updateCurrentSemesterFromDate(this.currentDate);
                this.calculateWeekDatesFromCurrentDate();
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
      .height(300)

      Row() {
        Button('取消')
          .width('45%')
          .height(45)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.showWeekPicker = false;
          })

        Blank()

        Button('确定')
          .width('45%')
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#45CAD9')
          .onClick(() => {
            this.showWeekPicker = false;
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  WeekScheduleContent() {
    Column() {
      // 星期表头
      Row() {
        // 左上角空白区域
        Column()
          .width(40)

        // 星期标题和日期
        ForEach(this.weekDays, (day: string, dayIndex: number) => {
          Column() {
            Text(day)
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 2 })
            
            // 显示对应的日期
            if (this.weekDates) {
              Text(this.getDateForWeekDay(dayIndex))
                .fontSize(14)
                .fontColor('#666666')
            }
          }
          .layoutWeight(1)
          .padding(4)
          .justifyContent(FlexAlign.Center)
        })
      }
      .width('100%')
      .height(70)
      .backgroundColor('#FAFAFA')
      .border({ width: { bottom: 1 }, color: '#E8E8E8' })

      // 课表内容区域
      Scroll() {
        Column() {
          ForEach(this.timeSlots, (time: string, timeIndex: number) => {
            Row() {
              // 时间显示列 - 只显示数字
              Column() {
                Text(`${timeIndex + 1}`)
                  .fontSize(16)
                  .fontColor('#666666')
                  .fontWeight(FontWeight.Medium)
              }
              .width(40)
              .height(70)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('#FAFAFA')
              .border({ width: { right: 1 }, color: '#E8E8E8' })

              // 七天的课程内容
              ForEach(this.weekDays, (day: string, dayIndex: number) => {
                Column() {
                  // 显示当前日期对应的课程数据
                  this.buildCurrentCourseCell(dayIndex + 1, timeIndex)
                }
                .layoutWeight(1)
                .height(60)
                .border({
                  width: { right: dayIndex < 6 ? 1 : 0, bottom: 1 },
                  color: '#E8E8E8'
                })
              })
            }
            .width('100%')
          })
        }
        .height('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildCurrentCourseCell(dayIndex: number, timeIndex: number) {
    // 获取课程数据并显示
    this.renderCourseCell(dayIndex, timeIndex)
  }

  @Builder
  renderCourseCell(dayIndex: number, timeIndex: number) {
    if (this.hasCourseAt(dayIndex, timeIndex)) {
      this.renderCourseWithData(dayIndex, timeIndex)
    } else {
      this.renderEmptyCell()
    }
  }

  @Builder
  renderCourseWithData(dayIndex: number, timeIndex: number) {
    Column() {
      Text(this.getCourseNameAt(dayIndex, timeIndex))
        .fontSize(11)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ bottom: 2 })
      
      // 显示教室信息
      if (this.hasClassroomAt(dayIndex, timeIndex)) {
        Text(this.getClassroomAt(dayIndex, timeIndex))
          .fontSize(9)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding(4)
    .backgroundColor(this.getCourseColorAt(dayIndex, timeIndex))
    .borderRadius(6)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin(2)
    .onClick(() => {
      this.onCourseClick(dayIndex, timeIndex);
    })
  }

  @Builder
  renderEmptyCell() {
    Column() {
      if (this.isLoadingCourses) {
        Text('...')
          .fontSize(9)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }

  /**
   * 检查指定位置是否有课程
   */
  private hasCourseAt(dayIndex: number, timeIndex: number): boolean {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    return course !== null;
  }

  /**
   * 获取指定位置的课程名
   */
  private getCourseNameAt(dayIndex: number, timeIndex: number): string {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    return course ? course.courseName : '';
  }

  /**
   * 检查指定位置的课程是否有教室信息
   */
  private hasClassroomAt(dayIndex: number, timeIndex: number): boolean {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    return course ? course.classroom && course.classroom.length > 0 : false;
  }

  /**
   * 获取指定位置的教室信息
   */
  private getClassroomAt(dayIndex: number, timeIndex: number): string {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    return course && course.classroom && course.classroom.length > 0 ? course.classroom[0] : '';
  }

  /**
   * 获取指定位置课程的颜色
   */
  private getCourseColorAt(dayIndex: number, timeIndex: number): string {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    return course ? this.getCourseColor(course.courseName) : Color.Transparent.toString();
  }

  /**
   * 处理课程点击事件
   */
  private onCourseClick(dayIndex: number, timeIndex: number): void {
    const course = this.courseService.getCourseAt(this.currentWeek, dayIndex, timeIndex);
    if (course) {
      console.info(`📚 [Course Click] ${course.courseName} - ${course.teacher.join(',')}`);
      // TODO: 显示课程详情弹窗
    }
  }

  /**
   * 根据课程名获取颜色
   */
  private getCourseColor(courseName: string): string {
    // 简单的颜色计算算法
    const colors = [
      '#E8F5E8', '#E3F2FD', '#F3E5F5', '#FFF3E0', '#FFEBEE',
      '#F0F4C3', '#FCE4EC', '#E0F2F1', '#FFF8E1', '#F1F8E9'
    ];
    
    let hash = 0;
    for (let i = 0; i < courseName.length; i++) {
      hash = courseName.charCodeAt(i) + ((hash << 5) - hash);
    }
    
    return colors[Math.abs(hash) % colors.length];
  }
}

@Component
struct MinePage {
  @State private userInfo: UserInfo = {
    avatar: '👤',
    username: '霞客同学',
    studentId: '2024001',
    college: '计算机学院',
    major: '软件工程',
    className: '软工2024-1班'
  };

  build() {
    Column() {
      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          Text(this.userInfo.avatar)
            .fontSize(48)
            .width(80)
            .height(80)
            .backgroundColor('#E3F2FD')
            .borderRadius(40)
            .textAlign(TextAlign.Center)
            .margin({ right: 16 })

          // 用户信息
          Column() {
            Text(this.userInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 4 })
            Text(`学号：${this.userInfo.studentId}`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 2 })
            Text(`${this.userInfo.college} · ${this.userInfo.major}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 2 })
            Text(this.userInfo.className)
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetY: 2
      })
      .margin({ top: 50, bottom: 20 })

      // 功能列表
      Column() {
        this.MenuSection('个人信息', this.getPersonalItems())
        this.MenuSection('学习相关', this.getStudyItems())
        this.MenuSection('系统功能', this.getSystemItems())
      }
      .width('90%')
      .layoutWeight(1)

      Blank()

      // 退出登录按钮
      Button('退出登录')
        .width('60%')
        .height(45)
        .fontSize(16)
        .fontColor('#FF5722')
        .backgroundColor(Color.White)
        .borderRadius(22)
        .border({
          width: 1,
          color: '#FF5722'
        })
        .margin({ bottom: 60 })
        .onClick(() => {
          // 退出登录逻辑
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  MenuSection(title: string, items: MenuItemType[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        ForEach(items, (item: MenuItemType, index: number) => {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .width(40)
              .textAlign(TextAlign.Center)
              .margin({ right: 12 })

            Column() {
              Text(item.title)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 2 })
              Text(item.desc)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 处理点击事件
          })

          if (index < items.length - 1) {
            Divider()
              .color('#F0F0F0')
              .strokeWidth(0.5)
              .margin({ left: 68 })
          }
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 20 })
    }
  }

  private getPersonalItems(): MenuItemType[] {
    return [
      { icon: '📝', title: '个人资料', desc: '修改个人信息' },
      { icon: '🔒', title: '账号安全', desc: '密码修改等' }
    ];
  }

  private getStudyItems(): MenuItemType[] {
    return [
      { icon: '⭐', title: '我的评价', desc: '课程和教师评价' },
      { icon: '📊', title: '学习统计', desc: '课程统计信息' },
      { icon: '📅', title: '课表管理', desc: '自定义课表' }
    ];
  }

  private getSystemItems(): MenuItemType[] {
    return [
      { icon: '📢', title: '系统通知', desc: '查看系统消息' },
      { icon: '❓', title: '帮助反馈', desc: '问题反馈和帮助' },
      { icon: 'ℹ️', title: '关于我们', desc: '应用信息' }
    ];
  }
}