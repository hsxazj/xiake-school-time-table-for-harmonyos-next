import { describe, it, expect } from '@ohos/hypium';
import { DateUtil } from '../../../main/ets/common/utils/DateUtil';

export default function DateUtilTest() {
  describe('DateUtilTest', () => {
    const testDate = new Date(2024, 5, 15, 14, 30, 0); // 2024-06-15 14:30:00
    
    /**
     * 测试日期格式化功能
     */
    describe('formatDate', () => {
      it('should_format_date_with_default_format', 0, () => {
        const formatted = DateUtil.formatDate(testDate);
        expect(formatted).assertEqual('2024-06-15 14:30:00');
      });

      it('should_format_date_with_custom_format', 0, () => {
        const formatted = DateUtil.formatDate(testDate, 'yyyy年MM月dd日 HH:mm');
        expect(formatted).assertEqual('2024年06月15日 14:30');
      });

      it('should_format_date_with_CN_format', 0, () => {
        const formatted = DateUtil.formatDate(testDate, DateUtil.FORMATS.DATETIME_CN);
        expect(formatted).assertEqual('2024年06月15日 14时30分');
      });

      it('should_return_null_for_invalid_date', 0, () => {
        const formatted = DateUtil.formatDate('invalid-date');
        expect(formatted).assertNull();
      });
    });

    /**
     * 测试周数计算功能
     */
    describe('getWeekNumber', () => {
      it('should_calculate_week_number', 0, () => {
        // 2024-01-01 是第1周
        const date1 = new Date(2024, 0, 1);
        const week1 = DateUtil.getDayOfYearPublic(date1);
        expect(week1).assertEqual(1);

        // 2024-06-15 是第167天
        const week2 = DateUtil.getDayOfYearPublic(testDate);
        expect(week2).assertEqual(167);
      });

      it('should_return_null_for_invalid_date', 0, () => {
        const week = DateUtil.getDayOfYearPublic('invalid-date');
        expect(week).assertNull();
      });
    });

    /**
     * 测试日期比较功能
     */
    describe('compareDates', () => {
      const date1 = new Date(2024, 5, 15);
      const date2 = new Date(2024, 5, 16);
      const date3 = new Date(2024, 5, 15);

      it('should_return_-1_when_first_date_earlier', 0, () => {
        const result = DateUtil.compareDates(date1, date2);
        expect(result).assertEqual(-1);
      });

      it('should_return_1_when_first_date_later', 0, () => {
        const result = DateUtil.compareDates(date2, date1);
        expect(result).assertEqual(1);
      });

      it('should_return_0_when_dates_equal', 0, () => {
        const result = DateUtil.compareDates(date1, date3);
        expect(result).assertEqual(0);
      });

      it('should_return_null_for_invalid_date', 0, () => {
        const result = DateUtil.compareDates(date1, 'invalid-date');
        expect(result).assertNull();
      });
    });

    /**
     * 测试额外功能：相对时间
     */
    describe('formatRelativeTime', () => {
      it('should_format_just_now', 0, () => {
        const now = new Date();
        const justNow = new Date(now.getTime() - 30 * 1000);
        const formatted = DateUtil.formatRelativeTime(justNow);
        expect(formatted).assertEqual('刚刚');
      });

      it('should_format_minutes_ago', 0, () => {
        const now = new Date();
        const minutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
        const formatted = DateUtil.formatRelativeTime(minutesAgo);
        expect(formatted).assertEqual('5分钟前');
      });

      it('should_format_today', 0, () => {
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 10, 30);
        const formatted = DateUtil.formatRelativeTime(today);
        expect(formatted).assertEqual(`今天 10:30`);
      });
    });
  });
}