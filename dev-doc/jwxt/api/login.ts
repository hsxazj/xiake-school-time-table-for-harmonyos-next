import { http } from "@/lib/jwxt/client";
import forge from "node-forge";

import { getCredentials } from "../credentials";
import { logout } from "./logout";

export async function login(): Promise<void> {
  await logout();

  const { sid, password } = getCredentials();
  if (!sid || !password) throw new Error("请先设置学号和密码");

  const html = await http.getText("xtgl/login_slogin.html", {
    referer: "xtgl/login_slogin.html",
    headers: {
      Accept:
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3",
    },
  });

  const csrfToken =
    html.match(/id=["']csrftoken["'][^>]*value=["']([^"']+)["']/i)?.[1] || "";

  const pubkey = await http.get<{ modulus: string; exponent: string }>(
    "xtgl/login_getPublicKey.html",
    { referer: "xtgl/login_slogin.html" }
  );

  const encrypted = encryptPassword(
    password,
    pubkey.modulus,
    pubkey.exponent
  );

  const form = new URLSearchParams();
  form.set("csrftoken", csrfToken);
  form.set("yhm", sid);
  form.set("mm", encrypted);

  const resp = await http.postForm<any>(
    "xtgl/login_slogin.html",
    form,
    {
      referer: "xtgl/login_slogin.html",
    }
  );

  const respText =
    typeof resp === "string"
      ? resp
      : resp
      ? JSON.stringify(resp)
      : "";
  if (respText.includes("用户名或密码不正确")) throw new Error("用户名或密码错误");
  if (respText.includes("验证码错误")) throw new Error("验证码错误");
  if (respText.includes("用户登录")) throw new Error("登录失败");
}

function encryptPassword(
  password: string,
  modulus: string,
  exponent: string
): string {
  const n = new forge.jsbn.BigInteger(
    forge.util.bytesToHex(forge.util.decode64(modulus)),
    16
  );
  const e = new forge.jsbn.BigInteger(
    forge.util.bytesToHex(forge.util.decode64(exponent)),
    16
  );
  const publicKey = forge.pki.setRsaPublicKey(n, e);
  return forge.util.encode64(publicKey.encrypt(password, "RSAES-PKCS1-V1_5"));
}
