import { formBindingData, formProvider } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CourseInfo } from '../models/CourseModels';

const TAG: string = 'FormService';

interface TodayCourseFormData {
  formId: string;
  todayCourses: CourseInfo[];
  isLoading: boolean;
}

/**
 * 卡片管理服务：主要负责卡片ID的存储管理和触发更新
 */
export class FormService {
  private static instance: FormService;

  private constructor() {
  }

  public static getInstance(): FormService {
    if (!FormService.instance) {
      FormService.instance = new FormService();
    }
    return FormService.instance;
  }

  /**
   * 添加卡片ID到首选项列表
   */
  public async addFormIdToPreferences(context: Context, formId: string): Promise<void> {
    try {
      // 使用同步方法避免竞态条件
      const pref = await preferences.getPreferences(context, 'form_store');

      // 使用同步获取，避免并发时的数据覆盖问题
      const existingFormIds = pref.getSync('todayCourseForms', []) as string[];
      hilog.info(0x0000, TAG, `当前已有的formIds: ${JSON.stringify(existingFormIds)}`);
      hilog.info(0x0000, TAG, `准备添加的formId: ${formId}`);

      if (!existingFormIds.includes(formId)) {
        existingFormIds.push(formId);
        // 使用同步方法立即写入和刷新
        pref.putSync('todayCourseForms', existingFormIds);
        pref.flushSync();
        hilog.info(0x0000, TAG, `FormId ${formId} added to preferences. Total forms: ${existingFormIds.length}`);
        hilog.info(0x0000, TAG, `更新后的formIds列表: ${JSON.stringify(existingFormIds)}`);
      } else {
        hilog.info(0x0000, TAG, `FormId ${formId} already exists in preferences`);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to add formId to preferences: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从首选项列表中移除卡片ID
   */
  public async removeFormIdFromPreferences(context: Context, formId: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, 'form_store');
      // 使用同步方法避免竞态条件
      const existingFormIds = pref.getSync('todayCourseForms', []) as string[];
      hilog.info(0x0000, TAG, `移除前的formIds: ${JSON.stringify(existingFormIds)}`);
      hilog.info(0x0000, TAG, `准备移除的formId: ${formId}`);

      const updatedFormIds = existingFormIds.filter(id => id !== formId);
      if (updatedFormIds.length !== existingFormIds.length) {
        // 使用同步方法立即写入和刷新
        pref.putSync('todayCourseForms', updatedFormIds);
        pref.flushSync();
        hilog.info(0x0000, TAG, `FormId ${formId} removed from preferences. Remaining forms: ${updatedFormIds.length}`);
        hilog.info(0x0000, TAG, `移除后的formIds列表: ${JSON.stringify(updatedFormIds)}`);
      } else {
        hilog.info(0x0000, TAG, `FormId ${formId} not found in preferences`);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to remove formId from preferences: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取所有活跃的卡片ID列表
   */
  public async getActiveFormIds(context: Context | undefined): Promise<string[]> {
    try {
      if (!context) {
        hilog.error(0x0000, TAG, '未提供上下文，无法获取活跃卡片列表');
        return [];
      }
      const pref = await preferences.getPreferences(context, 'form_store');
      const formIds = pref.getSync('todayCourseForms', []) as string[];
      hilog.info(0x0000, TAG, `获取到的活跃formIds: ${JSON.stringify(formIds)}`);
      return formIds;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to get active form ids: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 手动更新所有活跃卡片的数据
   * @param context 上下文
   * @param todayCourses 今日课程数据
   * @param classId 班级ID（可选）
   */
  public updateAllActiveWidgetsWithData(context: Context | undefined, todayCourses: CourseInfo[]): void {
    this.getActiveFormIds(context).then((activeFormIds) => {
      hilog.info(0x0000, TAG, `开始更新所有卡片数据，共找到 ${activeFormIds.length} 个卡片`);

      if (activeFormIds.length === 0) {
        hilog.info(0x0000, TAG, '没有找到活跃的卡片，跳过更新');
        return;
      }

      // 逐个更新每个卡片的数据
      for (const formId of activeFormIds) {
        try {
          hilog.info(0x0000, TAG, `更新卡片数据: ${formId}, 课程数量: ${todayCourses.length}`);

          // 使用最简单的数据结构进行测试
          const updateData = formBindingData.createFormBindingData({
            todayCourses: todayCourses,
            isLoading: false,
            timestamp: Date.now() // 添加时间戳确保数据变化
          });

          hilog.info(0x0000, TAG, `准备更新formId: ${formId}`);

          formProvider.updateForm(formId, updateData).then(() => {
            hilog.info(0x0000, TAG, `✅ 卡片 ${formId} 数据更新成功`);
          }).catch((error: Error) => {
            hilog.error(0x0000, TAG, `❌ 卡片 ${formId} 数据更新失败: ${JSON.stringify(error)}`);
            // 如果是16501001错误，可能是formId无效，尝试从列表中移除
            if (error.message && error.message.includes('16501001')) {
              hilog.warn(0x0000, TAG, `FormId ${formId} 可能已无效，考虑从列表中移除`);
            }
          });
        } catch (error) {
          hilog.error(0x0000, TAG, `更新卡片 ${formId} 数据出现异常: ${JSON.stringify(error)}`);
        }
      }

      hilog.info(0x0000, TAG, '所有卡片数据更新完成');
    }).catch((error: Error) => {
      hilog.error(0x0000, TAG, `获取活跃卡片列表失败: ${JSON.stringify(error)}`);
    });
  }

  /**
   * 触发所有活跃卡片重新加载数据（用于班级变化等场景）
   * @param context 上下文
   * @param newClassId 新班级ID（可选）
   */
  public updateAllActiveWidgets(context: Context | undefined, newClassId?: string): void {
    this.getActiveFormIds(context).then((activeFormIds) => {
      hilog.info(0x0000, TAG, `开始触发所有卡片更新，共找到 ${activeFormIds.length} 个卡片`);

      if (activeFormIds.length === 0) {
        hilog.info(0x0000, TAG, '没有找到活跃的卡片，跳过更新');
        return;
      }

      // 逐个触发每个卡片的更新
      for (const formId of activeFormIds) {
        try {
          hilog.info(0x0000, TAG, `触发卡片更新: ${formId}`);

          // 如果提供了新的班级ID，只传递相关信息，不传递完整的卡片数据
          let updateData: formBindingData.FormBindingData;
          if (newClassId) {
            // 传递简单的触发信息，让卡片自己处理数据更新
            updateData = formBindingData.createFormBindingData({
              trigger: 'classChanged',
              newClassId: newClassId
            });
            hilog.info(0x0000, TAG, `传递给卡片的新班级ID: ${newClassId}`);
          } else {
            // 只传递触发信息
            updateData = formBindingData.createFormBindingData({ trigger: 'refresh' });
            hilog.info(0x0000, TAG, '触发卡片刷新');
          }

          formProvider.updateForm(formId, updateData).then(() => {
            hilog.info(0x0000, TAG, `卡片 ${formId} 更新触发完成`);
          }).catch((error: Error) => {
            hilog.error(0x0000, TAG, `触发卡片 ${formId} 更新失败: ${JSON.stringify(error)}`);
          });
        } catch (error) {
          hilog.error(0x0000, TAG, `触发卡片 ${formId} 更新出现异常: ${JSON.stringify(error)}`);
        }
      }

      hilog.info(0x0000, TAG, '所有卡片更新触发完成');
    }).catch((error: Error) => {
      hilog.error(0x0000, TAG, `获取活跃卡片列表失败: ${JSON.stringify(error)}`);
    });
  }
}