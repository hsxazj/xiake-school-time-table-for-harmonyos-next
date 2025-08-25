import { HomePage } from '../components/pages/HomePage';
import { SchedulePage } from '../components/pages/SchedulePage';
import { MinePage } from '../components/pages/MinePage';

@Builder
export function MainTabNavPageBuilder() {
  MainTabNavPage();
}

@Component
struct MainTabNavPage {
  @State currentTabIndex: number = 0;
  @Consume('NavStack') pathStack: NavPathStack;

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
          MinePage()
        }
        .tabBar(this.TabBuilder('我的', 2, $r('app.media.me'), $r("app.media.meActive")))
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
}