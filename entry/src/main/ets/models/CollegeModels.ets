export interface College {
  collegeId: string;
  collegeName: string;
}

export interface Major {
  majorId: string;
  majorName: string;
  collegeId: string;
}

export interface ClassInfo {
  classId: string;
  className: string;
  majorId: string;
}

export interface ApiResponse<T> {
  code: number;
  msg: string; // 改为msg以匹配实际API响应
  data: T;
}

export interface UserSelection {
  collegeId: string; // 改为string类型
  collegeName: string;
  majorId: string; // 改为string类型
  majorName: string;
  classId: string; // 改为string类型
  className: string;
}