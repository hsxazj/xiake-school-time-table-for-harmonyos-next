export interface College {
  collegeId: number;
  collegeName: string;
}

export interface Major {
  majorId: number;
  majorName: string;
  collegeId: number;
}

export interface ClassInfo {
  classId: number;
  className: string;
  majorId: number;
}

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface UserSelection {
  collegeId: number;
  collegeName: string;
  majorId: number;
  majorName: string;
  classId: number;
  className: string;
}