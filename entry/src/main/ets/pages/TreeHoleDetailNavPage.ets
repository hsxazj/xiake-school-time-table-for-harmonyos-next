import { TreeHoleDetailPageBuilder } from '../components/pages/TreeHoleDetailPage';

@Builder
export function TreeHoleDetailNavPageBuilder() {
  TreeHoleDetailNavPage();
}

@Component
struct TreeHoleDetailNavPage {
  @Consume('NavStack') pathStack: NavPathStack;

  build() {
    NavDestination() {
      TreeHoleDetailPageBuilder()
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      console.info('🌳 [TreeHoleDetailNavPage] 页面就绪');
    })
  }
}