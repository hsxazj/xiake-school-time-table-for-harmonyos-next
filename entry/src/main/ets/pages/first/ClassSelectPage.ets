import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { SelectItem } from '../../components/base/SelectItem';
import { CustomPicker, PickerItem } from '../../components/base/CustomPicker';
import { CollegeApiService } from '../../services/api/CollegeApiService';
import { UserInfoManager } from '../../common/constants/PreferencesUtil';
import { ClassInfo, College, Major, UserSelection } from '../../models/CollegeModels';

@Entry
@Component
struct CollegeSelectPage {
  @State private isLoading: boolean = false;
  @State private collegeName: string = '请选择学院';
  @State private majorName: string = '请选择专业';
  @State private className: string = '请选择班级';
  @State private collegeId: number = 0;
  @State private majorId: number = 0;
  @State private classId: number = 0;
  @State private collegeList: College[] = [];
  @State private majorList: Major[] = [];
  @State private classList: ClassInfo[] = [];
  @State private selectedCollegeIndex: number = 0;
  @State private selectedMajorIndex: number = 0;
  @State private selectedClassIndex: number = 0;
  private collegeApiService: CollegeApiService = CollegeApiService.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();
  private collegePickerController: CustomDialogController = new CustomDialogController({
    builder: CustomPicker({
      items: [],
      selectedIndex: 0,
      title: '选择学院',
      onConfirm: (item: PickerItem, index: number) => {
        this.handleCollegeSelect(index);
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: false, // 禁用自动取消，让我们的动画处理
    maskColor: Color.Transparent  // 透明蒙版，我们自己处理
  });
  private majorPickerController: CustomDialogController = new CustomDialogController({
    builder: CustomPicker({
      items: [],
      selectedIndex: 0,
      title: '选择专业',
      onConfirm: (item: PickerItem, index: number) => {
        this.handleMajorSelect(index);
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: false,
    maskColor: Color.Transparent
  });
  private classPickerController: CustomDialogController = new CustomDialogController({
    builder: CustomPicker({
      items: [],
      selectedIndex: 0,
      title: '选择班级',
      onConfirm: (item: PickerItem, index: number) => {
        this.handleClassSelect(index);
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: false,
    maskColor: Color.Transparent
  });

  aboutToAppear(): void {
    this.loadInitialData();
  }

  build() {
    Column() {
      Text('打造属于你的课表吧！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#179FA2')
        .margin({
          top: 120,
          bottom: 40,
          left: 20,
          right: 20
        })
        .textAlign(TextAlign.Start)
        .width('100%')

      Column() {
        SelectItem({
          icon: $r('app.media.startIcon'),
          title: this.collegeName,
          iconBackgroundColor: '#F2FAF4',
          iconShadowColor: 'rgba(36, 194, 198, 0.2)',
          isSelected: this.collegeId !== 0,
          onTap: () => this.handleCollegeClick()
        })

        SelectItem({
          icon: $r('app.media.startIcon'),
          title: this.majorName,
          iconBackgroundColor: '#E0EFFF',
          iconShadowColor: 'rgba(126, 175, 252, 0.3)',
          isSelected: this.majorId !== 0,
          onTap: () => this.handleMajorClick()
        })

        SelectItem({
          icon: $r('app.media.startIcon'),
          title: this.className,
          iconBackgroundColor: '#FFF3E9',
          iconShadowColor: 'rgba(250, 207, 94, 0.2)',
          isSelected: this.classId !== 0,
          onTap: () => this.handleClassClick()
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
        .backgroundColor('#45CAD9')
        .borderRadius(22)
        .margin({ bottom: 60 })
        .shadow({
          radius: 20,
          color: 'rgba(157, 224, 231, 0.6)',
          offsetY: 0
        })
        .onClick(() => this.handleNextStep())

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .color('#45CAD9')
          .position({ x: '50%', y: '50%' })
          .translate({ x: '-50%', y: '-50%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
    .justifyContent(FlexAlign.Start)
  }

  private async loadInitialData(): Promise<void> {
    try {
      this.isLoading = true;
      const response = await this.collegeApiService.getAllColleges();
      this.collegeList = response.data;
    } catch (error) {
      console.error('Load colleges failed:', error);
      promptAction.showToast({
        message: '加载学院信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private createCollegePickerData(): PickerItem[] {
    return this.collegeList.map((item: College): PickerItem => {
      const pickerItem: PickerItem = { id: item.collegeId, name: item.collegeName };
      return pickerItem;
    });
  }

  private createMajorPickerData(): PickerItem[] {
    return this.majorList.map((item: Major): PickerItem => {
      const pickerItem: PickerItem = { id: item.majorId, name: item.majorName };
      return pickerItem;
    });
  }

  private createClassPickerData(): PickerItem[] {
    return this.classList.map((item: ClassInfo): PickerItem => {
      const pickerItem: PickerItem = { id: item.classId, name: item.className };
      return pickerItem;
    });
  }

  private async handleCollegeClick(): Promise<void> {
    if (this.collegeList.length === 0) {
      await this.loadInitialData();
    }

    if (this.collegeList.length > 0) {
      this.collegePickerController.close();
      this.collegePickerController = new CustomDialogController({
        builder: CustomPicker({
          items: this.createCollegePickerData(),
          selectedIndex: this.selectedCollegeIndex,
          title: '选择学院',
          onConfirm: (item: PickerItem, index: number) => {
            this.handleCollegeSelect(index);
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true
      });
      this.collegePickerController.open();
    }
  }

  private async handleCollegeSelect(index: number): Promise<void> {
    if (index >= 0 && index < this.collegeList.length) {
      const selectedCollege = this.collegeList[index];
      this.collegeId = selectedCollege.collegeId;
      this.collegeName = selectedCollege.collegeName;
      this.selectedCollegeIndex = index;

      this.resetMajorAndClass();
      await this.loadMajors();
    }
  }

  private async handleMajorClick(): Promise<void> {
    if (this.collegeId === 0) {
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorList.length === 0) {
      await this.loadMajors();
    }

    if (this.majorList.length > 0) {
      this.majorPickerController.close();
      this.majorPickerController = new CustomDialogController({
        builder: CustomPicker({
          items: this.createMajorPickerData(),
          selectedIndex: this.selectedMajorIndex,
          title: '选择专业',
          onConfirm: (item: PickerItem, index: number) => {
            this.handleMajorSelect(index);
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true
      });
      this.majorPickerController.open();
    }
  }

  private async handleMajorSelect(index: number): Promise<void> {
    if (index >= 0 && index < this.majorList.length) {
      const selectedMajor = this.majorList[index];
      this.majorId = selectedMajor.majorId;
      this.majorName = selectedMajor.majorName;
      this.selectedMajorIndex = index;

      this.resetClass();
      await this.loadClasses();
    }
  }

  private async handleClassClick(): Promise<void> {
    if (this.collegeId === 0) {
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorId === 0) {
      promptAction.showToast({
        message: '请选择专业',
        duration: 2000
      });
      return;
    }

    if (this.classList.length === 0) {
      await this.loadClasses();
    }

    if (this.classList.length > 0) {
      this.classPickerController.close();
      this.classPickerController = new CustomDialogController({
        builder: CustomPicker({
          items: this.createClassPickerData(),
          selectedIndex: this.selectedClassIndex,
          title: '选择班级',
          onConfirm: (item: PickerItem, index: number) => {
            this.handleClassSelect(index);
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true
      });
      this.classPickerController.open();
    }
  }

  private handleClassSelect(index: number): void {
    if (index >= 0 && index < this.classList.length) {
      const selectedClass = this.classList[index];
      this.classId = selectedClass.classId;
      this.className = selectedClass.className;
      this.selectedClassIndex = index;
    }
  }

  private async loadMajors(): Promise<void> {
    if (this.collegeId === 0) {
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
    if (this.majorId === 0) {
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
    this.majorId = 0;
    this.selectedMajorIndex = 0;
    this.majorList = [];

    this.resetClass();
  }

  private resetClass(): void {
    this.className = '请选择班级';
    this.classId = 0;
    this.selectedClassIndex = 0;
    this.classList = [];
  }

  private async handleNextStep(): Promise<void> {
    if (this.collegeId === 0) {
      promptAction.showToast({
        message: '请选择学院',
        duration: 2000
      });
      return;
    }

    if (this.majorId === 0) {
      promptAction.showToast({
        message: '请选择专业',
        duration: 2000
      });
      return;
    }

    if (this.classId === 0) {
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

    // 保存用户选择到PreferencesUtil
    this.userInfoManager.saveCollegeInfo(userSelection.collegeId.toString(), userSelection.collegeName);
    this.userInfoManager.saveMajorInfo(userSelection.majorId.toString(), userSelection.majorName);
    this.userInfoManager.saveClassInfo(userSelection.classId.toString(), userSelection.className);

    promptAction.showToast({
      message: '保存成功',
      duration: 1000
    });

    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/MainTabPage'
      });
    }, 1000);
  }
}