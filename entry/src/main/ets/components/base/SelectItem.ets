export interface SelectItemProps {
  icon: ResourceStr;
  title: string;
  iconBackgroundColor: string;
  iconShadowColor: string;
  isSelected: boolean;
  onTap?: () => void;
}

@Component
export struct SelectItem {
  @Prop icon: ResourceStr = '';
  @Prop title: string = '';
  @Prop iconBackgroundColor: string = '#F2FAF4';
  @Prop iconShadowColor: string = 'rgba(36, 194, 198, 0.2)';
  @Prop isSelected: boolean = false;
  onTap?: () => void;

  build() {
    Row() {
      Stack() {
        Circle()
          .width(50)
          .height(50)
          .fill(this.iconBackgroundColor)

        Image(this.icon)
          .width(30)
          .height(30)
      }
      .zIndex(10)
      .margin({ right: 15 })

      Text(this.title)
        .fontSize(16)
        .fontColor(this.isSelected ? '#333333' : '#A6A6A6')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .height(80)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .border( {style: BorderStyle.Solid, width: 1, color: this.iconShadowColor})
    .padding({
      left: 15,
      right: 15,
      top: 15,
      bottom: 15
    })
    .margin({ top: 10, bottom: 10 })
    .shadow({
      radius: 2,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 1
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      console.info(`SelectItem被点击，title: ${this.title}`);
      if (this.onTap) {
        console.info('调用onTap回调');
        this.onTap();
      } else {
        console.info('onTap回调为空');
      }
    })
  }
}