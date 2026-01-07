import { UserInfoManager, UserSchoolInfo } from '../../common/utils/UserInfoManager';
import { CourseInfo } from '../../models/CourseModels';
import { CourseColorUtil } from '../../common/utils/CourseColorUtil';
import { CourseTimeUtil } from '../../common/utils/CourseTimeUtil';
import { curves } from '@kit.ArkUI';
import { CourseApiService } from '../../services/api/CourseApiService';
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
  @State private userInfo: UserSchoolInfo | null = null;
  @State private todayCourses: CourseInfo[] = [];
  @State private isLoading: boolean = false;
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private courseApiService: CourseApiService = CourseApiService.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private formService: FormService = FormService.getInstance();
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
                .fontColor($r('app.color.schedule_primary_color'))
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
                .fontColor($r('app.color.schedule_primary_color'))
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
        .onClick(async () => {
          // 临时改为测试获取个人信息（应用启动时已自动登录）
          try {
            console.info('🔍 [HomePage] 开始测试获取个人信息...');

            // 直接获取个人信息（使用应用启动时保存的Cookie）
            hilog.info(DOMAIN, TAG, '📝 [HomePage] 开始获取个人信息...');
            const studentInfo = await this.jwxtGetInfoService.getInfo();
            hilog.info(DOMAIN, TAG, '✅ [HomePage] 个人信息获取成功');

            // 打印完整信息
            hilog.info(DOMAIN, TAG, '📋 ========== 学生个人信息 ==========');
            hilog.info(DOMAIN, TAG, '📋 姓名: %{public}s', studentInfo.name);
            hilog.info(DOMAIN, TAG, '📋 学号: %{public}s', studentInfo.student_id);
            hilog.info(DOMAIN, TAG, '📋 班级: %{public}s', studentInfo.class_name);
            hilog.info(DOMAIN, TAG, '📋 学院: %{public}s', studentInfo.college);
            hilog.info(DOMAIN, TAG, '📋 专业: %{public}s', studentInfo.major);
            hilog.info(DOMAIN, TAG, '📋 年级: %{public}s', studentInfo.grade);
            hilog.info(DOMAIN, TAG, '📋 性别: %{public}s', studentInfo.gender);
            hilog.info(DOMAIN, TAG, '📋 生日: %{public}s', studentInfo.birthday);
            hilog.info(DOMAIN, TAG, '📋 入学日期: %{public}s', studentInfo.enrollment_date);
            hilog.info(DOMAIN, TAG, '📋 手机: %{public}s', studentInfo.phone);
            hilog.info(DOMAIN, TAG, '📋 邮箱: %{public}s', studentInfo.email);
            hilog.info(DOMAIN, TAG, '📋 QQ: %{public}s', studentInfo.qq);
            hilog.info(DOMAIN, TAG, '📋 =====================================');

          } catch (error) {
            hilog.error(DOMAIN, TAG, '❌ [HomePage] 获取个人信息失败:', JSON.stringify(error));
            hilog.error(DOMAIN, TAG, '❌ [HomePage] 错误详情:', error instanceof Error ? error.message : String(error));
          }

          // 原来的跳转逻辑注释掉
          // this.pathStack.pushPathByName('ClassSelectNavPage', null);
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

      // 获取用户信息
      const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
      if (!userInfo || !userInfo.classId) {
        console.warn('未找到用户班级信息');
        return;
      }

      // 如果还没有缓存今日课程参数，则初始化
      if (!this.todayParams) {
        this.initTodayParams();
      }

      if (!this.todayParams) {
        console.warn('无法获取今日课程参数');
        return;
      }

      console.info(`🔍 [Today Course] 使用缓存参数: year=${this.todayParams.year}, week=${this.todayParams.week}, weekDay=${this.todayParams.weekDay}, term=${this.todayParams.termCode}`);

      const response = await this.courseApiService.getTodayCourseList(
        userInfo.classId,
        this.todayParams.year,
        this.todayParams.termCode,
        this.todayParams.week,
        this.todayParams.weekDay
      );

      // const response = await this.courseApiService.getTodayCourseList(
      //   userInfo.classId,
      //   2025,
      //   '3',
      //   3,
      //   '星期一'
      // );


      if (response.code === 200 && response.data) {
        this.todayCourses = response.data;
        // 更新课程颜色列表
        this.courseColorsList = CourseColorUtil.extractCourseNamesList(response.data);

        // 同时更新所有活跃卡片的数据
        console.info(`📱 [HomePage] 同步更新卡片数据，课程数量: ${response.data.length}`);
        this.formService.updateAllActiveWidgetsWithData(this.getUIContext().getHostContext(), response.data);
      } else {
        console.warn('获取今日课程失败');
      }

    } catch (error) {
      console.error('加载今日课程失败:', error);
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
    this.userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
  }
}