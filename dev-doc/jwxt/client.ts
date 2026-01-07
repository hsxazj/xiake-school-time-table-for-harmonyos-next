import { createHttp } from "./http";

export let http = createHttp({
  baseURL: process.env.EXPO_PUBLIC_JWXT_BASE_URL!,
  makeReferer: (p) =>process.env.EXPO_PUBLIC_API_URL! + (p.startsWith("/") ? p.slice(1) : p)
});