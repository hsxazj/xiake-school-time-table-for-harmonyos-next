import router from '@ohos.router';
import { ConfigApiService } from '../services/api/ConfigApiService';

@Entry
@Component
struct Index {
  @State message: string = '欢迎使用霞客课表';
  private configService: ConfigApiService = ConfigApiService.getInstance();

  aboutToAppear(): void {
    // 在应用启动时预加载配置信息
    this.preloadConfiguration();
  }
  
  /**
   * 预加载配置信息
   */
  private async preloadConfiguration(): Promise<void> {
    try {
      console.info('🚀 [App Init] 开始预加载配置信息');
      // 异步加载配置，不阻塞UI展示
      await this.configService.getConfig();
      console.info('✅ [App Init] 配置信息预加载完成');
    } catch (error) {
      console.warn('⚠️ [App Init] 配置预加载失败，将在课表页面重试:', error);
    } finally {
      // 2秒后跳转，确保用户看到启动画面
      setTimeout(() => {
        router.replaceUrl({
          url: 'pages/first/ClassSelectPage'
        });
      }, 2000);
    }
  }

  build() {
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

        Text('正在初始化...')
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
}