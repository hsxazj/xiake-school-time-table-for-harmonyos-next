import { http } from "../client";
import { login } from "./login";

export interface Exam {
  id: string; // 考试编号
  name: string; // 课程名称
  time: string; // 考试时间
  classroom: string; // 考场
  seat: string; // 座位号
}

export async function getExam(year: number, term: number): Promise<Exam[]> {
  const url = "kwgl/kscx_cxXsksxxIndex.html?doType=query&gnmkdm=N358105";
  const referer = "kwgl/kscx_cxXsksxxIndex.html?gnmkdm=N358105&layout=default";

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
  const exams: Exam[] = items.map((item: any) => ({
    id: item.sjbh,
    name: item.kcmc,
    time: item.kssj,
    classroom: item.cdmc,
    seat: item.zwh,
  }));
  return exams;
}
