import {
  ConfigApiService,
  SemesterInfo,
  CurrentSemesterStatus,
  ConfigApiResponse
} from '../services/api/ConfigApiService';
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
  private swiper: SwiperController = new SwiperController();
  private configService: ConfigApiService = ConfigApiService.getInstance();
  private weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  private timeSlots: string[] = ['8:00', '9:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];
  // TODO 模拟多周课程数据
  private allWeeksData: Record<number, Record<number, Record<number, CourseInfo | null>>> = {
    1: {
      // 第1周
      1: {
        // 周一
        1: {
          name: '高等数学',
          location: '教学楼A101',
          teacher: '张教授',
          color: '#E8F5E8'
        },
        2: {
          name: '线性代数',
          location: '教学楼A102',
          teacher: '李教授',
          color: '#E3F2FD'
        },
        4: {
          name: '数据结构',
          location: '实验楼B201',
          teacher: '王教授',
          color: '#FFF3E0'
        }
      },
      2: {
        // 周二
        0: {
          name: '英语',
          location: '外语楼C301',
          teacher: '陈教授',
          color: '#F3E5F5'
        },
        3: {
          name: '计算机网络',
          location: '教学楼A205',
          teacher: '刘教授',
          color: '#FFEBEE'
        }
      },
      3: {
        // 周三
        1: {
          name: '操作系统',
          location: '教学楼A301',
          teacher: '赵教授',
          color: '#F0F4C3'
        },
        5: {
          name: '软件工程',
          location: '教学楼B105',
          teacher: '孙教授',
          color: '#FCE4EC'
        }
      },
      4: {
        // 周四
        2: {
          name: '数据库原理',
          location: '实验楼B301',
          teacher: '钱教授',
          color: '#E0F2F1'
        }
      },
      5: {
        // 周五
        0: {
          name: '体育',
          location: '体育馆',
          teacher: '周教练',
          color: '#FFF8E1'
        },
        6: {
          name: '马克思主义原理',
          location: '教学楼C201',
          teacher: '吴教授',
          color: '#F1F8E9'
        }
      },
      6: {}, // 周六
      7: {}  // 周日
    },
    2: {
      // 第2周 - 不同的课程安排
      1: {
        0: {
          name: '高等数学',
          location: '教学楼A101',
          teacher: '张教授',
          color: '#E8F5E8'
        },
        3: {
          name: '算法设计',
          location: '实验楼B202',
          teacher: '李教授',
          color: '#FFECB3'
        }
      },
      2: {
        1: {
          name: '英语',
          location: '外语楼C301',
          teacher: '陈教授',
          color: '#F3E5F5'
        },
        4: {
          name: '计算机组成原理',
          location: '教学楼A206',
          teacher: '赵教授',
          color: '#E8EAF6'
        }
      },
      3: {
        2: {
          name: '操作系统',
          location: '教学楼A301',
          teacher: '赵教授',
          color: '#F0F4C3'
        }
      },
      4: {
        1: {
          name: '数据库原理',
          location: '实验楼B301',
          teacher: '钱教授',
          color: '#E0F2F1'
        },
        5: {
          name: '编译原理',
          location: '教学楼A401',
          teacher: '孙教授',
          color: '#FCE4EC'
        }
      },
      5: {
        0: {
          name: '体育',
          location: '体育馆',
          teacher: '周教练',
          color: '#FFF8E1'
        }
      },
      6: {},
      7: {}
    }
  };

  aboutToAppear(): void {
    // 先初始化默认配置，确保有基础数据
    this.initDefaultConfig();
    // 检查配置服务是否已有数据，如果有则直接使用，否则重新加载
    this.initializeFromExistingConfig();
  }

  /**
   * 从现有配置初始化 (如果应用启动时已预加载)
   */
  private async initializeFromExistingConfig(): Promise<void> {
    try {
      const semesterList = this.configService.getSemesterList();
      if (semesterList && semesterList.length > 0) {
        // 使用已存在的配置数据
        console.info('📋 [Schedule] 使用预加载的配置数据');
        this.processExistingConfig();
      } else {
        // 没有预加载数据，重新获取
        console.info('📋 [Schedule] 预加载数据不存在，重新获取配置');
        await this.loadConfig();
      }
    } catch (error) {
      console.error('📋 [Schedule] 配置初始化失败:', error);
      await this.loadConfig(); // 降级处理
    }
  }

  /**
   * 处理现有配置数据
   */
  private processExistingConfig(): void {
    // 获取学期列表
    const tempSemesterList = this.configService.getSemesterList();
    this.semesterList = [];
    tempSemesterList.forEach((semester) => {
      this.semesterList.push({
        year: semester.year,
        semester: semester.semester,
        startDate: semester.startDate,
        endDate: semester.endDate,
        totalWeeks: semester.totalWeeks
      });
    });

    // 计算当前学期状态
    const tempStatus = this.configService.calculateCurrentSemesterStatus();
    const newCurrentStatus: CurrentSemesterStatus = {
      isInSemester: tempStatus.isInSemester,
      isInHoliday: tempStatus.isInHoliday,
      currentWeek: tempStatus.currentWeek,
      statusText: tempStatus.statusText
    };
    if (tempStatus.currentSemester) {
      newCurrentStatus.currentSemester = {
        year: tempStatus.currentSemester.year,
        semester: tempStatus.currentSemester.semester,
        startDate: tempStatus.currentSemester.startDate,
        endDate: tempStatus.currentSemester.endDate,
        totalWeeks: tempStatus.currentSemester.totalWeeks
      };
    }
    this.currentStatus = newCurrentStatus;
    this.displayStatusText = tempStatus.statusText;

    if (tempStatus.isInSemester && tempStatus.currentSemester) {
      // 当前在学期中
      const tempCurrentSemester = tempStatus.currentSemester;
      const newSemester: SemesterInfo = {
        year: tempCurrentSemester.year,
        semester: tempCurrentSemester.semester,
        startDate: tempCurrentSemester.startDate,
        endDate: tempCurrentSemester.endDate,
        totalWeeks: tempCurrentSemester.totalWeeks
      };
      this.currentSemester = newSemester;
      this.currentWeek = tempStatus.currentWeek;
      this.totalWeeks = tempCurrentSemester.totalWeeks;
      this.updateWeekDates(tempCurrentSemester.startDate);

      // 延迟定位到当前周
      setTimeout(() => {
        this.navigateToCurrentWeek();
      }, 100);
    } else if (tempStatus.isInHoliday) {
      // 当前在假期中
      const latestSemester = this.getLatestSemester();
      if (latestSemester) {
        const newSemester: SemesterInfo = {
          year: latestSemester.year,
          semester: latestSemester.semester,
          startDate: latestSemester.startDate,
          endDate: latestSemester.endDate,
          totalWeeks: latestSemester.totalWeeks
        };
        this.currentSemester = newSemester;
        this.totalWeeks = latestSemester.totalWeeks;
        this.currentWeek = 1; // 假期中默认显示第1周
        this.updateWeekDates(latestSemester.startDate);
      }
    }

    console.info(`📅 [Schedule Config] 状态: ${this.displayStatusText}, 当前学期: ${this.currentSemester?.year}年${this.currentSemester?.semester ===
      1 ? '秋季' : '春季'}学期`);
  }

  /**
   * 加载配置信息 (支持完整的学期管理系统)
   */
  private async loadConfig(): Promise<void> {
    try {
      // 调用配置服务
      const rawConfigResponse = await this.configService.getConfig();
      // 手动构建响应对象，避免对象字面量错误
      const configResponse: ConfigApiResponse = {
        msg: rawConfigResponse.msg,
        code: rawConfigResponse.code,
        data: {
          start: rawConfigResponse.data.start,
          end: rawConfigResponse.data.end
        }
      };

      if (configResponse.code === 200 && configResponse.data) {
        // 获取学期列表
        const tempSemesterList = this.configService.getSemesterList();
        // 清空并重新填充
        this.semesterList = [];
        tempSemesterList.forEach((semester) => {
          this.semesterList.push({
            year: semester.year,
            semester: semester.semester,
            startDate: semester.startDate,
            endDate: semester.endDate,
            totalWeeks: semester.totalWeeks
          });
        });

        // 计算当前学期状态
        const tempStatus = this.configService.calculateCurrentSemesterStatus();
        // 手动复制状态对象
        const newCurrentStatus: CurrentSemesterStatus = {
          isInSemester: tempStatus.isInSemester,
          isInHoliday: tempStatus.isInHoliday,
          currentWeek: tempStatus.currentWeek,
          statusText: tempStatus.statusText
        };
        if (tempStatus.currentSemester) {
          newCurrentStatus.currentSemester = {
            year: tempStatus.currentSemester.year,
            semester: tempStatus.currentSemester.semester,
            startDate: tempStatus.currentSemester.startDate,
            endDate: tempStatus.currentSemester.endDate,
            totalWeeks: tempStatus.currentSemester.totalWeeks
          };
        }
        this.currentStatus = newCurrentStatus;
        this.displayStatusText = tempStatus.statusText;

        if (tempStatus.isInSemester && tempStatus.currentSemester) {
          // 当前在学期中
          const tempCurrentSemester = tempStatus.currentSemester;
          const newSemester: SemesterInfo = {
            year: tempCurrentSemester.year,
            semester: tempCurrentSemester.semester,
            startDate: tempCurrentSemester.startDate,
            endDate: tempCurrentSemester.endDate,
            totalWeeks: tempCurrentSemester.totalWeeks
          };
          this.currentSemester = newSemester;
          this.currentWeek = tempStatus.currentWeek;
          this.totalWeeks = tempCurrentSemester.totalWeeks;
          this.updateWeekDates(tempCurrentSemester.startDate);

          // 延迟定位到当前周，确保Swiper已完全初始化
          setTimeout(() => {
            this.navigateToCurrentWeek();
          }, 100);
        } else if (tempStatus.isInHoliday) {
          // 当前在假期中，显示最近的学期
          const latestSemester = this.getLatestSemester();
          if (latestSemester) {
            const newSemester: SemesterInfo = {
              year: latestSemester.year,
              semester: latestSemester.semester,
              startDate: latestSemester.startDate,
              endDate: latestSemester.endDate,
              totalWeeks: latestSemester.totalWeeks
            };
            this.currentSemester = newSemester;
            this.totalWeeks = latestSemester.totalWeeks;
            this.currentWeek = 1; // 假期中默认显示第1周
            this.updateWeekDates(latestSemester.startDate);
          }
        }

        console.info(`📅 [Schedule Config] 状态: ${this.displayStatusText}, 当前学期: ${this.currentSemester?.year}年${this.currentSemester?.semester ===
          1 ? '秋季' : '春季'}学期`);
      } else {
        console.error('配置加载失败:', configResponse.msg);
      }
    } catch (error) {
      console.error('配置请求失败:', error);
      // 保持默认配置
    }
  }

  /**
   * 初始化默认配置
   */
  private initDefaultConfig(): void {
    this.totalWeeks = 20;
    this.currentWeek = 1;
    this.displayStatusText = "第1周";

    // 默认学期信息 (2025学年第一学期)
    this.currentSemester = {
      year: "2024",
      semester: 1,
      startDate: "2024-09-08",
      endDate: "2025-01-21",
      totalWeeks: 20
    };

    this.updateWeekDates(this.currentSemester.startDate);
  }

  /**
   * 获取最近的学期 (用于假期中的显示)
   */
  private getLatestSemester(): SemesterInfo | null {
    if (this.semesterList.length === 0) {
      return null;
    }

    const today = new Date();
    let latestSemester: SemesterInfo | null = null;

    // 找到最近结束的学期，如果没有就用最后一个学期
    for (const semester of this.semesterList) {
      const endDate = new Date(semester.endDate);
      if (endDate <= today) {
        latestSemester = semester;
      }
    }

    return latestSemester || this.semesterList[this.semesterList.length - 1];
  }

  /**
   * 更新周日期信息
   */
  private updateWeekDates(startDate?: string): void {
    const semesterStartDate = startDate || this.currentSemester?.startDate || "2024-09-08";

    const weekRange = this.configService.calculateWeekDates(semesterStartDate, this.currentWeek);
    this.weekDates = {
      startDate: weekRange.startDate,
      endDate: weekRange.endDate
    };
    this.currentMonth = this.configService.getMonthString(this.weekDates.startDate);

    // 同步Swiper位置到当前周
    if (this.swiper && this.currentWeek > 0) {
      this.swiper.changeIndex(this.currentWeek - 1);
    }
  }

  /**
   * 导航到当前周 (应用启动时自动定位)
   */
  private navigateToCurrentWeek(): void {
    if (this.currentWeek > 0 && this.currentWeek <= this.totalWeeks) {
      console.info(`📍 [Navigation] 自动定位到第${this.currentWeek}周`);
      // 强制更新Swiper位置
      if (this.swiper) {
        this.swiper.changeIndex(this.currentWeek - 1);
      }
      // 确保状态同步
      this.updateWeekDates();
    }
  }

  /**
   * 切换学期 (支持上一个/下一个学期切换)
   */
  private switchSemester(direction: 'prev' | 'next'): void {
    if (!this.currentSemester) {
      return;
    }

    // 先创建当前学期的副本用于传参
    const currentSemesterCopy: SemesterInfo = {
      year: this.currentSemester.year,
      semester: this.currentSemester.semester,
      startDate: this.currentSemester.startDate,
      endDate: this.currentSemester.endDate,
      totalWeeks: this.currentSemester.totalWeeks
    };

    // 调用服务获取邻接学期
    const rawTargetSemester = this.configService.getAdjacentSemester(currentSemesterCopy, direction);
    if (rawTargetSemester) {
      // 手动复制学期对象
      const targetSemester: SemesterInfo = {
        year: rawTargetSemester.year,
        semester: rawTargetSemester.semester,
        startDate: rawTargetSemester.startDate,
        endDate: rawTargetSemester.endDate,
        totalWeeks: rawTargetSemester.totalWeeks
      };

      this.currentSemester = targetSemester;
      this.totalWeeks = targetSemester.totalWeeks;
      this.currentWeek = 1; // 切换学期后默认显示第1周

      // 重新计算状态文本
      const now = new Date();
      const startDate = new Date(targetSemester.startDate);
      const endDate = new Date(targetSemester.endDate);

      if (now >= startDate && now <= endDate) {
        // 切换到的学期是当前学期
        const realCurrentWeek = this.configService.calculateWeekInSemester(targetSemester.startDate, now);
        this.currentWeek = realCurrentWeek;
        this.displayStatusText = `第${realCurrentWeek}周`;
      } else {
        // 切换到的学期不是当前学期
        this.displayStatusText = `第${this.currentWeek}周`;
      }

      this.updateWeekDates(targetSemester.startDate);

      console.info(`📅 [Semester Switch] 切换到${targetSemester.year}年${targetSemester.semester === 1 ? '秋季' :
        '春季'}学期`);
    }
  }

  /**
   * 切换周数
   */
  private onWeekChange(weekNum: number): void {
    this.currentWeek = weekNum;

    // 如果不在假期中，更新显示状态
    if (!this.currentStatus?.isInHoliday) {
      this.displayStatusText = `第${weekNum}周`;
    }

    this.updateWeekDates();
    // 切换Swiper到对应页面
    this.swiper.changeIndex(weekNum - 1);
  }

  /**
   * 生成周数数组
   */
  private generateWeekNumbers(): number[] {
    const weeks: number[] = [];
    for (let i = 1; i <= this.totalWeeks; i++) {
      weeks.push(i);
    }
    return weeks;
  }

  build() {
    Stack() {
      Column() {
        // 顶部日期和周次tabbar
        Row() {
          // 月份显示
          Text(this.currentMonth)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#45CAD9')
            .margin({ right: 10 })

          // 周数可点击区域
          Row() {
            Text(this.displayStatusText || `第${this.currentWeek || 1}周`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentStatus?.isInHoliday ? '#FF9800' : '#333333') // 假期中用橙色
            Text('▼')
              .fontSize(12)
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
              .fontSize(12)
              .fontColor('#666666')
          }
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 15,
          bottom: 10
        })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })

        // Swiper容器用于滑动切换周
        Swiper(this.swiper) {
          // 生成多周的课表内容
          ForEach(this.generateWeekNumbers(), (weekNum: number) => {
            this.WeekScheduleContent(weekNum)
          })
        }
        .width('100%')
        .layoutWeight(1)
        .indicator(false)
        .loop(false)
        .onChange((index: number) => {
          this.currentWeek = index + 1;
          this.updateWeekDates();
        })
        .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
          this.currentWeek = index + 1;
          this.updateWeekDates();
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
        Text(`${this.currentSemester?.year || '2024'}年${this.currentSemester?.semester === 1 ? '秋季' : '春季'}学期`)
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
          ForEach(this.generateWeekNumbers(), (weekNum: number) => {
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
              this.onWeekChange(weekNum);
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
  WeekScheduleContent(weekNum: number) {
    Column() {
      // 星期表头
      Row() {
        // 左上角空白区域
        Column()
          .width(40)

        // 星期标题
        ForEach(this.weekDays, (day: string, dayIndex: number) => {
          Column() {
            Text(day)
              .fontSize(13)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1)
          .padding(6)
          .justifyContent(FlexAlign.Center)
        })
      }
      .width('100%')
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
              .height(60)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('#FAFAFA')
              .border({ width: { right: 1 }, color: '#E8E8E8' })

              // 七天的课程内容
              ForEach(this.weekDays, (day: string, dayIndex: number) => {
                Column() {
                  this.buildCourseCell(weekNum, dayIndex + 1, timeIndex)
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
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildCourseCell(weekNum: number, dayIndex: number, timeIndex: number) {
    if (this.allWeeksData[weekNum]?.[dayIndex]?.[timeIndex]) {
      Column() {
        Text(this.allWeeksData[weekNum][dayIndex][timeIndex]!.name)
          .fontSize(11)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ bottom: 2 })
        Text(this.allWeeksData[weekNum][dayIndex][timeIndex]!.location)
          .fontSize(9)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding(4)
      .backgroundColor(this.allWeeksData[weekNum][dayIndex][timeIndex]!.color)
      .borderRadius(6)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin(2)
      .onClick(() => {
        // 点击课程详情
      })
    } else {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
    }
  }
}

// 课程信息接口
interface CourseInfo {
  name: string;
  location: string;
  teacher: string;
  color: string;
}

@Component
struct MinePage {
  @State private userInfo: UserInfo = {
    avatar: '👤',
    username: '侠客同学',
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