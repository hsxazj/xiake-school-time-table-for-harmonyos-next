import { describe, it, expect } from '@ohos/hypium';
import { CourseInfo, CoursePosition, CourseRequestParams, TodayCourseRequestParams } from '../../../main/ets/models/CourseModels';

// 模拟课程数据
const mockCourseInfo: CourseInfo = {
  courseId: 101,
  courseName: '高等数学',
  teacher: '张教授',
  classroom: '教学楼A301',
  weekday: '星期一',
  section: '1-2节',
  weeks: '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]',
  courseTime: ['08:00', '09:40'],
  campus: '东校区'
};

const mockApiResponse = {
  courseId: 102,
  courseName: '大学英语',
  teacher: '李教授',
  classroom: '外语楼205',
  weekday: '星期二',
  section: '3-4节',
  weeks: '[1,3,5,7,9,11,13,15]',
  courseTime: ['10:00', '11:40'],
  campus: '西校区'
};

// 时间冲突检测工具函数
function checkCourseConflict(course1: CourseInfo, course2: CourseInfo): boolean {
  if (course1.weekday !== course2.weekday) return false;
  
  const course1Start = parseInt(course1.courseTime[0].split(':')[0]);
  const course1End = parseInt(course1.courseTime[1].split(':')[0]);
  const course2Start = parseInt(course2.courseTime[0].split(':')[0]);
  const course2End = parseInt(course2.courseTime[1].split(':')[0]);
  
  return (course1Start < course2End && course1End > course2Start);
}

// 数据转换函数
function convertApiDataToCourse(data: any): CourseInfo {
  return {
    courseId: data.courseId,
    courseName: data.courseName,
    teacher: data.teacher,
    classroom: data.classroom,
    weekday: data.weekday,
    section: data.section,
    weeks: data.weeks,
    courseTime: data.courseTime,
    campus: data.campus
  };
}

export default function CourseModelsTest() {
  describe('CourseModels', () => {
    /**
     * 模型初始化测试
     */
    describe('模型初始化', () => {
      it('应正确创建CourseInfo对象', 0, () => {
        const course: CourseInfo = { ...mockCourseInfo };
        expect(course.courseId).assertEqual(101);
        expect(course.courseName).assertEqual('高等数学');
        expect(course.teacher).assertEqual('张教授');
      });

      it('应正确创建CourseRequestParams对象', 0, () => {
        const params: CourseRequestParams = {
          week: 5,
          term: '3',
          year: '2024',
          classId: 'CS2023'
        };
        expect(params.week).assertEqual(5);
        expect(params.term).assertEqual('3');
        expect(params.classId).assertEqual('CS2023');
      });

      it('应正确创建TodayCourseRequestParams对象', 0, () => {
        const params: TodayCourseRequestParams = {
          classId: 'CS2023',
          year: 2024,
          term: '3',
          weeks: 5,
          weekday: '星期一'
        };
        expect(params.classId).assertEqual('CS2023');
        expect(params.weekday).assertEqual('星期一');
      });
    });

    /**
     * 数据转换测试
     */
    describe('数据转换', () => {
      it('应将API响应数据转换为CourseInfo对象', 0, () => {
        const converted = convertApiDataToCourse(mockApiResponse);
        expect(converted.courseId).assertEqual(102);
        expect(converted.courseName).assertEqual('大学英语');
        expect(converted.teacher).assertEqual('李教授');
        expect(converted.classroom).assertEqual('外语楼205');
      });

      it('应处理缺失字段的API数据', 0, () => {
        const partialData = {
          courseId: 103,
          courseName: '计算机科学'
        };
        const converted = convertApiDataToCourse(partialData);
        expect(converted.courseId).assertEqual(103);
        expect(converted.courseName).assertEqual('计算机科学');
        expect(converted.teacher).assertUndefined();
      });
    });

    /**
     * 业务逻辑验证
     */
    describe('课程时间冲突检测', () => {
      it('应检测到时间冲突', 0, () => {
        const course1: CourseInfo = {
          ...mockCourseInfo,
          courseTime: ['10:00', '11:40']
        };
        const course2: CourseInfo = {
          ...mockApiResponse,
          courseTime: ['11:00', '12:40']
        };
        const conflict = checkCourseConflict(course1, course2);
        expect(conflict).assertTrue();
      });

      it('不应检测不同日期的时间冲突', 0, () => {
        const course1: CourseInfo = {
          ...mockCourseInfo,
          weekday: '星期一'
        };
        const course2: CourseInfo = {
          ...mockApiResponse,
          weekday: '星期二'
        };
        const conflict = checkCourseConflict(course1, course2);
        expect(conflict).assertFalse();
      });

      it('应正确处理无重叠的时间段', 0, () => {
        const course1: CourseInfo = {
          ...mockCourseInfo,
          courseTime: ['08:00', '09:40']
        };
        const course2: CourseInfo = {
          ...mockApiResponse,
          courseTime: ['10:00', '11:40']
        };
        const conflict = checkCourseConflict(course1, course2);
        expect(conflict).assertFalse();
      });
    });

    /**
     * 模型方法测试
     */
    describe('模型方法', () => {
      it('应正确获取课程详情', 0, () => {
        const course: CourseInfo = { ...mockCourseInfo };
        const details = `课程: ${course.courseName}
教师: ${course.teacher}
时间: ${course.weekday} ${course.section} (${course.courseTime.join('-')})
地点: ${course.classroom}, ${course.campus}`;
        
        expect(details).assertContain('高等数学');
        expect(details).assertContain('张教授');
        expect(details).assertContain('教学楼A301');
      });

      it('应正确处理周次信息', 0, () => {
        const course: CourseInfo = { ...mockCourseInfo };
        const weekNumbers = course.weeks.replace(/[\[\]]/g, '').split(',').map(Number);
        expect(weekNumbers.length).assertEqual(16);
        expect(weekNumbers[0]).assertEqual(1);
        expect(weekNumbers[15]).assertEqual(16);
      });
    });
  });
}