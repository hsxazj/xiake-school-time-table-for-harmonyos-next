import { UserInfoManager } from '../../common/utils/UserInfoManager';
import router from '@ohos.router';

// 用户信息接口
interface UserInfo {
  avatar: Resource;
  username: string;
  studentId: string;
  college: string;
  major: string;
  className: string;
}

// 菜单项类型接口
interface MenuItemType {
  icon: Resource;
  title: string;
  desc: string;
}

@Component
export struct MinePage {
  private pathStack: NavPathStack = new NavPathStack();
  @State private userInfo: UserInfo = {
    avatar: $r('app.media.defaultAvatar'),
    username: 'FJUTER',
    studentId: '2024001',
    college: '加载中...',
    major: '加载中...',
    className: '加载中...'
  };
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  aboutToAppear(): void {
    this.loadUserInfo();
  }

  build() {
    Column() {
      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          Image(this.userInfo.avatar)
            .height(45)
            .width(45)
            .borderRadius(40)
            .margin({ right: 16 })

          // 用户信息
          Column() {
            Text(this.userInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 4 })
            // Text(`学号：${this.userInfo.studentId}`)
            //   .fontSize(14)
            //   .fontColor('#666666')
            //   .margin({ bottom: 2 })
            Text(`${this.userInfo.college}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 2 })
            Text(`${this.userInfo.major}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 2 })
            Text(this.userInfo.className)
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(24)
      .borderWidth(1)
      .borderColor('#F2F2F2')
      .shadow({
        radius: 10,
        color: '#80000000',   // 半透明黑
        offsetX: 0,
        offsetY: 4
      })
      .margin({ top: 50, bottom: 20 })
      .onClick(() => {
        this.navigateToClassSelect();
      })

      // 功能列表 - 只保留问题反馈和关于我们
      Column() {
        this.MenuSection('帮助与信息', this.getHelpItems())
      }
      .width('90%')
      .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  MenuSection(title: string, items: MenuItemType[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        ForEach(items, (item: MenuItemType, index: number) => {
          Row() {
            Image(item.icon)
              .height(24)
              .width(24)
              .margin({ right: 16 })

            Column() {
              Text(item.title)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 2 })
              Text(item.desc)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 处理点击事件
          })

          if (index < items.length - 1) {
            Divider()
              .color('#F0F0F0')
              .strokeWidth(0.5)
              .margin({ left: 68 })
          }
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 20 })
      .shadow({
        radius: 10,
        color: '#80000000',   // 半透明黑
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  private loadUserInfo(): void {
    const schoolInfo = this.userInfoManager.getUserInfo(getContext(this));
    console.info('获取到的用户信息:', JSON.stringify(schoolInfo));

    // 更新学院、专业、班级信息
    if (schoolInfo.collegeName) {
      this.userInfo.college = schoolInfo.collegeName;
    }

    if (schoolInfo.majorName) {
      this.userInfo.major = schoolInfo.majorName;
    }

    if (schoolInfo.className) {
      this.userInfo.className = schoolInfo.className;
    }

    // 如果没有完整信息，显示提示
    if (!schoolInfo.collegeName || !schoolInfo.majorName || !schoolInfo.className) {
      console.info('用户信息不完整，建议用户完善信息');
    }
  }

  private getHelpItems(): MenuItemType[] {
    return [
      { icon: $r("app.media.problemFeedback"), title: '问题反馈', desc: '反馈使用问题和建议' },
      { icon: $r("app.media.aboutUs"), title: '关于我们', desc: '应用信息和版本' }
    ];
  }

  /**
   * 跳转到班级选择页面
   */
  private navigateToClassSelect(): void {
    try {
      router.pushUrl({
        url: 'pages/ClassSelectPage'
      });
      console.info('跳转到班级选择页面');
    } catch (error) {
      console.error('跳转到班级选择页面失败:', error);
    }
  }
}