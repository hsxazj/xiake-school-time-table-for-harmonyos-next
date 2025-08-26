// 课程API请求参数
export interface CourseRequestParams {
  week: number; // 第几周
  term: string; // 学期代号：3为第一学期(秋季)，12为第二学期(春季)
  year: string; // 学年，如"2024"
  classId?: string; // 班级ID
  username?: string; // 学生用户名
}

// 今日课程过滤请求参数
export interface TodayCourseRequestParams {
  classId: string;
  year: number;
  term: string;
  weeks: number;
  weekday: string;
}

// 课程信息
export interface CourseInfo {
  courseId: number; // 课程ID为数字
  courseName: string;
  teacher: string; // 教师为字符串，不是数组
  classroom: string; // 教室为字符串，不是数组
  weekday: string; // 星期几，如"星期一"
  section: string; // 节次，如"1-2节"
  weeks: string; // 周次，如"[2,3,4,6,7,8,9,10,11]"
  courseTime: string[]; // 具体上课时间
  campus: string; // 校区
}

// 课程位置信息
export interface CoursePosition {
  week: number;
  day: number;
  timeSlot: number;
  course: CourseInfo;
}
