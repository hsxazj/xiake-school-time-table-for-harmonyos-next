// TODO: 安全存储和获取

let currentSid = "";
let currentPassword = "";

export function setCredentials(sid: string, password: string) {
  currentSid = sid;
  currentPassword = password;
}

export function getCredentials() {
  return { sid: currentSid, password: currentPassword };
}
