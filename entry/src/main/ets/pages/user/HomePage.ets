import { promptAction } from '@kit.ArkUI';
import { StorageService } from '../../services/storage/StorageService';
import { UserSelection } from '../../models/CollegeModels';

@Entry
@Component
struct HomePage {
  @State private userSelection: UserSelection | null = null;
  @State private isLoading: boolean = true;

  private storageService: StorageService = StorageService.getInstance();

  aboutToAppear(): void {
    this.loadUserData();
  }

  private async loadUserData(): Promise<void> {
    try {
      this.userSelection = await this.storageService.getUserSelection();
      
      if (!this.userSelection) {
        promptAction.showToast({
          message: '未找到用户信息，请重新选择',
          duration: 2000
        });
      }
    } catch (error) {
      console.error('Load user data failed:', error);
      promptAction.showToast({
        message: '加载用户信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .color('#45CAD9')
          .margin({ top: 200 })
      } else {
        Text('欢迎使用侠客课表')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#179FA2')
          .margin({ top: 60, bottom: 40 })

        if (this.userSelection) {
          Column() {
            Row() {
              Text('学院：')
                .fontSize(16)
                .fontColor('#666666')
                .width(80)
              
              Text(this.userSelection.collegeName)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 15 })

            Row() {
              Text('专业：')
                .fontSize(16)
                .fontColor('#666666')
                .width(80)
              
              Text(this.userSelection.majorName)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 15 })

            Row() {
              Text('班级：')
                .fontSize(16)
                .fontColor('#666666')
                .width(80)
              
              Text(this.userSelection.className)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
            }
            .width('100%')
          }
          .width('80%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({
            radius: 8,
            color: 'rgba(0, 0, 0, 0.1)',
            offsetY: 2
          })
          .margin({ bottom: 40 })

          Text('🎉 设置完成！')
            .fontSize(20)
            .fontColor('#45CAD9')
            .margin({ bottom: 20 })

          Text('您已成功选择了学院、专业和班级信息')
            .fontSize(14)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 40 })
        } else {
          Text('未找到选择信息')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 100 })
        }

        Button('开始使用')
          .width('60%')
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#45CAD9')
          .borderRadius(22)
          .shadow({
            radius: 20,
            color: 'rgba(157, 224, 231, 0.6)',
            offsetY: 0
          })
          .onClick(() => {
            promptAction.showToast({
              message: '欢迎使用侠客课表！',
              duration: 2000
            });
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
    .padding(20)
    .justifyContent(FlexAlign.Center)
  }
}