import { promptAction } from '@kit.ArkUI';
import { SelectItem } from '../components/base/SelectItem';
import { CollegeApiService } from '../services/api/CollegeApiService';
import { UserInfoManager } from '../common/utils/PreferencesUtil';
import { ClassInfo, College, Major, UserSelection } from '../models/CollegeModels';

@Builder
export function ClassSelectNavPageBuilder() {
  ClassSelectNavPage();
}

@Component
struct ClassSelectNavPage {
  @Consume('NavStack') pathStack: NavPathStack;
  @State private isLoading: boolean = false;
  @State private isInitializing: boolean = true; // 新增初始化状态
  @State private collegeName: string = '加载中...'; // 初始显示加载中
  @State private majorName: string = '加载中...'; // 初始显示加载中
  @State private className: string = '加载中...'; // 初始显示加载中
  @State private collegeId: string = '';
  @State private majorId: string = '';
  @State private classId: string = '';
  @State private collegeList: College[] = [];
  @State private majorList: Major[] = [];
  @State private classList: ClassInfo[] = [];
  @State private selectedCollegeIndex: number = 0;
  @State private selectedMajorIndex: number = 0;
  @State private selectedClassIndex: number = 0;
  private collegeApiService: CollegeApiService = CollegeApiService.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  @State private showCollegePicker: boolean = false;
  @State private showMajorPicker: boolean = false;
  @State private showClassPicker: boolean = false;
  @State private tempCollegeIndex: number = 0; // 临时学院选择索引
  @State private tempMajorIndex: number = 0; // 临时专业选择索引  
  @State private tempClassIndex: number = 0; // 临时班级选择索引

  aboutToAppear(): void {
    console.info('ClassSelectPage aboutToAppear 开始');
    this.loadInitialData();
  }

