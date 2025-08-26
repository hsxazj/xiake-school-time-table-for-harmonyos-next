import { AppConfigManager } from '../services/AppConfigManager';
import { UserInfoManager } from '../common/utils/PreferencesUtil';


@Entry
@Component
struct OpenNavPage {
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
            .color('#45CAD9')
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
      await this.appConfigManager.initialize();

      this.initMessage = '加载完成！';

      // 检查是否已设置完整的学籍信息
      const hasCompleteInfo = this.userInfoManager.hasCompleteUserInfo();

      // 短暂延迟后跳转
      setTimeout(() => {
        if (hasCompleteInfo) {
          // 已有完整信息，直接跳转到主页Tab页面
          this.pathStack.clear();
          this.pathStack.pushPathByName('MainTabNavPage', null);
        } else {
          // 没有完整信息，跳转到学院选择页面
          this.pathStack.clear();
          this.pathStack.pushPathByName('ClassSelectNavPage', null);
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
}