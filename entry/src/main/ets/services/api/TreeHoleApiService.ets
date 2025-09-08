import { 
  TreeHoleItem, 
  TreeHoleComment, 
  PostTreeHoleRequest, 
  PostCommentRequest,
  TreeHolePaginationData,
  TreeHoleApiPaginationData
} from '../../models/TreeHoleModels';
import { ApiResponse, HttpService } from './HttpService';

// 导出类型
export { 
  TreeHoleItem, 
  TreeHoleComment, 
  PostTreeHoleRequest, 
  PostCommentRequest 
} from '../../models/TreeHoleModels';

/**
 * 树洞API请求参数接口
 */
export interface TreeHoleRequestParams {
  /** 状态筛选 (1-正常, 0-禁用等) */
  status?: number;
  /** 页码 */
  pageNum?: number;
  /** 每页数量 */
  pageSize?: number;
  /** 树洞类型 (3-普通树洞等) */
  type?: number;
}

/**
 * 评论请求参数接口
 */
export interface CommentsRequestParams {
  /** 树洞ID */
  treeHoleId: number;
  /** 页码 */
  pageNum?: number;
  /** 每页数量 */
  pageSize?: number;
}

/**
 * 点赞请求参数接口
 */
export interface LikeRequestParams {
  /** 树洞ID */
  treeHoleId: number;
  /** 是否点赞 (true-点赞, false-取消点赞) */
  isLike: boolean;
}

/**
 * 评论点赞请求参数接口
 */
export interface CommentLikeRequestParams {
  /** 评论ID */
  commentId: number;
  /** 是否点赞 (true-点赞, false-取消点赞) */
  isLike: boolean;
}

/**
 * 评论点踩请求参数接口
 */
export interface CommentDislikeRequestParams {
  /** 评论ID */
  commentId: number;
  /** 是否点踩 (true-点踩, false-取消点踩) */
  isDislike: boolean;
}

/**
 * 删除树洞请求参数接口
 */
export interface DeleteTreeHoleRequestParams {
  /** 树洞ID */
  treeHoleId: number;
}

/**
 * 删除评论请求参数接口
 */
export interface DeleteCommentRequestParams {
  /** 评论ID */
  commentId: number;
}

/**
 * 树洞功能API服务封装
 * 基于HttpService实现真实的API请求
 */
export class TreeHoleApiService {
  private static instance: TreeHoleApiService;
  private httpService = HttpService.getInstance();

  private constructor() {
    console.info('🌳 [TreeHoleApiService] 初始化树洞API服务');
  }

  public static getInstance(): TreeHoleApiService {
    if (!TreeHoleApiService.instance) {
      TreeHoleApiService.instance = new TreeHoleApiService();
    }
    return TreeHoleApiService.instance;
  }

