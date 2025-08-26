import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UserInfoManager } from '../common/utils/UserInfoManager';
import { CourseApiService } from '../services/api/CourseApiService';
import { AppConfigManager } from '../services/AppConfigManager';
import { CourseInfo } from '../models/CourseModels';

interface TodayParm {
  year: number;
  week: number;
  termCode: string;
  weekDay: string;
}

interface TodayCourseFormData {
  formId: string;
  todayCourses: CourseInfo[];
  isLoading: boolean;
}

const TAG: string = 'EntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {
  private courseApiService: CourseApiService = CourseApiService.getInstance();
  private appConfigManager: AppConfigManager = AppConfigManager.getInstance();
  private userInfoManager: UserInfoManager = UserInfoManager.getInstance();

  onAddForm(want: Want) {
    if (!want || !want.parameters) {
      hilog.error(0x0000, TAG, `FormAbility onAddForm want or want.parameters is undefined`);
      return formBindingData.createFormBindingData('');
    }

    let formName: string = want.parameters[formInfo.FormParam.NAME_KEY] as string;
    let formId: string = want.parameters[formInfo.FormParam.IDENTITY_KEY] as string;

    hilog.info(0x0000, TAG, `FormAbility onAddForm, formId = ${formId}, formName = ${formName}`);

    if (formName === 'todayCourse') {
      hilog.info(0x0000, TAG, `🎯 [FormAbility] 创建todayCourse`);

      let formData: TodayCourseFormData = {
        formId: formId,
        todayCourses: [],
        isLoading: true
      };

      // 异步加载今日课程数据
      this.loadTodayCourses(formId);

      return formBindingData.createFormBindingData(formData);
    }

    return formBindingData.createFormBindingData('');
  }

  onCastToNormalForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onCastToNormalForm, formId = ${formId}`);
  }

  onUpdateForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onUpdateForm, formId = ${formId}`);
    this.loadTodayCourses(formId);
  }

  onFormEvent(formId: string, message: string) {
    hilog.info(0x0000, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);
    this.loadTodayCourses(formId);
  }

  onRemoveForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onRemoveForm, formId = ${formId}`);
  }

  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }

  private async loadTodayCourses(formId: string): Promise<void> {
    try {
      // 先更新为加载状态
      let loadingFormData: TodayCourseFormData = {
        formId: formId,
        todayCourses: [],
        isLoading: true
      };
      let loadingFormMsg: formBindingData.FormBindingData = formBindingData.createFormBindingData(loadingFormData);
      formProvider.updateForm(formId, loadingFormMsg);

      await this.appConfigManager.initialize();

      // 获取用户班级信息
      const classId = this.userInfoManager.getClassId(this.context);

      hilog.info(0x0000, TAG, `👤 [FormAbility] 用户班级: ${classId}`);
      
      if (!classId) {
        hilog.warn(0x0000, TAG, '未找到用户班级信息');
        return;
      }

      const todayParams = this.initTodayParams();
      if (!todayParams) {
        hilog.warn(0x0000, TAG, '无法获取今日课程参数');
        return;
      }

      hilog.info(0x0000, TAG,
        `🔍 [Today Course Form] 加载课程: year=${todayParams.year}, week=${todayParams.week}, weekDay=${todayParams.weekDay}, term=${todayParams.termCode}`);

      // TODO 模拟
      const response = await this.courseApiService.getTodayCourseList(
        classId,
        todayParams.year,
        todayParams.termCode,
        todayParams.week,
        todayParams.weekDay
      );

      if (response.code === 200 && response.data) {
        this.updateFormData(formId, response.data, false);
      } else {
        hilog.warn(0x0000, TAG, '获取今日课程失败');
      }

    } catch (error) {
      hilog.error(0x0000, TAG, '加载今日课程失败:', JSON.stringify(error));
    }
  }

  private updateFormData(formId: string, courses: CourseInfo[], isLoading: boolean): void {
    let formData: TodayCourseFormData = {
      formId: formId,
      todayCourses: courses,
      isLoading: isLoading
    };
    let formMsg: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formMsg).then(() => {
      hilog.info(0x0000, TAG, `updateForm success, courses: ${courses.length}`);
    }).catch((error: Error) => {
      hilog.error(0x0000, TAG, 'updateForm failed.%s', JSON.stringify(error));
    });
  }

  private initTodayParams(): TodayParm | null {
    const currentStatus = this.appConfigManager.getCurrentStatus();
    if (!currentStatus || !currentStatus.currentSemester) {
      hilog.warn(0x0000, TAG, '未找到当前学期信息');
      return null;
    }

    const today = new Date();
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    const weekDayStr = weekdays[today.getDay()];

    return {
      year: parseInt(currentStatus.currentSemester.academicYear),
      week: currentStatus.currentWeek,
      termCode: currentStatus.currentSemester.semester === 1 ? '3' : '12',
      weekDay: weekDayStr
    };
  }
}