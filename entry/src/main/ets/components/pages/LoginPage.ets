import { LoginApiService } from '../../services/api/LoginApiService';
import { LoginForm, LoginStatus } from '../../models/LoginModels';
import { UserInfoManager } from '../../common/utils/UserInfoManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const DOMAIN = 0x3000; // Login Page domain

@Builder
export function LoginNavPageBuilder() {
  LoginNavPage();
}

@Component
struct LoginNavPage {
  @Consume('NavStack') pathStack: NavPathStack;

  build() {
    NavDestination() {
      LoginPageContent()
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
  }
}

/**
 * 登录页面组件
 * 提供账号密码登录功能
 */
@Component
@Preview
export struct LoginPageContent {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private loginForm: LoginForm = {
    username: '',
    password: ''
  };
  @State private loginStatus: LoginStatus = LoginStatus.IDLE;
  @State private errorMessage: string = '';
  @State private showPassword: boolean = false;
  @State private pageOpacity: number = 0; // 页面初始透明度为0
  @State private pageTranslateY: number = 30; // 页面初始向下偏移30px
  private promptAction = this.getUIContext().getPromptAction();
  private loginService: LoginApiService = LoginApiService.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  aboutToAppear(): void {
    // 启动渐显动画
    this.startFadeInAnimation();
  }

