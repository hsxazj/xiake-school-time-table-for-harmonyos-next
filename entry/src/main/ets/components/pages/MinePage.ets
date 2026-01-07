import { AppConfigManager } from '../../services/AppConfigManager';
import { common } from '@kit.AbilityKit';
import { JwxtGetInfoService } from '../../services/jwxt/JwxtGetInfoService';
import { CookieManager } from '../../services/jwxt/CookieManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0004;
const TAG = 'MinePage';

// 用户信息接口
interface UserInfo {
  avatar: Resource | string;
  username: string;
  realName: string;
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
  @Consume('NavStack') pathStack: NavPathStack;
  @StorageLink('loginStatusChanged') @Watch('onLoginStatusChanged') loginStatusChanged: number = 0;
  @State private userInfo: UserInfo = {
    avatar: $r('app.media.defaultAvatar'),
    username: '未登录',
    realName: '',
    studentId: '',
    college: '加载中...',
    major: '加载中...',
    className: '加载中...'
  };
  @State private pageOpacity: number = 0; // 页面初始透明度为0
  @State private pageTranslateY: number = 30; // 页面初始向下偏移30px
  @State private isLoggingOut: boolean = false; // 是否正在退出登录
  @State private isLoggedIn: boolean = false; // 登录状态
  @State private isCheckingLogin: boolean = true; // 是否正在检查登录状态
  @State private treeHoleEnabled: boolean = true; // 树洞功能状态
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  private cookieManager: CookieManager = CookieManager.getInstance();

  aboutToAppear(): void {
    this.checkLoginStatus();
    this.loadTreeHoleSettings();
    // 启动渐显动画
    this.startFadeInAnimation();
  }

  build() {
    Column() {
      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          if (typeof this.userInfo.avatar === 'string') {
            // 网络头像
            Image(this.userInfo.avatar)
              .height(45)
              .width(45)
              .borderRadius(40)
              .margin({ right: 16 })
              .alt($r('app.media.defaultAvatar')) // 加载失败时显示默认头像
          } else {
            // 本地Resource头像
            Image(this.userInfo.avatar)
              .height(45)
              .width(45)
              .borderRadius(40)
              .margin({ right: 16 })
          }

          // 用户信息
          Column() {
            // 显示用户真实姓名（如果有）或用户名
            if (this.isCheckingLogin) {
              Text('正在验证登录状态...')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#999999')
                .margin({ bottom: 4 })
            } else {
              Text(this.userInfo.realName || this.userInfo.username)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 4 })

              // 显示学号（如果已登录）
              if (this.isLoggedIn && this.userInfo.studentId) {
                Text(`学号：${this.userInfo.studentId}`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })
              }

              // 显示专业和班级（如果已登录）
              if (this.isLoggedIn && this.userInfo.major && this.userInfo.className) {
                Text(`${this.userInfo.major} ${this.userInfo.className}`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 2 })
              }

