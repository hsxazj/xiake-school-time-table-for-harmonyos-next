import { UserInfoManager, UserSchoolInfo } from '../../common/utils/UserInfoManager';
import { CourseInfo } from '../../models/CourseModels';
import { MOCK_TODAY_COURSES } from '../../common/constants/AppConstants';
import { curves } from '@kit.ArkUI';
import { CourseApiService } from '../../services/api/CourseApiService';
import { AppConfigManager } from '../../services/AppConfigManager';

interface TodayParm{
  year: number;
  week: number;
  termCode: string;
  weekDay: string;
}

@Component
export struct HomePage {
  @Consume('NavStack') pathStack: NavPathStack;
  // pathStack: NavPathStack = new NavPathStack();
  @State private userInfo: UserSchoolInfo | null = null;
  @State private todayCourses: CourseInfo[] = [];
  @State private isLoading: boolean = false;
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private courseApiService: CourseApiService = CourseApiService.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  // 今日课程参数缓存
  private todayParams: TodayParm | null = null;
  // 动画支持 - 与周课程页保持一致
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 150 });

  aboutToAppear(): void {
    this.loadUserInfo();
    this.loadTodayCourses();
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(`你好，同学`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 20 }) // 从4增加到8

          // 显示学院+班级信息
          if (this.userInfo) {
            Row() {
              Text(`${this.userInfo.collegeName} ${this.userInfo.className}`)
                .fontSize(16)
                .fontColor('#666666')

              Text('切换')
                .fontSize(16)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
          } else {
            Row() {
              Text('学院信息加载中...')
                .fontSize(14)
                .fontColor('#666666')

              Text('切换')
                .fontSize(12)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
          top: 8,
          bottom: 8,
          left: 4,
          right: 4
        })
        .borderRadius(8)
        .onClick(() => {
          this.pathStack.pushPathByName('ClassSelectNavPage', null);
        })

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
            Text('暂无今日课程')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 50, bottom: 50 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F0F2F5') // 今日课程区域使用稍深的灰蓝色
      .borderRadius(24)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetY: 2
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
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.teacher || '')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(this.getTimeRange(courseInfo.courseTime))
        .fontSize(14)
        .fontColor('#24C2C6')
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.classroom || '')
        .fontSize(14)
        .fontColor('#666666')
        .alignSelf(ItemAlign.Start)

    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(24)
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

  private getTimeRange(courseTime?: string[]): string {
    if (!courseTime || courseTime.length === 0) {
      return '';
    }

    const firstTime = courseTime[0];
    const lastTime = courseTime[courseTime.length - 1];

    const startTime = firstTime.split('-')[0];
    const endTime = lastTime.split('-')[1];

    return `${startTime}-${endTime}`;
  }

  private async loadTodayCourses(): Promise<void> {
    this.isLoading = true;

    try {
      // 等待配置管理器初始化
      await this.appConfigManager.initialize();
      
      // 获取用户信息
      const userInfo = this.userInfoManager.getUserInfo(getContext(this));
      if (!userInfo || !userInfo.classId) {
        console.warn('未找到用户班级信息');
        this.todayCourses = MOCK_TODAY_COURSES; // 使用模拟数据作为备用
        return;
      }

      // 如果还没有缓存今日课程参数，则初始化
      if (!this.todayParams) {
        this.initTodayParams();
      }

      if (!this.todayParams) {
        console.warn('无法获取今日课程参数，使用模拟数据');
        this.todayCourses = MOCK_TODAY_COURSES;
        return;
      }

      console.info(`🔍 [Today Course] 使用缓存参数: year=${this.todayParams.year}, week=${this.todayParams.week}, weekDay=${this.todayParams.weekDay}, term=${this.todayParams.termCode}`);

      // 调用今日课程接口
      const response = await this.courseApiService.getTodayCourseList(
        userInfo.classId,
        this.todayParams.year,
        this.todayParams.termCode,
        this.todayParams.week,
        this.todayParams.weekDay
      );


      if (response.code === 200 && response.data) {
        this.todayCourses = response.data;
      } else {
        console.warn('获取今日课程失败，使用模拟数据');
        this.todayCourses = MOCK_TODAY_COURSES;
      }

    } catch (error) {
      console.error('加载今日课程失败:', error);
      this.todayCourses = MOCK_TODAY_COURSES; // 降级到模拟数据
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 初始化今日课程参数缓存
   */
  private initTodayParams(): void {
    // 获取已经计算好的当前学期状态
    const currentStatus = this.appConfigManager.getCurrentStatus();
    if (!currentStatus || !currentStatus.currentSemester) {
      console.warn('未找到当前学期信息');
      return;
    }

    // 获取今天是星期几
    const today = new Date();
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    const weekDayStr = weekdays[today.getDay()];

    // 缓存今日课程参数
    this.todayParams = {
      year: parseInt(currentStatus.currentSemester.academicYear),
      week: currentStatus.currentWeek,
      termCode: currentStatus.currentSemester.semester === 1 ? '3' : '12',
      weekDay: weekDayStr
    };

    console.info(`✅ [Today Params Cache] 已缓存参数: ${JSON.stringify(this.todayParams)}`);
  }

  private loadUserInfo(): void {
    this.userInfo = this.userInfoManager.getUserInfo(getContext(this));
  }
}