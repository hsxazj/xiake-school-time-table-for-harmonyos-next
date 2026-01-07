import { http } from "../client";
import { login } from "./login";

export interface Course {
  id: string; // 课程号 warn: 由于同一个课程有不同星期/教室等，getCourse返回的课程号可能重复
  classroom: string; // 教室
  sessions: number[]; // 节次
  name: string; // 课程名称
  teacher: string; // 任课教师
  day_of_week: number; // 星期
  weeks: number[]; // 周次
}

export async function getCourse(year: number, term: number): Promise<Course[]> {
  const url = "kbcx/xskbcx_cxXsKb.html?gnmkdm=N2151";
  const referer = "kbcx/xskbcx_cxXsKb.html?gnmkdm=N2151&layout=default";

  const xqm = term ** 2 * 3;
  const form = new URLSearchParams();
  form.set("xnm", String(year));
  form.set("xqm", String(xqm));

  let data: any = await http.postForm<any>(url, form, { referer });
  if (!data || typeof data !== "object") {
    await login();
    data = await http.get<any>(url, { referer });
  }
  if (!data || typeof data !== "object") {
    throw new Error("获取信息失败：返回格式异常");
  }
  const items = Array.isArray(data) ? data : data?.kbList ?? [];
  const courses: Course[] = items.map((item: any) => ({
    id: item.kch_id,
    classroom: item.cdmc,
    sessions: parseSessions(item.jcs),
    name: item.kcmc,
    teacher: item.xm,
    day_of_week: Number(item.xqj),
    weeks: parseWeeks(item.zcd),
  }));
  return courses;
}

function parseSessions(sessionsStr: string): number[] {
  if (!sessionsStr) return [];
  const match = sessionsStr.trim().match(/(\d+)(?:-(\d+))?/);
  if (!match) return [];
  const start = Number(match[1]);
  const end = match[2] ? Number(match[2]) : start;
  const sessions: number[] = [];
  for (let i = start; i <= end; i++) {
    sessions.push(i);
  }
  return sessions;
}

function parseWeeks(weeksStr: string): number[] {
  if (!weeksStr) return [];
  const normalized = weeksStr.replace(/，/g, ",").replace(/\s+/g, "");
  const parts = normalized.split(",").filter(Boolean);
  const weeks = new Set<number>();
  for (const part of parts) {
    const match = part.match(/(\d+)(?:-(\d+))?周?(?:\((单|双)\))?/);
    if (!match) continue;
    const start = Number(match[1]);
    const end = match[2] ? Number(match[2]) : start;
    const parity = match[3];
    for (let i = start; i <= end; i++) {
      if (parity === "双" && i % 2 === 1) continue;
      if (parity === "单" && i % 2 === 0) continue;
      weeks.add(i);
    }
  }
  return Array.from(weeks).sort((a, b) => a - b);
}
