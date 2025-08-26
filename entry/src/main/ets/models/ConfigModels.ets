export interface ConfigApiResponseData {
  start: Map<string, string[]>;
  end: Map<string, string[]>;
  week?: number;
  weekDayStr?: string;
  year?: number;
  termCode?: string;
}

// 处理后的学期信息
export interface SemesterInfo {
  academicYear: string; // 学年，如 "2024" 表示2024学年
  semester: number; // 1: 第一学期(秋季学期), 2: 第二学期(春季学期)
  startDate: string;
  endDate: string;
  totalWeeks: number;
}

// 当前状态信息
export interface CurrentSemesterStatus {
  isInSemester: boolean;
  isInHoliday: boolean;
  currentSemester?: SemesterInfo;
  currentWeek: number;
  statusText: string; // "第X周" 或 "假期中"
}

export interface WeekDateRange {
  startDate: Date;
  endDate: Date;
}