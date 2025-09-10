import { HomePage } from '../components/pages/HomePage';
import { SchedulePage } from '../components/pages/SchedulePage';
import { TreeHolePage } from '../components/pages/TreeHolePage';
import { MinePage } from '../components/pages/MinePage';
import { LoginPage } from '../components/pages/LoginPage';
import { LoginApiService } from '../services/api/LoginApiService';

@Builder
export function MainTabNavPageBuilder() {
  MainTabNavPage();
}

@Component
struct MainTabNavPage {
  @State currentTabIndex: number = 0;
  @State isLoggedIn: boolean = false;
  @StorageLink('loginStatusChanged') @Watch('onLoginStatusChanged') loginStatusChanged: number = 0;
  @Consume('NavStack') pathStack: NavPathStack;
  
  private loginService: LoginApiService = LoginApiService.getInstance();

  aboutToAppear(): void {
    // 检查登录状态
    this.checkLoginStatus();
  }

  /**
   * 监听登录状态变化
   */
  private onLoginStatusChanged(): void {
    console.info(`[MainTab] 收到登录状态变化通知: ${this.loginStatusChanged}`);
    this.checkLoginStatus();
  }

  /**
   * 检查登录状态
   */
  private checkLoginStatus(): void {
    this.isLoggedIn = this.loginService.isLoggedIn();
    console.info(`[MainTab] 登录状态检查: ${this.isLoggedIn ? '已登录' : '未登录'}`);
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, icon: Resource, iconActive: Resource) {
    Column() {
      Image(this.currentTabIndex === targetIndex ? iconActive : icon)
        .height(26)
        .width(26)
      Text(title)
        .fontColor(this.currentTabIndex === targetIndex ? '#45CAD9' : '#999999')
        .fontSize(16)
        .fontWeight(this.currentTabIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, controller: new TabsController() }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBuilder('首页', 0, $r('app.media.home'), $r("app.media.homeActive")))

        TabContent() {
          SchedulePage()
        }
        .tabBar(this.TabBuilder('课表', 1, $r('app.media.classList'), $r('app.media.classListActive')))

        TabContent() {
          TreeHolePage()
        }
        .tabBar(this.TabBuilder('树洞', 2, $r('app.media.treehole'), $r("app.media.treehole_active")))

        TabContent() {
          // 根据登录状态条件渲染页面
          if (this.isLoggedIn) {
            MinePage()
          } else {
            LoginPage()
          }
        }
        .tabBar(this.TabBuilder('我的', 3, $r('app.media.me'), $r("app.media.meActive")))
      }
      .width('100%')
      .height('100%')
      .barBackgroundColor($r('sys.color.comp_background_list_card'))
      .barMode(BarMode.Fixed)
      .vertical(false)
      .scrollable(false)
      .onChange((index: number) => {
        this.currentTabIndex = index;
        
        // 当切换到"我的"tab时，重新检查登录状态
        if (index === 3) {
          this.checkLoginStatus();
        }
      })
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.getUIContext().getRouter().back();
      return true;
    })
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      console.info('all path stack:', this.pathStack.getAllPathName())
    })
  }
}