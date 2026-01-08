import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtCredentialsManager } from '../services/jwxt/JwxtCredentialsManager';


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
   * 等待初始化完成后跳转到主页面
   */
  private async waitForInitAndNavigate(): Promise<void> {
    try {
      // 获取应用上下文
      const context = getContext(this);

      // 1. 更新加载状态
      this.initMessage = '正在初始化配置...';
      console.info('[OpenPage] 开始初始化应用配置');

      // 2. 尝试初始化配置（但不阻塞跳转）
      try {
        const startTime = Date.now();
        const initResult = await this.appConfigManager.initialize(context);
        const elapsedTime = Date.now() - startTime;

        console.info(`[OpenPage] 配置初始化完成，耗时: ${elapsedTime}ms，使用缓存: ${initResult.usedCache}`);
      } catch (configError) {
        // 配置初始化失败不影响跳转，让后续页面自己处理
        console.warn('[OpenPage] 配置初始化失败，继续跳转:', configError);
      }

      // 3. 检查凭证（无论配置是否成功）
      this.initMessage = '正在检查登录状态...';

      // 检查是否有存储的账号和密码
      const hasCredentials = this.credentialsManager.hasCredentials(context);

      // 4. 根据凭证状态跳转页面
      if (!hasCredentials) {
        // 没有存储凭证，跳转到登录页
        console.info('[OpenPage] 未找到存储的账号密码，跳转到登录页');
        this.pathStack.replacePathByName('LoginNavPage', { from: 'OpenPage' });
      } else {
        // 已有凭证，直接跳转到主页Tab页面
        console.info('[OpenPage] 已找到存储的账号密码，跳转到主页');
        this.pathStack.replacePathByName('MainTabNavPage', null);
      }

    } catch (error) {
      console.error('[OpenPage] 页面初始化失败:', error);
      this.initMessage = '初始化失败，请重试';
      // 即使初始化失败也跳转到登录页，让用户重新登录
      setTimeout(() => {
        this.pathStack.replacePathByName('LoginNavPage', null);
      }, 2000);
    }
  }
}