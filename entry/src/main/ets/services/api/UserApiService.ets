import { GetUserInfoApiResponse, GetUserInfoResponse, SimpleUserInfo } from '../../models/UserModels';
import { HttpService } from './HttpService';

/**
 * 用户信息API服务封装
 * 处理用户信息获取和管理相关的API请求
 */
export class UserApiService {
  private static instance: UserApiService;
  private httpService = HttpService.getInstance();

  private constructor() {
    console.info('👤 [UserApiService] 初始化用户API服务');
  }

  public static getInstance(): UserApiService {
    if (!UserApiService.instance) {
      UserApiService.instance = new UserApiService();
    }
    return UserApiService.instance;
  }

  /**
   * 获取当前用户信息
   * GET /getInfo
   * 需要在请求头中携带token
   */
  public async getUserInfo(): Promise<GetUserInfoResponse> {
    try {
      console.info('👤 [UserApiService] 获取用户信息');

      // 使用HttpService的getDirect方法，因为/getInfo接口直接返回完整数据，不包装在ApiResponse中
      const response: GetUserInfoApiResponse = await this.httpService.getDirect<GetUserInfoApiResponse>('/getInfo');

      if (response.code === 200) {
        console.info('👤 [UserApiService] 获取用户信息成功');
        console.info(`👤 [UserApiService] 用户: ${response.user.realName} (${response.user.userName})`);
        console.info(`👤 [UserApiService] 班级: ${response.user.stuClassId}`);

        // 将GetUserInfoApiResponse转换为标准的GetUserInfoResponse格式
        const result: GetUserInfoResponse = {
          msg: response.msg,
          code: response.code,
          permissions: response.permissions,
          roles: response.roles,
          user: response.user
        };

        return result;
      } else {
        throw new Error(`获取用户信息失败: ${response.msg}`);
      }
    } catch (error) {
      console.error('👤 [UserApiService] 获取用户信息失败:', error);
      throw new Error('获取用户信息失败，请检查登录状态');
    }
  }

  /**
   * 将完整用户信息转换为简化用户信息
   */
  public convertToSimpleUserInfo(userInfo: GetUserInfoResponse): SimpleUserInfo {
    return {
      userId: userInfo.user.userId,
      userName: userInfo.user.userName,
      stuClassId: userInfo.user.stuClassId,
      nickName: userInfo.user.nickName,
      realName: userInfo.user.realName,
      avatar: userInfo.user.avatar,
      admin: userInfo.user.admin
    };
  }

  /**
   * 检查用户信息是否有效
   */
  public isValidUserInfo(userInfo: SimpleUserInfo | null): boolean {
    if (!userInfo) {
      return false;
    }

    // 检查关键字段是否存在
    return !!(
      userInfo.userId &&
      userInfo.userName &&
      userInfo.stuClassId &&
      userInfo.realName
    );
  }
}