  @Builder
  CollegePickerBuilder() {
    Column() {
      // 标题栏
      Row() {
        Text('选择学院')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(Color.White)

      // 分割线
      Divider()
        .color('#F0F0F0')

      // 使用TextPicker实现滚轮选择
      TextPicker({
        range: this.collegeList.map(college => college.collegeName),
        selected: this.tempCollegeIndex
      })
        .defaultPickerItemHeight(52)
        .width('100%')
        .layoutWeight(1)// 使用layoutWeight占据剩余空间
        .backgroundColor(Color.White)
        .padding(0)// 去除默认内边距
        .margin(0)// 去除默认外边距
        .onChange((value: string | string[], index: number | number[]) => {
          const selectedValue = Array.isArray(value) ? value[0] : value;
          const selectedIndex = Array.isArray(index) ? index[0] : index;
          console.info(`临时选择学院: ${selectedValue}, index: ${selectedIndex}`);
          this.tempCollegeIndex = selectedIndex; // 只更新临时状态
        })

      Button('确定')
        .margin({ top: 16, bottom: 30 })
        .width('80%')
        .backgroundColor('#45CAD9')
        .fontColor(Color.White)
        .onClick(() => {
          // 确定时才真正选择
          this.selectedCollegeIndex = this.tempCollegeIndex;
          this.handleCollegeSelect(this.tempCollegeIndex);
          this.showCollegePicker = false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  MajorPickerBuilder() {
    Column() {
      // 标题栏
      Row() {
        Text('选择专业')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(Color.White)

      // 分割线
      Divider()
        .color('#F0F0F0')

      // 使用TextPicker实现滚轮选择
      TextPicker({
        range: this.majorList.map(major => major.majorName),
        selected: this.tempMajorIndex
      })
        .defaultPickerItemHeight(52)
        .width('100%')
        .layoutWeight(1)// 使用layoutWeight占据剩余空间
        .backgroundColor(Color.White)
        .padding(0)// 去除默认内边距
        .margin(0)// 去除默认外边距
        .onChange((value: string | string[], index: number | number[]) => {
          const selectedValue = Array.isArray(value) ? value[0] : value;
          const selectedIndex = Array.isArray(index) ? index[0] : index;
          console.info(`临时选择专业: ${selectedValue}, index: ${selectedIndex}`);
          this.tempMajorIndex = selectedIndex; // 只更新临时状态
        })

      Button('确定')
        .margin({ top: 16, bottom: 30 })
        .width('80%')
        .backgroundColor('#45CAD9')
        .fontColor(Color.White)
        .onClick(() => {
          // 确定时才真正选择
          this.selectedMajorIndex = this.tempMajorIndex;
          this.handleMajorSelect(this.tempMajorIndex);
          this.showMajorPicker = false;
        })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  ClassPickerBuilder() {
    Column() {
      // 标题栏
      Row() {
        Text('选择班级')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(Color.White)

      // 分割线
      Divider()
        .color('#F0F0F0')

      // 使用TextPicker实现滚轮选择
      TextPicker({
        range: this.classList.map(classInfo => classInfo.className),
        selected: this.tempClassIndex
      })
        .defaultPickerItemHeight(52)
        .width('100%')
        .layoutWeight(1)// 使用layoutWeight占据剩余空间
        .backgroundColor(Color.White)
        .padding(0)// 去除默认内边距
        .margin(0)// 去除默认外边距
        .onChange((value: string | string[], index: number | number[]) => {
          const selectedValue = Array.isArray(value) ? value[0] : value;
          const selectedIndex = Array.isArray(index) ? index[0] : index;
          console.info(`临时选择班级: ${selectedValue}, index: ${selectedIndex}`);
          this.tempClassIndex = selectedIndex; // 只更新临时状态
        })

      Button('确定')
        .margin({ top: 16, bottom: 30 })
        .width('80%')
        .backgroundColor('#45CAD9')
        .fontColor(Color.White)
        .onClick(() => {
          // 确定时才真正选择
          this.selectedClassIndex = this.tempClassIndex;
          this.handleClassSelect(this.tempClassIndex);
          this.showClassPicker = false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  build() {
    NavDestination() {
      Column() {
        Text('选择要查看的班级')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#179FA2')
          .margin({
            top: 120
          })
          .textAlign(TextAlign.Start)
          .width('80%')

        Column() {
          SelectItem({
            icon: $r('app.media.college'),
            title: this.collegeName,
            iconBackgroundColor: '#F2FAF4',
            iconShadowColor: 'rgba(36, 194, 198, 0.2)',
            isSelected: this.collegeId !== '',
            onTap: () => {
              console.info(`学院点击事件触发，isInitializing=${this.isInitializing}`);
              if (!this.isInitializing) {
                this.handleCollegeClick();
              } else {
                console.info('初始化中，点击被忽略');
              }
            }
          })
            .bindSheet($$this.showCollegePicker, this.CollegePickerBuilder(), {
              showClose: false,
              height: 400,
              dragBar: true,
              maskColor: 'rgba(0, 0, 0, 0.4)',
              onAppear: () => {
                console.log("学院选择器显示");
              },
              onDisappear: () => {
                console.log("学院选择器隐藏");
              }
            })

          SelectItem({
            icon: $r('app.media.major'),
            title: this.majorName,
            iconBackgroundColor: '#E0EFFF',
            iconShadowColor: 'rgba(126, 175, 252, 0.3)',
            isSelected: this.majorId !== '',
            onTap: () => {
              console.info(`专业点击事件触发，isInitializing=${this.isInitializing}`);
              if (!this.isInitializing) {
                this.handleMajorClick();
              } else {
                console.info('初始化中，点击被忽略');
              }
            }
          })
            .bindSheet($$this.showMajorPicker, this.MajorPickerBuilder(), {
              showClose: false,
              height: 400,
              dragBar: true,
              maskColor: 'rgba(0, 0, 0, 0.4)',
              onAppear: () => {
                console.log("专业选择器显示");
              },
              onDisappear: () => {
                console.log("专业选择器隐藏");
              }
            })

          SelectItem({
            icon: $r('app.media.class_icon'),
            title: this.className,
            iconBackgroundColor: '#FFF3E9',
            iconShadowColor: 'rgba(250, 207, 94, 0.2)',
            isSelected: this.classId !== '',
            onTap: () => {
              console.info(`班级点击事件触发，isInitializing=${this.isInitializing}`);
              if (!this.isInitializing) {
                this.handleClassClick();
              } else {
                console.info('初始化中，点击被忽略');
              }
            }
          })
            .bindSheet($$this.showClassPicker, this.ClassPickerBuilder(), {
              showClose: false,
              height: 400,
              dragBar: true,
              maskColor: 'rgba(0, 0, 0, 0.4)',
              onAppear: () => {
                console.log("班级选择器显示");
              },
              onDisappear: () => {
                console.log("班级选择器隐藏");
              }
            })
        }
        .width('90%')
        .margin({ top: 20 })

        Blank()

        Button('下一步')
          .width('60%')
          .height(45)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.isInitializing ? '#CCCCCC' : '#45CAD9')// 初始化时灰色
          .borderRadius(22)
          .margin({ bottom: 60 })
          .shadow({
            radius: 20,
            color: this.isInitializing ? 'rgba(204, 204, 204, 0.3)' : 'rgba(157, 224, 231, 0.6)',
            offsetY: 0
          })
          .onClick(() => {
            if (!this.isInitializing) {
              this.handleNextStep();
            }
          })

        if (this.isLoading || this.isInitializing) {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#45CAD9')

            Text(this.isInitializing ? '正在加载用户信息...' : '加载中...')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 10 })
          }
          .position({ x: '50%', y: '50%' })
          .translate({ x: '-50%', y: '-50%' })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Start)
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })

  }

  private async loadInitialData(): Promise<void> {
    try {
      console.info('开始初始化，isInitializing = true');
      this.isInitializing = true;
      const response = await this.collegeApiService.getAllColleges();
      this.collegeList = response.data;
      console.info(`学院列表加载完成，共${this.collegeList.length}个学院`);

      // 学院列表加载完成后，加载用户之前的选择
      await this.loadUserPreviousSelections();
    } catch (error) {
      console.error('Load colleges failed:', error);
      promptAction.showToast({
        message: '加载学院信息失败',
        duration: 2000
      });
    } finally {
      console.info('初始化完成，isInitializing = false');
      this.isInitializing = false; // 初始化完成，开放操作
    }
  }

  /**
   * 加载用户之前的选择信息
   */
  private async loadUserPreviousSelections(): Promise<void> {
    try {
      const userInfo = this.userInfoManager.getUserInfo();
      console.info('用户信息:', JSON.stringify(userInfo));

      // 先重置为默认状态
      this.collegeName = '请选择学院';
      this.majorName = '请选择专业';
      this.className = '请选择班级';

      if (userInfo.collegeId && userInfo.collegeId !== '0') {
        // 用户之前已选择学院
        this.collegeId = userInfo.collegeId; // 直接使用字符串
        this.collegeName = userInfo.collegeName;

        // 找到学院在列表中的索引 - 直接比较字符串ID
        const collegeIndex = this.collegeList.findIndex(college => college.collegeId === userInfo.collegeId);
        if (collegeIndex >= 0) {
          this.selectedCollegeIndex = collegeIndex;
        }

        console.info(`已选择学院: ${this.collegeName} (ID: ${this.collegeId})`);

        // 加载专业数据
        await this.loadMajorsForPreSelection();

        if (userInfo.majorId && userInfo.majorId !== '0' && this.majorList.length > 0) {
          // 用户之前已选择专业，且专业列表不为空
          this.majorId = userInfo.majorId; // 直接使用字符串
          this.majorName = userInfo.majorName;

          // 找到专业在列表中的索引 - 直接比较字符串ID
          const majorIndex = this.majorList.findIndex(major => major.majorId === userInfo.majorId);
          if (majorIndex >= 0) {
            this.selectedMajorIndex = majorIndex;
          }

          console.info(`已选择专业: ${this.majorName} (ID: ${this.majorId})`);

          // 加载班级数据
          await this.loadClassesForPreSelection();

          if (userInfo.classId && userInfo.classId !== '0' && this.classList.length > 0) {
            // 用户之前已选择班级，且班级列表不为空
            this.classId = userInfo.classId; // 直接使用字符串
            this.className = userInfo.className;

            // 找到班级在列表中的索引 - 直接比较字符串ID
            const classIndex = this.classList.findIndex(classInfo => classInfo.classId === userInfo.classId);
            if (classIndex >= 0) {
              this.selectedClassIndex = classIndex;
            }

            console.info(`已选择班级: ${this.className} (ID: ${this.classId})`);
          }
        } else if (userInfo.majorId && userInfo.majorId !== '0') {
          // 专业数据加载失败，但保持用户的选择显示
          console.warn('专业列表为空，但保留用户之前的专业选择显示');
          this.majorId = userInfo.majorId; // 直接使用字符串
          this.majorName = userInfo.majorName;

          if (userInfo.classId && userInfo.classId !== '0') {
            this.classId = userInfo.classId; // 直接使用字符串
            this.className = userInfo.className;
          }
        }
      }

      console.info('用户之前的选择已加载完成');
    } catch (error) {
      console.error('加载用户之前选择失败:', error);
      // 加载失败时也要重置为默认状态
      this.collegeName = '请选择学院';
      this.majorName = '请选择专业';
      this.className = '请选择班级';
    }
  }

  /**
   * 为预选择加载专业数据（不显示loading）
   */
  private async loadMajorsForPreSelection(): Promise<void> {
    if (this.collegeId === '') {
      return;
    }

    try {
      const response = await this.collegeApiService.getAllMajors(this.collegeId);
      if (response.code === 200 && response.data) {
        this.majorList = response.data;
        console.info(`加载了${this.majorList.length}个专业`);
      } else {
        console.warn(`加载专业失败: ${response.msg || '未知错误'}`);
        this.majorList = []; // 确保是空数组
      }
    } catch (error) {
      console.error('Load majors for preselection failed:', error);
      this.majorList = []; // 确保是空数组
    }
  }

  /**
   * 为预选择加载班级数据（不显示loading）
   */
  private async loadClassesForPreSelection(): Promise<void> {
    if (this.majorId === '') {
      return;
    }

    try {
      const response = await this.collegeApiService.getAllClasses(this.majorId);
      if (response.code === 200 && response.data) {
        this.classList = response.data;
        console.info(`加载了${this.classList.length}个班级`);
      } else {
        console.warn(`加载班级失败: ${response.msg || '未知错误'}`);
        this.classList = []; // 确保是空数组
      }
    } catch (error) {
      console.error('Load classes for preselection failed:', error);
      this.classList = []; // 确保是空数组
    }
  }

  private async handleCollegeClick(): Promise<void> {
    console.info('点击学院选择');

    if (this.collegeList.length === 0) {
      console.info('学院列表为空，重新加载');
      await this.loadInitialData();
    }

    if (this.collegeList.length > 0) {
      console.info(`准备显示学院选择器，共${this.collegeList.length}个学院`);
      // 初始化临时选择状态为当前选择
      this.tempCollegeIndex = this.selectedCollegeIndex;
      this.showCollegePicker = true;
    } else {
      console.error('学院列表仍然为空，无法显示选择器');
    }
  }

  private async handleCollegeSelect(index: number): Promise<void> {
    if (index >= 0 && index < this.collegeList.length) {
      const selectedCollege = this.collegeList[index];
      this.collegeId = selectedCollege.collegeId; // 直接使用，已经是字符串
      this.collegeName = selectedCollege.collegeName;
      this.selectedCollegeIndex = index;

      this.resetMajorAndClass();
      await this.loadMajors();
    }
  }

  private async handleMajorClick(): Promise<void> {
    console.info('点击专业选择');

    if (this.collegeId === '') {
      console.warn('未选择学院，无法选择专业');
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorList.length === 0) {
      console.info('专业列表为空，重新加载');
      await this.loadMajors();
    }

    if (this.majorList.length > 0) {
      console.info(`准备显示专业选择器，共${this.majorList.length}个专业`);
      // 初始化临时选择状态为当前选择
      this.tempMajorIndex = this.selectedMajorIndex;
      this.showMajorPicker = true;
    } else {
      console.error('专业列表仍然为空，无法显示选择器');
      promptAction.showToast({
        message: '该学院暂无专业数据',
        duration: 2000
      });
    }
  }

  private async handleMajorSelect(index: number): Promise<void> {
    if (index >= 0 && index < this.majorList.length) {
      const selectedMajor = this.majorList[index];
      this.majorId = selectedMajor.majorId; // 直接使用，已经是字符串
      this.majorName = selectedMajor.majorName;
      this.selectedMajorIndex = index;

      this.resetClass();
      await this.loadClasses();
    }
  }

  private async handleClassClick(): Promise<void> {
    console.info('点击班级选择');

    if (this.collegeId === '') {
      console.warn('未选择学院，无法选择班级');
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorId === '') {
      console.warn('未选择专业，无法选择班级');
      promptAction.showToast({
        message: '请选择专业',
        duration: 2000
      });
      return;
    }

    if (this.classList.length === 0) {
      console.info('班级列表为空，重新加载');
      await this.loadClasses();
    }

    if (this.classList.length > 0) {
      console.info(`准备显示班级选择器，共${this.classList.length}个班级`);
      // 初始化临时选择状态为当前选择
      this.tempClassIndex = this.selectedClassIndex;
      this.showClassPicker = true;
    } else {
      console.error('班级列表仍然为空，无法显示选择器');
      promptAction.showToast({
        message: '该专业暂无班级数据',
        duration: 2000
      });
    }
  }

  private handleClassSelect(index: number): void {
    if (index >= 0 && index < this.classList.length) {
      const selectedClass = this.classList[index];
      this.classId = selectedClass.classId; // 直接使用，已经是字符串
      this.className = selectedClass.className;
      this.selectedClassIndex = index;
    }
  }

  private async loadMajors(): Promise<void> {
    if (this.collegeId === '') {
      return;
    }

    try {
      this.isLoading = true;
      const response = await this.collegeApiService.getAllMajors(this.collegeId);
      this.majorList = response.data;
    } catch (error) {
      console.error('Load majors failed:', error);
      promptAction.showToast({
        message: '加载专业信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async loadClasses(): Promise<void> {
    if (this.majorId === '') {
      return;
    }

    try {
      this.isLoading = true;
      const response = await this.collegeApiService.getAllClasses(this.majorId);
      this.classList = response.data;
    } catch (error) {
      console.error('Load classes failed:', error);
      promptAction.showToast({
        message: '加载班级信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private resetMajorAndClass(): void {
    this.majorName = '请选择专业';
    this.majorId = '';
    this.selectedMajorIndex = 0;
    this.majorList = [];

    this.resetClass();
  }

  private resetClass(): void {
    this.className = '请选择班级';
    this.classId = '';
    this.selectedClassIndex = 0;
    this.classList = [];
  }

  private async handleNextStep(): Promise<void> {
    if (this.collegeId === '') {
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorId === '') {
      promptAction.showToast({
        message: '请选择专业',
        duration: 2000
      });
      return;
    }

    if (this.classId === '') {
      promptAction.showToast({
        message: '请选择班级',
        duration: 2000
      });
      return;
    }

    const userSelection: UserSelection = {
      collegeId: this.collegeId,
      collegeName: this.collegeName,
      majorId: this.majorId,
      majorName: this.majorName,
      classId: this.classId,
      className: this.className
    };

    // 检查用户之前是否已有完整信息（用于判断是首次设置还是修改设置）
    const hadCompleteInfo = this.userInfoManager.hasCompleteUserInfo();

    // 保存用户选择到PreferencesUtil
    this.userInfoManager.saveCollegeInfo(userSelection.collegeId, userSelection.collegeName);
    this.userInfoManager.saveMajorInfo(userSelection.majorId, userSelection.majorName);
    this.userInfoManager.saveClassInfo(userSelection.classId, userSelection.className);

    promptAction.showToast({
      message: '保存成功',
      duration: 1000
    });

    setTimeout(() => {
      if (hadCompleteInfo) {
        // 用户之前已有完整信息，说明是从首页切换过来的，直接返回主页面
        this.pathStack.replacePathByName('MainTabNavPage', null);
      } else {
        // 用户之前没有完整信息，说明是首次设置，跳转到欢迎页面
        this.pathStack.replacePathByName('WelcomeNavPage', null);
      }
    }, 1000);
  }
}