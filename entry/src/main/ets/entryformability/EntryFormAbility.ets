import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UserInfoManager } from '../common/utils/UserInfoManager';
import { CourseApiService } from '../services/api/CourseApiService';
import { AppConfigManager } from '../services/AppConfigManager';
import { CourseInfo } from '../models/CourseModels';
import { FormService } from '../services/FormService';

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
  private formService: FormService = FormService.getInstance();

   onAddForm(want: Want) {
    if (!want || !want.parameters) {
      hilog.error(0x0000, TAG, `FormAbility onAddForm want or want.parameters is undefined`);
      return formBindingData.createFormBindingData('');
    }

    let formName: string = want.parameters[formInfo.FormParam.NAME_KEY] as string;
    let formId: string = want.parameters[formInfo.FormParam.IDENTITY_KEY] as string;

    hilog.info(0x0000, TAG, `FormAbility onAddForm, formId = ${formId}, formName = ${formName}`);

    hilog.info(0x0000, TAG, `🎯 [FormAbility] 创建${formName}`)

    if (formName === 'todayCourse') {
      hilog.info(0x0000, TAG, `🎯 [FormAbility] 创建todayCourse`);

      // 异步添加 formId 到首选项列表（但不阻塞返回）
      this.formService.addFormIdToPreferences(this.context, formId).then(() => {
        hilog.info(0x0000, TAG, `FormId ${formId} 添加到首选项成功`);
      }).catch((error:Error) => {
        hilog.error(0x0000, TAG, `FormId ${formId} 添加到首选项失败: ${JSON.stringify(error)}`);
      });

      let initFormData: TodayCourseFormData = {
        formId: formId,
        todayCourses: [],
        isLoading: true
      };

      // 异步加载今日课程数据
      this.loadTodayCourses(formId);

      return formBindingData.createFormBindingData(initFormData);
    }

    return formBindingData.createFormBindingData('');
  }

  onCastToNormalForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onCastToNormalForm, formId = ${formId}`);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object> | undefined) {
    hilog.info(0x0000, TAG, `FormAbility onUpdateForm, formId = ${formId}`);
    hilog.info(0x0000, TAG, `接收到的参数: ${JSON.stringify(wantParams)}`);
    
    // 检查是否传递了新的班级ID
    let newClassId: string | undefined;
    if (wantParams) {
      if (wantParams['newClassId']) {
        newClassId = wantParams['newClassId'] as string;
        hilog.info(0x0000, TAG, `接收到主应用传递的新班级ID: ${newClassId}`);
      }
      
      if (wantParams['trigger']) {
        const trigger = wantParams['trigger'] as string;
        hilog.info(0x0000, TAG, `接收到触发信号: ${trigger}`);
      }
    }
    
    this.loadTodayCourses(formId, newClassId);
  }


  onFormEvent(formId: string, message: string) {
    hilog.info(0x0000, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);
    this.loadTodayCourses(formId);
  }

  onRemoveForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onRemoveForm, formId = ${formId}`);
    // 从首选项列表中移除 formId（异步执行）
    this.formService.removeFormIdFromPreferences(this.context, formId).then(() => {
      hilog.info(0x0000, TAG, `FormId ${formId} 从首选项移除成功`);
    }).catch((error:Error) => {
      hilog.error(0x0000, TAG, `FormId ${formId} 从首选项移除失败: ${JSON.stringify(error)}`);
    });
  }

  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }

  private async loadTodayCourses(formId: string, overrideClassId?: string): Promise<void> {
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
      
      // 优先使用传递的班级ID，否则从首选项中获取
      const classId = overrideClassId || this.userInfoManager.getClassId(this.context);

      hilog.info(0x0000, TAG, `👤 [FormAbility] 使用班级ID: ${classId} (来源: ${overrideClassId ? '主应用传递' : '首选项获取'})`);

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
        2025,
        '3',
        3,
        '星期一'
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