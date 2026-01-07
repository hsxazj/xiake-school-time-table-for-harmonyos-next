import { ExamInfo } from '../../models/ExamModels';
import { JwxtGetExamService } from '../../services/jwxt/JwxtGetExamService';
import { AppConfigManager } from '../../services/AppConfigManager';
import { curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0010;
const TAG = 'ExamPage';

@Component
export struct ExamPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private examList: ExamInfo[] = [];
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';
  private jwxtGetExamService: JwxtGetExamService = JwxtGetExamService.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();

  // 动画效果 - 与HomePage保持一致
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 150 });

  aboutToAppear(): void {
    this.loadExamList();
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('考试安排')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: 5,
        right: 5,
        top: 50,
        bottom: 20
      })

      // 考试列表区域
      Column() {

        // 考试列表内容
        if (this.isLoading) {
          // 加载中状态
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color($r('app.color.schedule_primary_color'))
              .margin({ bottom: 10 })

            Text('加载中...')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        } else if (this.errorMessage) {
          // 错误状态
          Column() {
            Text('❌')
              .fontSize(40)
              .margin({ bottom: 10 })

            Text(this.errorMessage)
              .fontSize(16)
              .fontColor('#FF6B6B')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })

            Button('重试')
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.schedule_primary_color'))
              .borderRadius(20)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .onClick(() => {
                this.errorMessage = '';
                this.loadExamList();
              })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        } else if (this.examList.length > 0) {
          // 有考试数据
          List() {
            ForEach(this.examList, (exam: ExamInfo, index: number) => {
              ListItem() {
                this.ExamCard(exam, index + 1)
              }
            })
          }
          .borderRadius(24)
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          // 无考试数据
          Column() {
            Text('📝')
              .fontSize(60)
              .margin({ bottom: 10 })

            Text('暂无考试安排')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ bottom: 5 })

            Text('当前学期还没有考试信息')
              .fontSize(14)
              .fontColor('#BBBBBB')
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({
        radius: 10,
        color: '#80000000',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 20 })
      .layoutWeight(1)

      Blank()
    }
    .width('90%')
    .height('100%')
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  ExamCard(examInfo: ExamInfo, index: number) {
    Column() {
      // 序号和课程名称
      Row() {
        Text(`${index}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.schedule_primary_color'))
          .width(40)
          .textAlign(TextAlign.Center)

        Column() {
          Text(examInfo.name || '未知课程')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .alignSelf(ItemAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 考试详细信息
      Column({ space: 8 }) {
        // 考试时间
        Row() {
          Text('🕐')
            .fontSize(16)
            .width(30)

          Text(examInfo.time || '时间待定')
            .fontSize(15)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        // 考场信息
        Row() {
          Text('📍')
            .fontSize(16)
            .width(30)

          Text(examInfo.classroom || '考场待定')
            .fontSize(15)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        // 座位号
        Row() {
          Text('💺')
            .fontSize(16)
            .width(30)

          Text(`座位号: ${examInfo.seat || '待定'}`)
            .fontSize(15)
            .fontColor('#666666')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('#F8F9FA')
    .borderRadius(24)
    .border({
      width: 2,
      color: $r('app.color.schedule_primary_color'),
      radius: 16
    })
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
    .transition(this.effect)
  }

  /**
   * 加载考试列表
   */
  private async loadExamList(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      hilog.info(DOMAIN, TAG, '📝 [ExamPage] 开始加载考试列表...');

      // 等待配置管理器初始化
      await this.appConfigManager.initialize();

      // 获取当前学期状态
      const currentStatus = this.appConfigManager.getCurrentStatus();
      if (!currentStatus || !currentStatus.currentSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 无法获取当前学期信息');
        this.errorMessage = '无法获取学期信息，请稍后重试';
        return;
      }

      const academicYear = parseInt(currentStatus.currentSemester.academicYear);
      const semester = currentStatus.currentSemester.semester;

      hilog.info(DOMAIN, TAG, '📅 [ExamPage] 当前学期: year=%{public}d, term=%{public}d',
        academicYear, semester);

      // 调用服务获取考试信息
      const examList = await this.jwxtGetExamService.getExam(academicYear, semester);
      this.examList = examList;

      hilog.info(DOMAIN, TAG, '✅ [ExamPage] 考试列表加载成功，共 %{public}d 条记录', examList.length);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [ExamPage] 加载考试列表失败: %{public}s', JSON.stringify(error));

      if (error instanceof Error) {
        this.errorMessage = error.message;
      } else {
        this.errorMessage = '加载考试信息失败，请稍后重试';
      }
    } finally {
      this.isLoading = false;
    }
  }
}
