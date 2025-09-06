import { TreeHolePostPageBuilder } from '../components/pages/TreeHolePostPage';

@Builder
export function TreeHolePostNavPageBuilder() {
  TreeHolePostNavPage();
}

@Component
struct TreeHolePostNavPage {
  @Consume('NavStack') pathStack: NavPathStack;

  build() {
    NavDestination() {
      TreeHolePostPageBuilder()
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      console.info('🌳 [TreeHolePostNavPage] 页面就绪');
    })
  }
}