/**
 * 树洞详情页面导航组件
 * 参考MainTabNavPage的结构，将TreeHoleDetailPage直接集成
 */
import { TreeHoleComment, TreeHoleItem } from '../models/TreeHoleModels';
import { TreeHoleApiService } from '../services/api/TreeHoleApiService';
import { LoginApiService } from '../services/api/LoginApiService';
import { curves } from '@kit.ArkUI';
import { API_CONFIG } from '../common/constants/AppConstants';

@Builder
export function TreeHoleDetailNavPageBuilder() {
  TreeHoleDetailNavPage();
}

@Component
struct TreeHoleDetailNavPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private treeHoleItem: TreeHoleItem | null = null;
  @State private commentsList: TreeHoleComment[] = [];
  @State private isLoading: boolean = false;
  @State private commentText: string = '';
  @State private isCommenting: boolean = false;
  @State private isLoggedIn: boolean = false;
  @State private pageOpacity: number = 0; // 页面初始透明度为0
  @State private pageTranslateY: number = 30; // 页面初始向下偏移30px
  @State private transitionEffect: TransitionEffect = TransitionEffect.IDENTITY;
  // 接收参数
  private treeHoleId: number = 0;
  private treeHoleApiService: TreeHoleApiService = TreeHoleApiService.getInstance();
  private loginService: LoginApiService = LoginApiService.getInstance();

  aboutToAppear(): void {
    console.info('🌳 [TreeHoleDetailNavPage] 页面初始化');
    this.checkLoginStatus();
    this.startFadeInAnimation();
  }

  /**
   * 检查登录状态
   */
  private checkLoginStatus(): void {
    this.isLoggedIn = this.loginService.isLoggedIn();
    console.info(`🌳 [TreeHoleDetailNavPage] 登录状态: ${this.isLoggedIn}`);
  }

  /**
   * 启动渐显动画
   */
  private startFadeInAnimation(): void {
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslateY = 0;
      console.info('[TreeHoleDetailNavPage] 🎬 启动渐显动画');
    }, 100);
  }

  @Builder
  buildTitleBar() {
    Row() {
      Button('返回')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 设置返回转场效果
          this.transitionEffect = TransitionEffect.IDENTITY;
          this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 342, 38) }, () => {
            this.pathStack.pop(false);
          });
        })

      Text('树洞详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位
      Row() {
      }
      .width(60)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildTreeHoleDetail() {
    if (this.treeHoleItem) {
      Column() {
        // 顶部日期和时间信息
        Row() {
          // 大号日期显示
          Column() {
            Text(this.treeHoleItem.createAt.substring(8, 10))
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#45CAD9')
              .lineHeight(36)

            Text(this.treeHoleItem.createAt.substring(0, 7))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 })

            Text(this.treeHoleItem.createAt.substring(11, 19))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 20 })

          // 销毁倒计时（如果有的话）
          if (this.treeHoleItem.deleteTime) {
            Column() {
              Text('⏰ 销毁倒计时')
                .fontSize(10)
                .fontColor('#FF6B6B')
              Text(this.formatDeleteTime())
                .fontSize(12)
                .fontColor('#FF6B6B')
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 16 })

        // 帖子内容
        Text(this.treeHoleItem.content)
          .fontSize(16)
          .fontColor('#333333')
          .lineHeight(24)
          .width('100%')
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Start)
          .geometryTransition(`content_${this.treeHoleItem.id}`, { follow: true })

        // 作者信息
        Row() {
          Image(this.treeHoleItem.avatar ? `${API_CONFIG.BASE_URL}${this.treeHoleItem.avatar}` : $r('app.media.defaultAvatar'))
            .width(32)
            .height(32)
            .borderRadius(16)
            .margin({ right: 12 })
            .geometryTransition(`avatar_${this.treeHoleItem.id}`, { follow: true })

          Column() {
            Text(this.treeHoleItem.anonymous === 1 ?
              (this.treeHoleItem.nickName || `匿名用户${this.treeHoleItem.userId}`) :
            this.treeHoleItem.realName)
              .fontSize(14)
              .fontColor('#666666')
              .fontWeight(FontWeight.Medium)
              .geometryTransition(`author_${this.treeHoleItem.id}`, { follow: true })

            Text(this.treeHoleItem.anonymous === 1 ? '匿名发布' : '实名发布')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 16 })

        // 底部统计和操作栏
        Row() {
          // 统计信息
          Row() {
            Image($r('app.media.comment'))
              .width(16)
              .height(16)
              .margin({ right: 8 })
            Text(`${this.treeHoleItem.replies}`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .geometryTransition(`comment_${this.treeHoleItem.id}`, { follow: true })

          Blank()

          // 点赞操作
          Row() {
            Image(this.treeHoleItem.isLike === 1 ?$r('app.media.like_active'):$r('app.media.like'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
              .fillColor(this.treeHoleItem.isLike === 1 ? '#FF6B6B' : '#999999')

            Text(this.treeHoleItem.likes.toString())
              .fontSize(14)
              .fontColor(this.treeHoleItem.isLike === 1 ? '#FF6B6B' : '#666666')
          }
          .padding({
            left: 8,
            right: 8,
            top: 6,
            bottom: 6
          })
          .borderRadius(12)
          .backgroundColor(this.treeHoleItem.isLike === 1 ? '#FFF0F0' : '#F5F5F5')
          .geometryTransition(`like_${this.treeHoleItem.id}`, { follow: true })
          .onClick(() => {
            this.handleLikeClick();
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ bottom: 16 })
      .shadow({
        radius: 8,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 2
      })
    }
  }

  @Builder
  buildCommentsHeader() {
    Row() {
      Image($r('app.media.comment'))
        .width(16)
        .height(16)
        .margin({ right: 8 })
      Text(`评论`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text(`(${this.commentsList.length})`)
        .fontSize(16)
        .fontColor('#999999')
        .margin({ left: 6 })

      Blank()

      // 排序按钮
      Text('按时间排序')
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
  }

  @Builder
  buildCommentsList() {
    if (this.commentsList.length === 0) {
      Column() {
        Text('暂无评论，快来抢沙发吧~')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 20 })
    } else {
      Column() {
        ForEach(this.commentsList, (comment: TreeHoleComment) => {
          this.buildCommentItem(comment)
        }, (comment: TreeHoleComment) => comment.id.toString())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  buildCommentItem(comment: TreeHoleComment) {
    Column() {
      Row() {
        Image(comment.avatar ? `${API_CONFIG.BASE_URL}${comment.avatar}` : $r('app.media.defaultAvatar'))
          .width(36)
          .height(36)
          .borderRadius(18)
          .margin({ right: 12 })

        Column() {
          Text(comment.author)
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)

          Text(this.formatCommentTime(comment.createTime))
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 3 })
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 匿名标识
        if (comment.isAnonymous) {
          Text('匿名')
            .fontSize(10)
            .fontColor('#999999')
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 评论内容
      Text(comment.content)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(12)
    .borderWidth(1)
    .borderColor('#E8E8E8')
    .margin({ bottom: 12 })
    .shadow({
      radius: 6,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildCommentInput() {
    Row() {
      TextInput({ placeholder: '写下你的评论...', text: this.commentText })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.commentText = value;
        })
        .onSubmit(() => {
          this.handleSendComment();
        })
        .enabled(!this.isCommenting)

      if (this.commentText.trim().length > 0) {
        Button('发送')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .height(40)
          .width(60)
          .margin({ left: 12 })
          .enabled(!this.isCommenting)
          .onClick(() => {
            this.handleSendComment();
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderColor('#E5E5E5')
    .borderWidth({ top: 1 })
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color('#007AFF')
        .margin({ bottom: 16 })

      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildLoginPrompt() {
    Row() {
      Text('登录后可参与评论和点赞互动')
        .fontSize(14)
        .fontColor('#999999')

      Blank()

      Button('去登录')
        .fontSize(14)
        .fontColor('#45CAD9')
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor('#45CAD9')
        .borderRadius(16)
        .padding({
          left: 16,
          right: 16,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          // 可以在这里添加跳转到登录页面的逻辑
          console.info('🌳 [TreeHoleDetailNavPage] 用户点击去登录');
        })
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor('#F8F9FA')
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏
        this.buildTitleBar()

        if (this.treeHoleItem) {
          // 主内容区域
          Scroll() {
            Column() {
              // 树洞详情
              this.buildTreeHoleDetail()

              // 评论标题
              this.buildCommentsHeader()

              // 评论列表
              this.buildCommentsList()
            }
            .layoutWeight(1)
            .width('100%')
            .padding(16)
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .align(Alignment.TopStart)

          // 评论输入框（仅登录用户显示）
          if (this.isLoggedIn) {
            this.buildCommentInput()
          } else {
            this.buildLoginPrompt()
          }
        } else if (this.isLoading) {
          // 加载状态
          this.buildLoadingState()
        } else {
          // 空状态
          Column() {
            Text('未找到树洞信息')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .opacity(this.pageOpacity)
      .translate({ x: 0, y: this.pageTranslateY })
      .animation({
        duration: 700,
        curve: Curve.EaseInOut,
        iterations: 1,
        playMode: PlayMode.Normal
      })
    }
    .title('树洞详情')
    .hideTitleBar(true)
    .transition(this.transitionEffect)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;

      // 接收页面参数
      const params = ctx.pathInfo.param as TreeHoleItem;
      if (params) {
        console.info('🌳 [TreeHoleDetailNavPage] 接收到参数:', JSON.stringify(params));
        this.treeHoleItem = params;
        this.treeHoleId = params.id;
        this.loadComments();
      } else {
        console.error('🌳 [TreeHoleDetailNavPage] 未接收到树洞数据');
      }

      console.info('🌳 [TreeHoleDetailNavPage] 页面就绪');
    })
    .onBackPressed(() => {
      // 设置返回转场效果
      this.transitionEffect = TransitionEffect.IDENTITY;
      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 342, 38) }, () => {
        this.pathStack.pop(false);
      });
      return true;
    })
  }

  // ===== 事件处理方法 =====

  /**
   * 加载评论数据
   */
  private async loadComments(): Promise<void> {
    try {
      this.isLoading = true;
      console.info(`🌳 [TreeHoleDetailNavPage] 开始加载树洞 ${this.treeHoleId} 的评论`);

      const commentsData = await this.treeHoleApiService.getTreeHoleComments(this.treeHoleId, 1, 50);
      this.commentsList = commentsData.list;

      console.info(`🌳 [TreeHoleDetailNavPage] 加载了 ${commentsData.list.length} 条评论`);
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 加载评论失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 发送评论
   */
  private async handleSendComment(): Promise<void> {
    if (this.commentText.trim().length === 0) {
      return;
    }

    try {
      this.isCommenting = true;
      console.info('🌳 [TreeHoleDetailNavPage] 发送评论');

      const result = await this.treeHoleApiService.postComment({
        treeHoleId: this.treeHoleId,
        content: this.commentText.trim(),
        isAnonymous: false
      });

      if (result.code === 200) {
        this.commentText = '';
        // 重新加载评论
        await this.loadComments();
      }
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 发送评论失败:', error);
    } finally {
      this.isCommenting = false;
    }
  }

  /**
   * 处理评论点赞
   */
  private async handleCommentLike(comment: TreeHoleComment): Promise<void> {
    try {
      console.info(`🌳 [TreeHoleDetailNavPage] 点赞评论 ${comment.id}`);

      const newIsLiked = !(comment.isLiked ?? false);
      const result = await this.treeHoleApiService.toggleCommentLike(comment.id, newIsLiked);

      if (result.code === 200) {
        // 更新本地状态
        const index = this.commentsList.findIndex(c => c.id === comment.id);
        if (index >= 0) {
          this.commentsList[index].isLiked = newIsLiked;
          this.commentsList[index].likeCount += newIsLiked ? 1 : -1;
        }
      }
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 评论点赞失败:', error);
    }
  }

  /**
   * 处理评论点踩
   */
  private async handleCommentDislike(comment: TreeHoleComment): Promise<void> {
    try {
      console.info(`🌳 [TreeHoleDetailNavPage] 点踩评论 ${comment.id}`);

      const newIsDisliked = !(comment.isDisliked ?? false);
      const result = await this.treeHoleApiService.toggleCommentDislike(comment.id, newIsDisliked);

      if (result.code === 200) {
        // 更新本地状态
        const index = this.commentsList.findIndex(c => c.id === comment.id);
        if (index >= 0) {
          this.commentsList[index].isDisliked = newIsDisliked;
          this.commentsList[index].dislikeCount += newIsDisliked ? 1 : -1;
        }
      }
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 评论点踩失败:', error);
    }
  }

  /**
   * 格式化评论时间
   */
  private formatCommentTime(timeStr: string): string {
    try {
      const commentTime = new Date(timeStr).getTime();
      const currentTime = new Date().getTime();
      const timeDiff = currentTime - commentTime;

      const minutes = Math.floor(timeDiff / (1000 * 60));
      const hours = Math.floor(timeDiff / (1000 * 60 * 60));
      const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24));

      if (minutes < 1) {
        return '刚刚';
      } else if (minutes < 60) {
        return `${minutes}分钟前`;
      } else if (hours < 24) {
        return `${hours}小时前`;
      } else if (days < 7) {
        return `${days}天前`;
      } else {
        return timeStr.substring(5, 16); // 显示月-日 时:分
      }
    } catch (error) {
      return timeStr;
    }
  }

  /**
   * 格式化销毁时间
   */
  private formatDeleteTime(): string {
    if (!this.treeHoleItem?.deleteTime) {
      return '';
    }

    try {
      const deleteTime = new Date(this.treeHoleItem.deleteTime).getTime();
      const currentTime = new Date().getTime();
      const timeDiff = deleteTime - currentTime;

      if (timeDiff <= 0) {
        return '已销毁';
      }

      const hours = Math.floor(timeDiff / (1000 * 60 * 60));
      const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));

      if (hours > 0) {
        return `${hours}小时${minutes}分钟后销毁`;
      } else {
        return `${minutes}分钟后销毁`;
      }
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 格式化销毁时间失败:', error);
      return '时间错误';
    }
  }

  /**
   * 处理帖子点赞点击
   */
  private handleLikeClick(): void {
    if (!this.isLoggedIn) {
      this.showLoginRequiredDialog();
      return;
    }

    // 实现点赞逻辑
    console.info('🌳 [TreeHoleDetailNavPage] 处理帖子点赞');
    // TODO: 调用API接口
  }

  /**
   * 显示需要登录的对话框
   */
  private showLoginRequiredDialog(): void {
    AlertDialog.show({
      title: '需要登录',
      message: '点赞和评论功能需要登录后才能使用',
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('🌳 [TreeHoleDetailNavPage] 用户取消登录');
        }
      },
      secondaryButton: {
        value: '去登录',
        fontColor: '#45CAD9',
        action: () => {
          console.info('🌳 [TreeHoleDetailNavPage] 用户选择去登录');
          // TODO: 跳转到登录页面或切换到登录Tab
        }
      }
    });
  }

  /**
   * 设置树洞数据
   */
  public setTreeHoleItem(item: TreeHoleItem): void {
    this.treeHoleItem = item;
    this.treeHoleId = item.id;
    console.info(`🌳 [TreeHoleDetailNavPage] 设置树洞数据，ID: ${item.id}`);
  }
}