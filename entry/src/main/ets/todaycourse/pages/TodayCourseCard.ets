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
    Swiper() {
      ForEach(this.testCourses, (course: SimpleCourse) => {
        Column() {
          Text(course.courseName)
            .maxLines(2)
            .fontColor(Color.White)
            .fontSize(17)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontWeight(FontWeight.Bold)
            .margin({
              left: 12,
              top: 12,
              right: 12
            })

          Blank()

          Column() {
            Text(course.timeRange)
              .fontColor(Color.White)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 6 })

            Text(course.classroom)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(2)
              .fontSize(17)
              .opacity(0.9)
          }
          .alignItems(HorizontalAlign.End)
          .width('100%')
          .padding({
            left: 12,
            right: 12,
            bottom: 12
          })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
      }, (course: SimpleCourse) => course.courseName)
    }
    .loop(false)
    .autoPlay(false)
    .width('100%')
    .height('100%')
    .backgroundColor('#4A90E2')
    .borderRadius(12)
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
}