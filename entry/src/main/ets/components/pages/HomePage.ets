import { UserInfoManager, UserSchoolInfo } from '../../common/constants/PreferencesUtil';
import router from '@ohos.router';

@Component
export struct HomePage {
  @State private userInfo: UserSchoolInfo | null = null;
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  aboutToAppear(): void {
    this.loadUserInfo();
  }

  build() {
    Column() {
      // 顶部问候语（删除右上角通知图标）
      Row() {
        Column() {
          Text(`你好，同学`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 8 }) // 从4增加到8
          
          // 显示学院+班级信息
          if (this.userInfo) {
            Row() {
              Text(`${this.userInfo.collegeName} ${this.userInfo.className}`)
                .fontSize(14)
                .fontColor('#666666')
              
              Text('切换')
                .fontSize(12)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
          } else {
            Row() {
              Text('学院信息加载中...')
                .fontSize(14)
                .fontColor('#666666')
              
              Text('切换')
                .fontSize(12)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
          top: 8,
          bottom: 8,
          left: 4,
          right: 4
        })
        .borderRadius(8)
        .onClick(() => {
          this.navigateToClassSelect();
        })

        Blank()
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 50,
        bottom: 20
      })

      // 今日课程区域（拉长并删除查看更多）
      Column() {
        Text('今日课程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 15 })

        // 课程列表区域 - 增加高度
        Column() {
          Text('暂无今日课程')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 50, bottom: 50 })
        }
        .width('100%')
        .height(300) // 从100增加到300
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F0F2F5') // 今日课程区域使用稍深的灰蓝色
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetY: 2
      })
      .margin({ bottom: 20 })
      .layoutWeight(1) // 让今日课程区域占用更多空间

      Blank()
    }
    .width('90%')
    .height('100%')
    .backgroundColor(Color.White) // 背景改为白色
    .justifyContent(FlexAlign.Start)
  }

  private loadUserInfo(): void {
    this.userInfo = this.userInfoManager.getUserInfo();
  }

  /**
   * 跳转到班级选择页面
   */
  private navigateToClassSelect(): void {
    try {
      router.pushUrl({
        url: 'pages/first/ClassSelectPage'
      });
    } catch (error) {
      console.error('跳转到班级选择页面失败:', error);
    }
  }
}