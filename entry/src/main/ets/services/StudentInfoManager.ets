/**
 * 学生信息管理器
 *
 * 职责：
 * - 管理学生个人信息的持久化存储和内存缓存
 * - 提供全局访问接口（AppStorage）
 * - 支持 @Provide/@Consume 模式
 *
 * 使用方法：
 * ```typescript
 * // 保存学生信息
 * StudentInfoManager.saveStudentInfo(context, studentInfo);
 *
 * // 加载学生信息到内存（应用启动时调用）
 * await StudentInfoManager.loadStudentInfoToMemory(context);
 *
 * // 从内存获取学生信息
 * const info = StudentInfoManager.getStudentInfoFromMemory();
 *
 * // 在组件中使用 @StorageLink
 * @StorageLink('student_info') studentInfo: StudentInfo | null = null;
 * ```
 *
 * @since 2026-01-08
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { StudentInfo } from './jwxt/JwxtGetInfoService';

const DOMAIN: number = 0x0010;
const TAG: string = 'StudentInfoManager';

// 首选项存储 key
const STORAGE_KEY_STUDENT_INFO = 'cached_student_info';

// AppStorage key（用于全局访问）
export const APP_STORAGE_KEY_STUDENT_INFO = 'student_info';

/**
 * 学生信息管理器类
 * 单例模式
 */
export class StudentInfoManager {
  private static instance: StudentInfoManager;

  private constructor() {
    hilog.info(DOMAIN, TAG, '✅ StudentInfoManager 初始化完成');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): StudentInfoManager {
    if (!StudentInfoManager.instance) {
      StudentInfoManager.instance = new StudentInfoManager();
    }
    return StudentInfoManager.instance;
  }

  /**
   * 保存学生信息到首选项和内存
   *
   * @param context 应用上下文
   * @param studentInfo 学生信息
   */
  public saveStudentInfo(context: Context, studentInfo: StudentInfo): void {
    try {
      // 1. 保存到首选项（持久化）
      const jsonStr = JSON.stringify(studentInfo);
      PreferencesUtil.getInstance().putValue(context, STORAGE_KEY_STUDENT_INFO, jsonStr, true);
      hilog.info(DOMAIN, TAG, `✅ [Save] 学生信息已保存到首选项: ${studentInfo.name} (${studentInfo.student_id})`);

      // 2. 保存到 AppStorage（内存，全局访问）
      AppStorage.setOrCreate<StudentInfo>(APP_STORAGE_KEY_STUDENT_INFO, studentInfo);
      hilog.info(DOMAIN, TAG, `✅ [Save] 学生信息已加载到内存`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Save] 保存学生信息失败: ${errorMsg}`);
    }
  }

  /**
   * 从首选项加载学生信息到内存
   *
   * @param context 应用上下文
   * @returns 成功返回 true，失败或不存在返回 false
   */
  public async loadStudentInfoToMemory(context: Context): Promise<boolean> {
    try {
      const jsonStr = PreferencesUtil.getInstance().getValue(
        context,
        STORAGE_KEY_STUDENT_INFO,
        ''
      ) as string;

      if (!jsonStr) {
        hilog.info(DOMAIN, TAG, `📭 [Load] 首选项中无学生信息缓存`);
        return false;
      }

      const studentInfo: StudentInfo = JSON.parse(jsonStr);

      // 加载到 AppStorage
      AppStorage.setOrCreate<StudentInfo>(APP_STORAGE_KEY_STUDENT_INFO, studentInfo);

      hilog.info(DOMAIN, TAG, `✅ [Load] 学生信息已加载到内存: ${studentInfo.name} (${studentInfo.student_id})`);
      return true;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Load] 加载学生信息失败: ${errorMsg}`);
      return false;
    }
  }

  /**
   * 从内存获取学生信息
   *
   * @returns 学生信息，如果不存在返回 null
   */
  public getStudentInfoFromMemory(): StudentInfo | null {
    try {
      const studentInfo = AppStorage.get<StudentInfo>(APP_STORAGE_KEY_STUDENT_INFO);
      if (studentInfo) {
        hilog.info(DOMAIN, TAG, `✅ [Get] 从内存获取学生信息: ${studentInfo.name}`);
        return studentInfo;
      } else {
        hilog.info(DOMAIN, TAG, `📭 [Get] 内存中无学生信息`);
        return null;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Get] 获取学生信息失败: ${errorMsg}`);
      return null;
    }
  }

  /**
   * 清除学生信息（从首选项和内存）
   *
   * @param context 应用上下文
   */
  public clearStudentInfo(context: Context): void {
    try {
      // 1. 从首选项删除
      PreferencesUtil.getInstance().removeValue(context, STORAGE_KEY_STUDENT_INFO);
      hilog.info(DOMAIN, TAG, `🗑️ [Clear] 已从首选项删除学生信息`);

      // 2. 从 AppStorage 删除
      AppStorage.delete(APP_STORAGE_KEY_STUDENT_INFO);
      hilog.info(DOMAIN, TAG, `🗑️ [Clear] 已从内存删除学生信息`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `❌ [Clear] 清除学生信息失败: ${errorMsg}`);
    }
  }

  /**
   * 检查是否有学生信息缓存
   *
   * @param context 应用上下文
   * @returns 有缓存返回 true，否则返回 false
   */
  public hasStudentInfo(context: Context): boolean {
    const jsonStr = PreferencesUtil.getInstance().getValue(
      context,
      STORAGE_KEY_STUDENT_INFO,
      ''
    ) as string;
    return !!jsonStr;
  }
}
