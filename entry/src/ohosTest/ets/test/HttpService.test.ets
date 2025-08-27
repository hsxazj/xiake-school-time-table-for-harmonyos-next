import { describe, it, expect } from '@ohos/hypium';
import { HttpService } from '../../../main/ets/services/api/HttpService';
import axios from '@ohos/axios';
import { AppStorage } from '@ohos/arkui/ArkUI';

// 模拟axios模块
globalThis['axios'] = {
  create: () => ({
    get: jest.fn(),
    post: jest.fn(),
    interceptors: {
      request: { use: jest.fn() },
      response: { use: jest.fn() }
    },
    defaults: {
      headers: { common: {} }
    }
  })
} as any;

// 模拟AppStorage
globalThis['AppStorage'] = {
  get: jest.fn(),
  setOrCreate: jest.fn()
} as any;

export default function HttpServiceTest() {
  describe('HttpService', () => {
    let httpService: HttpService;
    
    beforeEach(() => {
      // 重置单例实例
      (HttpService as any).instance = null;
      httpService = HttpService.getInstance();
      jest.clearAllMocks();
    });

    /**
     * 测试单例模式
     */
    describe('getInstance', () => {
      it('should_return_same_instance', 0, () => {
        const instance1 = HttpService.getInstance();
        const instance2 = HttpService.getInstance();
        expect(instance1 === instance2).assertTrue();
      });
    });

    /**
     * 测试GET请求
     */
    describe('get', () => {
      it('should_send_GET_request_successfully', 0, async () => {
        // 模拟成功响应
        (httpService.getAxiosInstance().get as jest.Mock).mockResolvedValue({
          data: { code: 0, msg: 'success', data: { id: 1 } }
        });

        const result = await httpService.get('/test');
        expect(result.code).assertEqual(0);
        expect(result.data.id).assertEqual(1);
      });

      it('should_handle_network_error', 0, async () => {
        // 模拟网络错误
        (httpService.getAxiosInstance().get as jest.Mock).mockRejectedValue({
          request: true,
          message: 'Network Error'
        });

        try {
          await httpService.get('/test');
        } catch (error) {
          expect(error.message).assertEqual('网络连接失败，请检查网络设置');
        }
      });
    });

    /**
     * 测试POST请求
     */
    describe('post', () => {
      it('should_send_POST_request_successfully', 0, async () => {
        // 模拟成功响应
        (httpService.getAxiosInstance().post as jest.Mock).mockResolvedValue({
          data: { code: 0, msg: 'success', data: { id: 2 } }
        });

        const result = await httpService.post('/create', { name: 'test' });
        expect(result.code).assertEqual(0);
        expect(result.data.id).assertEqual(2);
      });

      it('should_handle_timeout_error', 0, async () => {
        // 模拟超时错误
        (httpService.getAxiosInstance().post as jest.Mock).mockRejectedValue({
          code: 'ECONNABORTED',
          message: 'Timeout'
        });

        try {
          await httpService.post('/create', {});
        } catch (error) {
          expect(error.message).assertEqual('网络请求失败');
        }
      });
    });

    /**
     * 测试错误处理
     */
    describe('handleError', () => {
      it('should_handle_401_unauthorized', 0, async () => {
        // 模拟401响应
        (httpService.getAxiosInstance().get as jest.Mock).mockRejectedValue({
          response: { status: 401, data: { message: 'Unauthorized' } }
        });

        try {
          await httpService.get('/protected');
        } catch (error) {
          expect(error.message).assertEqual('未授权，请重新登录');
          expect(AppStorage.setOrCreate).toHaveBeenCalledWith('token', '');
        }
      });

      it('should_handle_500_server_error', 0, async () => {
        // 模拟500响应
        (httpService.getAxiosInstance().get as jest.Mock).mockRejectedValue({
          response: { status: 500, data: { message: 'Server Error' } }
        });

        try {
          await httpService.get('/server-error');
        } catch (error) {
          expect(error.message).assertEqual('服务器内部错误');
        }
      });
    });

    /**
     * 测试请求头操作
     */
    describe('requestHeaders', () => {
      it('should_set_and_remove_default_header', 0, () => {
        httpService.setDefaultHeader('X-Test-Header', 'test-value');
        expect(httpService.getAxiosInstance().defaults.headers.common['X-Test-Header']).assertEqual('test-value');
        
        httpService.removeDefaultHeader('X-Test-Header');
        expect(httpService.getAxiosInstance().defaults.headers.common['X-Test-Header']).assertUndefined();
      });
    });
  });
}