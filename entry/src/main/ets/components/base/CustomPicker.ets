import { promptAction } from '@kit.ArkUI';

import { PickerItem, PickerProps } from '../../common/types/PickerTypes';

export { PickerItem, PickerProps };

@CustomDialog
export struct CustomPicker {
  controller: CustomDialogController;
  @Prop items: PickerItem[] = [];
  @State selectedIndex: number = 0;
  @Prop title: string = '';
  onConfirm?: (item: PickerItem, index: number) => void;
  onCancel?: () => void;

  @State private isVisible: boolean = false;

  aboutToAppear(): void {
    // 延迟一帧后开始进入动画，确保初始状态渲染完成
    setTimeout(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseOut
      }, () => {
        this.isVisible = true;
      });
    }, 16);
  }

  private closeWithAnimation(): void {
    // 退出动画 - 属性动画控制
    animateTo({
      duration: 250,
      curve: Curve.EaseIn
    }, () => {
      this.isVisible = false;
    });
    
    // 动画完成后关闭弹窗
    setTimeout(() => {
      this.controller.close();
    }, 250);
  }

  build() {
    Stack() {
      // 透明背景用于捕获点击事件
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.closeWithAnimation();
          this.onCancel?.();
        })

      // 选择器内容
      Column() {
        // 标题栏
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor('#999999')
            .onClick(() => {
              this.closeWithAnimation();
              this.onCancel?.();
            })

          Blank()

          Text(this.title)
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)

          Blank()

          Text('完成')
            .fontSize(16)
            .fontColor('#44CADB')
            .onClick(() => {
              if (this.items.length > 0 && this.selectedIndex < this.items.length) {
                this.onConfirm?.(this.items[this.selectedIndex], this.selectedIndex);
              }
              this.closeWithAnimation();
            })
        }
        .width('100%')
        .height(50)
        .padding({ left: 15, right: 15 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        // 分割线
        Divider()
          .color('#F0F0F0')
          .strokeWidth(1)

        // 选择器内容区域
        if (this.items.length > 0) {
          TextPicker({ 
            range: this.items.map(item => item.name), 
            selected: this.selectedIndex 
          })
            .width('100%')
            .height(280)
            .backgroundColor(Color.White)
            .padding({ left: 5, right: 5 })
            .onChange((value: string | string[], index: number | number[]) => {
              if (typeof index === 'number') {
                this.selectedIndex = index;
              }
            })
        } else {
          Column() {
            Text('暂无数据')
              .fontSize(16)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(280)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .padding({ bottom: 10 })
      .translate({ 
        y: this.isVisible ? 0 : 350  // 属性动画：显示时y=0，隐藏时y=350向下偏移
      })
      .animation({
        duration: 300,
        curve: Curve.EaseOut
      })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Bottom)
  }
}