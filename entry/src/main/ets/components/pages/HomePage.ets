
import { CourseInfo } from '../../models/CourseModels';
import { CourseColorUtil } from '../../common/utils/CourseColorUtil';
import { CourseTimeUtil } from '../../common/utils/CourseTimeUtil';
import { TodayCourseUtil, TodayParams } from '../../common/utils/TodayCourseUtil';
import { curves } from '@kit.ArkUI';
import { AppConfigManager } from '../../services/AppConfigManager';
import { FormService } from '../../services/FormService';
import { JwxtGetInfoService } from '../../services/jwxt/JwxtGetInfoService';
import { StudentInfoManager } from '../../services/StudentInfoManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
  private studentInfoManager: StudentInfoManager = StudentInfoManager.getInstance();
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  // 今日课程参数缓存
  private todayParams: TodayParams | null = null;
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

      // 使用 TodayCourseUtil 加载今日课程
      const todayCourses = await TodayCourseUtil.loadTodayCourses();

      // 更新状态
      this.todayCourses = todayCourses;

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
    // 使用 TodayCourseUtil 获取今日参数
    this.todayParams = TodayCourseUtil.getTodayParams();

    if (this.todayParams) {
      console.info(`✅ [Today Params Cache] 基于真实今日计算参数: ${JSON.stringify(this.todayParams)}`);
    } else {
      console.warn('⚠️ [Today Params Cache] 无法获取今日参数');
    }
  }

  private loadUserInfo(): void {
    // TODO 获取
  }

  /**
   * 加载学生姓名
   * 优先从 StudentInfoManager 获取,如果没有则调用 API 获取并保存
   */
  private async loadStudentName(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [HomePage] 开始加载学生姓名...');
      const context = getContext(this);

      // 1. 先尝试从内存获取
      let studentInfo = this.studentInfoManager.getStudentInfoFromMemory();

      // 2. 如果内存中没有,尝试从首选项加载到内存
      if (!studentInfo) {
        hilog.info(DOMAIN, TAG, '💾 [HomePage] 内存中无学生信息,尝试从首选项加载...');
        const loaded = await this.studentInfoManager.loadStudentInfoToMemory(context);
        if (loaded) {
          studentInfo = this.studentInfoManager.getStudentInfoFromMemory();
        }
      }

      // 3. 如果首选项中也没有,调用 API 获取并保存
      if (!studentInfo) {
        hilog.info(DOMAIN, TAG, '🌐 [HomePage] 首选项中无学生信息,调用 API 获取...');
        studentInfo = await this.jwxtGetInfoService.getInfo(context);
        // 保存到 StudentInfoManager
        this.studentInfoManager.saveStudentInfo(context, studentInfo);
      }

      // 4. 更新 UI
      this.studentName = studentInfo.name;
      hilog.info(DOMAIN, TAG, '✅ [HomePage] 学生姓名加载成功: %{public}s', this.studentName);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [HomePage] 加载学生姓名失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      // 保持默认值"同学"
    }
  }
}