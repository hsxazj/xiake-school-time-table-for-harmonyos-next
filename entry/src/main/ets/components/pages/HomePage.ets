import { UserInfoManager, UserSchoolInfo } from '../../common/constants/PreferencesUtil';
import { CourseInfo } from '../../models/CourseModels';
import { MOCK_TODAY_COURSES } from '../../common/constants/AppConstants';

@Component
export struct HomePage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private userInfo: UserSchoolInfo | null = null;
  @State private todayCourses: CourseInfo[] = [];
  @State private isLoading: boolean = false;
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  aboutToAppear(): void {
    this.loadUserInfo();
    this.loadTodayCourses();
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(`你好，同学`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 20 }) // 从4增加到8

          // 显示学院+班级信息
          if (this.userInfo) {
            Row() {
              Text(`${this.userInfo.collegeName} ${this.userInfo.className}`)
                .fontSize(16)
                .fontColor('#666666')

              Text('切换')
                .fontSize(16)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
          } else {
            Row() {
              Text('学院信息加载中...')
                .fontSize(14)
                .fontColor('#666666')

              Text('切换')
                .fontSize(12)
                .fontColor('#45CAD9')
                .margin({ left: 8 })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
          top: 8,
          bottom: 8,
          left: 4,
          right: 4
        })
        .borderRadius(8)
        .onClick(() => {
          this.pathStack.pushPathByName('ClassSelectNavPage', null);
        })

        Blank()
      }
      .width('100%')
      .padding({
        left: 5,
        right: 5,
        top: 50,
        bottom: 20
      })

      // 今日课程区域（拉长并删除查看更多）
      Column() {
        Text('今日课程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 15 })

        // 课程列表区域 - 增加高度
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 50, bottom: 50 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        } else if (this.todayCourses.length > 0) {
          List() {
            ForEach(this.todayCourses, (course: CourseInfo) => {
              ListItem() {
                this.CourseCard(course)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          Column() {
            Text('暂无今日课程')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 50, bottom: 50 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F0F2F5') // 今日课程区域使用稍深的灰蓝色
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetY: 2
      })
      .margin({ bottom: 20 })
      .layoutWeight(1) // 让今日课程区域占用更多空间

      Blank()
    }
    .width('90%')
    .height('100%')
    .backgroundColor(Color.White) // 背景改为白色
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  CourseCard(courseInfo: CourseInfo) {
    Column() {
      Text(courseInfo.courseName || '')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.teacher || '')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(courseInfo.classroom || '')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 6 })
        .alignSelf(ItemAlign.Start)

      Text(this.getTimeRange(courseInfo.courseTime))
        .fontSize(14)
        .fontColor('#24C2C6')
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding({
      left: 16,
      right: 16,
      top: 16,
      bottom: 16
    })
    .margin({ bottom: 12 })
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 2
    })
    .alignItems(HorizontalAlign.Start)
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

  private async loadTodayCourses(): Promise<void> {
    this.isLoading = true;

    // 模拟加载延迟
    setTimeout(() => {
      this.todayCourses = MOCK_TODAY_COURSES;
      this.isLoading = false;
    }, 500);
  }

  private loadUserInfo(): void {
    this.userInfo = this.userInfoManager.getUserInfo();
  }
}