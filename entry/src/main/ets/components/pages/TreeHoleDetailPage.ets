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
            .width('100%')
            .padding(16)
          }
          .layoutWeight(1)
          
          // 评论输入框
          this.buildCommentInput()
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
    }
    .title('树洞详情')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }

  @Builder
  private buildTitleBar() {
    Row() {
      Button('返回')
        .onClick(() => {
          this.pathStack.pop()
        })
        .backgroundColor('#F5F5F5')
        .fontColor('#333333')
        
      Blank()
      
      Text('树洞详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        
      Blank()
      
      // 占位
      Row() {}
      .width(60)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private buildTreeHoleDetail() {
    if (this.treeHoleItem) {
      Column() {
        // 日期信息
        Row() {
          Column() {
            Text(this.treeHoleItem.createAt.substring(8, 10))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            
            Text(this.treeHoleItem.createAt.substring(0, 7))
              .fontSize(12)
              .fontColor('#999999')
            
            Text(this.treeHoleItem.createAt.substring(11))
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 15 })
          
          // 倒计时功能暂时移除，因新数据结构中没有countdown字段
          // if (this.treeHoleItem.countdown) {
          //   Text(this.treeHoleItem.countdown)
          //     .fontSize(12)
          //     .fontColor('#A0ADCA')
          //     .layoutWeight(1)
          //     .textAlign(TextAlign.End)
          // }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 12 })

        // 作者信息
        Row() {
          Image(this.treeHoleItem.avatar || $r('app.media.defaultAvatar'))
            .width(30)
            .height(30)
            .borderRadius(15)
            .margin({ right: 10 })
          
          Text(this.treeHoleItem.anonymous === 1 ? (this.treeHoleItem.nickName || `用户${this.treeHoleItem.userId}`) : this.treeHoleItem.realName)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 内容
        Text(this.treeHoleItem.content)
          .fontSize(16)
          .fontColor('#333333')
          .lineHeight(24)
          .width('100%')
          .margin({ top: 15, bottom: 15 })

        // 底部操作栏
        Row() {
          Text(`创建时间: ${this.treeHoleItem.createAt}`)
            .fontSize(12)
            .fontColor('#A0ADCA')
            .margin({ left: 10, top: 2 })
        
          Blank()
        
          Text(`赞 ${this.treeHoleItem.likes}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ top: 12, bottom: 12 })
        .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 8, bottomRight: 8 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 16 })
    }
  }

  @Builder
  private buildCommentsHeader() {
    Row() {
      Text(`评论 (${this.commentsList.length})`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
    }
    .width('100%')
    .margin({ top: 8, bottom: 12 })
  }

  @Builder
  private buildCommentsList() {
    if (this.commentsList.length === 0) {
      Column() {
        Text('暂无评论，快来抢沙发吧~')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center)
    } else {
      Column() {
        ForEach(this.commentsList, (comment: TreeHoleComment) => {
          this.buildCommentItem(comment)
        }, (comment: TreeHoleComment) => comment.id.toString())
      }
      .width('100%')
    }
  }

  @Builder
  private buildCommentItem(comment: TreeHoleComment) {
    Column() {
      Row() {
        Image(comment.avatar || $r('app.media.defaultAvatar'))
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

      Text(comment.content)
        .fontSize(14)
        .fontColor('#333333')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 8, bottom: 8 })

      // 底部操作
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
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  private buildCommentInput() {
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
  private buildLoadingState() {
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

  // ===== 事件处理方法 =====

  /**
   * 加载评论数据
   */
  private async loadComments(): Promise<void> {
    try {
      this.isLoading = true;
      console.info(`🌳 [TreeHoleDetailPage] 开始加载树洞 ${this.treeHoleId} 的评论`);
      
      const commentsData = await this.treeHoleApiService.getTreeHoleComments(this.treeHoleId, 1, 50);
      this.commentsList = commentsData.list;
      
      console.info(`🌳 [TreeHoleDetailPage] 加载了 ${commentsData.list.length} 条评论`);
    } catch (error) {
      console.error('🌳 [TreeHoleDetailPage] 加载评论失败:', error);
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
      console.info('🌳 [TreeHoleDetailPage] 发送评论');
      
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
      console.error('🌳 [TreeHoleDetailPage] 发送评论失败:', error);
    } finally {
      this.isCommenting = false;
    }
  }

  /**
   * 处理评论点赞
   */
  private async handleCommentLike(comment: TreeHoleComment): Promise<void> {
    try {
      console.info(`🌳 [TreeHoleDetailPage] 点赞评论 ${comment.id}`);
      
      const newIsLiked = !comment.isLiked;
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
      console.error('🌳 [TreeHoleDetailPage] 评论点赞失败:', error);
    }
  }

  /**
   * 处理评论点踩
   */
  private async handleCommentDislike(comment: TreeHoleComment): Promise<void> {
    try {
      console.info(`🌳 [TreeHoleDetailPage] 点踩评论 ${comment.id}`);
      
      const newIsDisliked = !comment.isDisliked;
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
      console.error('🌳 [TreeHoleDetailPage] 评论点踩失败:', error);
    }
  }

  /**
   * 设置树洞数据
   */
  public setTreeHoleItem(item: TreeHoleItem): void {
    this.treeHoleItem = item;
    this.treeHoleId = item.id;
    console.info(`🌳 [TreeHoleDetailPage] 设置树洞数据，ID: ${item.id}`);
  }
}