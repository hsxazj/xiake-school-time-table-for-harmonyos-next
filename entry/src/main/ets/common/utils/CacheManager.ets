import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from './PreferencesUtil';
import { ConfigApiResponseData } from '../../models/ConfigModels';
import { CourseInfo } from '../../models/CourseModels';

const DOMAIN: number = 0x0001;
const TAG: string = 'CacheManager';

// 缓存key常量
const CACHE_KEY_PREFIX_SCHEDULE = 'cache_schedule_';
const CACHE_KEY_CONFIG = 'cache_config';
const CACHE_KEY_WEEKS_LIST = 'cache_weeks_list';

// 缓存容量限制
const MAX_CACHED_WEEKS = 20;

// 定义缓存数据结构的接口
interface CachedScheduleData {
  data: CourseInfo[];
  cachedAt: number;
  version: string;
}

// 配置数据结构接口
interface ConfigDataStructure {
  start: Record<string, string[]>;
  end: Record<string, string[]>;
}

interface CachedConfigData {
  data: ConfigDataStructure;
  cachedAt: number;
  version: string;
}

// 辅助函数: 构建课表缓存key
function buildScheduleCacheKey(year: string, term: string, week: number): string {
  return `${CACHE_KEY_PREFIX_SCHEDULE}${year}_${term}_${week}`;
}

// 辅助函数: 构建周次标识符
function buildWeekIdentifier(year: string, term: string, week: number): string {
  return `${year}_${term}_${week}`;
}

// 辅助函数: 获取已缓存的周次列表
async function getWeeksList(): Promise<string[]> {
  try {
    const context = getContext();
    const listValue = PreferencesUtil.getInstance().getValue(context, CACHE_KEY_WEEKS_LIST, '') as string;

    if (!listValue) {
      return [];
    }

    return JSON.parse(listValue) as string[];
  } catch (error) {
    hilog.error(DOMAIN, TAG, `❌ 读取周次列表失败: ${JSON.stringify(error)}`);
    return [];
  }
}

// 辅助函数: 将周次添加到已缓存列表
async function addWeekToList(year: string, term: string, week: number): Promise<void> {
  try {
    const weekIdentifier = buildWeekIdentifier(year, term, week);
    const weeksList = await getWeeksList();

    // 如果已存在,先删除旧的(移到最后)
    const index = weeksList.indexOf(weekIdentifier);
    if (index !== -1) {
      weeksList.splice(index, 1);
    }

    // 添加到列表末尾(最新的)
    weeksList.push(weekIdentifier);

    // 保存更新后的列表
    const context = getContext();
    const listValue = JSON.stringify(weeksList);
    PreferencesUtil.getInstance().putValue(context, CACHE_KEY_WEEKS_LIST, listValue, true);
  } catch (error) {
    hilog.error(DOMAIN, TAG, `❌ 更新周次列表失败: ${JSON.stringify(error)}`);
  }
}

/**
 * 缓存管理器
 * 职责: 统一管理课表和配置的缓存操作
 */
export class CacheManager {

  /**
   * 保存课表缓存
   * @param year 学年 (如 "2024")
   * @param term 学期代号 ("3"=第一学期, "12"=第二学期)
   * @param week 周次
   * @param data 课程数据列表
   */
  public static async saveScheduleCache(
    year: string,
    term: string,
    week: number,
    data: CourseInfo[]
  ): Promise<void> {
    try {
      const cacheKey = buildScheduleCacheKey(year, term, week);
      const cacheData: CachedScheduleData = {
        data: data,
        cachedAt: Date.now(),
        version: '1.0'
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, cacheKey, cacheValue, true);

      // 将该周添加到已缓存列表
      await addWeekToList(year, term, week);

      hilog.info(DOMAIN, TAG, `✅ 缓存课表成功: ${cacheKey}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存课表失败: ${JSON.stringify(error)}`);
      // 错误静默处理,不抛出
    }
  }

