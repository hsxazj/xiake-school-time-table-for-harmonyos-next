interface SimpleCourse {
  courseName: string;
  classroom: string;
  timeRange: string;
}

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct TodayCourseCard {
  @LocalStorageProp('formId') formId: string = '';
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly MESSAGE: string = 'open today course';
  readonly FONT_COLOR: Color = Color.Black;
  readonly BG_COLOR: Color = Color.White;
  // 静态测试数据
  private testCourses: SimpleCourse[] = [
    {
      courseName: "高等数学（1）I",
      classroom: "博学5＃－204",
      timeRange: "8:20-10:00"
    },
    {
      courseName: "大学英语（1）",
      classroom: "博学3＃－语音301",
      timeRange: "10:15-11:50"
    },
    {
      courseName: "思想道德与法治",
      classroom: "博学2＃－101",
      timeRange: "14:30-16:10"
    }
  ];

  build() {
    Column() {
      Row() {
        Text('今日课程')
          .fontColor(this.FONT_COLOR)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
      }
      .margin({ bottom: 5 })
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Swiper() {
        ForEach(this.testCourses, (course: SimpleCourse) => {
          Column() {
            Text(course.courseName)
              .maxLines(1)
              .fontColor(this.FONT_COLOR)
              .fontSize(15)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontWeight(FontWeight.Bold)

            Column() {
              Text(course.timeRange)
                .fontColor(Color.Brown)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text(course.classroom)
                .fontColor(this.FONT_COLOR)
                .fontWeight(FontWeight.Bold)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(2)
                .fontSize(15)
                .opacity(0.9)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Start)
        }, (course: SimpleCourse) => course.courseName)
      }
      .layoutWeight(1)
      .loop(false)
      .autoPlay(false)
      .borderRadius(5)
      .indicator(false)
      .onClick(() => {
        postCardAction(this, {
          action: this.ACTION_TYPE,
          abilityName: this.ABILITY_NAME,
          params: {
            message: this.MESSAGE
          }
        });
      })
    }
    .padding({
      top: 13,
      left: 12,
      right: 12,
      bottom: 13
    })
    .width('100%')
    .height('100%')
    .backgroundColor(this.BG_COLOR)

  }
}