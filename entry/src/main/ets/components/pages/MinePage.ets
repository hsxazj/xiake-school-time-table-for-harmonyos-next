import { UserInfoManager } from '../../common/utils/UserInfoManager';
import { LoginApiService } from '../../services/api/LoginApiService';

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
  @State private pageOpacity: number = 0; // 页面初始透明度为0
  @State private pageTranslateY: number = 30; // 页面初始向下偏移30px
  @State private isLoggingOut: boolean = false; // 是否正在退出登录
  
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private loginService: LoginApiService = LoginApiService.getInstance();

  aboutToAppear(): void {
    this.loadUserInfo();
    // 启动渐显动画
    this.startFadeInAnimation();
  }

  /**
   * 启动渐显动画
   */
  private startFadeInAnimation(): void {
    // 短暂延时后启动动画，让组件先完成初始化
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslateY = 0;
      console.info('[MinePage] 🎬 启动渐显动画');
    }, 100);
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
        color: '#80000000', // 半透明黑
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

      // 退出登录按钮
      Button(this.isLoggingOut ? '退出中...' : '退出登录')
        .width('90%')
        .height(44)
        .fontSize(16)
        .fontColor('#FF6B6B')
        .backgroundColor(Color.White)
        .borderWidth(1)
        .borderColor('#FF6B6B')
        .borderRadius(8)
        .enabled(!this.isLoggingOut)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.showLogoutConfirmDialog();
        })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .opacity(this.pageOpacity)
    .translate({ x: 0, y: this.pageTranslateY })
    .animation({
      duration: 700,
      curve: Curve.EaseInOut, // 使用EaseOutBack创造轻微回弹效果
      iterations: 1,
      playMode: PlayMode.Normal
    })
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
        color: '#80000000', // 半透明黑
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  private loadUserInfo(): void {
    const schoolInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
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
   * 显示退出登录确认对话框
   */
  private showLogoutConfirmDialog(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确认要退出当前账户吗？',
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('[MinePage] 用户取消退出登录');
        }
      },
      secondaryButton: {
        value: '确认退出',
        fontColor: '#FF6B6B',
        action: () => {
          this.handleLogout();
        }
      }
    });
  }

  /**
   * 处理退出登录
   */
  private async handleLogout(): Promise<void> {
    try {
      this.isLoggingOut = true;
      console.info('[MinePage] 🔄 开始退出登录...');

      // 获取context用于清除首选项
      const context = this.getUIContext().getHostContext();
      
      // 调用登录服务的退出方法
      this.loginService.logout(context);
      console.info('[MinePage] ✅ 退出登录成功');

      // 通知登录状态变化
      AppStorage.setOrCreate('loginStatusChanged', Date.now());
      console.info('[MinePage] 📢 已发送登录状态变化通知');

      // 显示成功提示
      this.showToast('已退出登录');

    } catch (error) {
      console.error('[MinePage] ❌ 退出登录失败:', JSON.stringify(error));
      this.showToast('退出登录失败，请重试');
    } finally {
      this.isLoggingOut = false;
    }
  }

  /**
   * 显示Toast提示
   */
  private showToast(message: string): void {
    // 使用系统Toast显示提示信息
    // 注意：这里使用console.info作为简单实现，实际项目中可以使用更完整的Toast组件
    console.info(`[Toast] ${message}`);
  }

  /**
   * 跳转到班级选择页面
   */
  private navigateToClassSelect(): void {
    try {
      this.pathStack.pushPathByName('ClassSelectPage', null);
      console.info('跳转到班级选择页面');
    } catch (error) {
      console.error('跳转到班级选择页面失败:', error);
    }
  }
}