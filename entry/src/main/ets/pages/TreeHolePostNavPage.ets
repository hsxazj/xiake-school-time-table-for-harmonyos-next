/**
 * 树洞发布页面导航组件
 * 参考MainTabNavPage的结构，将TreeHolePostPage直接集成
 */
import { PostTreeHoleRequest } from '../models/TreeHoleModels';
import { TreeHoleApiService } from '../services/api/TreeHoleApiService';
import { UserInfoManager } from '../common/utils/UserInfoManager';
import { SimpleUserInfo } from '../models/UserModels';

// 内容验证结果接口
interface ValidationResult {
  isValid: boolean;
  message?: string;
}

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
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

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
        .placeholderColor('#CCCCCC')
        .textAlign(TextAlign.Start)
        .onTextSelectionChange((selectionStart: number, selectionEnd: number) => {
          this.updateWordCount();
        })
        .onChange((value: string) => {
          this.content = value;
          this.updateWordCount();
        })

      // 字数统计和提示
      Row() {
        // 左侧提示文字
        if (this.wordCount === 0) {
          Text('分享你的想法...')
            .fontSize(12)
            .fontColor('#999999')
        } else if (this.isAnonymous) {
          Text('匿名发布，需管理员审核')
            .fontSize(12)
            .fontColor('#FF9500')
        } else {
          Text('实名发布，立即可见')
            .fontSize(12)
            .fontColor('#31BFCC')
        }

        Blank()

        Text(`${this.wordCount}/${this.maxLength}`)
          .fontSize(14)
          .fontColor(this.wordCount > this.maxLength * 0.8 ? '#FF6B6B' : '#999999')
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(25)
    .borderWidth(1)
    .borderColor('#E8E8E8')
    .margin({ bottom: 15 })
    .shadow({
      radius: 6,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildAnonymousOption() {
    Row() {
      // 匿名开关 - 使用原生Checkbox
      Checkbox({ name: 'anonymous', group: 'checkboxGroup' })
        .select(this.isAnonymous)
        .selectedColor('#31BFCC')
        .unselectedColor('#CCCCCC')
        .onChange((value: boolean) => {
          this.isAnonymous = value;
          console.info(`🌳 [TreeHolePostNavPage] 切换匿名模式: ${this.isAnonymous}`);
        })
        .margin({ right: 12 })

      Text('匿名发布')
        .fontSize(16)
        .fontColor('#333333')
        .onClick(() => {
          this.isAnonymous = !this.isAnonymous;
          console.info(`🌳 [TreeHolePostNavPage] 切换匿名模式: ${this.isAnonymous}`);
        })

      Blank()

      Text(this.isAnonymous ? '匿名模式' : '实名模式')
        .fontSize(14)
        .fontColor(this.isAnonymous ? '#31BFCC' : '#666666')
        .fontWeight(this.isAnonymous ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor(Color.White)
    .borderRadius(25)
    .borderWidth(1)
    .borderColor('#E8E8E8')
    .margin({ bottom: 15 })
    .alignItems(VerticalAlign.Center)
    .shadow({
      radius: 6,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.isAnonymous = !this.isAnonymous;
      console.info(`🌳 [TreeHolePostNavPage] 切换匿名模式: ${this.isAnonymous}`);
    })
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
      .margin({
        left: 20,
        right: 20,
        bottom: 30,
        top: 10
      })
      .enabled(this.canPublish() && !this.isPublishing)
      .shadow({
        radius: this.canPublish() ? 8 : 4,
        color: this.canPublish() ? '#1031BFCC' : '#10CCCCCC',
        offsetX: 0,
        offsetY: 3
      })
      .onClick(() => {
        this.handlePublish();
      })
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏
        this.buildTitleBar()

        // 主内容区域 - 移到顶部
        Scroll() {
          Column() {
            this.buildContentInput()
            this.buildAnonymousOption()
          }
          .width('100%')
          .padding({ top: 10, left: 10, right: 10 })
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)

        // 底部发布按钮 - 固定在底部
        this.buildPublishButton()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
      .justifyContent(FlexAlign.Start)
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
    const trimmedContent = this.content.trim();

    // 基础验证
    if (trimmedContent.length === 0) {
      return false;
    }

    if (trimmedContent.length > this.maxLength) {
      return false;
    }

    // 发布状态检查
    if (this.isPublishing) {
      return false;
    }

    return true;
  }

  /**
   * 详细的内容验证
   */
  private validateContent(): ValidationResult {
    const trimmedContent = this.content.trim();

    // 空内容检查
    if (trimmedContent.length === 0) {
      return { isValid: false, message: '树洞内容不能为空' } as ValidationResult;
    }

    // 长度检查
    if (trimmedContent.length > this.maxLength) {
      return { isValid: false, message: `内容长度不能超过${this.maxLength}个字符` } as ValidationResult;
    }

    // 最小长度检查
    if (trimmedContent.length < 5) {
      return { isValid: false, message: '内容至少需要5个字符' } as ValidationResult;
    }

    // 敏感词检查（简单示例）
    const sensitiveWords = ['测试敏感词', '违规内容'];
    for (const word of sensitiveWords) {
      if (trimmedContent.includes(word)) {
        return { isValid: false, message: '内容包含不当词汇，请修改后重试' } as ValidationResult;
      }
    }

    return { isValid: true } as ValidationResult;
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
    // 详细验证
    const validation = this.validateContent();
    if (!validation.isValid) {
      this.showErrorDialog(validation.message || '内容验证失败');
      return;
    }

    try {
      this.isPublishing = true;

      // 获取学籍信息
      const userInfo = this.userInfoManager.getUserInfo(this.getUIContext().getHostContext());
      if (!userInfo.classId) {
        this.showErrorDialog('请先完成学籍信息设置');
        return;
      }

      // 获取当前登录用户信息
      const currentUser: SimpleUserInfo | null =
        this.userInfoManager.getCurrentUserInfo(this.getUIContext().getHostContext());
      if (!currentUser || !currentUser.userId) {
        this.showErrorDialog('请先登录后再发布');
        return;
      }

      // 构造API请求参数（匹配后端接口格式）
      const request: PostTreeHoleRequest = {
        content: this.content.trim(),
        anonymous: this.isAnonymous ? 1 : 0, // 转换为数字格式
        parentId: 0, // 发布树洞时为0
        userId: currentUser.userId, // 使用真实的用户ID
        deleteTime: ""  // 空字符串表示不设置删除时间
      };

      console.info('🌳 [TreeHolePostNavPage] 开始发布树洞，请求参数:', JSON.stringify(request));
      const result = await this.treeHoleApiService.postTreeHole(request);

      if (result.code === 200) {
        console.info('🌳 [TreeHolePostNavPage] 发布成功');

        // 发布成功后的提示
        const message = this.isAnonymous ?
          '发布成功！内容已提交，等待管理员审核后显示' :
          '发布成功！内容已发布';

        // 显示成功提示
        this.getUIContext().showAlertDialog({
          title: '发布成功',
          message: message,
          primaryButton: {
            value: '确定',
            action: () => {
              // 返回树洞列表页面，并触发刷新
              this.pathStack.pop();

              // 通知树洞页面刷新数据
              setTimeout(() => {
                // 这里可以通过AppStorage或其他方式通知树洞页面刷新
                console.info('🌳 [TreeHolePostNavPage] 通知树洞页面刷新');
              }, 100);
            }
          }
        });
      } else {
        // 处理服务器返回的错误
        const errorMessage = this.parseServerError(result.code, result.msg);
        this.showErrorDialog(errorMessage);
      }
    } catch (error) {
      console.error('🌳 [TreeHolePostNavPage] 发布失败:', error);

      // 解析网络错误
      const errorMessage = this.parseNetworkError(error);
      this.showErrorDialog(errorMessage);
    } finally {
      this.isPublishing = false;
    }
  }

  /**
   * 解析服务器错误
   */
  private parseServerError(code: number, message?: string): string {
    switch (code) {
      case 401:
        return '用户未登录或登录已过期，请重新登录';
      case 403:
        return '没有发布权限，请联系管理员';
      case 429:
        return '发布过于频繁，请稍后再试';
      case 500:
        return '服务器内部错误，请稍后重试';
      default:
        return message || `发布失败(错误码: ${code})`;
    }
  }

  /**
   * 解析网络错误
   */
  private parseNetworkError(error: Error | string | object): string {
    if (typeof error === 'string') {
      if (error.includes('timeout')) {
        return '网络请求超时，请检查网络连接';
      } else if (error.includes('network')) {
        return '网络连接失败，请检查网络设置';
      }
    } else if (error instanceof Error) {
      if (error.message.includes('timeout')) {
        return '网络请求超时，请检查网络连接';
      } else if (error.message.includes('network')) {
        return '网络连接失败，请检查网络设置';
      }
    }

    return '发布失败，请检查网络连接后重试';
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