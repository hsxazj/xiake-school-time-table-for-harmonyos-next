export interface UserInfo {
  id: string;
  userName: string;
  nickName?: string;
  email?: string;
  phone?: string;
  avatar?: string;
  collegeId?: number;
  majorId?: number;
  classId?: number;
}

export interface LoginRequest {
  userName: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: UserInfo;
}

export interface Course {
  courseId: number;
  courseName: string;
  teacher: string;
  classroom: string;
  weekday: number;
  sectionStart: number;
  sectionEnd: number;
  weeks: string;
}

export interface CourseAdd extends Omit<Course, 'courseId'> {
  id?: number;
  userId: string;
  userName?: string;
}