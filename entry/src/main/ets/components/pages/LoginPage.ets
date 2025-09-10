import { LoginApiService } from '../../services/api/LoginApiService';
import { LoginForm, LoginStatus } from '../../models/LoginModels';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';

const DOMAIN = 0x3000; // Login Page domain

/**
 * 登录页面组件
 * 提供账号密码登录功能
 */
@Component
@Preview
export struct LoginPage {
  @State private loginForm: LoginForm = {
    username: '',
    password: ''
  };
  @State private loginStatus: LoginStatus = LoginStatus.IDLE;
  @State private errorMessage: string = '';
  @State private showPassword: boolean = false;

  private loginService: LoginApiService = LoginApiService.getInstance();

  build() {
    Column() {
      // 顶部Logo和标题区域
      this.buildHeader()

      // 登录表单区域
      this.buildLoginForm()

      // 登录按钮
      this.buildLoginButton()

      // 错误信息显示
      if (this.errorMessage) {
        this.buildErrorMessage()
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    .padding({ left: 24, right: 24, top: 40 })
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
          .borderColor(this.loginForm.username ? '#3B82F6' : '#E5E7EB')
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
            .borderColor(this.loginForm.password ? '#3B82F6' : '#E5E7EB')
            .borderWidth(1)
            .placeholderColor('#9CA3AF')
            .fontSize(16)
            .padding({ left: 12, right: 40 })
            .type(this.showPassword ? InputType.Normal : InputType.Password)
            .onChange((value: string) => {
              this.loginForm.password = value;
              this.clearError();
            })

          // 密码可见性切换按钮
          Button() {
            Image(this.showPassword ? $r('app.media.treehole') : $r('app.media.treehole_active'))
              .width(20)
              .height(20)
              .fillColor('#9CA3AF')
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .position({ x: '85%', y: '50%' })
          .translate({ x: '-50%', y: '-50%' })
          .onClick(() => {
            this.showPassword = !this.showPassword;
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
    .backgroundColor(this.isFormValid() && this.loginStatus !== LoginStatus.LOADING ? '#3B82F6' : '#9CA3AF')
    .enabled(this.isFormValid() && this.loginStatus !== LoginStatus.LOADING)
    .onClick(() => {
      this.handleLogin();
    })
  }

  @Builder
  buildErrorMessage() {
    Row({ space: 8 }) {
      Image($r('app.media.treehole'))
        .width(16)
        .height(16)
        .fillColor('#EF4444')

      Text(this.errorMessage)
        .fontSize(14)
        .fontColor('#EF4444')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FEF2F2')
    .borderRadius(8)
    .borderColor('#FECACA')
    .borderWidth(1)
    .margin({ top: 16 })
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

      // 调用登录API
      await this.loginService.login(this.loginForm);

      this.loginStatus = LoginStatus.SUCCESS;
      hilog.info(DOMAIN, 'LoginPage', '✅ [Login] 登录成功');

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
    promptAction.showToast({
      message: '登录成功！',
      duration: 2000,
      bottom: 100
    });
    
    // 延时触发状态更新，让父组件有机会重新检查登录状态
    setTimeout(() => {
      // 通过修改AppStorage中的一个标记来触发MainTabNavPage的状态检查
      AppStorage.setOrCreate('loginStatusChanged', Date.now());
    }, 500);
    
    hilog.info(DOMAIN, 'LoginPage', '🎉 [Success] 登录成功提示已显示');
  }
}