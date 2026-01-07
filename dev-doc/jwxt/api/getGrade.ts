import { http } from "../client";
import { login } from "./login";

export interface Grade {
  id: string; // 课程号
  name: string; // 课程名称
  score: string; // 成绩
  grade_point: string; // 绩点
  credits: string; // 学分
}

export async function getGrade(year: number, term: number): Promise<Grade[]> {
  const url = "cjcx/cjcx_cxDgXscj.html?doType=query&gnmkdm=N305005";
  const referer =
    "cjcx/cjcx_cxDgXscj.html?gnmkdm=N305005&layout=default";

  const xqm = term ** 2 * 3;
  const form = new URLSearchParams();
  form.set("xnm", String(year));
  form.set("xqm", String(xqm));
  form.set("_search", "false");
  form.set("nd", String(Date.now()));
  form.set("queryModel.showCount", "100");
  form.set("queryModel.currentPage", "1");
  form.set("queryModel.sortName", "");
  form.set("queryModel.sortOrder", "asc");
  form.set("time", "0");

  let data: any = await http.postForm<any>(url, form, { referer });
  if (!data || typeof data !== "object") {
    await login();
    data = await http.get<any>(url, { referer });
  }
  if (!data || typeof data !== "object") {
    throw new Error("获取信息失败：返回格式异常");
  }
  const items = Array.isArray(data) ? data : data?.items ?? [];
  const grades: Grade[] = items.map((item: any) => ({
    id: item.kch_id,
    name: item.kcmc,
    grade_point: item.jd,
    score: item.cj,
    credits: item.xf,
  }));
  return grades;
}
