/**
 * 课程数据解析工具类
 *
 * 参考 dev-doc/jwxt/api/getCourse.ts 和 dev-doc/jwxt/api/AnalysisCourse.py
 * 提供标准的课程数据解析功能
 *
 * @author AI Refactor
 * @date 2026-01-07
 */
export class CourseParser {
  /**
   * 解析节次字符串为节次数组
   *
   * 参考: getCourse.ts 的 parseSessions 函数
   *
   * 示例:
   * - "1-2" -> [1, 2]
   * - "1-2节" -> [1, 2]
   * - "3-4节" -> [3, 4]
   * - "1-6节" -> [1, 2, 3, 4, 5, 6]
   * - "1" -> [1]
   *
   * @param sessionsStr 节次字符串
   * @returns 节次数组
   */
  public static parseSessions(sessionsStr: string): number[] {
    if (!sessionsStr) {
      return [];
    }

    // 移除"节"字符
    const cleanStr = sessionsStr.trim().replace(/节$/g, '');

    // 匹配 "数字-数字" 或 "数字" 格式
    const match = cleanStr.match(/(\d+)(?:-(\d+))?/);
    if (!match) {
      return [];
    }

    const start = Number(match[1]);
    const end = match[2] ? Number(match[2]) : start;

    // 生成连续的节次数组
    const sessions: number[] = [];
    for (let i = start; i <= end; i++) {
      sessions.push(i);
    }

    return sessions;
  }

  /**
   * 解析周次字符串为周次数组
   *
   * 参考: getCourse.ts 的 parseWeeks 函数 和 AnalysisCourse.py 的 parse_week_range 函数
   *
   * 支持多种格式:
   * 1. JSON数组格式: "[2,3,4,6,7,8,9]" (现有API返回格式)
   * 2. 字符串表达式: "1-16周"、"1-8周(单)"、"1-8周(双)"、"1-5周,8周,12-14周"
   *
   * 示例:
   * - "[2,3,4,6,7,8,9]" -> [2,3,4,6,7,8,9]
   * - "1-16周" -> [1,2,3,...,16]
   * - "1-8周(单)" -> [1,3,5,7]
   * - "1-8周(双)" -> [2,4,6,8]
   * - "1-5周,8周" -> [1,2,3,4,5,8]
   *
   * @param weeksStr 周次字符串
   * @returns 周次数组(已排序)
   */
  public static parseWeeks(weeksStr: string): number[] {
    if (!weeksStr) {
      return [];
    }

    try {
      // 格式1: JSON数组 "[2,3,4,6,7,8,9]"
      if (weeksStr.startsWith('[') && weeksStr.endsWith(']')) {
        const weekArray = JSON.parse(weeksStr) as number[];
        return weekArray.sort((a, b) => a - b);
      }

      // 格式2: 字符串表达式 "1-16周"、"1-8周(单)" 等
      return CourseParser.parseWeeksExpression(weeksStr);

    } catch (error) {
      console.error('解析周次失败:', error, weeksStr);
      return [];
    }
  }

  /**
   * 解析周次字符串表达式
   *
   * 参考: getCourse.ts 的 parseWeeks 函数 和 AnalysisCourse.py 的 parse_week_range 函数
   *
   * @param weeksStr 周次表达式,如 "1-16周"、"1-8周(单)"、"1-5周,8周"
   * @returns 周次数组(已排序)
   */
  private static parseWeeksExpression(weeksStr: string): number[] {
    const weeks = new Set<number>();

    // 规范化字符串:替换中文逗号为英文逗号,移除空格
    const normalized = weeksStr.replace(/,/g, ',').replace(/\s+/g, '');

    // 按逗号分割各部分
    const parts = normalized.split(',').filter(part => part.length > 0);

    for (const part of parts) {
      // 匹配格式: "起始-结束周(单|双)" 或 "单周"
      // 示例: "1-8周(单)"、"1-16周"、"14周"
      const match = part.match(/(\d+)(?:-(\d+))?周?(?:\((单|双)\))?/);
      if (!match) {
        continue;
      }

      const start = Number(match[1]);
      const end = match[2] ? Number(match[2]) : start;
      const parity = match[3]; // "单" 或 "双" 或 undefined

      // 生成周次范围
      for (let i = start; i <= end; i++) {
        // 单双周过滤
        if (parity === '双' && i % 2 === 1) {
          continue; // 双周跳过奇数周
        }
        if (parity === '单' && i % 2 === 0) {
          continue; // 单周跳过偶数周
        }
        weeks.add(i);
      }
    }

    // 转换为排序后的数组
    return Array.from(weeks).sort((a, b) => a - b);
  }

  /**
   * 判断课程是否在指定周
   *
   * @param weeksStr 周次字符串(支持JSON数组或表达式)
   * @param targetWeek 目标周数
   * @returns 是否在指定周
   */
  public static isCourseInWeek(weeksStr: string, targetWeek: number): boolean {
    if (!weeksStr) {
      return true; // 如果没有周次信息,默认所有周都有
    }

    const weekList = CourseParser.parseWeeks(weeksStr);
    return weekList.includes(targetWeek);
  }

  /**
   * 解析星期字符串为数字
   *
   * @param weekdayStr 星期字符串,如 "星期一"、"星期二"
   * @returns 星期数字(1-7,1表示周一,7表示周日)
   */
  public static parseWeekday(weekdayStr: string): number {
    const weekdayMap: Record<string, number> = {
      '星期一': 1,
      '星期二': 2,
      '星期三': 3,
      '星期四': 4,
      '星期五': 5,
      '星期六': 6,
      '星期日': 7
    };
    return weekdayMap[weekdayStr] || 1;
  }

  /**
   * 提取节次字符串的首数字(用于排序)
   *
   * 参考: AnalysisCourse.py 的 parse_jc_order 函数
   *
   * @param sectionStr 节次字符串,如 "1-2节"、"3-4节"
   * @returns 首数字,用于排序
   */
  public static getSectionOrder(sectionStr: string): number {
    if (!sectionStr) {
      return 0;
    }

    const match = sectionStr.match(/(\d+)/);
    return match ? Number(match[1]) : 0;
  }

  /**
   * 解析课程时间为二维数组格式
   *
   * 将节次数组按连续性分组
   * 示例: [1,2,3,5,6] -> [[1,2,3], [5,6]]
   *
   * @param sections 节次数组
   * @returns 二维数组,每个子数组是一组连续的节次
   */
  public static parseCourseTime(sections: number[]): number[][] {
    if (!sections || sections.length === 0) {
      return [];
    }

    const result: number[][] = [];
    let currentGroup: number[] = [];

    for (let i = 0; i < sections.length; i++) {
      if (i === 0 || sections[i] === sections[i - 1] + 1) {
        // 第一个或连续的节次
        currentGroup.push(sections[i]);
      } else {
        // 不连续,保存之前的组,开始新组
        if (currentGroup.length > 0) {
          result.push([...currentGroup]);
        }
        currentGroup = [sections[i]];
      }
    }

    // 保存最后一组
    if (currentGroup.length > 0) {
      result.push(currentGroup);
    }

    return result;
  }
}
