import { HomePage } from '../components/pages/HomePage';
import { SchedulePage } from '../components/pages/SchedulePage';
import { TreeHolePage } from '../components/pages/TreeHolePage';
import { MinePage } from '../components/pages/MinePage';
import { AppConfigManager } from '../services/AppConfigManager';

@Builder
export function MainTabNavPageBuilder() {
  MainTabNavPage();
}

@Component
struct MainTabNavPage {
  @State currentTabIndex: number = 0;
  @State treeHoleEnabled: boolean = true; // 树洞功能状态
  @Consume('NavStack') pathStack: NavPathStack;
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();

  aboutToAppear(): void {
    // 加载树洞功能状态
    this.loadTreeHoleSettings();
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, icon: Resource, iconActive: Resource) {
    Column() {
      Image(this.currentTabIndex === targetIndex ? iconActive : icon)
        .height(26)
        .width(26)
      Text(title)
        .fontColor(this.currentTabIndex === targetIndex ? $r('app.color.schedule_primary_color') : '#999999')
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
        // 首页 Tab - 始终显示
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBuilder('首页', 0, $r('app.media.home'), $r("app.media.homeActive")))

        // 课表 Tab - 始终显示
        TabContent() {
          SchedulePage()
        }
        .tabBar(this.TabBuilder('课表', 1, $r('app.media.classList'), $r('app.media.classListActive')))

        // 树洞 Tab - 根据设置动态显示
        if (this.treeHoleEnabled) {
          TabContent() {
            TreeHolePage()
          }
          .tabBar(this.TabBuilder('树洞', 2, $r('app.media.treehole'), $r("app.media.treehole_active")))
        }

        // 我的 Tab - 始终显示，索引需要根据树洞是否显示动态调整
        TabContent() {
          MinePage()
        }
        .tabBar(this.TabBuilder('我的', this.treeHoleEnabled ? 3 : 2, $r('app.media.me'), $r("app.media.meActive")))
      }
      .width('100%')
      .height('100%')
      .barBackgroundColor($r('sys.color.comp_background_list_card'))
      .barMode(BarMode.Fixed)
      .vertical(false)
      .scrollable(false)
      .onChange((index: number) => {
        this.currentTabIndex = index;
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

  /**
   * 加载树洞功能设置
   */
  private loadTreeHoleSettings(): void {
    try {
      // 从AppConfigManager获取树洞功能状态
      this.treeHoleEnabled = this.appConfigManager.getTreeHoleEnabled();
      console.info(`[MainTabNavPage] 树洞功能状态: ${this.treeHoleEnabled}`);
    } catch (error) {
      console.error('[MainTabNavPage] 加载树洞功能设置失败:', error);
      this.treeHoleEnabled = true; // 默认启用
    }
  }
}