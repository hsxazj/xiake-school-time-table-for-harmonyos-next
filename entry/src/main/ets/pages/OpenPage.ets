import { AppConfigManager } from '../services/AppConfigManager';
import { UserInfoManager } from '../common/utils/UserInfoManager';
import { CacheManager } from '../common/utils/CacheManager';
import { CourseApiService } from '../services/api/CourseApiService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0003;
const TAG: string = 'OpenPage';


@Entry
@Component
struct OpenPage {
  @Provide('NavStack') pathStack: NavPathStack = new NavPathStack();
  @State message: string = '欢迎使用霞客课表';
  @State initMessage: string = '正在加载...';
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  aboutToAppear(): void {
    this.waitForInitAndNavigate();
  }

  build() {
    Navigation(this.pathStack) {
      RelativeContainer() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(80)
            .height(80)
            .margin({ bottom: 20 })

          Text(this.message)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#179FA2')
            .textAlign(TextAlign.Center)

          Text(this.initMessage)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 20 })
            .textAlign(TextAlign.Center)

          LoadingProgress()
            .width(30)
            .height(30)
            .color($r('app.color.schedule_primary_color'))
            .margin({ top: 20 })
        }
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
      }
      .height('100%')
      .width('100%')
      .backgroundColor('#F8F8F8')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
  }

  /**
   * 等待初始化完成后跳转到主页面
   */
  private async waitForInitAndNavigate(): Promise<void> {
    try {
      // 等待AppConfigManager初始化完成
      const initResult = await this.appConfigManager.initialize();

      // 检查是否使用了缓存
      if (initResult.usedCache) {
        this.initMessage = '服务器可能异常，使用本地数据';

        // 显示 toast 提示
        this.getUIContext().getPromptAction().showToast({
          message: '数据可能延时显示',
          duration: 3000,
          bottom: '150vp'
        });
      } else {
        this.initMessage = '加载完成！';
      }

      // 检查是否已设置完整的学籍信息
      const hasCompleteInfo = this.userInfoManager.hasCompleteUserInfo(this.getUIContext().getHostContext());

      // 启动静默预加载课表 (当周±1周)
      if (hasCompleteInfo) {
        this.preloadScheduleCache();
      }

      // 短暂延迟后跳转
      setTimeout(() => {
        if (hasCompleteInfo) {
          // 已有完整信息，直接跳转到主页Tab页面
          this.pathStack.replacePathByName('MainTabNavPage', null);
        } else {
          // 没有完整信息，跳转到学院选择页面
          this.pathStack.replacePathByName('ClassSelectNavPage', null);
        }
      }, 500);

    } catch (error) {
      console.error('Index页面初始化失败:', error);
      this.initMessage = '初始化失败，请重试';
      // 即使初始化失败也跳转，让用户能正常使用
      setTimeout(() => {
        this.pathStack.replacePathByName('ClassSelectNavPage', null);
      }, 2000);
    }
  }

  /**
   * 静默预加载课表缓存 (当周±1周)
   */
  private preloadScheduleCache(): void {
    try {
      const currentStatus = this.appConfigManager.getCurrentStatus();
      if (!currentStatus || !currentStatus.currentSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ 无法获取当前学期信息,跳过预加载');
        return;
      }

      const context = this.getUIContext().getHostContext();
      const userInfo = this.userInfoManager.getUserInfo(context);
      if (!userInfo || !userInfo.classId) {
        hilog.warn(DOMAIN, TAG, '⚠️ 无法获取用户班级信息,跳过预加载');
        return;
      }

      const year = currentStatus.currentSemester.academicYear;
      const term = currentStatus.currentSemester.semester === 1 ? '3' : '12';
      const currentWeek = currentStatus.currentWeek;
      const classId = userInfo.classId;

      hilog.info(DOMAIN, TAG, `🚀 开始预加载: ${year}学年 学期${term} 第${currentWeek}周 ±1周`);

      // 静默预加载 (不阻塞UI,不await)
      CacheManager.preloadSchedules(year, term, currentWeek, async (y: string, t: string, w: number) => {
        const courseApiService = CourseApiService.getInstance();
        const params = courseApiService.buildCourseParams(y, parseInt(t) === 3 ? 1 : 2, w, classId);
        const response = await courseApiService.getCourseList(params);
        return response.data;
      }).catch((err: Error) => {
        hilog.warn(DOMAIN, TAG, `⚠️ 预加载失败: ${err.message}`);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 预加载异常: ${JSON.stringify(error)}`);
      // 静默处理,不影响主流程
    }
  }
}