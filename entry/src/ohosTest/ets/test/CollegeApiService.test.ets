import { describe, it, expect } from '@ohos/hypium';
import { CollegeApiService } from '../../../main/ets/services/api/CollegeApiService';
import { HttpService } from '../../../main/ets/services/api/HttpService';
import { College, Major, ClassInfo } from '../../../main/ets/models/CollegeModels';

// 模拟HttpService
globalThis['HttpService'] = {
  getInstance: () => ({
    get: jest.fn()
  })
} as any;

// 测试数据
const mockColleges: College[] = [
  { id: '1', name: '计算机学院' },
  { id: '2', name: '经济学院' }
];

const mockMajors: Major[] = [
  { id: '101', name: '软件工程', collegeId: '1' },
  { id: '102', name: '人工智能', collegeId: '1' }
];

const mockClasses: ClassInfo[] = [
  { id: '1001', name: '2023级1班', majorId: '101' },
  { id: '1002', name: '2023级2班', majorId: '101' }
];

export default function CollegeApiServiceTest() {
  describe('CollegeApiService', () => {
    let collegeService: CollegeApiService;
    let httpService: HttpService;
    
    beforeEach(() => {
      // 重置单例实例
      (CollegeApiService as any).instance = null;
      collegeService = CollegeApiService.getInstance();
      httpService = HttpService.getInstance() as any;
      jest.clearAllMocks();
    });

    /**
     * 测试单例模式
     */
    describe('getInstance', () => {
      it('should_return_same_instance', 0, () => {
        const instance1 = CollegeApiService.getInstance();
        const instance2 = CollegeApiService.getInstance();
        expect(instance1 === instance2).assertTrue();
      });
    });

    /**
     * 测试获取学院列表
     */
    describe('getAllColleges', () => {
      it('should_fetch_colleges_successfully', 0, async () => {
        // 模拟成功响应
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 0,
          msg: 'success',
          data: mockColleges
        });

        const result = await collegeService.getAllColleges();
        expect(result.code).assertEqual(0);
        expect(result.data.length).assertEqual(2);
        expect(result.data[0].name).assertEqual('计算机学院');
      });

      it('should_handle_API_error', 0, async () => {
        // 模拟API错误
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 500,
          msg: '服务器错误',
          data: null
        });

        const result = await collegeService.getAllColleges();
        expect(result.code).assertEqual(500);
        expect(result.msg).assertEqual('服务器错误');
      });
    });

    /**
     * 测试获取专业列表
     */
    describe('getAllMajors', () => {
      it('should_fetch_majors_with_correct_parameters', 0, async () => {
        // 模拟成功响应
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 0,
          msg: 'success',
          data: mockMajors
        });

        const collegeId = '1';
        const result = await collegeService.getAllMajors(collegeId);
        
        // 验证参数传递
        expect(httpService.get).toHaveBeenCalledWith(
          '/classes/getAllMajorsByCollege',
          { collegeId: collegeId }
        );
        
        expect(result.data.length).assertEqual(2);
        expect(result.data[0].name).assertEqual('软件工程');
      });

      it('should_handle_invalid_collegeId', 0, async () => {
        // 模拟无效ID响应
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 404,
          msg: '学院不存在',
          data: null
        });

        const result = await collegeService.getAllMajors('999');
        expect(result.code).assertEqual(404);
        expect(result.msg).assertEqual('学院不存在');
      });
    });

    /**
     * 测试获取班级列表
     */
    describe('getAllClasses', () => {
      it('should_fetch_classes_with_correct_parameters', 0, async () => {
        // 模拟成功响应
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 0,
          msg: 'success',
          data: mockClasses
        });

        const majorId = '101';
        const result = await collegeService.getAllClasses(majorId);
        
        // 验证参数传递
        expect(httpService.get).toHaveBeenCalledWith(
          '/classes/getAllClassesByMajor',
          { majorId: majorId }
        );
        
        expect(result.data.length).assertEqual(2);
        expect(result.data[0].name).assertEqual('2023级1班');
      });

      it('should_handle_empty_class_list', 0, async () => {
        // 模拟空数据响应
        (httpService.get as jest.Mock).mockResolvedValue({
          code: 0,
          msg: 'success',
          data: []
        });

        const result = await collegeService.getAllClasses('102');
        expect(result.data.length).assertEqual(0);
      });
    });
  });
}