// TODO: 获取开学时间
// 校外获取地址（均只有当前学年）：
// https://hall.fjut.edu.cn/EIP//edu/education/schoolcalendar/showCalendar.htm
// https://jwc.fjut.edu.cn/_upload/tpl/0a/94/2708/template2708/js/week.js
// 校内教务系统周课表处获取：
// 
export async function getStartDate(year: number, term: number): Promise<Date> {
  const table: Record<string, string> = {
    "2025-2": "2026-03-02",
    "2025-1": "2025-09-08",
    "2024-2": "2025-02-17",
    "2024-1": "2024-09-02",
    "2023-2": "2024-02-26",
    "2023-1": "2023-09-04",
    "2022-2": "2023-02-13",
    "2022-1": "2022-08-29",
    "2021-2": "2022-02-21",
    "2021-1": "2021-08-30",
    "2020-2": "2021-03-01",
    "2020-1": "2020-09-14",
  };
  const key = `${year}-${term}`;
  const dateStr = table[key] ?? "2026-03-02";
  return new Date(dateStr);
}
