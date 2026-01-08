/**
 * 图片预览对话框组件
 * 支持全屏查看、缩放、滑动切换等功能
 */
import { curves } from '@kit.ArkUI';
import { API_CONFIG } from '../../common/constants/AppConstants';

/**
 * 图片预览关闭回调类
 */
export class ImagePreviewCloseCallback {
  handler?: () => void;

  constructor(handler?: () => void) {
    this.handler = handler;
  }

  call(): void {
    if (this.handler) {
      this.handler();
    }
  }
}

@Component
export struct ImagePreviewDialog {
  @Prop isVisible: boolean = false;
  @Prop images: string[] = [];
  @Prop currentIndex: number = 0;
  @Prop onClose: ImagePreviewCloseCallback = new ImagePreviewCloseCallback();
  @State private currentImageIndex: number = 0;
  @State private imageScale: number = 1;
  @State private imageOffsetX: number = 0;
  @State private imageOffsetY: number = 0;
  @State private dialogOpacity: number = 0;
  @State private imageOpacity: number = 0;
  @State private clickTimer: number = 0;

  aboutToAppear(): void {
    this.currentImageIndex = this.currentIndex;
    if (this.isVisible) {
      this.startShowAnimation();
    }
  }

  aboutToDisappear(): void {
    // 清理定时器
    if (this.clickTimer) {
      clearTimeout(this.clickTimer);
      this.clickTimer = 0;
    }
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 黑色背景遮罩
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(this.dialogOpacity * 0.9)
          .onClick(() => {
            this.handleClose();
          })

        // 主要内容区域
        Column() {
          // 顶部操作栏
          this.buildTopBar()

          // 图片展示区域
          this.buildImageViewer()

          // 底部指示器（多图时显示）
          if (this.images.length > 1) {
            this.buildBottomIndicator()
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .opacity(this.dialogOpacity)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }

  @Builder
  buildTopBar() {
    Row() {
      // 关闭按钮
      Button() {
        Text('×')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .borderRadius(20)
      .onClick(() => {
        this.handleClose();
      })

      Blank()

      // 图片计数（多图时显示）
      if (this.images.length > 1) {
        Text(`${this.currentImageIndex + 1} / ${this.images.length}`)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .borderRadius(16)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 40 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildImageViewer() {
    Stack() {
      if (this.images.length > 0 && this.currentImageIndex < this.images.length) {
        Image(this.getImageUrl(this.images[this.currentImageIndex]))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .scale({ x: this.imageScale, y: this.imageScale })
          .translate({ x: this.imageOffsetX, y: this.imageOffsetY })
          .opacity(this.imageOpacity)
          .gesture(
            GestureGroup(GestureMode.Parallel,
              // 缩放手势
              PinchGesture({ fingers: 2, distance: 1 })
                .onActionStart(() => {
                  hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 开始缩放手势');
                })
                .onActionUpdate((event: GestureEvent) => {
                  this.imageScale = Math.max(0.5, Math.min(3, event.scale));
                })
                .onActionEnd(() => {
                  hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 缩放手势结束');
                  // 缩放结束后重置位置
                  if (this.imageScale < 1) {
                    this.resetImageTransform();
                  }
                }),

              // 拖拽/滑动手势（支持放大拖拽和图片切换）
              PanGesture({ fingers: 1, distance: 3, direction: PanDirection.All })
                .onActionStart(() => {
                  if (this.imageScale > 1.1) {
                    hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 开始拖拽手势');
                  } else {
                    hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 开始滑动手势');
                  }
                })
                .onActionUpdate((event: GestureEvent) => {
                  if (this.imageScale > 1.1) {
                    // 放大状态下的拖拽移动
                    this.imageOffsetX += event.offsetX;
                    this.imageOffsetY += event.offsetY;
                  } else if (this.images.length > 1 && this.imageScale <= 1.1) {
                    // 正常状态下只允许水平滑动
                    if (Math.abs(event.offsetX) > Math.abs(event.offsetY)) {
                      const maxOffset = 60;
                      const clampedOffset = Math.max(-maxOffset, Math.min(maxOffset, event.offsetX * 0.5));
                      this.imageOffsetX = clampedOffset;
                    }
                  }
                })
                .onActionEnd((event: GestureEvent) => {
                  if (this.imageScale > 1.1) {
                    hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 拖拽手势结束');
                  } else if (this.images.length > 1 && this.imageScale <= 1.1) {
                    // 判断是否为有效的水平滑动
                    const isHorizontalSwipe = Math.abs(event.offsetX) > Math.abs(event.offsetY) && Math.abs(event.offsetX) > 20;
                    
                    this.resetImageOffset();
                    
                    if (isHorizontalSwipe) {
                      if (event.offsetX > 20 && this.currentImageIndex > 0) {
                        // 向右滑动，显示上一张
                        hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 滑动到上一张');
                        this.switchToPrevious();
                      } else if (event.offsetX < -20 && this.currentImageIndex < this.images.length - 1) {
                        // 向左滑动，显示下一张
                        hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 滑动到下一张');
                        this.switchToNext();
                      }
                    }
                  }
                })
            )
          )
          .gesture(
            // 单击手势关闭预览
            TapGesture({ count: 1 })
              .onAction(() => {
                hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 单击图片');
                // 激进优化：延时减少到50ms，最大化响应速度
                this.clickTimer = setTimeout(() => {
                  hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 单击关闭预览');
                  this.handleClose();
                }, 50);
              })
          )
          .gesture(
            // 双击手势切换缩放状态
            TapGesture({ count: 2 })
              .onAction(() => {
                hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 双击切换缩放');
                // 清除单击定时器
                if (this.clickTimer) {
                  clearTimeout(this.clickTimer);
                  this.clickTimer = 0;
                }
                
                if (this.imageScale === 1) {
                  this.getUIContext().animateTo({
                    duration: 300,
                    curve: Curve.EaseOut
                  }, () => {
                    this.imageScale = 2;
                  });
                } else {
                  this.resetImageTransform();
                }
              })
          )
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildBottomIndicator() {
    Row() {
      ForEach(this.images, (imageUrl: string, index: number) => {
        Circle()
          .width(8)
          .height(8)
          .fill(index === this.currentImageIndex ? '#FFFFFF' : 'rgba(255, 255, 255, 0.4)')
          .margin({ left: 4, right: 4 })
      }, (imageUrl: string, index: number) => `indicator_${index}_${imageUrl}`)
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 开始显示动画
   */
  private startShowAnimation(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.dialogOpacity = 1;
      this.imageOpacity = 1;
    });
  }

  /**
   * 开始隐藏动画
   */
  private startHideAnimation(): void {
    this.getUIContext().animateTo({
      duration: 100,
      curve: Curve.EaseIn
    }, () => {
      this.dialogOpacity = 0;
      this.imageOpacity = 0;
    });

    // 动画结束后调用关闭回调
    setTimeout(() => {
      if (this.onClose) {
        this.onClose.call();
      }
    }, 100);
  }

  /**
   * 处理关闭事件
   */
  private handleClose(): void {
    hilog.info(DOMAIN,TAG,'🖼️ [ImagePreviewDialog] 关闭图片预览');
    this.startHideAnimation();
  }

  /**
   * 切换到上一张图片
   */
  private switchToPrevious(): void {
    if (this.currentImageIndex > 0) {
      this.resetImageTransform();
      this.getUIContext().animateTo({
        duration: 200,
        curve: Curve.EaseInOut
      }, () => {
        this.currentImageIndex--;
      });
      hilog.info(DOMAIN,TAG,`🖼️ [ImagePreviewDialog] 切换到上一张: ${this.currentImageIndex - 1}`);
    }
  }

  /**
   * 切换到下一张图片
   */
  private switchToNext(): void {
    if (this.currentImageIndex < this.images.length - 1) {
      this.resetImageTransform();
      this.getUIContext().animateTo({
        duration: 200,
        curve: Curve.EaseInOut
      }, () => {
        this.currentImageIndex++;
      });
      hilog.info(DOMAIN,TAG,`🖼️ [ImagePreviewDialog] 切换到下一张: ${this.currentImageIndex + 1}`);
    }
  }

  /**
   * 重置图片变换状态
   */
  private resetImageTransform(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.imageScale = 1;
      this.imageOffsetX = 0;
      this.imageOffsetY = 0;
    });
  }

  /**
   * 重置图片位置偏移
   */
  private resetImageOffset(): void {
    this.getUIContext().animateTo({
      duration: 200,
      curve: Curve.EaseOut
    }, () => {
      this.imageOffsetX = 0;
      this.imageOffsetY = 0;
    });
  }

  /**
   * 获取完整的图片URL
   */
  private getImageUrl(imagePath: string): string {
    if (!imagePath) {
      return '';
    }
    
    // 如果已经是完整URL则直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // 否则拼接基础URL
    return `${API_CONFIG.BASE_URL}${imagePath.startsWith('/') ? imagePath : '/' + imagePath}`;
  }
}