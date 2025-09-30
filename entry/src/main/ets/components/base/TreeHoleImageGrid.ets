/**
 * 树洞图片网格展示组件
 * 支持1-3张图片的自适应网格布局
 */
import { API_CONFIG } from '../../common/constants/AppConstants';

/**
 * 图片点击事件回调类
 */
export class ImageClickCallback {
  handler?: (imageUrl: string, imageIndex: number, allImages: string[]) => void;

  constructor(handler?: (imageUrl: string, imageIndex: number, allImages: string[]) => void) {
    this.handler = handler;
  }

  call(imageUrl: string, imageIndex: number, allImages: string[]): void {
    if (this.handler) {
      this.handler(imageUrl, imageIndex, allImages);
    }
  }
}

@Component
export struct TreeHoleImageGrid {
  @Prop images: string[] = [];
  @Prop onImageClick?: ImageClickCallback;
  @Prop maxWidth: number = 300;
  @Prop imageBorderRadius: number = 8;

  build() {
    if (!this.images || this.images.length === 0) {
      // 无图片时不渲染任何内容
      Column() {}
        .width(0)
        .height(0)
    } else {
      Column() {
        this.buildImageGrid()
      }
      .width('100%')
      .margin({ top: 12, bottom: 8 })
    }
  }

  @Builder
  buildImageGrid() {
    if (this.images.length === 1) {
      // 单图片：较大尺寸展示
      this.buildSingleImage()
    } else if (this.images.length === 2) {
      // 双图片：横向并排
      this.buildDoubleImages()
    } else if (this.images.length === 3) {
      // 三图片：第一张大图，后两张小图竖排
      this.buildTripleImages()
    }
  }

  @Builder
  buildSingleImage() {
    Image(this.getImageUrl(this.images[0]))
      .width('100%')
      .height(200)
      .objectFit(ImageFit.Cover)
      .borderRadius(this.imageBorderRadius)
      .onClick(() => {
        this.handleImageClick(this.images[0], 0);
      })
  }

  @Builder
  buildDoubleImages() {
    Row() {
      ForEach(this.images.slice(0, 2), (imageUrl: string, index: number) => {
        Image(this.getImageUrl(imageUrl))
          .width('48%')
          .height(150)
          .objectFit(ImageFit.Cover)
          .borderRadius(this.imageBorderRadius)
          .onClick(() => {
            this.handleImageClick(imageUrl, index);
          })
      }, (imageUrl: string, index: number) => `double_${index}_${imageUrl}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  buildTripleImages() {
    Row() {
      // 左侧大图
      Image(this.getImageUrl(this.images[0]))
        .width('48%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .borderRadius(this.imageBorderRadius)
        .onClick(() => {
          this.handleImageClick(this.images[0], 0);
        })

      // 右侧双图竖排
      Column() {
        ForEach(this.images.slice(1, 3), (imageUrl: string, index: number) => {
          Image(this.getImageUrl(imageUrl))
            .width('100%')
            .height(92)
            .objectFit(ImageFit.Cover)
            .borderRadius(this.imageBorderRadius)
            .onClick(() => {
              this.handleImageClick(imageUrl, index + 1);
            })
        }, (imageUrl: string, index: number) => `triple_${index + 1}_${imageUrl}`)
      }
      .width('48%')
      .height(200)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 处理图片点击事件
   */
  private handleImageClick(imageUrl: string, imageIndex: number): void {
    console.info(`🖼️ [TreeHoleImageGrid] 点击图片: ${imageIndex}, URL: ${imageUrl}`);
    
    if (this.onImageClick) {
      this.onImageClick.call(imageUrl, imageIndex, this.images);
    }
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