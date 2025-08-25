import { CourseInfo } from '../../models/CourseModels';

export interface ApiConfig {
  BASE_URL: string;
  VERSION: string;
  TIMEOUT: number;
}

export const API_CONFIG: ApiConfig = {
  BASE_URL: 'https://school-time.fjutxiake.com',
  VERSION: '2.1.8',
  TIMEOUT: 10000
};

export const MOCK_TODAY_COURSES: CourseInfo[] = [
  {
    courseId: 2928872,
    courseName: "高等数学（1）I",
    teacher: "祝丽华",
    classroom: "博学5＃－204",
    section: "1-2节",
    weeks: "[2,3,4,6,7,8,9,10,11,12,13,14,15]",
    courseTime: [
      "8:20-9:05",
      "9:15-10:00"
    ],
    weekday: "星期一",
    campus: "北校区"
  },
  {
    courseId: 2928874,
    courseName: "大学英语（1）",
    teacher: "游冰婷",
    classroom: "博学3＃－语音301",
    section: "3-4节",
    weeks: "[3]",
    courseTime: [
      "10:15-11:00",
      "11:05-11:50"
    ],
    weekday: "星期一",
    campus: "北校区"
  },
  {
    courseId: 2928875,
    courseName: "思想道德与法治",
    teacher: "李明",
    classroom: "博学2＃－101",
    section: "5-6节",
    weeks: "[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]",
    courseTime: [
      "14:30-15:15",
      "15:25-16:10"
    ],
    weekday: "星期一",
    campus: "北校区"
  }
];