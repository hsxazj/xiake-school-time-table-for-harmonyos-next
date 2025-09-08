/**
 * 树洞主页面组件
 * 参考class-schedule-c的tree-hole.vue实现，适配ArkTS/HarmonyOS
 */
import { TreeHoleItem } from '../../models/TreeHoleModels';
import { TreeHoleApiService } from '../../services/api/TreeHoleApiService';
import { UserInfoManager } from '../../common/utils/UserInfoManager';

@Component
export struct TreeHolePage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private treeHoleList: TreeHoleItem[] = [];
  @State private isLoading: boolean = false;
  @State private isRefreshing: boolean = false;
  @State private isLoggedIn: boolean = false;
  @State private currentPage: number = 1;
  @State private hasMore: boolean = true;
  // 服务实例
  private treeHoleApiService: TreeHoleApiService = TreeHoleApiService.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  // 分页参数
  private readonly pageSize: number = 10;

  aboutToAppear(): void {
    console.info('🌳 [TreeHolePage] 页面即将显示，初始化数据');
    this.checkLoginStatus();
    this.loadTreeHoleList(true);
  }

  onPageShow(): void {
    console.info('🌳 [TreeHolePage] 页面显示');
    // 每次页面显示时刷新登录状态
    this.checkLoginStatus();
  }

  build() {
    Column() {
      // 主内容区域 - 使用滚动列表包含发布区域和内容
      if ((this.treeHoleList?.length || 0) === 0 && !this.isLoading) {
        this.buildEmptyStateWithHeader()
      } else {
        this.buildScrollableContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  /**
   * 构建可滚动的内容（包含发布区域和树洞列表）
   */
  @Builder
  buildScrollableContent() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      List() {
        // 发布区域作为列表的第一项
        ListItem() {
          this.buildPublishArea()
        }
        .margin({ bottom: 15 })

        // 树洞内容列表
        ForEach(this.treeHoleList || [], (item: TreeHoleItem, index: number) => {
          ListItem() {
            this.buildTreeHoleItem(item)
          }
          .margin({ left: 20, right: 20, top: 8 })
        }, (item: TreeHoleItem) => item.id.toString())

        // 加载更多指示器
        if (this.hasMore) {
          ListItem() {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color('#31BFCC')
                .margin({ right: 8 })

              Text('加载更多...')
                .fontSize(14)
                .fontColor('#999999')
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height(50)
          }
          .margin({ top: 10, bottom: 80 })
        } else if ((this.treeHoleList?.length || 0) > 0) {
          ListItem() {
            Text('— 已经到底了 —')
              .fontSize(14)
              .fontColor('#999999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .height(50)
          }
          .margin({ top: 10, bottom: 80 })
        }
      }
      .onReachEnd(() => {
        if (this.hasMore && !this.isLoading) {
          this.loadMoreData();
        }
      })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .onRefreshing(() => {
      this.handleRefresh();
    })
  }

  /**
   * 构建带头部的空状态
   */
  @Builder
  buildEmptyStateWithHeader() {
    Column() {
      // 发布区域
      Column() {
        this.buildPublishArea()
      }
      .margin({ top: 20, bottom: 15 })

      // 空状态
      Column() {
        Image($r('app.media.startIcon'))
          .width(80)
          .height(80)
          .opacity(0.3)
          .margin({ bottom: 15 })

        Text('— 暂无树洞内容 —')
          .fontSize(16)
          .fontColor('#999999')
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建发布区域
   */
  @Builder
  buildPublishArea() {
    Stack() {
      // 背景
      Image($r('app.media.treeHole_background'))
        .width('100%')
        .height(120)
        .objectFit(ImageFit.Cover)
        .borderRadius(25)

      Column() {
        Text('匿名分享，随心而发')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 15, bottom: 20 })

        Row() {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .margin({ right: 8 })

          Text('发布')
            .fontSize(16)
            .fontColor('#2DBACC')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .width('70%')
        .height(35)
        .backgroundColor('rgba(242, 251, 252, 0.68)')
        .borderRadius(25)
        .onClick(() => {
          this.handlePostClick();
        })
      }
      .padding({ left: 25, right: 25 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .padding({ left: 20, right: 20 })
    .width('100%')
    .height(120)
  }

  /**
   * 构建树洞条目
   */
  @Builder
  buildTreeHoleItem(item: TreeHoleItem) {
    Column() {
      // 头部信息
      Row() {
        Image($r('app.media.defaultAvatar'))
          .width(35)
          .height(35)
          .borderRadius(20)
          .margin({ right: 10 })

        Column() {
          Text(item.anonymous === 1 ? (item.nickName || `用户${item.userId}`) : item.realName)
            .fontSize(15)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 12 })

      // 内容
      Text(item.content)
        .fontSize(16)
        .fontColor('#333333')
        .lineHeight(24)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ bottom: 15, left: 10, right: 10 })

      // 底部信息
      Row() {
        Text(item.createAt.replace('T', ' '))
          .fontSize(12)
          .fontColor('#A0ADCA')

        Blank()

        // 评论
        Row() {
          Image($r('app.media.startIcon'))
            .width(16)
            .height(16)
            .margin({ right: 4 })

          Text(item.replies.toString())
            .fontSize(12)
            .fontColor('#A0ADCA')
        }
        .margin({ right: 15 })

        // 点赞
        Row() {
          Image(item.isLike === 1 ? $r('app.media.homeActive') : $r('app.media.home'))
            .width(16)
            .height(16)
            .margin({ right: 4 })

          Text(item.likes.toString())
            .fontSize(12)
            .fontColor(item.isLike === 1 ? '#E8311A' : '#A0ADCA')
        }
        .onClick(() => {
          this.handleLikeClick(item);
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  // ===== 事件处理方法 =====

  /**
   * 检查登录状态
   */
  private checkLoginStatus(): void {
    // 暂时设为false，待登录功能实现后更新
    this.isLoggedIn = false;
    console.info(`🌳 [TreeHolePage] 登录状态: ${this.isLoggedIn}`);
  }

  /**
   * 加载树洞列表
   * @param reset 是否重置列表
   */
  private async loadTreeHoleList(reset: boolean = false): Promise<void> {
    try {
      this.isLoading = true;

      if (reset) {
        this.currentPage = 1;
        this.treeHoleList = [];
      }

      // 先加载置顶内容（仅第一页）
      if (this.currentPage === 1) {
        const topData = await this.treeHoleApiService.getTreeHoleList(1, 3, 4);
        this.treeHoleList = topData?.list || [];
      }

      // 加载普通内容
      const normalData = await this.treeHoleApiService.getTreeHoleList(this.currentPage, this.pageSize, 1);

      if (reset) {
        this.treeHoleList = [...(this.treeHoleList || []), ...(normalData?.list || [])];
      } else {
        this.treeHoleList = [...(this.treeHoleList || []), ...(normalData?.list || [])];
      }

      this.hasMore = normalData?.hasNext || false;

      console.info(`🌳 [TreeHolePage] 加载完成，当前${this.treeHoleList?.length || 0}条数据`);
    } catch (error) {
      console.error('🌳 [TreeHolePage] 加载树洞列表失败:', error);
      // 确保在出错时数组仍然有效
      if (!this.treeHoleList) {
        this.treeHoleList = [];
      }
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  /**
   * 加载更多数据
   */
  private async loadMoreData(): Promise<void> {
    if (this.hasMore && !this.isLoading) {
      this.currentPage++;
      await this.loadTreeHoleList(false);
    }
  }

  /**
   * 处理下拉刷新
   */
  private async handleRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadTreeHoleList(true);
  }

  /**
   * 处理发布按钮点击
   */
  private handlePostClick(): void {
    if (!this.isLoggedIn) {
      this.showLoginRequiredToast();
      return;
    }

    console.info('🌳 [TreeHolePage] 跳转到发布页面');
    // this.pathStack.pushPathByName('TreeHolePostPage', null);
  }

  /**
   * 处理树洞项点击
   */
  private handleItemClick(item: TreeHoleItem): void {
    if (!this.isLoggedIn) {
      this.showLoginRequiredToast();
      return;
    }

    console.info(`🌳 [TreeHolePage] 查看树洞详情 ID:${item.id}`);
    // this.pathStack.pushPathByName('TreeHoleDetailPage', item);
  }

  /**
   * 处理点赞点击
   */
  private async handleLikeClick(item: TreeHoleItem): Promise<void> {
    if (!this.isLoggedIn) {
      this.showLoginRequiredToast();
      return;
    }

    try {
      const newIsLiked = item.isLike !== 1;
      const result = await this.treeHoleApiService.toggleLike(item.id, newIsLiked);

      if (result.code === 200) {
        // 更新本地状态
        const index = this.treeHoleList.findIndex(treeHole => treeHole.id === item.id);
        if (index >= 0) {
          this.treeHoleList[index].isLike = newIsLiked ? 1 : 0;
          this.treeHoleList[index].likes += newIsLiked ? 1 : -1;
        }
        console.info(`🌳 [TreeHolePage] ${newIsLiked ? '点赞' : '取消点赞'}成功`);
      }
    } catch (error) {
      console.error('🌳 [TreeHolePage] 点赞操作失败:', error);
    }
  }

  /**
   * 显示需要登录的提示
   */
  private showLoginRequiredToast(): void {
    // 显示登录提示和登录按钮
    this.getUIContext().showAlertDialog({
      title: '需要登录',
      message: '请先登录后再使用此功能',
      primaryButton: {
        value: '暂不登录',
        action: () => {
          console.info('🌳 [TreeHolePage] 用户取消登录');
        }
      },
      secondaryButton: {
        value: '去登录',
        action: () => {
          console.info('🌳 [TreeHolePage] 用户选择去登录');
          // TODO: 跳转到登录页面
        }
      }
    });
  }
}