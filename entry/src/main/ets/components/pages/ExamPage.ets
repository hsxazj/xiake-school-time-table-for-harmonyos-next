import { ExamInfo } from '../../models/ExamModels';
import { JwxtGetExamService } from '../../services/jwxt/JwxtGetExamService';
import { JwxtGetGradeService, GradeInfo } from '../../services/jwxt/JwxtGetGradeService';
import { JwxtGetInfoService, StudentInfo } from '../../services/jwxt/JwxtGetInfoService';
import { StudentInfoManager } from '../../services/StudentInfoManager';
import { AppConfigManager } from '../../services/AppConfigManager';
import { CacheManager } from '../../common/utils/CacheManager';
import { curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ConfigApiService, SemesterInfo } from '../../services/api/ConfigApiService';
import { jwxtConnectionBus, JwxtConnectionListener } from '../../services/jwxt/JwxtConnectionEvent';
import { CookieManager } from '../../services/jwxt/CookieManager';

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
  private jwxtGetInfoService: JwxtGetInfoService = JwxtGetInfoService.getInstance();
  private studentInfoManager: StudentInfoManager = StudentInfoManager.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private configService: ConfigApiService = ConfigApiService.getInstance();
  private context = this.getUIContext().getHostContext();
  // 考试页面独立的学期状态管理
  @State private currentExamSemester: SemesterInfo | null = null;
  @State private semesterList: SemesterInfo[] = [];
  @State private showSemesterPicker: boolean = false;
  // 学生信息和年级限制
  @State private studentInfo: StudentInfo | null = null;
  @State private userGrade: number = 0; // 学生入学年份(数字格式)
  // 教务系统连接事件监听器
  private jwxtConnectionListener: JwxtConnectionListener = (cookie: string, isConnected: boolean) => {
    hilog.info(DOMAIN, TAG, '🔔 [Event] 收到教务系统连接事件: isConnected=%{public}s', isConnected);
    if (isConnected) {
      // 异步刷新考试数据
      this.refreshExamFromApi();
    }
  };
  // 动画效果 - 与HomePage保持一致
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.8, 1.0), duration: 150 });

  async aboutToAppear(): Promise<void> {
    // 先主动检查一次教务系统连接状态（解决跨页面状态同步问题）
    const cookieManager = CookieManager.getInstance();
    const isConnected = cookieManager.isConnected();
    if (isConnected) {
      hilog.info(DOMAIN, TAG, '✅ [ExamPage] 检测到教务系统已连接，准备刷新考试数据');
    }

    // 注册教务系统连接事件监听器
    jwxtConnectionBus.onConnectionSuccess(this.jwxtConnectionListener);
    hilog.info(DOMAIN, TAG, '📡 [ExamPage] 已注册教务系统连接事件监听器');

    // 获取学生信息(包括入学年份)
    await this.loadStudentInfo();
    // 初始化学期数据
    await this.initializeSemesterData();
    // 加载考试列表
    this.loadExamList();

    // 如果已连接，在初始化完成后刷新数据
    if (isConnected) {
      this.refreshExamFromApi();
    }
  }

  aboutToDisappear(): void {
    // 注销教务系统连接事件监听器
    jwxtConnectionBus.offConnectionSuccess(this.jwxtConnectionListener);
    hilog.info(DOMAIN, TAG, '📡 [ExamPage] 已注销教务系统连接事件监听器');
  }

  /**
   * 加载学生信息(获取入学年份用于年级限制)
   * 优先从 StudentInfoManager 获取,如果没有则调用 API 获取并保存
   */
  private async loadStudentInfo(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '📋 [ExamPage] 开始获取学生信息...');


      // 1. 先尝试从内存获取
      let studentInfo = this.studentInfoManager.getStudentInfoFromMemory();

      // 2. 如果内存中没有,尝试从首选项加载到内存
      if (!studentInfo) {
        hilog.info(DOMAIN, TAG, '💾 [ExamPage] 内存中无学生信息,尝试从首选项加载...');
        const loaded = await this.studentInfoManager.loadStudentInfoToMemory(this.context);
        if (loaded) {
          studentInfo = this.studentInfoManager.getStudentInfoFromMemory();
        }
      }

      // 3. 如果首选项中也没有,调用 API 获取并保存
      if (!studentInfo) {
        hilog.info(DOMAIN, TAG, '🌐 [ExamPage] 首选项中无学生信息,调用 API 获取...');
        studentInfo = await this.jwxtGetInfoService.getInfo(this.context);
        // 保存到 StudentInfoManager
        this.studentInfoManager.saveStudentInfo(this.context, studentInfo);
      }

      // 4. 更新状态
      this.studentInfo = studentInfo;
      if (this.studentInfo && this.studentInfo.grade) {
        // 将 grade 字符串转换为数字 (如 "2024" -> 2024)
        this.userGrade = parseInt(this.studentInfo.grade);
        hilog.info(DOMAIN, TAG, '📋 [ExamPage] 学生入学年份: %{public}d', this.userGrade);
      } else {
        hilog.warn(DOMAIN, TAG, '📋 [ExamPage] 未获取到学生入学年份，将不限制年级');
        this.userGrade = 0; // 0 表示不限制
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '📋 [ExamPage] 获取学生信息失败: %{public}s', JSON.stringify(error));
      this.userGrade = 0; // 失败时不限制年级
    }
  }

  /**
   * 初始化学期数据 - 独立管理考试页面的学期状态
   */
  private async initializeSemesterData(): Promise<void> {
    try {
      // 等待配置管理器初始化
      await this.appConfigManager.initialize();

      // 获取学期列表
      this.semesterList = this.configService.getSemesterList();

      // 获取当前学期状态
      const currentStatus = this.configService.calculateCurrentSemesterStatus(new Date());
      if (currentStatus && currentStatus.currentSemester) {
        this.currentExamSemester = currentStatus.currentSemester;
        hilog.info(DOMAIN, TAG, '✅ [ExamPage] 初始化学期: %{public}s学年第%{public}d学期',
          this.currentExamSemester.academicYear, this.currentExamSemester.semester);
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 无法获取当前学期信息');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [ExamPage] 初始化学期数据失败: %{public}s', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // 顶部标题栏 - 包含学期切换
      Row() {
        Column() {
          Text('考试安排')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          // 显示当前学期信息
          if (this.currentExamSemester) {
            Text(`${this.currentExamSemester.academicYear}学年第${this.currentExamSemester.semester}学期`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 切换学期按钮
        Button('切换学期')
          .fontSize(14)
          .fontColor($r('app.color.schedule_primary_color'))
          .backgroundColor('#E3F2FD')
          .height(36)
          .borderRadius(18)
          .border({
            width: 1,
            color: $r('app.color.schedule_primary_color'),
            radius: 18
          })
          .padding({
            left: 16,
            right: 16,
            top: 0,
            bottom: 0
          })
          .onClick(() => {
            this.showSemesterPicker = true;
          })
      }
      .width('100%')
      .padding({
        left: 5,
        right: 5,
        top: 50,
        bottom: 20
      })
      .bindSheet($$this.showSemesterPicker, this.SemesterPickerBuilder(), {
        showClose: false,
        height: 400,
        dragBar: true,
        maskColor: 'rgba(0, 0, 0, 0.4)',
        onAppear: () => {
          hilog.info(DOMAIN, TAG, '📅 [ExamPage] 学期选择器显示');
        },
        onDisappear: () => {
          hilog.info(DOMAIN, TAG, '📅 [ExamPage] 学期选择器隐藏');
        }
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
                .padding({
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: 8
                })
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
        if (examInfo.time) {
          Row() {
            Text(examInfo.time)
              .fontSize(15)
              .fontColor('#666666')
              .layoutWeight(1)
          }
          .width('100%')
        }

        if(examInfo.classroom){
          // 考场信息
          Row() {
            Text(examInfo.classroom)
              .fontSize(15)
              .fontColor('#666666')
              .layoutWeight(1)
          }
          .width('100%')
        }

        if(examInfo.seat){
          // 座位号
          Row() {
            Text(`座位号: ${examInfo.seat || '待定'}`)
              .fontSize(15)
              .fontColor('#666666')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')
        }

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
   * 学期选择器 (仿照 SchedulePage，带年级过滤)
   */
  @Builder
  SemesterPickerBuilder() {
    Column() {
      // 学期列表
      Text('选择学期')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })

      Scroll() {
        Column() {
          ForEach(this.getAccessibleSemesterList(), (semester: SemesterInfo) => {
            Row() {
              Column() {
                Text(`${semester.academicYear}学年第${semester.semester}学期`)
                  .fontSize(16)
                  .fontColor(this.isSameSemester(semester, this.currentExamSemester)
                    ? $r('app.color.schedule_primary_color')
                    : '#333333')
                  .fontWeight(this.isSameSemester(semester, this.currentExamSemester)
                    ? FontWeight.Medium
                    : FontWeight.Normal)

                Text(`${semester.startDate} ~ ${semester.endDate}`)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Blank()

              if (this.isSameSemester(semester, this.currentExamSemester)) {
                Text('✓')
                  .fontSize(16)
                  .fontColor($r('app.color.schedule_primary_color'))
              }
            }
            .width('100%')
            .height(70)
            .padding({ left: 20, right: 20 })
            .onClick(async () => {
              await this.onSemesterItemClick(semester);
            })

            Divider()
              .color('#F0F0F0')
              .strokeWidth(0.5)
          })
        }
      }
      .layoutWeight(1)

      Row() {
        Button('取消')
          .width('80%')
          .height(45)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.showSemesterPicker = false;
          })
      }
      .width('100%')
      .margin({ top: 20 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
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
   * 获取可访问的学期列表(过滤掉入学年之前的学期)
   */
  private getAccessibleSemesterList(): SemesterInfo[] {
    return this.semesterList.filter((semester: SemesterInfo) => {
      return this.canAccessSemester(semester);
    });
  }

  /**
   * 判断两个学期是否相同
   */
  private isSameSemester(semester1: SemesterInfo | null, semester2: SemesterInfo | null): boolean {
    if (!semester1 || !semester2) {
      return false;
    }
    return semester1.academicYear === semester2.academicYear && semester1.semester === semester2.semester;
  }

  /**
   * 处理学期选择点击事件
   */
  private async onSemesterItemClick(semester: SemesterInfo): Promise<void> {
    if (this.isSameSemester(semester, this.currentExamSemester)) {
      // 点击当前学期,直接关闭选择器
      this.showSemesterPicker = false;
      return;
    }

    hilog.info(DOMAIN, TAG, '📅 [ExamPage] 切换学期: %{public}s学年第%{public}d学期',
      semester.academicYear, semester.semester);

    // 更新当前学期
    this.currentExamSemester = semester;

    // 关闭选择器
    this.showSemesterPicker = false;

    // 重新加载考试数据
    await this.loadExamList();
  }

  /**
   * 加载考试列表（只从缓存加载）
   *
   * 新策略：缓存优先，不主动调用API
   * 1. 只从缓存加载考试和成绩数据
   * 2. 如果有缓存，立即渲染
   * 3. 如果没有缓存，显示空白状态
   * 4. 等待教务系统连接事件后，由事件监听器异步调用API更新
   */
  private async loadExamList(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '📝 [ExamPage] 开始加载考试列表...');

      // 检查当前学期是否存在
      if (!this.currentExamSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 当前学期信息为空');
        this.errorMessage = '无法获取学期信息，请稍后重试';
        this.isLoading = false;
        return;
      }

      const academicYear = parseInt(this.currentExamSemester.academicYear);
      const semester = this.currentExamSemester.semester;

      hilog.info(DOMAIN, TAG, '📅 [ExamPage] 加载学期: year=%{public}d, term=%{public}d',
        academicYear, semester);

      // 只从缓存加载
      hilog.info(DOMAIN, TAG, '📚 [ExamPage] 从缓存加载考试和成绩信息');
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
      } else {
        // 无缓存数据，显示空白状态，等待教务系统连接事件
        hilog.info(DOMAIN, TAG, `📚 [ExamPage] 无缓存数据，等待教务系统连接后更新`);
        this.examList = [];
      }

      this.isLoading = false;

    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ [ExamPage] 加载缓存数据失败: %{public}s', JSON.stringify(error));
      this.examList = [];
      this.isLoading = false;
    }
  }

  /**
   * 从API刷新考试数据（由教务系统连接事件触发）
   *
   * 策略：
   * 1. 后台异步请求API
   * 2. API成功后更新数据和缓存
   * 3. 静默刷新，不影响当前显示
   */
  private async refreshExamFromApi(): Promise<void> {
    if (!this.currentExamSemester) {
      hilog.warn(DOMAIN, TAG, '⚠️ [Refresh] 当前学期信息为空，跳过刷新');
      return;
    }

    const academicYear = parseInt(this.currentExamSemester.academicYear);
    const semester = this.currentExamSemester.semester;

    try {
      hilog.info(DOMAIN, TAG, '🔄 [Refresh] 开始从API刷新考试数据: year=%{public}d, term=%{public}d',
        academicYear, semester);

      // 并行调用服务获取考试信息和成绩信息
      const results = await Promise.all([
        this.jwxtGetExamService.getExam(academicYear, semester),
        this.jwxtGetGradeService.getGrade(academicYear, semester)
      ]);

      const examList = results[0];
      const gradeList = results[1];

      hilog.info(DOMAIN, TAG, '🔄 [Refresh] API请求成功，更新数据: %{public}d条考试, %{public}d条成绩',
        examList.length, gradeList.length);

      // API成功，覆盖旧数据和缓存
      await CacheManager.saveExamCache(academicYear, semester, examList);
      await CacheManager.saveGradeCache(academicYear, semester, gradeList);

      // 将成绩信息匹配到考试信息中
      this.examList = this.mergeExamWithGrades(examList, gradeList);

      hilog.info(DOMAIN, TAG, '🔄 [Refresh] 考试列表刷新完成，共 %{public}d 条记录，其中 %{public}d 条有成绩',
        this.examList.length,
        this.examList.filter((exam: ExamInfo) => exam.score !== undefined).length);

    } catch (error) {
      hilog.error(DOMAIN, TAG, '🔄 [Refresh] 从API刷新考试数据失败: %{public}s', JSON.stringify(error));
      // 静默失败，不影响用户体验
    }
  }

  /**
   * 处理下拉刷新 - 直接触发API请求，跳过缓存
   */
  private async handleRefresh(): Promise<void> {
    try {
      this.isRefreshing = true;
      hilog.info(DOMAIN, TAG, '🔄 [ExamPage] 下拉刷新：直接请求API更新数据');

      // 检查当前学期是否存在
      if (!this.currentExamSemester) {
        hilog.warn(DOMAIN, TAG, '⚠️ [ExamPage] 当前学期信息为空');
        return;
      }

      const academicYear = parseInt(this.currentExamSemester.academicYear);
      const semester = this.currentExamSemester.semester;

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
   * 判断指定学期是否在学生入学后(年级限制)
   *
   * @param targetSemester 要判断的学期
   * @returns true表示可以访问,false表示不可访问
   */
  private canAccessSemester(targetSemester: SemesterInfo | null): boolean {
    // 如果没有获取到学生入学年份,不限制
    if (!this.userGrade || this.userGrade === 0) {
      hilog.info(DOMAIN, TAG, '📋 [ExamPage] 未获取到入学年份，不限制访问');
      return true;
    }

    // 如果目标学期为空,不允许访问
    if (!targetSemester) {
      hilog.warn(DOMAIN, TAG, '📋 [ExamPage] 目标学期为空');
      return false;
    }

    // 获取目标学期的学年(起始年份)
    const academicYear = parseInt(targetSemester.academicYear);

    // 判断: 入学年份 <= 学年起始年份 才能访问
    // 例如: 2024年入学的学生,可以访问2024学年及以后的学期,不能访问2023学年及之前的学期
    const canAccess = this.userGrade <= academicYear;

    hilog.info(DOMAIN, TAG, '📋 [ExamPage] 年级限制检查: 入学年份=%{public}d, 目标学年=%{public}d, 可访问=%{public}s',
      this.userGrade, academicYear, canAccess ? 'true' : 'false');

    return canAccess;
  }

  /**
   * 将成绩信息匹配到考试信息中<br>
   * 注意：没有考试信息的课程也会以“虚拟考试”形式返回
   * @param examList  考试信息列表
   * @param gradeList 成绩信息列表
   * @returns 合并后的考试信息列表（包含虚拟考试）
   */
  private mergeExamWithGrades(
    examList: ExamInfo[],
    gradeList: GradeInfo[]
  ): ExamInfo[] {
    /* 1. 先处理“有考试”的部分 */
    const withExam: ExamInfo[] = examList.map((exam) => {
      const matchedGrade = gradeList.find((g) => g.name === exam.name);

      if (matchedGrade) {
        hilog.info(
          DOMAIN,
          TAG,
          '🎯 [ExamPage] 课程 "%{public}s" 匹配到成绩: %{public}s',
          exam.name,
          matchedGrade.score
        );
        /* 手动复制，避免展开运算符 */
        const examWithScore: ExamInfo = {
          id: exam.id,
          name: exam.name,
          time: exam.time,
          classroom: exam.classroom,
          seat: exam.seat,
          score: matchedGrade.score,
        };
        return examWithScore;
      } else {
        hilog.warn(
          DOMAIN,
          TAG,
          '⚠️ [ExamPage] 课程 "%{public}s" 未找到对应成绩',
          exam.name
        );
        return exam; // 原考试对象，不含成绩
      }
    });

    /* 2. 再处理“只有成绩、没有考试”的课程 */
    const gradeMap = new Set(examList.map((e) => e.name)); // 已有考试的课程名
    const virtualExams: ExamInfo[] = gradeList
      .filter((g) => !gradeMap.has(g.name))
      .map((g) => {
        hilog.info(
          DOMAIN,
          TAG,
          '🎯 [ExamPage] 课程 "%{public}s" 无考试信息，生成虚拟考试，成绩: %{public}s',
          g.name,
          g.score
        );
        return {
          name: g.name,
          score: g.score, // 挂上成绩
        } as ExamInfo;
      });

    /* 3. 合并后一次性返回 */
    return withExam.concat(virtualExams);
  }
}
