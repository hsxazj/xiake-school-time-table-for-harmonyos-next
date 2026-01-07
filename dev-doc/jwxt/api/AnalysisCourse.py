# -*- coding: utf-8 -*-
"""
课表解析工具
功能：解析 test.json 课表文件，支持按周次和星期查询课程
"""

import json
import re
import sys
import os
from typing import List, Dict, Any


def parse_week_range(zcd: str) -> List[int]:
    """
    解析周次字符串，返回周次列表

    参数:
        zcd: 周次字符串，例如 "1-12周,14周" 或 "1-8周" 或 "8周,12-14周(双)"

    返回:
        周次列表，例如 [1, 2, 3, ..., 12, 14]
    """
    if not zcd or not isinstance(zcd, str):
        return []

    weeks = set()
    parts = zcd.split(',')

    for part in parts:
        part = part.strip()

        # 匹配范围格式: "1-12周"
        range_match = re.search(r'(\d+)-(\d+)周', part)
        if range_match:
            start = int(range_match.group(1))
            end = int(range_match.group(2))

            # 检查单双周标记
            if '(单)' in part:
                weeks.update(range(start, end + 1, 2) if start % 2 == 1 else range(start + 1, end + 1, 2))
            elif '(双)' in part:
                weeks.update(range(start, end + 1, 2) if start % 2 == 0 else range(start + 1, end + 1, 2))
            else:
                weeks.update(range(start, end + 1))
            continue

        # 匹配单周格式: "14周"
        single_match = re.search(r'(\d+)周', part)
        if single_match:
            weeks.add(int(single_match.group(1)))

    return sorted(list(weeks))


def parse_schedule(json_path: str) -> Dict[str, Any]:
    """
    解析JSON课表文件

    参数:
        json_path: JSON文件路径

    返回:
        包含学年、学期、课程列表的字典
    """
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 提取关键信息
        xsxx = data.get('xsxx', {})
        xnmc = xsxx.get('XNMC', '未知学年')
        xqm = xsxx.get('XQM', '未知学期')
        kb_list = data.get('kbList', [])

        return {
            'xnmc': xnmc,
            'xqm': xqm,
            'kb_list': kb_list
        }

    except FileNotFoundError:
        print(f"错误: 找不到文件 '{json_path}'")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"错误: 文件 '{json_path}' 不是有效的JSON格式")
        sys.exit(1)
    except Exception as e:
        print(f"错误: 读取文件时发生异常 - {e}")
        sys.exit(1)


def parse_jc_order(jc: str) -> int:
    """
    提取节次字符串的首数字用于排序

    参数:
        jc: 节次字符串，例如 "1-2节" 或 "3-4节"

    返回:
        首数字，例如 1, 3, 5, 7
    """
    match = re.search(r'(\d+)', jc)
    return int(match.group(1)) if match else 0


def query_courses(schedule_data: Dict[str, Any], week: int, weekday: int) -> List[Dict[str, str]]:
    """
    根据周次和星期查询课程

    参数:
        schedule_data: 课表数据字典
        week: 周次 (1-20)
        weekday: 星期几 (1-7)

    返回:
        符合条件的课程列表
    """
    kb_list = schedule_data['kb_list']
    matched_courses = []

    for course in kb_list:
        # 检查星期是否匹配
        xqj = str(course.get('xqj', ''))
        if xqj != str(weekday):
            continue

        # 检查周次是否匹配
        zcd = course.get('zcd', '')
        week_list = parse_week_range(zcd)
        if week not in week_list:
            continue

        # 提取需要的字段
        matched_courses.append({
            'kcmc': course.get('kcmc', '未知课程'),
            'jc': course.get('jc', '未知节次'),
            'cdmc': course.get('cdmc', '未知地点'),
            'xm': course.get('xm', '未知教师'),
            'zcd': zcd
        })

    # 按节次排序
    matched_courses.sort(key=lambda c: parse_jc_order(c['jc']))

    return matched_courses


def display_courses(courses: List[Dict[str, str]], week: int, weekday: int,
                   xnmc: str, xqm: str) -> None:
    """
    格式化显示课程信息

    参数:
        courses: 课程列表
        week: 周次
        weekday: 星期几
        xnmc: 学年名称
        xqm: 学期名称
    """
    weekday_names = {
        1: '星期一', 2: '星期二', 3: '星期三', 4: '星期四',
        5: '星期五', 6: '星期六', 7: '星期日'
    }

    print("\n" + "=" * 50)
    print(f"学年: {xnmc}    学期: {xqm}")
    print(f"第 {week} 周 {weekday_names.get(weekday, '未知')} 的课程安排")
    print("=" * 50)

    if not courses:
        print("\n今天没有课程安排\n")
    else:
        for idx, course in enumerate(courses, 1):
            print(f"\n{idx}. {course['kcmc']}")
            print(f"   节次: {course['jc']}")
            print(f"   地点: {course['cdmc']}")
            print(f"   教师: {course['xm']}")
            print(f"   周次: {course['zcd']}")

    print("\n" + "=" * 50)
    print(f"共 {len(courses)} 门课程")
    print("=" * 50 + "\n")


def main():
    """
    主函数：实现交互式查询
    """
    # 获取JSON文件路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, 'test.json')

    # 解析课表数据
    print("正在加载课表数据...")
    schedule_data = parse_schedule(json_path)
    print(f"课表加载成功！")
    print(f"学年: {schedule_data['xnmc']}, 学期: {schedule_data['xqm']}\n")

    # 交互式查询循环
    while True:
        try:
            # 输入周次
            week_input = input("请输入周次 (1-20，输入 q 退出): ").strip()
            if week_input.lower() in ['q', 'quit', '退出']:
                print("感谢使用，再见！")
                break

            week = int(week_input)
            if week < 1 or week > 20:
                print("错误: 周次必须在 1-20 之间，请重新输入\n")
                continue

            # 输入星期
            weekday_input = input("请输入星期几 (1-7，1表示星期一): ").strip()
            if weekday_input.lower() in ['q', 'quit', '退出']:
                print("感谢使用，再见！")
                break

            weekday = int(weekday_input)
            if weekday < 1 or weekday > 7:
                print("错误: 星期必须在 1-7 之间，请重新输入\n")
                continue

            # 查询并显示课程
            courses = query_courses(schedule_data, week, weekday)
            display_courses(courses, week, weekday,
                          schedule_data['xnmc'], schedule_data['xqm'])

        except ValueError:
            print("错误: 请输入有效的数字\n")
        except KeyboardInterrupt:
            print("\n\n程序已中断，再见！")
            break
        except Exception as e:
            print(f"发生错误: {e}\n")


if __name__ == "__main__":
    main()
