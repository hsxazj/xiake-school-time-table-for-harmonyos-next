import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { CollegeApiService } from '../../../main/ets/services/api/CollegeApiService';
import { StorageService } from '../../../main/ets/services/storage/StorageService';

export default function CollegeSelectTest() {
  describe('CollegeSelect', () => {
    let collegeApiService: CollegeApiService;
    let storageService: StorageService;

    beforeAll(() => {
      console.log('College select test start');
    });

    beforeEach(() => {
      collegeApiService = CollegeApiService.getInstance();
      storageService = StorageService.getInstance();
    });

    afterEach(() => {
      collegeApiService = null;
      storageService = null;
    });

    afterAll(() => {
      console.log('College select test end');
    });

    it('should create CollegeApiService instance', () => {
      expect(collegeApiService).not.assertNull();
      expect(collegeApiService instanceof CollegeApiService).assertTrue();
    });

    it('should create StorageService instance', () => {
      expect(storageService).not.assertNull();
      expect(storageService instanceof StorageService).assertTrue();
    });

    it('should have singleton pattern', () => {
      const instance1 = CollegeApiService.getInstance();
      const instance2 = CollegeApiService.getInstance();
      expect(instance1 === instance2).assertTrue();
    });

    it('should handle storage operations', async () => {
      const testKey = 'test_key';
      const testValue = 'test_value';
      
      const setResult = await storageService.setItem(testKey, testValue);
      expect(setResult).assertTrue();
      
      const getValue = await storageService.getItem(testKey, '');
      expect(getValue).assertEqual(testValue);
      
      const removeResult = await storageService.removeItem(testKey);
      expect(removeResult).assertTrue();
    });
  });
}