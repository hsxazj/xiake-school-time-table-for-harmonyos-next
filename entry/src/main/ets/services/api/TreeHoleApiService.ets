import {
  PostCommentRequest,
  PostTreeHoleRequest,
  TreeHoleApiPaginationData,
  TreeHoleComment,
  TreeHoleItem,
  TreeHolePaginationData,
  TreeHolePicture,
  GetPicturesRequest
} from '../../models/TreeHoleModels.ets_';
import { ApiResponse, HttpService } from './HttpService';

// 导出类型
export {
  TreeHoleItem,
  TreeHoleComment,
  PostTreeHoleRequest,
  PostCommentRequest,
  TreeHolePicture,
  GetPicturesRequest
} from '../../models/TreeHoleModels.ets_';

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

  /** 父级ID (用于获取评论，评论的parentId为树洞ID) */
  parentId?: number;
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
 * 获取评论的请求参数接口（基于parentId的方式）
 */
export interface GetCommentsRequestParams {
  /** 父级ID (对应树洞ID) */
  parentId: number;

  /** 页码 */
  pageNum: number;

  /** 每页数量 */
  pageSize: number;

  /** 状态筛选 */
  status: number;
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
    hilog.info(DOMAIN,TAG,'🌳 [TreeHoleApiService] 初始化树洞API服务');
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
    return {} as TreeHolePaginationData<TreeHoleItem>;
  }

  /**
   * 获取树洞评论列表
   * GET /treeHole/get?parentId=xxx&pageNum=1&pageSize=10&status=1
   */
  public async getTreeHoleComments(
    treeHoleId: number,
    pageNum: number = 1,
    pageSize: number = 10
  ): Promise<TreeHolePaginationData<TreeHoleComment>> {
    return {} as TreeHolePaginationData<TreeHoleComment>;
  }

  /**
   * 发布树洞
   * POST /treeHole/add
   */
  public async postTreeHole(request: PostTreeHoleRequest): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;
  }

  /**
   * 发布评论
   * POST /treeHole/add (参考class-schedule-c实现)
   */
  public async postComment(request: PostCommentRequest): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;

  }

  /**
   * 发布评论（使用完整请求参数）
   * POST /treeHole/add (与发布树洞使用相同的接口和格式)
   */
  public async postCommentWithFullRequest(request: PostTreeHoleRequest): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;

  }

  /**
   * 点赞/取消点赞树洞
   * POST /treeHole/like
   */
  public async toggleLike(treeHoleId: number, isLike: boolean): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;

  }

  /**
   * 点赞/取消点赞评论
   * POST /treeHole/comment/like
   */
  public async toggleCommentLike(commentId: number, isLike: boolean): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;

  }

  /**
   * 点踩/取消点踩评论
   * POST /treeHole/comment/dislike
   */
  public async toggleCommentDislike(commentId: number, isDislike: boolean): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;

  }

  /**
   * 删除树洞
   * DELETE /treeHole/delete?treeHoleId=xxx
   */
  public async deleteTreeHole(treeHoleId: number): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;
  }

  /**
   * 删除评论
   * DELETE /treeHole/comment/delete?commentId=xxx
   */
  public async deleteComment(commentId: number): Promise<ApiResponse<boolean>> {
    return {} as ApiResponse<boolean>;
  }

  /**
   * 获取树洞图片
   * GET /picture/getPictures?treeHoleId=xxx
   */
  public async getPictures(treeHoleId: number): Promise<TreeHolePicture[]> {
    return [] as TreeHolePicture[];
  }

  /**
   * 构建树洞列表请求参数的便捷方法
   */
  public buildTreeHoleParams(pageNum: number = 1, pageSize: number = 10, status: number = 1,
    type?: number): TreeHoleRequestParams {
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