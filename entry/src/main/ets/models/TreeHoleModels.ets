/**
 * 树洞功能相关数据模型定义
 * 参考class-schedule-c项目的树洞功能实现
 */

/**
 * 树洞内容项接口
 */
export interface TreeHoleItem {
  /** 树洞ID */
  id: number;
  /** 内容文本 */
  content: string;
  /** 作者昵称（匿名时使用昵称，非匿名时使用真实姓名） */
  author: string;
  /** 头像地址 */
  avatar: string;
  /** 创建时间 */
  createTime: string;
  /** 点赞数量 */
  likeCount: number;
  /** 评论数量 */
  commentCount: number;
  /** 是否匿名发布 */
  isAnonymous: boolean;
  /** 当前用户是否已点赞 */
  isLiked: boolean;
  /** 是否置顶 */
  isTop?: boolean;
  /** 销毁倒计时（如果有定时销毁） */
  countdown?: string;
}

/**
 * 树洞评论接口
 */
export interface TreeHoleComment {
  /** 评论ID */
  id: number;
  /** 评论内容 */
  content: string;
  /** 评论作者 */
  author: string;
  /** 头像地址 */
  avatar: string;
  /** 创建时间 */
  createTime: string;
  /** 点赞数 */
  likeCount: number;
  /** 点踩数 */
  dislikeCount: number;
  /** 当前用户是否已点赞 */
  isLiked: boolean;
  /** 当前用户是否已点踩 */
  isDisliked: boolean;
  /** 是否匿名评论 */
  isAnonymous: boolean;
  /** 父级树洞ID */
  treeHoleId: number;
}

/**
 * 发布树洞的请求参数
 */
export interface PostTreeHoleRequest {
  /** 内容文本 */
  content: string;
  /** 是否匿名发布 */
  isAnonymous: boolean;
  /** 图片列表（可选） */
  images?: string[];
  /** 定时销毁时间（可选） */
  deleteTime?: string;
}

/**
 * 发布评论的请求参数
 */
export interface PostCommentRequest {
  /** 树洞ID */
  treeHoleId: number;
  /** 评论内容 */
  content: string;
  /** 是否匿名评论 */
  isAnonymous: boolean;
}

/**
 * API响应的基础接口
 */
export interface TreeHoleApiResponse<T> {
  /** 响应码 */
  code: number;
  /** 响应消息 */
  message: string;
  /** 响应数据 */
  data: T;
}

/**
 * 分页数据接口
 */
export interface TreeHolePaginationData<T> {
  /** 数据列表 */
  list: T[];
  /** 当前页码 */
  pageNum: number;
  /** 每页数量 */
  pageSize: number;
  /** 总页数 */
  totalPages: number;
  /** 总记录数 */
  total: number;
  /** 是否有下一页 */
  hasNext: boolean;
}