import { promptAction } from '@kit.ArkUI';
import { UserInfoManager, UserSchoolInfo } from '../../common/constants/PreferencesUtil';
import { CurrentSemesterStatus } from '../../services/api/ConfigApiService';
import { AppConfigManager } from '../../services/AppConfigManager';

@Entry
@Component
struct HomePage {
  @State private userInfo: UserSchoolInfo | null = null;
  @State private isLoading: boolean = true;
  @State private currentStatus: CurrentSemesterStatus | null = null;
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();

  aboutToAppear(): void {
    this.loadUserData();
    this.loadCurrentStatus();
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
        Text('欢迎使用霞客课表')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#179FA2')
          .margin({ top: 60, bottom: 20 })

        // 学期状态卡片 (参照class-schedule-c的homepage显示)
        if (this.currentStatus) {
          Column() {
            Row() {
              Text('📅')
                .fontSize(20)
                .margin({ right: 10 })

              Text(this.currentStatus.statusText)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            }
            .justifyContent(FlexAlign.Start)
            .width('100%')
            .margin({ bottom: 8 })

            if (this.currentStatus.currentSemester) {
              Row() {
                Text('学期：')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(60)

                Text(`${this.currentStatus.currentSemester.academicYear}学年第${this.currentStatus.currentSemester.semester}学期`)
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 5 })
            }

            if (this.currentStatus.isInHoliday) {
              Text('🏖️ 假期愉快！')
                .fontSize(14)
                .fontColor('#45CAD9')
                .margin({ top: 5 })
            }
          }
          .width('90%')
          .padding(16)
          .backgroundColor(this.currentStatus.isInSemester ? '#E8F8F9' : '#FFF8E1')
          .borderRadius(12)
          .border({
            width: 1,
            color: this.currentStatus.isInSemester ? '#45CAD9' : '#FFC107'
          })
          .margin({ bottom: 20 })
        }

        if (this.userInfo) {
          Column() {
            Row() {
              Text('学院：')
                .fontSize(16)
                .fontColor('#666666')
                .width(80)

              Text(this.userInfo.collegeName)
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

              Text(this.userInfo.majorName)
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

              Text(this.userInfo.className)
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
              message: '欢迎使用霞客课表！',
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

  private async loadCurrentStatus(): Promise<void> {
    try {
      // 直接获取当前状态，不触发重新初始化
      // AppConfigManager已经在EntryAbility中初始化完成
      this.currentStatus = this.appConfigManager.getCurrentStatus();

      if (this.currentStatus) {
        console.info(`HomePage loaded current status: ${this.currentStatus.statusText}`);
      } else {
        console.error('HomePage: 配置未初始化或初始化失败');
        // 不显示任何学期信息
      }
    } catch (error) {
      console.error('Load current status failed:', error);
    }
  }

  private async loadUserData(): Promise<void> {
    try {
      this.userInfo = this.userInfoManager.getUserInfo();

      if (!this.userInfoManager.hasCompleteUserInfo()) {
        promptAction.showToast({
          message: '未找到用户信息，请重新选择',
          duration: 2000
        });
        this.userInfo = null;
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
}