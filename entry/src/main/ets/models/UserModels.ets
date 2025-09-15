/**
 * 用户信息相关数据模型定义
 * 基于 /getInfo 接口返回的数据结构
 */

/**
 * 用户信息接口（完整用户数据）
 */
export interface UserInfo {
  /** 创建者 */
  createBy: string;

  /** 创建时间 */
  createTime: string;

  /** 更新者 */
  updateBy: string | null;

  /** 更新时间 */
  updateTime: string | null;

  /** 备注 */
  remark: string | null;

  /** 用户ID */
  userId: number;

  /** 部门ID */
  deptId: number | null;

  /** 用户名（学号） */
  userName: string;

  /** 学生班级ID */
  stuClassId: string;

  /** 昵称 */
  nickName: string;

  /** 真实姓名 */
  realName: string;

  /** 邮箱 */
  email: string;

  /** 手机号 */
  phonenumber: string;

  /** 性别（0-男，1-女） */
  sex: string;

  /** 头像路径 */
  avatar: string;

  /** 密码（已加密） */
  password: string;

  /** 状态（0-正常，1-停用） */
  status: string;

  /** 删除标志（0-存在，1-删除） */
  delFlag: string;

  /** 最后登录IP */
  loginIp: string;

  /** 最后登录时间 */
  loginDate: string;

  /** 部门信息 */
  dept: object | null;

  /** 角色列表 */
  roles: string[];

  /** 角色ID列表 */
  roleIds: number[] | null;

  /** 岗位ID列表 */
  postIds: number[] | null;

  /** 角色ID */
  roleId: number | null;

  /** 是否管理员 */
  admin: boolean;
}

/**
 * 获取用户信息API响应接口
 */
export interface GetUserInfoResponse {
  /** 响应消息 */
  msg: string;

  /** 响应代码 */
  code: number;

  /** 权限列表 */
  permissions: string[];

  /** 角色列表 */
  roles: string[];

  /** 用户信息 */
  user: UserInfo;
}

/**
 * /getInfo接口的原始响应类型（直接返回，不包装在ApiResponse中）
 * 该接口与其他API接口的响应格式不同，直接返回完整数据
 */
export interface GetUserInfoApiResponse {
  /** 响应消息 */
  msg: string;

  /** 响应代码 */
  code: number;

  /** 权限列表 */
  permissions: string[];

  /** 角色列表 */
  roles: string[];

  /** 用户信息 */
  user: UserInfo;
}

/**
 * 简化的用户信息接口（用于本地存储和状态管理）
 */
export interface SimpleUserInfo {
  /** 用户ID */
  userId: number;

  /** 用户名（学号） */
  userName: string;

  /** 学生班级ID */
  stuClassId: string;

  /** 昵称 */
  nickName: string;

  /** 真实姓名 */
  realName: string;

  /** 头像路径 */
  avatar: string;

  /** 是否管理员 */
  admin: boolean;
}

/**
 * 登录状态信息接口
 */
export interface LoginStatus {
  /** 是否已登录 */
  isLoggedIn: boolean;

  /** 登录时间 */
  loginTime?: string;

  /** token过期时间 */
  expireTime?: string;

  /** 用户信息 */
  userInfo?: SimpleUserInfo;
}