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
  },
  {
    courseId: 2928876,
    courseName: "计算机程序设计基础",
    teacher: "王教授",
    classroom: "计算机1＃－402",
    section: "7-8节",
    weeks: "[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]",
    courseTime: [
      "16:25-17:10",
      "17:15-18:00"
    ],
    weekday: "星期一",
    campus: "北校区"
  },
  {
    courseId: 2928877,
    courseName: "大学物理（1）",
    teacher: "张博士",
    classroom: "理工1＃－303",
    section: "9-10节",
    weeks: "[2,3,4,5,6,7,8,9,10,11,12,13,14,15]",
    courseTime: [
      "19:00-19:45",
      "19:50-20:35"
    ],
    weekday: "星期一",
    campus: "北校区"
  },
  {
    courseId: 2928878,
    courseName: "体育（1）",
    teacher: "刘老师",
    classroom: "体育馆",
    section: "11-12节",
    weeks: "[1,3,5,7,9,11,13,15]",
    courseTime: [
      "20:40-21:25",
      "21:30-22:15"
    ],
    weekday: "星期一",
    campus: "北校区"
  }
];