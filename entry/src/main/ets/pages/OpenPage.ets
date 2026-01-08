import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtCredentialsManager } from '../services/jwxt/JwxtCredentialsManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
      // 获取应用上下文
      const context = getContext(this);

      // 1. 检查凭证
      this.initMessage = '正在检查登录凭证...';
      hilog.info(DOMAIN, TAG, '🔍 [Init] 开始检查登录凭证');

      const hasCredentials = this.credentialsManager.hasCredentials(context);

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
      const fastInitSuccess = await this.appConfigManager.tryInitializeFromCache(context);
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
        const initResult = await this.appConfigManager.initialize(context);
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