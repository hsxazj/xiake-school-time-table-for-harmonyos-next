import { http } from "@/lib/jwxt/client";

export async function logout(): Promise<void> {
  const url = "logout";
  const referer = "xtgl/index_initMenu.html";
  await http.post<any>(url, { referer });
}
