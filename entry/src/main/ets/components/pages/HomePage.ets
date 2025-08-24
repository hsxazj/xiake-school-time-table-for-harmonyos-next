@Component
export struct HomePage {
  @State private username: string = '';
  @State private collegeName: string = '';

  aboutToAppear(): void {
    // 这里可以加载用户信息
    this.username = '同学';
    this.collegeName = '计算机学院';
  }

  build() {
    Column() {
      // 顶部问候语
      Row() {
        Column() {
          Text(`你好，${this.username}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 4 })
          Text(`${this.collegeName}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 消息图标
        Text('🔔')
          .fontSize(24)
          .onClick(() => {
            // 消息点击事件
          })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 50,
        bottom: 20
      })

      // 功能区域
      Column() {
        // 今日课程卡片
        Column() {
          Row() {
            Text('今日课程')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Blank()
            Text('查看更多 >')
              .fontSize(14)
              .fontColor('#45CAD9')
              .onClick(() => {
                // 跳转到课表页
              })
          }
          .width('100%')
          .margin({ bottom: 15 })

          // 课程列表
          Column() {
            Text('暂无今日课程')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 20, bottom: 20 })
          }
          .width('100%')
          .height(100)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetY: 2
        })
        .margin({ bottom: 20 })

        // 快捷功能
        Column() {
          Text('快捷功能')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .margin({ bottom: 15 })

          Grid() {
            GridItem() {
              this.FunctionCard('📅', '我的课表', '#E3F2FD')
            }

            GridItem() {
              this.FunctionCard('⭐', '课程评价', '#F3E5F5')
            }

            GridItem() {
              this.FunctionCard('📢', '系统通知', '#E8F5E8')
            }

            GridItem() {
              this.FunctionCard('❓', '问题反馈', '#FFF3E0')
            }
          }
          .rowsTemplate('1fr 1fr')
          .columnsTemplate('1fr 1fr')
          .rowsGap(15)
          .columnsGap(15)
          .height(200)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetY: 2
        })
      }
      .width('90%')
      .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FunctionCard(icon: string, title: string, bgColor: string) {
    Column() {
      Text(icon)
        .fontSize(32)
        .margin({ bottom: 8 })
      Text(title)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(bgColor)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 处理点击事件
    })
  }
}