import { HomePage } from '../components/pages/HomePage';
import { SchedulePage } from '../components/pages/SchedulePage';
import { MinePage } from '../components/pages/MinePage';

@Entry
@Component
struct MainTabPage {
  @State currentTabIndex: number = 0;

  @Builder
  TabBuilder(title: string, targetIndex: number) {
    Column() {
      Text(this.getTabIcon(targetIndex))
        .fontSize(22)
        .fontColor(this.currentTabIndex === targetIndex ? '#45CAD9' : '#999999')
        .margin({ bottom: 4 })
      Text(title)
        .fontColor(this.currentTabIndex === targetIndex ? '#45CAD9' : '#999999')
        .fontSize(12)
        .fontWeight(this.currentTabIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: new TabsController() }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder('首页', 0))

      TabContent() {
        SchedulePage()
      }
      .tabBar(this.TabBuilder('课表', 1))

      TabContent() {
        MinePage()
      }
      .tabBar(this.TabBuilder('我的', 2))
    }
    .width('100%')
    .height('100%')
    .barBackgroundColor('#FFFFFF')
    .barMode(BarMode.Fixed)
    .vertical(false)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
  }

  private getTabIcon(index: number): string {
    const icons = ['🏠', '📅', '👤'];
    return icons[index] || '';
  }
}