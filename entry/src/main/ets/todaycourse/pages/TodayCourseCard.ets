import { CourseInfo } from '../../models/CourseModels';

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct TodayCourseCard {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('todayCourses') @Watch('onCoursesChange') todayCourses: CourseInfo[] = [];
  @LocalStorageProp('isLoading') isLoading: boolean = false;
  @LocalStorageProp('errorMessage') errorMessage: string = '';
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly MESSAGE: string = 'open today course';
  readonly FONT_COLOR: string = '#666666';
  readonly BG_COLOR: Color = Color.White;
  readonly FULL_WIDTH_PERCENT: string = '100%';
  readonly FULL_HEIGHT_PERCENT: string = '100%';

  onCoursesChange() {
    // 课程数据更新时的处理
  }

  aboutToAppear(): void {
    // 组件即将出现时的处理
  }

  build() {
    Column() {
      Row() {
        Text('今日课程')
          .fontColor(this.FONT_COLOR)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
      }
      .margin({ bottom: 5 })
      .width(this.FULL_WIDTH_PERCENT)
      .justifyContent(FlexAlign.Start)

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontColor(this.FONT_COLOR)
            .fontSize(14)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      } else if (this.errorMessage !== '') {
        Column() {
          Text(this.errorMessage+'🥳')
            .fontColor(this.FONT_COLOR)
            .fontSize(14)
            .margin({ bottom: 8 })
          Text('点击打开应用设置')
            .fontSize(12)
            .fontColor(this.FONT_COLOR)
            .opacity(0.8)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      } else if (this.todayCourses.length > 0) {
        Swiper() {
          ForEach(this.todayCourses, (course: CourseInfo, index: number) => {
            Column() {
              Text(course.courseName || '')
                .maxLines(1)
                .fontColor(this.FONT_COLOR)
                .fontSize(18)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontWeight(FontWeight.Bold)

              Column() {
                Text(this.getTimeRange(course.courseTime))
                  .fontColor(Color.Brown)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })

                Text(course.classroom || '')
                  .fontColor(this.FONT_COLOR)
                  .fontWeight(FontWeight.Bold)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .maxLines(2)
                  .fontSize(15)
                  .opacity(0.9)
              }
              .alignItems(HorizontalAlign.Start)
              .width(this.FULL_WIDTH_PERCENT)
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width(this.FULL_WIDTH_PERCENT)
            .height(this.FULL_HEIGHT_PERCENT)
            .alignItems(HorizontalAlign.Start)
          }, (course: CourseInfo) => course.courseName || '')
        }
        .layoutWeight(1)
        .loop(false)
        .autoPlay(false)
        .borderRadius(5)
        .indicator(false)
      } else {
        Column() {
          Text('今日无课😋')
            .fontColor(this.FONT_COLOR)
            .fontSize(14)
            .margin({ bottom: 8 })
          Text('去做点喜欢的事☝️🤓')
            .fontSize(14)
            .fontColor(this.FONT_COLOR)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      }
    }
    .padding({
      top: 13,
      left: 12,
      right: 12,
      bottom: 13
    })
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .backgroundColor(this.BG_COLOR)
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

  private getTimeRange(courseTime?: string[]): string {
    if (!courseTime || courseTime.length === 0) {
      return '';
    }

    const firstTime = courseTime[0];
    const lastTime = courseTime[courseTime.length - 1];

    const startTime = firstTime.split('-')[0];
    const endTime = lastTime.split('-')[1];

    return `${startTime}-${endTime}`;
  }
}