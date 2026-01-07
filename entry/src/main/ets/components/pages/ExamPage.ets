import { ExamInfo } from '../../models/ExamModels';
import { JwxtGetExamService } from '../../services/jwxt/JwxtGetExamService';
import { JwxtGetGradeService, GradeInfo } from '../../services/jwxt/JwxtGetGradeService';
import { AppConfigManager } from '../../services/AppConfigManager';
import { CacheManager } from '../../common/utils/CacheManager';
import { curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0010;
const TAG = 'ExamPage';

@Component
export struct ExamPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private examList: ExamInfo[] = [];
  @State private isLoading: boolean = false;
  @State private isRefreshing: boolean = false;
  @State private errorMessage: string = '';
  private jwxtGetExamService: JwxtGetExamService = JwxtGetExamService.getInstance();
  private jwxtGetGradeService: JwxtGetGradeService = JwxtGetGradeService.getInstance();
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

      // 考试列表区域 - 使用Refresh组件支持下拉刷新
      Refresh({ refreshing: $$this.isRefreshing }) {
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
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 4 })
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
        .padding(10)
        .backgroundColor(Color.White)
        .borderRadius(24)
        .margin({ bottom: 20 })
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .onRefreshing(() => {
        this.handleRefresh();
      })

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
          Text(examInfo.time || '时间待定')
            .fontSize(15)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        // 考场信息
        Row() {
          Text(examInfo.classroom || '考场待定')
            .fontSize(15)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        // 座位号
        Row() {
          Text(`座位号: ${examInfo.seat || '待定'}`)
            .fontSize(15)
            .fontColor('#666666')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')

        // 考试成绩（如果有）
        if (examInfo.score !== undefined && examInfo.score !== '') {
          Row() {
            Text('成绩: ')
              .fontSize(15)
              .fontColor('#666666')

            Text(examInfo.score)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getScoreColor(examInfo.score))
          }
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('#F8F9FA')
    .borderRadius(16)
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
   * 根据成绩获取显示颜色
   * @param score 成绩字符串
   * @returns 颜色值（及格绿色，不及格红色，其他黑色）
   */
  private getScoreColor(score: string): string {
    // 尝试将成绩转换为数字
    const numericScore = parseFloat(score);

    // 如果是数字成绩
    if (!isNaN(numericScore)) {
      // 大于等于60分为及格，显示绿色
      if (numericScore >= 60) {
        return '#00C853'; // 绿色
      } else {
        // 小于60分为不及格，显示红色
        return '#FF3B30'; // 红色
      }
    }

    // 如果是等级成绩（如"优秀"、"良好"、"及格"、"不及格"等）
    const passGrades = ['优秀', '良好', '中等', '及格', '合格', '通过', 'A', 'B', 'C', 'D', 'P', 'PASS'];
    const failGrades = ['不及格', '不合格', '未通过', 'F', 'FAIL'];

    if (passGrades.some(grade => score.includes(grade))) {
      return '#00C853'; // 绿色
    } else if (failGrades.some(grade => score.includes(grade))) {
      return '#FF3B30'; // 红色
    }

    // 其他情况（如"缓考"、"缺考"等）显示默认颜色
    return '#333333'; // 黑色
  }

  /**
   * 加载考试列表（使用缓存优先策略）
   *
   * 策略：
   * 1. 优先从缓存加载并立即渲染（关闭loading）
   * 2. 后台异步请求API更新数据
   * 3. API成功后静默覆盖数据和缓存
   * 4. API失败且有缓存时显示提示
   */
  private async loadExamList(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [ExamPage] 开始加载考试列表...');

      // 等待配置管理器初始化
      await this.appConfigManager.initialize();

      // 获取当前学期状态
      const currentStatus = this.appConfigManager.getCurrentStatus();
      if (!currentStatus || !currentStatus.currentSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 无法获取当前学期信息');
        this.errorMessage = '无法获取学期信息，请稍后重试';
        this.isLoading = false;
        return;
      }

      const academicYear = parseInt(currentStatus.currentSemester.academicYear);
      const semester = currentStatus.currentSemester.semester;

      hilog.info(DOMAIN, TAG, '📅 [ExamPage] 当前学期: year=%{public}d, term=%{public}d',
        academicYear, semester);

      // 步骤1: 尝试从缓存加载
      hilog.info(DOMAIN, TAG, '📚 [ExamPage] 优先从缓存加载考试和成绩信息');
      const cachedExamList = await CacheManager.getExamCache(academicYear, semester);
      const cachedGradeList = await CacheManager.getGradeCache(academicYear, semester);

      if (cachedExamList && cachedExamList.length > 0) {
        // 有缓存，立即使用缓存数据渲染
        hilog.info(DOMAIN, TAG, `📚 [ExamPage] 使用缓存数据: ${cachedExamList.length}条考试信息`);

        // 如果也有成绩缓存，将成绩匹配到考试中
        if (cachedGradeList && cachedGradeList.length > 0) {
          this.examList = this.mergeExamWithGrades(cachedExamList, cachedGradeList);
        } else {
          this.examList = cachedExamList;
        }

        // 立即关闭loading，显示缓存数据
        this.isLoading = false;
      } else {
        hilog.info(DOMAIN, TAG, `📚 [ExamPage] 无缓存数据，等待API请求`);
        this.isLoading = true;
      }

      // 步骤2: 后台异步请求API更新（无论缓存是否存在都请求）
      hilog.info(DOMAIN, TAG, '📚 [ExamPage] 后台请求API更新数据');

      // 并行调用服务获取考试信息和成绩信息
      const results = await Promise.all([
        this.jwxtGetExamService.getExam(academicYear, semester),
        this.jwxtGetGradeService.getGrade(academicYear, semester)
      ]);

      const examList = results[0];
      const gradeList = results[1];

      hilog.info(DOMAIN, TAG, '✅ [ExamPage] API请求成功，更新数据: %{public}d条考试, %{public}d条成绩',
        examList.length, gradeList.length);

      // 步骤3: API成功，覆盖旧数据和缓存
      // 保存到缓存
      await CacheManager.saveExamCache(academicYear, semester, examList);
      await CacheManager.saveGradeCache(academicYear, semester, gradeList);

      // 将成绩信息匹配到考试信息中
      this.examList = this.mergeExamWithGrades(examList, gradeList);

      hilog.info(DOMAIN, TAG, '🎉 [ExamPage] 考试列表处理完成，共 %{public}d 条记录，其中 %{public}d 条有成绩',
        this.examList.length,
        this.examList.filter((exam: ExamInfo) => exam.score !== undefined).length);

      this.isLoading = false;

    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [ExamPage] 加载考试列表失败: %{public}s', JSON.stringify(error));

      // 请求失败，根据是否有缓存数据显示不同提示
      if (this.examList.length > 0) {
        // 有缓存数据，提示使用本地缓存（不设置 errorMessage，继续显示缓存数据）
        hilog.warn(DOMAIN, TAG, '📚 [ExamPage] 请求失败，继续使用缓存数据');
        const promptAction = this.getUIContext().getPromptAction();
        promptAction.showToast({
          message: '请求教务系统失败，使用本地缓存',
          duration: 3000,
          bottom: '100vp'
        });
      } else {
        // 无缓存数据，显示错误信息
        if (error instanceof Error) {
          this.errorMessage = error.message;
        } else {
          this.errorMessage = '加载考试信息失败，请稍后重试';
        }
      }

      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  /**
   * 处理下拉刷新 - 直接触发API请求，跳过缓存
   */
  private async handleRefresh(): Promise<void> {
    try {
      this.isRefreshing = true;
      hilog.info(DOMAIN, TAG, '🔄 [ExamPage] 下拉刷新：直接请求API更新数据');

      // 获取当前学期状态
      await this.appConfigManager.initialize();
      const currentStatus = this.appConfigManager.getCurrentStatus();

      if (!currentStatus || !currentStatus.currentSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 无法获取当前学期信息');
        return;
      }

      const academicYear = parseInt(currentStatus.currentSemester.academicYear);
      const semester = currentStatus.currentSemester.semester;

      // 直接并行调用API获取最新数据
      const results = await Promise.all([
        this.jwxtGetExamService.getExam(academicYear, semester),
        this.jwxtGetGradeService.getGrade(academicYear, semester)
      ]);

      const examList = results[0];
      const gradeList = results[1];

      hilog.info(DOMAIN, TAG, '✅ [ExamPage] 刷新成功：%{public}d条考试, %{public}d条成绩',
        examList.length, gradeList.length);

      // 更新缓存
      await CacheManager.saveExamCache(academicYear, semester, examList);
      await CacheManager.saveGradeCache(academicYear, semester, gradeList);

      // 更新界面数据
      this.examList = this.mergeExamWithGrades(examList, gradeList);

    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [ExamPage] 刷新失败: %{public}s', JSON.stringify(error));

      // 显示错误提示
      const promptAction = this.getUIContext().getPromptAction();
      promptAction.showToast({
        message: '刷新失败，请稍后重试',
        duration: 2000,
        bottom: '100vp'
      });
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 将成绩信息匹配到考试信息中
   * @param examList 考试信息列表
   * @param gradeList 成绩信息列表
   * @returns 合并后的考试信息列表
   */
  private mergeExamWithGrades(examList: ExamInfo[], gradeList: GradeInfo[]): ExamInfo[] {
    return examList.map((exam: ExamInfo) => {
      // 查找对应的成绩
      const matchedGrade = gradeList.find((grade: GradeInfo) => grade.name === exam.name);

      if (matchedGrade) {
        hilog.info(DOMAIN, TAG, '🎯 [ExamPage] 课程 "%{public}s" 匹配到成绩: %{public}s',
          exam.name, matchedGrade.score);
        // 返回包含成绩的考试信息（手动复制属性，不使用展开运算符）
        const examWithScore: ExamInfo = {
          id: exam.id,
          name: exam.name,
          time: exam.time,
          classroom: exam.classroom,
          seat: exam.seat,
          score: matchedGrade.score
        };
        return examWithScore;
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 课程 "%{public}s" 未找到对应成绩', exam.name);
        // 返回不包含成绩的考试信息
        return exam;
      }
    });
  }
}
