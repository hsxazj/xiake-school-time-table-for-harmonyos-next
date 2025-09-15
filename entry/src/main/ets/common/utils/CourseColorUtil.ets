import { CourseInfo } from '../../models/CourseModels';

/**
 * 课程颜色工具类
 * 提供统一的课程颜色计算逻辑，避免代码重复
 */
export class CourseColorUtil {
  // 背景颜色数组（浅色调）
  private static readonly BACKGROUND_COLORS: string[] = [
    '#E3F2FD', '#F3E5F5', '#E8F5E8', '#FFF3E0',
    '#F1F8E9', '#FCE4EC', '#E0F2F1', '#FFF8E1',
    '#F9FBE7', '#E1F5FE', '#FAE8E4', '#F3E5AB',
    '#E8EAF6', '#FFEBEE', '#E0F7FA', '#FFF9C4',
    '#F1F8F0', '#FFEAA7', '#DDD6FE', '#FEF3C7'
  ];
  // 文字颜色数组（深色调）
  private static readonly TEXT_COLORS: string[] = [
    '#1565C0', '#7B1FA2', '#2E7D32', '#EF6C00',
    '#558B2F', '#C2185B', '#00695C', '#F57F17',
    '#689F38', '#0277BD', '#D84315', '#F9A825',
    '#5E35B1', '#C62828', '#00838F', '#AFB42B',
    '#388E3C', '#FF8F00', '#512DA8', '#FBC02D'
  ];
  // 边框颜色数组（中等色调）
  private static readonly BORDER_COLORS: string[] = [
    '#42A5F5', '#BA68C8', '#66BB6A', '#FF9800',
    '#8BC34A', '#E91E63', '#26A69A', '#FFEB3B',
    '#9CCC65', '#29B6F6', '#FF5722', '#FDD835',
    '#9575CD', '#F44336', '#00BCD4', '#CDDC39',
    '#4CAF50', '#FFC107', '#673AB7', '#FFEB3B'
  ];

  /**
   * 获取课程颜色索引
   * @param courseName 课程名称
   * @param coursesList 课程列表（用于查找索引，可选）
   * @returns 颜色索引
   */
  public static getCourseColorIndex(courseName: string, coursesList?: string[]): number {
    let index = -1;

    // 如果提供了课程列表，优先从列表中查找索引
    if (coursesList && coursesList.length > 0) {
      index = coursesList.indexOf(courseName);
    }

    // 如果找不到，使用hash算法计算
    if (index === -1) {
      let hash = 0;
      for (let i = 0; i < courseName.length; i++) {
        hash = courseName.charCodeAt(i) + ((hash << 5) - hash);
      }
      index = Math.abs(hash);
    }

    // 如果index大于10，取余操作
    if (index > 10) {
      index = index % 10;
    }

    return index;
  }

  /**
   * 获取课程背景颜色
   * @param courseName 课程名称
   * @param coursesList 课程列表（可选）
   * @returns 背景颜色
   */
  public static getCourseBackgroundColor(courseName: string, coursesList?: string[]): string {
    const colorIndex = CourseColorUtil.getCourseColorIndex(courseName, coursesList);
    return CourseColorUtil.BACKGROUND_COLORS[colorIndex % CourseColorUtil.BACKGROUND_COLORS.length];
  }

  /**
   * 获取课程文字颜色
   * @param courseName 课程名称
   * @param coursesList 课程列表（可选）
   * @returns 文字颜色
   */
  public static getCourseTextColor(courseName: string, coursesList?: string[]): string {
    const colorIndex = CourseColorUtil.getCourseColorIndex(courseName, coursesList);
    return CourseColorUtil.TEXT_COLORS[colorIndex % CourseColorUtil.TEXT_COLORS.length];
  }

  /**
   * 获取课程边框颜色
   * @param courseName 课程名称
   * @param coursesList 课程列表（可选）
   * @returns 边框颜色
   */
  public static getCourseBorderColor(courseName: string, coursesList?: string[]): string {
    const colorIndex = CourseColorUtil.getCourseColorIndex(courseName, coursesList);
    return CourseColorUtil.BORDER_COLORS[colorIndex % CourseColorUtil.BORDER_COLORS.length];
  }

  /**
   * 从课程数据中提取去重的课程名列表
   * @param courses 课程数据数组
   * @returns 去重后的课程名数组
   */
  public static extractCourseNamesList(courses: CourseInfo[]): string[] {
    const courseNameSet = new Set<string>();
    courses.forEach(course => {
      if (course.courseName) {
        courseNameSet.add(course.courseName);
      }
    });
    return Array.from(courseNameSet);
  }
}