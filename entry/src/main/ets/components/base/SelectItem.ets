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
          .width(62)
          .height(62)
          .fill(this.iconBackgroundColor)
          .shadow({
            radius: 10,
            color: this.iconShadowColor,
            offsetY: 0
          })

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
    .padding({
      left: 20,
      right: 20,
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
      this.onTap?.();
    })
  }
}