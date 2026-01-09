import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtCredentialsManager } from '../services/jwxt/JwxtCredentialsManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GlobalContext } from '../common/utils/GlobalContext';
import { JwxtLoginService } from '../services/jwxt/JwxtLoginService';
import { JwxtHttpClient } from '../services/jwxt/JwxtHttpClient';
import { JwxtGetInfoService } from '../services/jwxt/JwxtGetInfoService';

const DOMAIN: number = 0x0001;
const TAG: string = 'OpenPage';

@Entry
@Component
struct OpenPage {
  @Provide('NavStack') pathStack: NavPathStack = new NavPathStack();
  @State message: string = '欢迎使用霞客课表';
  @State initMessage: string = '正在加载...';
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private credentialsManager: JwxtCredentialsManager = JwxtCredentialsManager.getInstance();
  private jwxtLoginService: JwxtLoginService = JwxtLoginService.getInstance();
  private jwxtHttpClient: JwxtHttpClient = JwxtHttpClient.getInstance();
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  private context = this.getUIContext().getHostContext();

  aboutToAppear(): void {
    GlobalContext.getInstance().setObject('UIContext', this.getUIContext());
    this.waitForInitAndNavigate();
    this.autoLoginJwxt();
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
   * 自动登录教务系统并获取学生信息
   * 应用启动时自动执行，将Cookie保存到内存，获取学生信息到首选项和AppStorage
   */
  private async autoLoginJwxt(): Promise<void> {
    try {
      // 设置登录状态为进行中
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'loading');
      hilog.info(DOMAIN, 'testTag', '🔐 [EntryAbility] 开始自动登录教务系统...');

      // 初始化HTTP客户端的Cookie管理
      await this.jwxtHttpClient.initialize(this.context);

      // 执行登录
      await this.jwxtLoginService.login(this.context);

      // 设置登录状态为成功
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'success');
      hilog.info(DOMAIN, 'testTag', '✅ [EntryAbility] 教务系统自动登录成功，Cookie已保存到内存');

      // ✅ 登录成功后，获取学生信息并保存
      try {
        hilog.info(DOMAIN, 'testTag', '📝 [EntryAbility] 开始获取学生信息...');
        const studentInfo = await this.jwxtGetInfoService.getInfo(this.context);
        hilog.info(DOMAIN, 'testTag',
          `✅ [EntryAbility] 学生信息获取成功: ${studentInfo.name} (${studentInfo.student_id})`);
      } catch (infoError) {
        // 获取学生信息失败不影响应用启动
        const errorMsg = infoError instanceof Error ? infoError.message : String(infoError);
        hilog.error(DOMAIN, 'testTag', `⚠️ [EntryAbility] 获取学生信息失败: ${errorMsg}`);
      }

    } catch (error) {
      // 设置登录状态为失败
      AppStorage.setOrCreate<string>('jwxt_auto_login_status', 'failed');
      hilog.error(DOMAIN, 'testTag', '❌ [EntryAbility] 教务系统自动登录失败: %{public}s',
        error instanceof Error ? error.message : JSON.stringify(error));
      // 不阻塞应用启动，仅记录错误
    }
  }

  /**
   * 等待配置初始化完成后跳转
   *
   * 优化逻辑：
   * 1. 检查是否有凭证
   * 2. 尝试使用缓存快速初始化（不等待API）
   * 3. 如果有缓存，直接跳转主页（后台自动更新配置）
   * 4. 如果无缓存，等待API加载完成再跳转
   * 5. 如果失败，跳转登录页
   */
  private async waitForInitAndNavigate(): Promise<void> {
    try {

      // 1. 检查凭证
      this.initMessage = '正在检查登录凭证...';
      hilog.info(DOMAIN, TAG, '🔍 [Init] 开始检查登录凭证');

      const hasCredentials = this.credentialsManager.hasCredentials(this.context);

      if (!hasCredentials) {
        // 无凭证 → 登录页
        hilog.info(DOMAIN, TAG, '❌ [Auth] 未找到存储的凭证，跳转到登录页');
        this.pathStack.replacePathByName('LoginNavPage', { from: 'OpenPage' });
        return;
      }

      hilog.info(DOMAIN, TAG, '✅ [Auth] 找到存储的凭证');

      // 2. 尝试使用缓存快速初始化
      this.initMessage = '正在加载配置...';
      hilog.info(DOMAIN, TAG, '🚀 [Init] 尝试快速初始化（缓存优先）');

      const startTime = Date.now();
      const fastInitSuccess = await this.appConfigManager.tryInitializeFromCache(this.context);
      const fastInitTime = Date.now() - startTime;

      if (fastInitSuccess) {
        // 3. 缓存初始化成功 → 立即跳转主页（后台自动更新配置）
        hilog.info(DOMAIN, TAG, `⚡ [Init] 快速初始化成功，耗时: ${fastInitTime}ms，立即跳转主页`);
        hilog.info(DOMAIN, TAG, '🎉 [Navigate] 凭证和配置均就绪，跳转到主页（后台更新中）');
        this.pathStack.replacePathByName('MainTabNavPage', null);
        return;
      }

      // 4. 无缓存，等待完整初始化
      hilog.info(DOMAIN, TAG, '⏳ [Init] 无缓存，开始完整初始化（等待API）');
      this.initMessage = '首次加载，正在获取配置...';

      try {
        const fullInitStart = Date.now();
        const initResult = await this.appConfigManager.initialize(this.context);
        const fullInitTime = Date.now() - fullInitStart;

        hilog.info(DOMAIN, TAG, `✅ [Init] 完整初始化成功，耗时: ${fullInitTime}ms，使用缓存: ${initResult.usedCache}`);

        // 5. 完整初始化成功 → 跳转主页
        hilog.info(DOMAIN, TAG, '🎉 [Navigate] 凭证和配置均就绪，跳转到主页');
        this.pathStack.replacePathByName('MainTabNavPage', null);

      } catch (configError) {
        // 配置加载失败 → 登录页
        const errorMsg = configError instanceof Error ? configError.message : String(configError);
        hilog.error(DOMAIN, TAG, `❌ [Init] 完整初始化失败: ${errorMsg}`);

        this.initMessage = '配置加载失败，请重新登录';
        setTimeout(() => {
          this.pathStack.replacePathByName('LoginNavPage', {
            from: 'OpenPage',
            reason: 'config_failed'
          });
        }, 1500);
      }

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Init] 页面初始化失败: ${errorMsg}`);
      this.initMessage = '初始化失败，请重试';

      // 即使初始化失败也跳转到登录页
      setTimeout(() => {
        this.pathStack.replacePathByName('LoginNavPage', { from: 'OpenPage' });
      }, 2000);
    }
  }
}