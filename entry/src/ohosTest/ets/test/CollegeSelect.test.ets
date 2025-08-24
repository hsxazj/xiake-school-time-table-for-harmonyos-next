import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import { CollegeApiService } from '../../../main/ets/services/api/CollegeApiService';
import { UserInfoManager } from '../../../main/ets/common/constants/PreferencesUtil';

export default function CollegeSelectTest() {
  describe('CollegeSelect', () => {
    let collegeApiService: CollegeApiService;
    let userInfoManager: UserInfoManager;

    beforeAll(() => {
      console.log('College select test start');
    });

    beforeEach(() => {
      collegeApiService = CollegeApiService.getInstance();
      userInfoManager = UserInfoManager.getInstance();
    });

    afterEach(() => {
      collegeApiService = null;
      userInfoManager = null;
    });

    afterAll(() => {
      console.log('College select test end');
    });

    it('should create CollegeApiService instance', () => {
      expect(collegeApiService).not.assertNull();
      expect(collegeApiService instanceof CollegeApiService).assertTrue();
    });

    it('should create UserInfoManager instance', () => {
      expect(userInfoManager).not.assertNull();
      expect(userInfoManager instanceof UserInfoManager).assertTrue();
    });

    it('should have singleton pattern', () => {
      const instance1 = CollegeApiService.getInstance();
      const instance2 = CollegeApiService.getInstance();
      expect(instance1 === instance2).assertTrue();
    });

    it('should handle user info operations', () => {
      const testCollegeId = '123';
      const testCollegeName = 'Test College';

      userInfoManager.saveCollegeInfo(testCollegeId, testCollegeName);

      const collegeId = userInfoManager.getCollegeId();
      const collegeName = userInfoManager.getCollegeName();

      expect(collegeId).assertEqual(testCollegeId);
      expect(collegeName).assertEqual(testCollegeName);

      userInfoManager.clearUserInfo();
    });
  });
}