  build() {
    Column() {
      // 顶部Logo和标题区域
      this.buildHeader()

      // 登录表单区域
      this.buildLoginForm()

      // 登录按钮
      this.buildLoginButton()

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    .padding({ left: 24, right: 24, top: 40 })
    .opacity(this.pageOpacity)
    .translate({ x: 0, y: this.pageTranslateY })
    .animation({
      duration: 700,
      curve: Curve.EaseInOut, // 使用EaseInOut创造流畅的渐显效果
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  @Builder
  buildHeader() {
    Column() {
      // Logo图标
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .borderRadius(16)
        .margin({ bottom: 20 })

      // 应用名称
      Text('霞客课表')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .margin({ bottom: 8 })

      // 副标题
      Text('请登录您的账号')
        .fontSize(16)
        .fontColor('#6B7280')
        .margin({ bottom: 40 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildLoginForm() {
    Column({ space: 20 }) {
      // 用户名输入框
      Column({ space: 8 }) {
        Text('学号')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#374151')
          .alignSelf(ItemAlign.Start)

        TextInput({
          placeholder: '请输入学号',
          text: $$this.loginForm.username
        })
          .height(48)
          .borderRadius(8)
          .backgroundColor(Color.White)
          .borderColor(this.loginForm.username ? $r('app.color.schedule_primary_color') : '#E5E7EB')
          .borderWidth(1)
          .placeholderColor('#9CA3AF')
          .fontSize(16)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.loginForm.username = value;
            this.clearError();
          })
      }

      // 密码输入框
      Column({ space: 8 }) {
        Text('密码')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#374151')
          .alignSelf(ItemAlign.Start)

        Row() {
          TextInput({
            placeholder: '请输入密码',
            text: $$this.loginForm.password
          })
            .layoutWeight(1)
            .height(48)
            .borderRadius(8)
            .backgroundColor(Color.White)
            .borderColor(this.loginForm.password ? $r('app.color.schedule_primary_color') : '#E5E7EB')
            .borderWidth(1)
            .placeholderColor('#9CA3AF')
            .fontSize(16)
            .padding({ left: 12, right: 40 })
            .type(this.showPassword ? InputType.Normal : InputType.Password)
            .onChange((value: string) => {
              this.loginForm.password = value;
              this.clearError();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .margin({ bottom: 32 })
  }

  @Builder
  buildLoginButton() {
    Button() {
      if (this.loginStatus === LoginStatus.LOADING) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(Color.White)
          Text('登录中...')
            .fontSize(16)
            .fontColor(Color.White)
        }
      } else {
        Text('登录')
          .fontSize(16)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(48)
    .borderRadius(8)
    .backgroundColor(this.isFormValid() && this.loginStatus !== LoginStatus.LOADING ? $r('app.color.schedule_primary_color') : '#9CA3AF')
    .enabled(this.isFormValid() && this.loginStatus !== LoginStatus.LOADING)
    .onClick(() => {
      this.handleLogin();
    })
  }

  /**
   * 启动渐显动画
   */
  private startFadeInAnimation(): void {
    // 短暂延时后启动动画，让组件先完成初始化
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslateY = 0;
      console.info('[LoginPage] 🎬 启动渐显动画');
    }, 100);
  }

  /**
   * 处理登录逻辑
   */
  private async handleLogin(): Promise<void> {
    if (!this.isFormValid()) {
      return;
    }

    try {
      this.loginStatus = LoginStatus.LOADING;
      this.clearError();

      hilog.info(DOMAIN, 'LoginPage', `🔐 [Login] 开始登录: ${this.loginForm.username}`);

      // 获取UIAbilityContext
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

      // 调用登录API，传递context用于token持久化
      await this.loginService.login(this.loginForm, context);

      this.loginStatus = LoginStatus.SUCCESS;
      hilog.info(DOMAIN, 'LoginPage', '✅ [Login] 登录成功');

      // 登录成功后自动获取用户信息
      try {
        hilog.info(DOMAIN, 'LoginPage', '🔄 [Login] 开始获取用户信息...');
        await this.userInfoManager.checkLoginStatus(context);
        hilog.info(DOMAIN, 'LoginPage', '✅ [Login] 用户信息获取成功');
      } catch (error) {
        hilog.error(DOMAIN, 'LoginPage', `⚠️ [Login] 获取用户信息失败: ${JSON.stringify(error)}`);
        // 用户信息获取失败不影响登录流程
      }

      // 登录成功的提示
      this.showSuccessMessage();

    } catch (error) {
      this.loginStatus = LoginStatus.FAILED;

      if (error instanceof Error) {
        this.errorMessage = error.message;
        hilog.error(DOMAIN, 'LoginPage', `❌ [Login] 登录失败: ${error.message}`);
      } else {
        this.errorMessage = '登录失败，请重试';
        hilog.error(DOMAIN, 'LoginPage', '❌ [Login] 登录失败: 未知错误');
      }
    }
  }

  /**
   * 表单验证
   */
  private isFormValid(): boolean {
    return !!(
      this.loginForm.username.trim().length > 0 &&
        this.loginForm.password.trim().length > 0
    );
  }

  /**
   * 清除错误信息
   */
  private clearError(): void {
    if (this.errorMessage) {
      this.errorMessage = '';
    }
    if (this.loginStatus === LoginStatus.FAILED) {
      this.loginStatus = LoginStatus.IDLE;
    }
  }

  /**
   * 显示成功提示
   */
  private showSuccessMessage(): void {
    // 显示成功提示
    this.promptAction.showToast({
      message: '登录成功！',
      duration: 2000,
      bottom: 100
    });

    // 启动渐隐动画
    this.startFadeOutAnimation();

    hilog.info(DOMAIN, 'LoginPage', '🎉 [Success] 登录成功提示已显示');
  }

  /**
   * 启动渐隐动画
   */
  private startFadeOutAnimation(): void {
    // 延时开始动画，让用户看到Toast提示
    setTimeout(() => {
      // 开始渐隐动画
      this.pageOpacity = 0;
      hilog.info(DOMAIN, 'LoginPage', '🎬 [Animation] 开始渐隐动画');

      // 动画完成后关闭模态页面
      setTimeout(() => {
        // 通过修改AppStorage中的一个标记来触发MainTabNavPage的状态检查
        AppStorage.setOrCreate('loginStatusChanged', Date.now());
        hilog.info(DOMAIN, 'LoginPage', '📢 [Notification] 发送登录状态变化通知');

        // 关闭模态页面
        this.pathStack.pop();
        hilog.info(DOMAIN, 'LoginPage', '🔙 [Navigation] 关闭登录模态页面');
      }, 500); // 减少延时，让MinePage能更早开始渐显
    }, 600); // 稍微减少等待时间，提升响应速度
  }
}