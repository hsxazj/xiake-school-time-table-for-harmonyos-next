import { describe, it, expect } from '@ohos/hypium';
import { PreferencesUtil } from '../../../main/ets/common/utils/PreferencesUtil';
import AbilityTestContext from '@ohos.application.abilityTestContext';

export default function PreferencesUtilTest() {
  describe('PreferencesUtilTest', () => {
    const context = AbilityTestContext.getContext();
    const preferencesUtil = PreferencesUtil.getInstance();
    const TEST_KEY = 'test_key';
    const TEST_VALUE = 'test_value';
    
    /**
     * 测试数据存储功能
     */
    describe('setPreferences', () => {
      it('should_save_value_to_preferences', 0, () => {
        preferencesUtil.putValue(context, TEST_KEY, TEST_VALUE);
        const value = preferencesUtil.getValue(context, TEST_KEY);
        expect(value).assertEqual(TEST_VALUE);
      });

      it('should_not_override_value_when_override_false', 0, () => {
        const newValue = 'new_value';
        preferencesUtil.putValue(context, TEST_KEY, newValue, false);
        const value = preferencesUtil.getValue(context, TEST_KEY);
        expect(value).assertEqual(TEST_VALUE);
      });
    });

    /**
     * 测试数据读取功能
     */
    describe('getPreferences', () => {
      it('should_get_value_from_preferences', 0, () => {
        preferencesUtil.putValue(context, TEST_KEY, TEST_VALUE);
        const value = preferencesUtil.getValue(context, TEST_KEY);
        expect(value).assertEqual(TEST_VALUE);
      });

      it('should_return_default_value_when_key_not_exist', 0, () => {
        const value = preferencesUtil.getValue(context, 'non_existent_key', 'default');
        expect(value).assertEqual('default');
      });
    });

    /**
     * 测试数据删除功能
     */
    describe('deletePreferences', () => {
      it('should_remove_value_from_preferences', 0, () => {
        preferencesUtil.putValue(context, TEST_KEY, TEST_VALUE);
        preferencesUtil.removeValue(context, TEST_KEY);
        const value = preferencesUtil.getValue(context, TEST_KEY);
        expect(value).assertEqual('');
      });

      it('should_clear_all_preferences', 0, () => {
        preferencesUtil.putValue(context, 'key1', 'value1');
        preferencesUtil.putValue(context, 'key2', 'value2');
        preferencesUtil.clearAll(context);
        const value1 = preferencesUtil.getValue(context, 'key1');
        const value2 = preferencesUtil.getValue(context, 'key2');
        expect(value1).assertEqual('');
        expect(value2).assertEqual('');
      });
    });
  });
}