  /**
   * 获取课表缓存
   * @param year 学年
   * @param term 学期代号
   * @param week 周次
   * @returns 课程数据列表,如果不存在则返回null
   */
  public static async getScheduleCache(
    year: string,
    term: string,
    week: number
  ): Promise<CourseInfo[] | null> {
    try {
      const cacheKey = buildScheduleCacheKey(year, term, week);
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, cacheKey, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 缓存不存在: ${cacheKey}`);
        return null;
      }

      const cached: CachedScheduleData = JSON.parse(cacheValue);
      hilog.info(DOMAIN, TAG, `📦 读取缓存成功: ${cacheKey}, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return cached.data;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取课表缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存配置缓存
   * @param data 配置数据
   */
  public static async saveConfigCache(data: ConfigApiResponseData): Promise<void> {
    try {
      // 将Map转换为普通对象以便JSON序列化
      const startObj: Record<string, string[]> = {};
      const endObj: Record<string, string[]> = {};

      data.start.forEach((value: string[], key: string) => {
        startObj[key] = value;
      });

      data.end.forEach((value: string[], key: string) => {
        endObj[key] = value;
      });

      const configData: ConfigDataStructure = {
        start: startObj,
        end: endObj
      };

      const cacheData: CachedConfigData = {
        data: configData,
        cachedAt: Date.now(),
        version: '1.0'
      };
      const cacheValue = JSON.stringify(cacheData);

      const context = getContext();
      PreferencesUtil.getInstance().putValue(context, CACHE_KEY_CONFIG, cacheValue, true);

      hilog.info(DOMAIN, TAG, `✅ 缓存配置成功`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 缓存配置失败: ${JSON.stringify(error)}`);
      // 错误静默处理
    }
  }

  /**
   * 获取配置缓存
   * @returns 配置数据,如果不存在则返回null
   */
  public static async getConfigCache(): Promise<ConfigApiResponseData | null> {
    try {
      const context = getContext();
      const cacheValue = PreferencesUtil.getInstance().getValue(context, CACHE_KEY_CONFIG, '') as string;

      if (!cacheValue) {
        hilog.info(DOMAIN, TAG, `📭 配置缓存不存在`);
        return null;
      }

      const cached: CachedConfigData = JSON.parse(cacheValue);

      // 将普通对象转换回Map
      const startMap = new Map<string, string[]>();
      const endMap = new Map<string, string[]>();

      Object.keys(cached.data.start).forEach((key: string) => {
        startMap.set(key, cached.data.start[key]);
      });

      Object.keys(cached.data.end).forEach((key: string) => {
        endMap.set(key, cached.data.end[key]);
      });

      hilog.info(DOMAIN, TAG, `📦 读取配置缓存成功, 缓存时间: ${new Date(cached.cachedAt).toLocaleString()}`);

      return {
        start: startMap,
        end: endMap
      };
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 读取配置缓存失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 预加载课表 (当周±1周)
   * @param year 当前学年
   * @param term 当前学期
   * @param currentWeek 当前周次
   * @param fetchScheduleFn 获取课表的函数
   */
  public static async preloadSchedules(
    year: string,
    term: string,
    currentWeek: number,
    fetchScheduleFn: (year: string, term: string, week: number) => Promise<CourseInfo[]>
  ): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, `🔄 开始预加载课表: ${year}学年 学期${term} 第${currentWeek}周 ±1周`);

      const weeksToLoad = [currentWeek - 1, currentWeek, currentWeek + 1];

      // 并行加载三周课表
      const promises = weeksToLoad.map(async (week) => {
        if (week < 1) {
          hilog.warn(DOMAIN, TAG, `⚠️ 周次${week}无效,跳过`);
          return;
        }

        try {
          // 先检查缓存是否存在
          const cached = await CacheManager.getScheduleCache(year, term, week);
          if (cached) {
            hilog.info(DOMAIN, TAG, `✓ 第${week}周已有缓存,跳过预加载`);
            return;
          }

          // 获取并缓存数据
          const data = await fetchScheduleFn(year, term, week);
          await CacheManager.saveScheduleCache(year, term, week, data);
          hilog.info(DOMAIN, TAG, `✓ 预加载第${week}周成功`);
        } catch (error) {
          hilog.warn(DOMAIN, TAG, `⚠️ 预加载第${week}周失败: ${JSON.stringify(error)}`);
          // 继续处理其他周
        }
      });

      await Promise.all(promises);
      hilog.info(DOMAIN, TAG, `✅ 预加载完成`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 预加载失败: ${JSON.stringify(error)}`);
      // 错误静默处理
    }
  }

  /**
   * 清理旧的课表缓存 (LRU淘汰)
   * 保留最多 MAX_CACHED_WEEKS 周的缓存
   */
  public static async cleanOldScheduleCaches(): Promise<void> {
    try {
      const weeksList = await getWeeksList();

      if (weeksList.length <= MAX_CACHED_WEEKS) {
        hilog.info(DOMAIN, TAG, `当前缓存${weeksList.length}周,无需清理`);
        return;
      }

      // 计算需要删除的数量
      const deleteCount = weeksList.length - MAX_CACHED_WEEKS;
      const weeksToDelete = weeksList.slice(0, deleteCount);

      hilog.info(DOMAIN, TAG, `🗑️ 开始清理旧缓存: 删除${deleteCount}周`);

      const context = getContext();
      weeksToDelete.forEach((weekKey: string) => {
        const cacheKey = `${CACHE_KEY_PREFIX_SCHEDULE}${weekKey}`;
        PreferencesUtil.getInstance().removeValue(context, cacheKey);
        hilog.info(DOMAIN, TAG, `🗑️ 已删除: ${cacheKey}`);
      });

      // 更新列表
      const newList = weeksList.slice(deleteCount);
      const newListValue = JSON.stringify(newList);
      PreferencesUtil.getInstance().putValue(context, CACHE_KEY_WEEKS_LIST, newListValue, true);

      hilog.info(DOMAIN, TAG, `✅ 清理完成,剩余${newList.length}周缓存`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `❌ 清理缓存失败: ${JSON.stringify(error)}`);
      // 错误静默处理
    }
  }
}