              // 显示学院（如果已登录）
              if (this.isLoggedIn && this.userInfo.college) {
                Text(this.userInfo.college)
                  .fontSize(12)
                  .fontColor('#999999')
              }
            }
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

      // // 功能设置列表 - 树洞开关
      // Column() {
      //   this.MenuSection('功能设置', this.getFunctionItems())
      // }
      // .width('90%')
      // .margin({ bottom: 20 })

      // // 功能列表 - 只保留问题反馈和关于我们
      // Column() {
      //   this.MenuSection('帮助与信息', this.getHelpItems())
      // }
      // .width('90%')

      Blank()

      // 登录/退出登录按钮
      if (this.isLoggedIn) {
        Button(this.isLoggingOut ? '退出中...' : '退出登录')
          .width('90%')
          .height(44)
          .fontSize(16)
          .fontColor('#FF6B6B')
          .backgroundColor(Color.White)
          .borderWidth(1)
          .borderColor('#FF6B6B')
          .borderRadius(8)
          .enabled(!this.isLoggingOut && !this.isCheckingLogin)
          .margin({ bottom: 20 })
          .onClick(() => {
            this.showLogoutConfirmDialog();
          })
      } else if (!this.isCheckingLogin) {
        Button('去登录')
          .width('90%')
          .height(44)
          .fontSize(16)
          .fontColor($r('app.color.schedule_primary_color'))
          .backgroundColor(Color.White)
          .borderWidth(1)
          .borderColor($r('app.color.schedule_primary_color'))
          .borderRadius(8)
          .margin({ bottom: 20 })
          .onClick(() => {
            this.navigateToLogin();
          })
      }
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

            // 根据section类型显示不同的右侧组件
            if (title === '功能设置' && item.title === '树洞功能') {
              // 树洞功能显示开关
              Toggle({ type: ToggleType.Switch, isOn: this.treeHoleEnabled })
                .selectedColor($r('app.color.schedule_primary_color'))
                .switchPointColor(Color.White)
                .onChange((isOn: boolean) => {
                  if (isOn !== this.treeHoleEnabled) {
                    this.toggleTreeHoleFunction();
                  }
                })
            } else {
              // 其他项目显示箭头
              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
            }
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 处理点击事件
            if (title === '功能设置' && item.title === '树洞功能') {
              // 树洞功能开关点击
              this.toggleTreeHoleFunction();
            }
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

  /**
   * 监听登录状态变化
   */
  private onLoginStatusChanged(): void {
    console.info(`[MinePage] 收到登录状态变化通知: ${this.loginStatusChanged}`);
    this.checkLoginStatus();
  }

  /**
   * 检查登录状态（基于Cookie缓存机制）
   * 通过尝试获取学生信息来验证登录状态
   */
  private async checkLoginStatus(): Promise<void> {
    try {
      this.isCheckingLogin = true;
      hilog.info(DOMAIN, TAG, '🔍 [MinePage] 开始检查登录状态（基于Cookie）...');

      // 尝试获取学生信息（会自动使用缓存的Cookie）
      const studentInfo = await this.jwxtGetInfoService.getInfo();

      // 如果成功获取，说明登录有效
      this.isLoggedIn = true;
      hilog.info(DOMAIN, TAG, '✅ [MinePage] 登录状态有效，获取到学生信息: %{public}s', studentInfo.name);

      // 更新用户信息显示
      this.userInfo.username = studentInfo.student_id;
      this.userInfo.realName = studentInfo.name;
      this.userInfo.studentId = studentInfo.student_id;
      this.userInfo.college = studentInfo.college || '学院信息未设置';
      this.userInfo.major = studentInfo.major || '专业信息未设置';
      this.userInfo.className = studentInfo.class_name || '班级信息未设置';

      hilog.info(DOMAIN, TAG, '📋 [MinePage] 用户信息已更新: %{public}s - %{public}s %{public}s',
        this.userInfo.realName, this.userInfo.major, this.userInfo.className);

    } catch (error) {
      // 获取失败，说明未登录或登录已过期
      this.isLoggedIn = false;
      hilog.warn(DOMAIN, TAG, '⚠️ [MinePage] 登录状态无效或已过期: %{public}s',
        error instanceof Error ? error.message : String(error));

      // 重置为未登录状态
      this.resetUserInfoToDefault();
    } finally {
      this.isCheckingLogin = false;
    }
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

  /**
   * 重置用户信息为默认状态
   */
  private resetUserInfoToDefault(): void {
    this.userInfo.username = '未登录';
    this.userInfo.realName = '';
    this.userInfo.studentId = '';
    this.userInfo.college = '请先登录';
    this.userInfo.major = '请先登录';
    this.userInfo.className = '请先登录';
    this.userInfo.avatar = $r('app.media.defaultAvatar');
  }

  private getHelpItems(): MenuItemType[] {
    return [
      { icon: $r("app.media.problemFeedback"), title: '问题反馈', desc: '反馈使用问题和建议' },
      { icon: $r("app.media.aboutUs"), title: '关于我们', desc: '应用信息和版本' }
    ];
  }

  /**
   * 获取功能设置列表项
   */
  private getFunctionItems(): MenuItemType[] {
    return [
      { icon: $r("app.media.treehole"), title: '树洞功能', desc: this.treeHoleEnabled ? '已启用' : '已禁用' }
    ];
  }

  /**
   * 加载树洞功能设置
   */
  private loadTreeHoleSettings(): void {
    try {
      // 从AppConfigManager获取树洞功能状态
      this.treeHoleEnabled = this.appConfigManager.getTreeHoleEnabled();
      console.info(`[MinePage] 树洞功能状态: ${this.treeHoleEnabled}`);
    } catch (error) {
      console.error('[MinePage] 加载树洞功能设置失败:', error);
      this.treeHoleEnabled = true; // 默认启用
    }
  }

  /**
   * 切换树洞功能状态
   */
  private toggleTreeHoleFunction(): void {
    try {
      const newState = !this.treeHoleEnabled;
      const context = this.getUIContext().getHostContext();

      // 检查context是否有效
      if (!context) {
        console.error('[MinePage] 无法获取有效的context');
        this.showToast('设置失败，请重试');
        return;
      }

      // 保存新状态到AppConfigManager
      this.appConfigManager.setTreeHoleEnabled(newState, context);
      this.treeHoleEnabled = newState;

      console.info(`[MinePage] 树洞功能已${newState ? '启用' : '禁用'}`);

      // 显示重启提示对话框
      this.showRestartConfirmDialog();

    } catch (error) {
      console.error('[MinePage] 切换树洞功能失败:', error);
      this.showToast('设置失败，请重试');
    }
  }

  /**
   * 显示重启确认对话框
   */
  private showRestartConfirmDialog(): void {
    this.getUIContext().showAlertDialog({
      title: '设置已更新',
      message: `树洞功能已${this.treeHoleEnabled ? '启用' : '禁用'}，需要重启应用才能生效。`,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '稍后重启',
        fontColor: $r('app.color.schedule_primary_color'),
        action: () => {
          this.showToast('设置已保存，下次启动时生效');
        }
      },
      secondaryButton: {
        value: '立即重启',
        fontColor: $r('app.color.schedule_primary_color'),
        action: () => {
          this.restartApp();
        }
      }
    });
  }

  /**
   * 重启应用
   */
  private restartApp(): void {
    try {
      const context = this.getUIContext().getHostContext();

      // 检查context是否有效
      if (!context) {
        console.error('[MinePage] 无法获取有效的context');
        this.showToast('重启失败，请手动重启应用');
        return;
      }

      console.info('[MinePage] 准备重启应用...');

      // 获取UIAbilityContext来执行重启
      const abilityContext = context as common.UIAbilityContext;

      // 使用HarmonyOS API重启应用
      abilityContext.terminateSelf((error: Error) => {
        if (error) {
          console.error('[MinePage] 重启应用失败:', error);
          this.showToast('重启失败，请手动重启应用');
        } else {
          console.info('[MinePage] 应用重启成功');
        }
      });
    } catch (error) {
      console.error('[MinePage] 重启应用异常:', error);
      this.showToast('重启失败，请手动重启应用');
    }
  }

  /**
   * 显示退出登录确认对话框
   */
  private showLogoutConfirmDialog(): void {
    this.getUIContext().showAlertDialog({
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
   * 跳转到登录页面
   */
  private navigateToLogin(): void {
    try {
      this.pathStack.pushPathByName('LoginNavPage', null, true); // 使用模态转场
      console.info('[MinePage] 跳转到登录页面');
    } catch (error) {
      console.error('[MinePage] 跳转到登录页面失败:', error);
    }
  }

  /**
   * 处理退出登录
   */
  private async handleLogout(): Promise<void> {
    // TODO 重写优先级高
  }

  /**
   * 显示Toast提示
   */
  private showToast(message: string): void {
    // 使用系统Toast显示提示信息
    // 注意：这里使用console.info作为简单实现，实际项目中可以使用更完整的Toast组件
    console.info(`[Toast] ${message}`);
  }
}