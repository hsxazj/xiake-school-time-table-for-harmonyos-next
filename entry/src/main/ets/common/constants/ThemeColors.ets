/**
 * 课表应用主题颜色常量
 * 定义应用的主要颜色系统，确保整个应用的颜色一致性
 */

/**
 * 主题颜色常量
 */
export class ThemeColors {
  /** 主色调 - 青蓝色 */
  static readonly PRIMARY = '#45CAD9';
  
  /** 主色调浅色版本 - 用于背景等 */
  static readonly PRIMARY_LIGHT = '#F0F9FB';
  
  /** 主色调深色版本 - 用于加深效果 */
  static readonly PRIMARY_DARK = '#3B9FB0';
  
  /** 禁用状态颜色 */
  static readonly DISABLED = '#CCCCCC';
  
  /** 成功状态颜色 */
  static readonly SUCCESS = '#4CAF50';
  
  /** 警告状态颜色 */
  static readonly WARNING = '#FF9800';
  
  /** 错误状态颜色 */
  static readonly ERROR = '#FF6B6B';
}

/**
 * 颜色资源引用常量
 * 用于在ArkTS组件中引用资源文件中定义的颜色
 */
export class ColorResources {
  /** 主色调资源引用 */
  static readonly PRIMARY = $r('app.color.schedule_primary_color');
  
  /** 主色调浅色资源引用 */
  static readonly PRIMARY_LIGHT = $r('app.color.schedule_primary_light');
  
  /** 主色调深色资源引用 */
  static readonly PRIMARY_DARK = $r('app.color.schedule_primary_dark');
}