/**
 * 树洞详情页面导航组件
 * 参考MainTabNavPage的结构，将TreeHoleDetailPage直接集成
 */
import { TreeHoleComment, TreeHoleItem, PostTreeHoleRequest, TreeHolePicture } from '../models/TreeHoleModels';
import { TreeHoleApiService } from '../services/api/TreeHoleApiService';
import { curves } from '@kit.ArkUI';
import { API_CONFIG } from '../common/constants/AppConstants';
import { TreeHoleImageGrid, ImageClickCallback } from '../components/base/TreeHoleImageGrid';
import { ImagePreviewDialog, ImagePreviewCloseCallback } from '../components/base/ImagePreviewDialog';

@Builder
export function TreeHoleDetailNavPageBuilder() {
  TreeHoleDetailNavPage();
}

@Component
struct TreeHoleDetailNavPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @StorageLink('loginStatusChanged') @Watch('onLoginStatusChanged') loginStatusChanged: number = 0;
  @State private treeHoleItem: TreeHoleItem | null = null;
  @State private commentsList: TreeHoleComment[] = [];
  @State private isLoading: boolean = false;
  @State private commentText: string = '';
  @State private isCommenting: boolean = false;
  @State private isLoggedIn: boolean = false;
  @State private pageOpacity: number = 0; // 页面初始透明度为0
  @State private pageTranslateY: number = 30; // 页面初始向下偏移30px
  @State private transitionEffect: TransitionEffect = TransitionEffect.IDENTITY;
  // 图片预览相关状态
  @State private imagePreviewVisible: boolean = false;
  @State private previewImages: string[] = [];
  @State private previewCurrentIndex: number = 0;
  // 接收参数
  private treeHoleId: number = 0;
  private treeHoleApiService: TreeHoleApiService = TreeHoleApiService.getInstance();

  aboutToAppear(): void {
    console.info('🌳 [TreeHoleDetailNavPage] 页面初始化');
    this.checkLoginStatus();
    this.startFadeInAnimation();
  }

  onPageShow(): void {
    console.info('🌳 [TreeHoleDetailNavPage] 页面显示');
    // 每次页面显示时刷新登录状态
    this.checkLoginStatusAsync();
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
              .fontColor($r('app.color.schedule_primary_color'))
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

        // 图片展示区域
        if (this.treeHoleItem.images && this.treeHoleItem.images.length > 0) {
          TreeHoleImageGrid({
            images: this.treeHoleItem.images,
            onImageClick: new ImageClickCallback((imageUrl: string, imageIndex: number, allImages: string[]) => this.handleImageClick(imageUrl, imageIndex, allImages)),
            imageBorderRadius: 12
          })
        }

        // 作者信息
        Row() {
          Image(this.treeHoleItem.avatar ? `${API_CONFIG.BASE_URL}${this.treeHoleItem.avatar}` :
          $r('app.media.defaultAvatar'))
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
            Image(this.treeHoleItem.isLike === 1 ? $r('app.media.like_active') : $r('app.media.like'))
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
    Column() {
      // 字数统计提示（添加动画效果）
      Row() {
        Blank()
        Text(`${this.commentText.length}/500`)
          .fontSize(12)
          .fontColor(this.commentText.length > 500 ? '#FF6B6B' : '#999999')
      }
      .width('100%')
      .height(this.commentText.length > 0 ? 32 : 0) // 动态高度
      .opacity(this.commentText.length > 0 ? 1 : 0) // 动态透明度
      .padding({ 
        left: 16, 
        right: 16, 
        bottom: this.commentText.length > 0 ? 8 : 0 // 动态内边距
      })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut,
        iterations: 1,
        playMode: PlayMode.Normal
      }) // 添加动画效果

      // 输入框和发送按钮
      Row() {
        TextInput({ placeholder: '写下你的评论...', text: this.commentText })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .borderWidth(this.commentText.length > 500 ? 1 : 0)
          .borderColor(this.commentText.length > 500 ? '#FF6B6B' : 'transparent')
          .onChange((value: string) => {
            this.commentText = value;
          })
          .onSubmit(() => {
            this.handleSendComment();
          })
          .enabled(!this.isCommenting)

        if (this.commentText.trim().length > 0) {
          if (this.isCommenting) {
            // 发送中状态
            Row() {
              LoadingProgress()
                .width(16)
                .height(16)
                .color($r('app.color.schedule_primary_color'))
                .margin({ right: 4 })
              Text('发送中...')
                .fontSize(12)
                .fontColor($r('app.color.schedule_primary_color'))
            }
            .height(40)
            .padding({ left: 12, right: 12 })
            .borderRadius(20)
            .backgroundColor($r('app.color.schedule_primary_light'))
            .margin({ left: 12 })
            .transition({
              type: TransitionType.Insert,
              opacity: 1,
              translate: { x: 0, y: 0 }
            })
            .transition({
              type: TransitionType.Delete,
              opacity: 0,
              translate: { x: 20, y: 0 }
            })
          } else {
            // 正常发送按钮
            Button('发送')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor(this.commentText.length > 500 ? '#CCCCCC' : $r('app.color.schedule_primary_color'))
              .borderRadius(20)
              .height(40)
              .width(60)
              .margin({ left: 12 })
              .enabled(!this.isCommenting && this.commentText.length <= 500)
              .onClick(() => {
                this.handleSendComment();
              })
              .transition({
                type: TransitionType.Insert,
                opacity: 1,
                translate: { x: 0, y: 0 }
              })
              .transition({
                type: TransitionType.Delete,
                opacity: 0,
                translate: { x: 20, y: 0 }
              })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    // 完全移除顶部边框，使用阴影替代分隔效果
    .shadow({
      radius: 4,
      color: '#10000000',
      offsetX: 0,
      offsetY: -2
    })
    .padding({ top: 16 }) // 增加顶部内边距
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
        .fontColor($r('app.color.schedule_primary_color'))
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor($r('app.color.schedule_primary_color'))
        .borderRadius(16)
        .padding({
          left: 16,
          right: 16,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          // 跳转到登录页面
          console.info('🌳 [TreeHoleDetailNavPage] 用户点击去登录');
          try {
            this.pathStack.pushPathByName('LoginNavPage', null);
          } catch (error) {
            console.error('🌳 [TreeHoleDetailNavPage] 跳转登录页面失败:', error);
          }
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

      // 图片预览对话框
      if (this.imagePreviewVisible) {
        ImagePreviewDialog({
          isVisible: this.imagePreviewVisible,
          images: this.previewImages,
          currentIndex: this.previewCurrentIndex,
          onClose: new ImagePreviewCloseCallback(() => this.handleImagePreviewClose())
        })
      }
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
        // 并行加载评论和图片数据
        this.loadComments();
        this.loadImages();
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

  /**
   * 设置树洞数据
   */
  public setTreeHoleItem(item: TreeHoleItem): void {
    this.treeHoleItem = item;
    this.treeHoleId = item.id;
    console.info(`🌳 [TreeHoleDetailNavPage] 设置树洞数据，ID: ${item.id}`);
  }

  /**
   * 检查登录状态
   */
  private checkLoginStatus(): void {
    // TODO 重写
  }

  /**
   * 异步检查登录状态
   */
  private async checkLoginStatusAsync(): Promise<void> {
    // TODO 重写
  }

  // ===== 事件处理方法 =====

  /**
   * 监听登录状态变化
   */
  private onLoginStatusChanged(): void {
    console.info(`🌳 [TreeHoleDetailNavPage] 收到登录状态变化通知: ${this.loginStatusChanged}`);
    // 登录状态变化时重新检查
    this.checkLoginStatusAsync();
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
   * 加载树洞图片数据
   */
  private async loadImages(): Promise<void> {
    try {
      console.info(`🌳 [TreeHoleDetailNavPage] 开始加载树洞 ${this.treeHoleId} 的图片`);

      const pictures = await this.treeHoleApiService.getPictures(this.treeHoleId);
      
      // 转换图片URL，添加baseUrl前缀（参考class-schedule-c实现）
      const imageUrls = pictures.map(item => `${API_CONFIG.BASE_URL}${item.url}`);
      
      // 更新树洞项目的图片数据
      if (this.treeHoleItem) {
        this.treeHoleItem.images = imageUrls;
      }

      console.info(`🌳 [TreeHoleDetailNavPage] 加载了 ${imageUrls.length} 张图片:`, imageUrls);
    } catch (error) {
      console.error('🌳 [TreeHoleDetailNavPage] 加载图片失败:', error);
      // 图片加载失败不影响主要功能，设置空数组
      if (this.treeHoleItem) {
        this.treeHoleItem.images = [];
      }
    }
  }

  /**
   * 发送评论
   */
  private async handleSendComment(): Promise<void> {
    // TODO 重写
  }

  /**
   * 处理评论点赞
   */
  private async handleCommentLike(comment: TreeHoleComment): Promise<void> {
    // TODO 重写
  }

  /**
   * 处理评论点踩
   */
  private async handleCommentDislike(comment: TreeHoleComment): Promise<void> {
    // TODO 重写
  }

  /**
   * 格式化评论时间
   */
  private formatCommentTime(timeStr: string): string {
    // TODO 重写
    return "";
  }

  /**
   * 格式化销毁时间
   */
  private formatDeleteTime(): string {
    // TODO 重写
    return ""
  }

  /**
   * 处理帖子点赞点击
   */
  private handleLikeClick(): void {
    // TODO 重写
  }

  /**
   * 处理图片点击事件
   */
  private handleImageClick(imageUrl: string, imageIndex: number, allImages: string[]): void {
    console.info(`🖼️ [TreeHoleDetailNavPage] 点击图片: ${imageIndex}, URL: ${imageUrl}`);
    
    this.previewImages = allImages;
    this.previewCurrentIndex = imageIndex;
    this.imagePreviewVisible = true;
  }

  /**
   * 处理图片预览关闭事件
   */
  private handleImagePreviewClose(): void {
    console.info('🖼️ [TreeHoleDetailNavPage] 关闭图片预览');
    this.imagePreviewVisible = false;
    this.previewImages = [];
    this.previewCurrentIndex = 0;
  }

  /**
   * 显示Toast提示
   */
  private showToast(message: string): void {
    this.getUIContext().showAlertDialog({
      message: message,
      alignment: DialogAlignment.Center,
      autoCancel: true,
      primaryButton: {
        value: '确定',
        action: () => {
          console.info('🌳 [TreeHoleDetailNavPage] Toast确认');
        }
      }
    });
  }

  /**
   * 显示需要登录的对话框
   */
  private showLoginRequiredDialog(): void {
    this.getUIContext().showAlertDialog({
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
        fontColor: $r('app.color.schedule_primary_color'),
        action: () => {
          console.info('🌳 [TreeHoleDetailNavPage] 用户选择去登录');
          // 跳转到登录页面
          try {
            this.pathStack.pushPathByName('LoginNavPage', null);
          } catch (error) {
            console.error('🌳 [TreeHoleDetailNavPage] 跳转登录页面失败:', error);
          }
        }
      }
    });
  }
}