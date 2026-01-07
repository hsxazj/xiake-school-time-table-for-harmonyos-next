import { http } from "../client";
import { login } from "./login";

export interface StudentInfo {
  name: string; // 姓名
  class_name: string; // 班级
  birthday: string; // 出生日期
  email: string; // 邮箱
  college: string; // 学院
  grade: string; // 年级
  qq: string; // QQ号码
  enrollment_date: string; // 入学日期
  phone: string; // 手机号码info
  gender: string; // 性别
  student_id: string; // 学号
  major: string; // 专业
}

export async function getInfo(): Promise<StudentInfo> {
  const url = "xsxxxggl/xsxxwh_cxCkDgxsxx.html?gnmkdm=N100801";
  const referer =
    "xsxxxggl/xsxxwh_cxCkDgxsxx.html?gnmkdm=N100801&layout=default";

  let data: any = await http.get<any>(url, { referer });
  if (!data || typeof data !== "object") {
    await login();
    data = await http.get<any>(url, { referer });
  }
  if (!data || typeof data !== "object") {
    throw new Error("获取信息失败：返回格式异常");
  }
  const info: StudentInfo = {
    name: data.xm,
    class_name: data.bh_id,
    birthday: data.csrq,
    email: data.dzyx,
    college: data.jg_id,
    grade: data.njdm_id,
    qq: data.qqhm,
    enrollment_date: data.rxrq,
    phone: data.sjhm,
    gender: data.xbm,
    student_id: data.xh,
    major: data.zyh_id,
  };
  return info;
}
