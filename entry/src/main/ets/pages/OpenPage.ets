import { AppConfigManager } from '../services/AppConfigManager';
import { JwxtCredentialsManager } from '../services/jwxt/JwxtCredentialsManager';
import { CookieManager } from '../services/jwxt/CookieManager';
import { JwxtLoginService } from '../services/jwxt/JwxtLoginService';
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
  private cookieManager: CookieManager = CookieManager.getInstance();
  private jwxtLoginService: JwxtLoginService = JwxtLoginService.getInstance();

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
      hilog.info(DOMAIN, TAG, '🚀 [Init] 开始初始化应用配置');

      // 2. 尝试初始化配置（但不阻塞跳转）
      try {
        const startTime = Date.now();
        const initResult = await this.appConfigManager.initialize(context);
        const elapsedTime = Date.now() - startTime;

        hilog.info(DOMAIN, TAG, `✅ [Init] 配置初始化完成，耗时: ${elapsedTime}ms，使用缓存: ${initResult.usedCache}`);
      } catch (configError) {
        // 配置初始化失败不影响跳转，让后续页面自己处理
        hilog.warn(DOMAIN, TAG, `⚠️ [Init] 配置初始化失败，继续跳转: ${configError}`);
      }

      // 3. 检查凭证（无论配置是否成功）
      this.initMessage = '正在检查登录状态...';
      hilog.info(DOMAIN, TAG, '🔍 [Auth] 开始检查登录状态');

      // 检查是否有存储的账号和密码
      const hasCredentials = this.credentialsManager.hasCredentials(context);

      // 4. 根据凭证状态决定跳转
      if (!hasCredentials) {
        // 没有存储凭证，跳转到登录页
        hilog.info(DOMAIN, TAG, '❌ [Auth] 未找到存储的凭证，跳转到登录页');
        this.pathStack.replacePathByName('LoginNavPage', { from: 'OpenPage' });
        return;
      }

      // 5. 有凭证，检查 EntryAbility 的 autoLoginJwxt 状态
      hilog.info(DOMAIN, TAG, '✅ [Auth] 找到存储的凭证，检查 autoLoginJwxt 状态');
      this.initMessage = '正在验证登录...';

      // 等待 autoLoginJwxt 完成（最多等待 15 秒）
      const autoLoginStatus = await this.waitForAutoLogin(15000);

      if (autoLoginStatus === 'success') {
        // autoLoginJwxt 已成功，直接跳转到主页
        hilog.info(DOMAIN, TAG, '🎉 [Auth] autoLoginJwxt 已成功，直接跳转到主页');
        this.pathStack.replacePathByName('MainTabNavPage', null);
      } else if (autoLoginStatus === 'failed') {
        // autoLoginJwxt 失败，尝试重新登录
        hilog.info(DOMAIN, TAG, '⚠️ [Auth] autoLoginJwxt 失败，尝试重新登录');
        await this.performLogin(context);
      } else {
        // 超时或未知状态，检查 Cookie 后决定
        hilog.info(DOMAIN, TAG, '⏱️ [Auth] autoLoginJwxt 状态未知，检查 Cookie');
        await this.checkCookieAndLogin(context);
      }

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Init] 页面初始化失败: ${errorMsg}`);
      this.initMessage = '初始化失败，请重试';

      // 即使初始化失败也跳转到登录页，让用户重新登录
      setTimeout(() => {
        this.pathStack.replacePathByName('LoginNavPage', { from: 'OpenPage' });
      }, 2000);
    }
  }

  /**
   * 等待 autoLoginJwxt 完成
   * @param timeout 最大等待时间（毫秒）
   * @returns 登录状态：'success' | 'failed' | 'timeout'
   */
  private async waitForAutoLogin(timeout: number): Promise<string> {
    const startTime = Date.now();
    const checkInterval = 100; // 每 100ms 检查一次

    while (Date.now() - startTime < timeout) {
      const status = AppStorage.get<string>('jwxt_auto_login_status');

      if (status === 'success') {
        hilog.info(DOMAIN, TAG, `✅ [Wait] autoLoginJwxt 成功（耗时 ${Date.now() - startTime}ms）`);
        return 'success';
      } else if (status === 'failed') {
        hilog.info(DOMAIN, TAG, `❌ [Wait] autoLoginJwxt 失败（耗时 ${Date.now() - startTime}ms）`);
        return 'failed';
      }

      // 等待一段时间后再检查
      await new Promise<void>(resolve => setTimeout(resolve, checkInterval));
    }

    hilog.warn(DOMAIN, TAG, `⏱️ [Wait] 等待 autoLoginJwxt 超时（${timeout}ms）`);
    return 'timeout';
  }

  /**
   * 检查 Cookie 并决定是否登录
   */
  private async checkCookieAndLogin(context: Context): Promise<void> {
    // 检查教务系统的 Cookie 是否已存在
    const jwxtHost = 'jwxtwx.fjut.edu.cn';
    const existingCookie = await this.cookieManager.getCookie(jwxtHost);

    if (existingCookie) {
      // Cookie 已存在，直接跳转到主页
      hilog.info(DOMAIN, TAG, '🎉 [Auth] Cookie 已存在，直接跳转到主页');
      this.pathStack.replacePathByName('MainTabNavPage', null);
    } else {
      // Cookie 不存在，执行登录
      hilog.info(DOMAIN, TAG, '⏳ [Auth] Cookie 不存在，执行登录流程');
      await this.performLogin(context);
    }
  }

  /**
   * 执行登录流程
   */
  private async performLogin(context: Context): Promise<void> {
    this.initMessage = '正在登录教务系统...';

    try {
      // 执行登录
      await this.jwxtLoginService.login(context);
      hilog.info(DOMAIN, TAG, '✅ [Login] 登录成功，跳转到主页');
      this.pathStack.replacePathByName('MainTabNavPage', null);
    } catch (loginError) {
      // 登录失败，跳转到登录页让用户手动重新登录
      const errorMsg = loginError instanceof Error ? loginError.message : String(loginError);
      hilog.error(DOMAIN, TAG, `❌ [Login] 自动登录失败: ${errorMsg}`);

      this.initMessage = '自动登录失败，请重新登录';
      setTimeout(() => {
        this.pathStack.replacePathByName('LoginNavPage', {
          from: 'OpenPage',
          reason: 'auto_login_failed'
        });
      }, 1500);
    }
  }
}