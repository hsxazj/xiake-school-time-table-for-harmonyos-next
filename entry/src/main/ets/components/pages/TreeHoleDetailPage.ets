/**
 * 树洞详情页面组件
 * 显示树洞内容和评论，支持发布评论
 */
import { TreeHoleItem, TreeHoleComment, TreeHolePaginationData } from '../../models/TreeHoleModels';
import { TreeHoleApiService } from '../../services/api/TreeHoleApiService';

@Builder
export function TreeHoleDetailPageBuilder() {
  TreeHoleDetailPage();
}

@Component
export struct TreeHoleDetailPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private treeHoleItem: TreeHoleItem | null = null;
  @State private commentsList: TreeHoleComment[] = [];
  @State private isLoading: boolean = false;
  @State private commentText: string = '';
  @State private isCommenting: boolean = false;
  
  // 接收参数
  private treeHoleId: number = 0;
  private treeHoleApiService: TreeHoleApiService = TreeHoleApiService.getInstance();

  aboutToAppear(): void {
    console.info('🌳 [TreeHoleDetailPage] 页面初始化');
    if (this.treeHoleId > 0) {
      this.loadComments();
    }
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
          }
          .layoutWeight(1)
          
          // 底部评论输入框
          this.buildCommentInput()
        } else {
          // 加载状态或错误状态
          this.buildLoadingState()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
    }
    .title('树洞详情')
    .hideTitleBar(true)
  }

  /**
   * 构建标题栏
   */
  @Builder
  buildTitleBar() {
    Row() {
      Image($r('app.media.startIcon'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.pathStack.pop();
        })
      
      Text('树洞详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 占位，保持标题居中
      Row().width(24).height(24)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建树洞详情
   */
  @Builder
  buildTreeHoleDetail() {
    if (this.treeHoleItem) {
      Column() {
      // 日期信息
      Row() {
        Column() {
          Text(this.treeHoleItem.createTime.substring(8, 10))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          
          Text(this.treeHoleItem.createTime.substring(0, 7))
            .fontSize(12)
            .fontColor('#999999')
          
          Text(this.treeHoleItem.createTime.substring(11))
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 15 })
        
        if (this.treeHoleItem.countdown) {
          Text(this.treeHoleItem.countdown)
            .fontSize(12)
            .fontColor('#A0ADCA')
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 内容文本
      Text(this.treeHoleItem.content)
        .fontSize(16)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
        .margin({ bottom: 20 })

      // 作者信息
      Row() {
        Image($r('app.media.defaultAvatar'))
          .width(30)
          .height(30)
          .borderRadius(15)
          .margin({ right: 10 })
        
        Text(this.treeHoleItem.author)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 10 })
    }
  }

  /**
   * 构建评论标题区域
   */
  @Builder
  buildCommentsHeader() {
    Row() {
      Text(`评论 ${this.commentsList.length}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
      
      // 绿色装饰线
      Row()
        .width(30)
        .height(3)
        .backgroundColor('#3EA5B3')
        .borderRadius(2)
        .margin({ left: 10, top: 2 })
      
      Blank()
      
      if (this.treeHoleItem) {
        Text(`赞 ${this.treeHoleItem.likeCount}`)
          .fontSize(14)
          .fontColor('#666666')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 15, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建评论列表
   */
  @Builder
  buildCommentsList() {
    if (this.commentsList.length === 0) {
      Column() {
        Text('暂无评论')
          .fontSize(14)
          .fontColor('#999999')
          .margin(30)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      Column() {
        ForEach(this.commentsList, (comment: TreeHoleComment, index: number) => {
          this.buildCommentItem(comment)
        }, (comment: TreeHoleComment) => comment.id.toString())
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 80 })
    }
  }

  /**
   * 构建评论项
   */
  @Builder
  buildCommentItem(comment: TreeHoleComment) {
    Column() {
      Row() {
        Image($r('app.media.defaultAvatar'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .margin({ right: 12 })
        
        Column() {
          Text(comment.author)
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
          
          Text(comment.createTime)
            .fontSize(12)
            .fontColor('#A0ADCA')
            .margin({ top: 2 })
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 8 })

      Text(comment.content)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Blank()
        
        // 点踩
        Row() {
          Image($r('app.media.startIcon'))
            .width(14)
            .height(14)
            .margin({ right: 4 })
          
          Text(comment.dislikeCount.toString())
            .fontSize(12)
            .fontColor(comment.isDisliked ? '#1296DB' : '#A0ADCA')
        }
        .margin({ right: 15 })
        .onClick(() => {
          this.handleCommentDislike(comment);
        })
        
        // 点赞
        Row() {
          Image($r('app.media.startIcon'))
            .width(14)
            .height(14)
            .margin({ right: 4 })
          
          Text(comment.likeCount.toString())
            .fontSize(12)
            .fontColor(comment.isLiked ? '#E8311A' : '#A0ADCA')
        }
        .onClick(() => {
          this.handleCommentLike(comment);
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 8 })
  }

  /**
   * 构建评论输入框
   */
  @Builder
  buildCommentInput() {
    Row() {
      TextInput({ 
        placeholder: '说点什么...',
        text: $$this.commentText 
      })
        .layoutWeight(1)
        .fontSize(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .padding({ left: 15, right: 15, top: 8, bottom: 8 })
        .maxLength(200)
        .onFocus(() => {
          this.isCommenting = true;
        })
        .onBlur(() => {
          if (this.commentText.trim() === '') {
            this.isCommenting = false;
          }
        })
      
      if (this.isCommenting || this.commentText.trim() !== '') {
        Button('发送')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#31BFCC')
          .borderRadius(15)
          .padding({ left: 15, right: 15, top: 8, bottom: 8 })
          .margin({ left: 8 })
          .onClick(() => {
            this.handleSendComment();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#E5E5E5' })
  }

  /**
   * 构建加载状态
   */
  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#31BFCC')
        .margin({ bottom: 15 })
      
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  // ===== 事件处理方法 =====

  /**
   * 加载评论数据
   */
  private async loadComments(): Promise<void> {
    try {
      this.isLoading = true;
      console.info(`🌳 [TreeHoleDetailPage] 加载评论 - ID: ${this.treeHoleId}`);
      
      const commentsData = await this.treeHoleApiService.getTreeHoleComments(this.treeHoleId);
      this.commentsList = commentsData.list;
      
      console.info(`🌳 [TreeHoleDetailPage] 加载了 ${this.commentsList.length} 条评论`);
    } catch (error) {
      console.error('🌳 [TreeHoleDetailPage] 加载评论失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 处理发送评论
   */
  private async handleSendComment(): Promise<void> {
    if (this.commentText.trim() === '') {
      return;
    }

    try {
      console.info('🌳 [TreeHoleDetailPage] 发送评论:', this.commentText.substring(0, 20));
      
      const success = await this.treeHoleApiService.postComment({
        treeHoleId: this.treeHoleId,
        content: this.commentText.trim(),
        isAnonymous: false
      });

      if (success) {
        this.commentText = '';
        this.isCommenting = false;
        // 重新加载评论
        await this.loadComments();
        console.info('🌳 [TreeHoleDetailPage] 评论发布成功');
      }
    } catch (error) {
      console.error('🌳 [TreeHoleDetailPage] 发送评论失败:', error);
    }
  }

  /**
   * 处理评论点赞
   */
  private handleCommentLike(comment: TreeHoleComment): void {
    console.info(`🌳 [TreeHoleDetailPage] 评论点赞 ID: ${comment.id}`);
    // TODO: 实现评论点赞逻辑
  }

  /**
   * 处理评论点踩
   */
  private handleCommentDislike(comment: TreeHoleComment): void {
    console.info(`🌳 [TreeHoleDetailPage] 评论点踩 ID: ${comment.id}`);
    // TODO: 实现评论点踩逻辑
  }

  /**
   * 设置树洞数据
   * @param item 树洞项数据
   */
  public setTreeHoleItem(item: TreeHoleItem): void {
    this.treeHoleItem = item;
    this.treeHoleId = item.id;
    console.info(`🌳 [TreeHoleDetailPage] 设置树洞数据 ID: ${item.id}`);
  }
}