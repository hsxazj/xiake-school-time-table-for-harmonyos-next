/**
 * 树洞功能相关数据模型定义
 * 参考class-schedule-c项目的树洞功能实现
 */

/**
 * 树洞内容项接口（基于后端真实数据结构）
 */
export interface TreeHoleItem {
  /** 树洞ID */
  id: number;
  /** 头像地址 */
  avatar: string;
  /** 真实姓名 */
  realName: string;
  /** 昵称（可为空） */
  nickName: string | null;
  /** 父级ID（用于回复层级结构） */
  parentId: number;
  /** 用户ID */
  userId: number;
  /** 内容文本 */
  content: string;
  /** 点赞数量 */
  likes: number;
  /** 点踩数量 */
  unlikes: number;
  /** 回复数量 */
  replies: number;
  /** 删除时间（软删除标记） */
  deleteTime: string | null;
  /** 状态（1-正常，0-禁用等） */
  status: number;
  /** 创建时间 */
  createAt: string;
  /** 更新时间 */
  updateAt: string | null;
  /** 是否匿名发布（0-非匿名，1-匿名） */
  anonymous: number;
  /** 处理用户ID（管理员操作时使用） */
  precessUserId: number | null;
  /** 是否已读（0-未读，1-已读） */
  isRead: number;
  /** 当前用户是否已点赞（0-未点赞，1-已点赞） */
  isLike: number;
  /** 当前用户是否已点踩（0-未点踩，1-已点踩） */
  isUnlike: number;
  /** 树洞类型（3-普通树洞，其他类型待扩展） */
  type: number;
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
 * 后端返回的树洞分页数据接口（真实API结构）
 */
export interface TreeHoleApiPaginationData<T> {
  /** 数据列表 */
  treeHoleVOList: T[];
  /** 总页数 */
  pageCount: number;
}

/**
 * 前端使用的树洞分页数据接口
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