/**
 * 树洞功能API服务封装
 * 复用现有HttpService，提供树洞相关的数据接口
 */
import { HttpService } from './HttpService';
import { 
  TreeHoleItem, 
  TreeHoleComment, 
  PostTreeHoleRequest, 
  PostCommentRequest,
  TreeHoleApiResponse,
  TreeHolePaginationData 
} from '../../models/TreeHoleModels';

export class TreeHoleApiService {
  private static instance: TreeHoleApiService;
  private httpService: HttpService = HttpService.getInstance();

  /**
   * 获取单例实例
   */
  public static getInstance(): TreeHoleApiService {
    if (!TreeHoleApiService.instance) {
      TreeHoleApiService.instance = new TreeHoleApiService();
    }
    return TreeHoleApiService.instance;
  }

  private constructor() {
    console.info('🌳 [TreeHoleApiService] 初始化树洞API服务');
  }

  /**
   * 获取树洞列表
   */
  public async getTreeHoleList(
    pageNum: number = 1, 
    pageSize: number = 10, 
    status: number = 1
  ): Promise<TreeHolePaginationData<TreeHoleItem>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 获取树洞列表 - 页码:${pageNum}, 大小:${pageSize}, 状态:${status}`);
      
      // 暂时返回Mock数据
      return await this.getMockTreeHoleList(pageNum, pageSize, status);
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 获取树洞列表失败:', error);
      throw new Error('获取树洞列表失败');
    }
  }

  /**
   * 获取树洞评论列表
   */
  public async getTreeHoleComments(
    treeHoleId: number, 
    pageNum: number = 1, 
    pageSize: number = 10
  ): Promise<TreeHolePaginationData<TreeHoleComment>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 获取评论列表 - 树洞ID:${treeHoleId}, 页码:${pageNum}`);
      
      // 暂时返回Mock数据
      return await this.getMockCommentsList(treeHoleId, pageNum, pageSize);
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 获取评论失败:', error);
      throw new Error('获取评论失败');
    }
  }

  /**
   * 发布树洞
   */
  public async postTreeHole(request: PostTreeHoleRequest): Promise<boolean> {
    try {
      console.info('🌳 [TreeHoleApiService] 发布树洞:', request.content.substring(0, 20) + '...');
      
      // 暂时返回成功
      return await this.mockPostTreeHole(request);
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 发布树洞失败:', error);
      throw new Error('发布树洞失败');
    }
  }

  /**
   * 发布评论
   */
  public async postComment(request: PostCommentRequest): Promise<boolean> {
    try {
      console.info(`🌳 [TreeHoleApiService] 发布评论 - 树洞ID:${request.treeHoleId}`);
      
      // 暂时返回成功
      return await this.mockPostComment(request);
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 发布评论失败:', error);
      throw new Error('发布评论失败');
    }
  }

  /**
   * 点赞/取消点赞树洞
   */
  public async toggleLike(treeHoleId: number, isLike: boolean): Promise<boolean> {
    try {
      console.info(`🌳 [TreeHoleApiService] ${isLike ? '点赞' : '取消点赞'} 树洞ID:${treeHoleId}`);
      
      // 暂时返回成功
      return true;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 点赞操作失败:', error);
      throw new Error('点赞操作失败');
    }
  }

  // ====== Mock 数据方法（开发阶段使用） ======

  /**
   * Mock 树洞列表数据
   */
  private async getMockTreeHoleList(pageNum: number, pageSize: number, status: number): Promise<TreeHolePaginationData<TreeHoleItem>> {
    return new Promise((resolve) => {
      // 模拟网络延迟
      setTimeout(() => {
        const mockData: TreeHoleItem[] = [
          {
            id: 1,
            content: "今天的课程安排好充实，终于理解了ArkTS的生命周期机制！💪",
            author: "匿名用户001",
            avatar: "defaultAvatar",
            createTime: "2024-12-06 14:30:00",
            likeCount: 15,
            commentCount: 8,
            isAnonymous: true,
            isLiked: false,
            isTop: status === 3 || status === 4
          },
          {
            id: 2,
            content: "有没有同学一起组队学习HarmonyOS开发的？欢迎私信交流经验~",
            author: "开发者小张",
            avatar: "defaultAvatar", 
            createTime: "2024-12-06 13:45:00",
            likeCount: 23,
            commentCount: 12,
            isAnonymous: false,
            isLiked: true,
            isTop: false
          },
          {
            id: 3,
            content: "刚刚解决了一个困扰我很久的组件状态管理问题，感觉整个世界都明亮了！✨",
            author: "匿名用户002",
            avatar: "defaultAvatar",
            createTime: "2024-12-06 12:20:00", 
            likeCount: 31,
            commentCount: 5,
            isAnonymous: true,
            isLiked: false,
            isTop: false
          }
        ];

        const result: TreeHolePaginationData<TreeHoleItem> = {
          list: mockData,
          pageNum,
          pageSize,
          totalPages: 3,
          total: 25,
          hasNext: pageNum < 3
        };

        resolve(result);
      }, 500); // 模拟500ms网络延迟
    });
  }

  /**
   * Mock 评论列表数据
   */
  private async getMockCommentsList(treeHoleId: number, pageNum: number, pageSize: number): Promise<TreeHolePaginationData<TreeHoleComment>> {
    return new Promise((resolve) => {
      setTimeout(() => {
        const mockComments: TreeHoleComment[] = [
          {
            id: 1,
            content: "太赞了！我也在学习这个，一起加油！",
            author: "学习达人",
            avatar: "defaultAvatar",
            createTime: "2024-12-06 15:10:00",
            likeCount: 5,
            dislikeCount: 0,
            isLiked: true,
            isDisliked: false,
            isAnonymous: false,
            treeHoleId: treeHoleId
          },
          {
            id: 2,
            content: "有什么好的学习资源推荐吗？",
            author: "匿名用户003",
            avatar: "defaultAvatar",
            createTime: "2024-12-06 15:25:00",
            likeCount: 2,
            dislikeCount: 0,
            isLiked: false,
            isDisliked: false,
            isAnonymous: true,
            treeHoleId: treeHoleId
          }
        ];

        const result: TreeHolePaginationData<TreeHoleComment> = {
          list: mockComments,
          pageNum,
          pageSize,
          totalPages: 1,
          total: 2,
          hasNext: false
        };

        resolve(result);
      }, 300);
    });
  }

  /**
   * Mock 发布树洞
   */
  private async mockPostTreeHole(request: PostTreeHoleRequest): Promise<boolean> {
    return new Promise((resolve) => {
      setTimeout(() => {
        console.info('🌳 [Mock] 发布成功');
        resolve(true);
      }, 800);
    });
  }

  /**
   * Mock 发布评论
   */
  private async mockPostComment(request: PostCommentRequest): Promise<boolean> {
    return new Promise((resolve) => {
      setTimeout(() => {
        console.info('🌳 [Mock] 评论发布成功');
        resolve(true);
      }, 600);
    });
  }
}