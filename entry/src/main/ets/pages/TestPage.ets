import { curves } from '@kit.ArkUI';

@Entry
@Component
struct TestPage {
  @State isPresent: boolean = false;

  // 只保留透明度 + 缩放（由 0 → 1）
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.6, 0.8) });

  build() {
    Stack() {
      if (this.isPresent) {
        Column() {
          Text('ArkUI')
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .width(150)
        .height(150)
        .borderRadius(10)
        .backgroundColor(0xf56c6c)
        .transition(this.effect)   // 应用转场
      }

      // 边框
      Column()
        .width(155)
        .height(155)
        .border({ width: 5, radius: 10, color: Color.Black })

      Button('Click')
        .margin({ top: 320 })
        .onClick(() => {
          this.isPresent = !this.isPresent;
        })
    }
    .width('100%')
    .height('60%')
  }
}