  /**
   * 获取树洞列表
   * GET /treeHole/get?status=1&pageNum=1&pageSize=10
   */
  public async getTreeHoleList(
    pageNum: number = 1, 
    pageSize: number = 10, 
    status: number = 1,
    type?: number
  ): Promise<TreeHolePaginationData<TreeHoleItem>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 获取树洞列表 - 页码:${pageNum}, 大小:${pageSize}, 状态:${status}`);
      
      const params: TreeHoleRequestParams = {
        status,
        pageNum,
        pageSize
      };
      
      if (type !== undefined) {
        params.type = type;
      }

      const response = await this.httpService.get<TreeHoleRequestParams, TreeHoleApiPaginationData<TreeHoleItem>>('/treeHole/get', params);

      // 转换后端数据结构为前端期望的格式
      const result: TreeHolePaginationData<TreeHoleItem> = {
        list: response.data.treeHoleVOList || [],
        pageNum: pageNum,
        pageSize: pageSize,
        totalPages: response.data.pageCount || 1,
        // 估算总记录数：如果是最后一页用当前页数据量，否则用pageSize * totalPages估算
        total: pageNum >= (response.data.pageCount || 1) 
          ? (pageNum - 1) * pageSize + (response.data.treeHoleVOList || []).length
          : (response.data.pageCount || 1) * pageSize,
        hasNext: pageNum < (response.data.pageCount || 1)
      };

      console.info(`🌳 [TreeHoleApiService] 获取树洞列表成功，共${result.list.length}条数据`);
      return result;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 获取树洞列表失败:', error);
      throw new Error('获取树洞列表失败');
    }
  }

  /**
   * 获取树洞评论列表
   * GET /treeHole/comments?treeHoleId=xxx&pageNum=1&pageSize=10
   */
  public async getTreeHoleComments(
    treeHoleId: number, 
    pageNum: number = 1, 
    pageSize: number = 10
  ): Promise<TreeHolePaginationData<TreeHoleComment>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 获取评论列表 - 树洞ID:${treeHoleId}, 页码:${pageNum}`);
      
      const params: CommentsRequestParams = {
        treeHoleId,
        pageNum,
        pageSize
      };

      const response = await this.httpService.get<CommentsRequestParams, TreeHolePaginationData<TreeHoleComment>>('/treeHole/comments', params);

      console.info(`🌳 [TreeHoleApiService] 获取评论列表成功，共${response.data.total}条数据`);
      return response.data;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 获取评论失败:', error);
      throw new Error('获取评论失败');
    }
  }

  /**
   * 发布树洞
   * POST /treeHole/post
   */
  public async postTreeHole(request: PostTreeHoleRequest): Promise<ApiResponse<boolean>> {
    try {
      console.info('🌳 [TreeHoleApiService] 发布树洞:', request.content.substring(0, 20) + '...');
      
      const response = await this.httpService.post<PostTreeHoleRequest, boolean>('/treeHole/post', request);

      console.info('🌳 [TreeHoleApiService] 发布树洞成功');
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 发布树洞失败:', error);
      throw new Error('发布树洞失败');
    }
  }

  /**
   * 发布评论
   * POST /treeHole/comment
   */
  public async postComment(request: PostCommentRequest): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 发布评论 - 树洞ID:${request.treeHoleId}`);
      
      const response = await this.httpService.post<PostCommentRequest, boolean>('/treeHole/comment', request);

      console.info('🌳 [TreeHoleApiService] 发布评论成功');
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 发布评论失败:', error);
      throw new Error('发布评论失败');
    }
  }

  /**
   * 点赞/取消点赞树洞
   * POST /treeHole/like
   */
  public async toggleLike(treeHoleId: number, isLike: boolean): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] ${isLike ? '点赞' : '取消点赞'} 树洞ID:${treeHoleId}`);
      
      const params: LikeRequestParams = {
        treeHoleId,
        isLike
      };

      const response = await this.httpService.post<LikeRequestParams, boolean>('/treeHole/like', params);

      console.info(`🌳 [TreeHoleApiService] ${isLike ? '点赞' : '取消点赞'}成功`);
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 点赞操作失败:', error);
      throw new Error('点赞操作失败');
    }
  }

  /**
   * 点赞/取消点赞评论
   * POST /treeHole/comment/like
   */
  public async toggleCommentLike(commentId: number, isLike: boolean): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] ${isLike ? '点赞' : '取消点赞'} 评论ID:${commentId}`);
      
      const params: CommentLikeRequestParams = {
        commentId,
        isLike
      };

      const response = await this.httpService.post<CommentLikeRequestParams, boolean>('/treeHole/comment/like', params);

      console.info(`🌳 [TreeHoleApiService] 评论${isLike ? '点赞' : '取消点赞'}成功`);
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 评论点赞操作失败:', error);
      throw new Error('评论点赞操作失败');
    }
  }

  /**
   * 点踩/取消点踩评论
   * POST /treeHole/comment/dislike
   */
  public async toggleCommentDislike(commentId: number, isDislike: boolean): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] ${isDislike ? '点踩' : '取消点踩'} 评论ID:${commentId}`);
      
      const params: CommentDislikeRequestParams = {
        commentId,
        isDislike
      };

      const response = await this.httpService.post<CommentDislikeRequestParams, boolean>('/treeHole/comment/dislike', params);

      console.info(`🌳 [TreeHoleApiService] 评论${isDislike ? '点踩' : '取消点踩'}成功`);
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 评论点踩操作失败:', error);
      throw new Error('评论点踩操作失败');
    }
  }

  /**
   * 删除树洞
   * DELETE /treeHole/delete?treeHoleId=xxx
   */
  public async deleteTreeHole(treeHoleId: number): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 删除树洞ID:${treeHoleId}`);
      
      const params: DeleteTreeHoleRequestParams = { treeHoleId };
      const response = await this.httpService.delete<DeleteTreeHoleRequestParams, boolean>('/treeHole/delete', params);

      console.info('🌳 [TreeHoleApiService] 删除树洞成功');
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 删除树洞失败:', error);
      throw new Error('删除树洞失败');
    }
  }

  /**
   * 删除评论
   * DELETE /treeHole/comment/delete?commentId=xxx
   */
  public async deleteComment(commentId: number): Promise<ApiResponse<boolean>> {
    try {
      console.info(`🌳 [TreeHoleApiService] 删除评论ID:${commentId}`);
      
      const params: DeleteCommentRequestParams = { commentId };
      const response = await this.httpService.delete<DeleteCommentRequestParams, boolean>('/treeHole/comment/delete', params);

      console.info('🌳 [TreeHoleApiService] 删除评论成功');
      return response;
    } catch (error) {
      console.error('🌳 [TreeHoleApiService] 删除评论失败:', error);
      throw new Error('删除评论失败');
    }
  }

  /**
   * 构建树洞列表请求参数的便捷方法
   */
  public buildTreeHoleParams(pageNum: number = 1, pageSize: number = 10, status: number = 1, type?: number): TreeHoleRequestParams {
    const params: TreeHoleRequestParams = {
      status,
      pageNum,
      pageSize
    };
    
    if (type !== undefined) {
      params.type = type;
    }
    
    return params;
  }

  /**
   * 构建评论请求参数的便捷方法
   */
  public buildCommentsParams(treeHoleId: number, pageNum: number = 1, pageSize: number = 10): CommentsRequestParams {
    return {
      treeHoleId,
      pageNum,
      pageSize
    };
  }
}