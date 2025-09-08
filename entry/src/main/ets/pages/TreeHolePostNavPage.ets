/**
 * 树洞发布页面导航组件
 * 参考MainTabNavPage的结构，将TreeHolePostPage直接集成
 */
import { PostTreeHoleRequest } from '../models/TreeHoleModels';
import { TreeHoleApiService } from '../services/api/TreeHoleApiService';

@Builder
export function TreeHolePostNavPageBuilder() {
  TreeHolePostNavPage();
}

@Component
struct TreeHolePostNavPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private content: string = '';
  @State private isAnonymous: boolean = true;
  @State private isPublishing: boolean = false;
  @State private wordCount: number = 0;
  
  // 配置参数
  private readonly maxLength: number = 500;
  private treeHoleApiService: TreeHoleApiService = TreeHoleApiService.getInstance();

  aboutToAppear(): void {
    console.info('🌳 [TreeHolePostNavPage] 发布页面初始化');
  }

  @Builder
  buildTitleBar() {
    Row() {
      Button('取消')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.handleCancel();
        })
      
      Text('发布树洞')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Button('发布')
        .fontSize(16)
        .fontColor(this.canPublish() ? '#31BFCC' : '#CCCCCC')
        .backgroundColor(Color.Transparent)
        .enabled(this.canPublish())
        .onClick(() => {
          this.handlePublish();
        })
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildContentInput() {
    Column() {
      TextArea({ 
        placeholder: '说点什么...',
        text: $$this.content 
      })
        .width('100%')
        .height(220)
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .maxLength(this.maxLength)
        .onTextSelectionChange((selectionStart: number, selectionEnd: number) => {
          this.updateWordCount();
        })
        .onChange(() => {
          this.updateWordCount();
        })
      
      // 字数统计
      Row() {
        Blank()
        
        Text(`${this.wordCount}/${this.maxLength}`)
          .fontSize(14)
          .fontColor(this.wordCount > this.maxLength * 0.8 ? '#FF6B6B' : '#999999')
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 10 })
  }

  @Builder
  buildAnonymousOption() {
    Row() {
      // 匿名开关
      Row() {
        Image(this.isAnonymous ? $r('app.media.homeActive') : $r('app.media.home'))
          .width(20)
          .height(20)
          .margin({ right: 8 })
        
        Text('匿名发布')
          .fontSize(16)
          .fontColor('#333333')
      }
      .onClick(() => {
        this.isAnonymous = !this.isAnonymous;
      })
      
      Blank()
      
      Text(this.isAnonymous ? '匿名模式' : '实名模式')
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor(Color.White)
    .margin({ left: 16, right: 16, top: 10 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildPublishButton() {
    Button(this.isPublishing ? '发布中...' : '发布树洞')
      .width('100%')
      .height(50)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .backgroundColor(this.canPublish() ? '#31BFCC' : '#CCCCCC')
      .borderRadius(25)
      .margin({ left: 16, right: 16, bottom: 30 })
      .enabled(this.canPublish() && !this.isPublishing)
      .onClick(() => {
        this.handlePublish();
      })
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏
        this.buildTitleBar()
        
        // 主内容区域
        Scroll() {
          Column() {
            this.buildContentInput()
            this.buildAnonymousOption()
          }
        }
        .layoutWeight(1)
        
        // 底部发布按钮
        this.buildPublishButton()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
    }
    .title('发布树洞')
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      console.info('🌳 [TreeHolePostNavPage] 页面就绪');
    })
    .onBackPressed(() => {
      this.handleCancel();
      return true;
    })
  }

  // ===== 辅助方法 =====

  /**
   * 更新字数统计
   */
  private updateWordCount(): void {
    this.wordCount = this.content.length;
  }

  /**
   * 检查是否可以发布
   */
  private canPublish(): boolean {
    return this.content.trim().length > 0 && 
           this.content.length <= this.maxLength && 
           !this.isPublishing;
  }

  // ===== 事件处理方法 =====

  /**
   * 处理取消操作
   */
  private handleCancel(): void {
    if (this.content.trim().length > 0) {
      // 显示确认对话框
      this.getUIContext().showAlertDialog({
        title: '确认退出',
        message: '内容尚未发布，确定要退出吗？',
        primaryButton: {
          value: '继续编辑',
          action: () => {
            // 不做任何操作，继续编辑
          }
        },
        secondaryButton: {
          value: '确认退出',
          action: () => {
            this.pathStack.pop();
          }
        }
      });
    } else {
      this.pathStack.pop();
    }
  }

  /**
   * 处理发布操作
   */
  private async handlePublish(): Promise<void> {
    if (!this.canPublish()) {
      return;
    }

    try {
      this.isPublishing = true;
      
      const request: PostTreeHoleRequest = {
        content: this.content.trim(),
        isAnonymous: this.isAnonymous
      };

      console.info('🌳 [TreeHolePostNavPage] 开始发布树洞');
      const result = await this.treeHoleApiService.postTreeHole(request);

      if (result.code === 200) {
        console.info('🌳 [TreeHolePostNavPage] 发布成功');
        
        // 显示成功提示
        this.getUIContext().showAlertDialog({
          title: '发布成功',
          message: this.isAnonymous ? '内容已提交，等待管理员审核' : '发布成功！',
          primaryButton: {
            value: '确定',
            action: () => {
              // 返回树洞列表页面
              this.pathStack.pop();
            }
          }
        });
      } else {
        this.showErrorDialog('发布失败，请重试');
      }
    } catch (error) {
      console.error('🌳 [TreeHolePostNavPage] 发布失败:', error);
      this.showErrorDialog('发布失败，请检查网络连接');
    } finally {
      this.isPublishing = false;
    }
  }

  /**
   * 显示错误对话框
   */
  private showErrorDialog(message: string): void {
    this.getUIContext().showAlertDialog({
      title: '发布失败',
      message: message,
      primaryButton: {
        value: '确定',
        action: () => {
          // 不做任何操作
        }
      }
    });
  }
}