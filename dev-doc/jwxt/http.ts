// Warn: Code from AI

import axios, {
  AxiosError,
  AxiosInstance,
  AxiosRequestConfig,
  AxiosResponse,
  isAxiosError,
} from "axios";

export class ApiError extends Error {
  status?: number;
  url?: string;
  data?: unknown;

  constructor(
    message: string,
    opts?: { status?: number; url?: string; data?: unknown }
  ) {
    super(message);
    this.name = "ApiError";
    this.status = opts?.status;
    this.url = opts?.url;
    this.data = opts?.data;
  }
}

type CreateHttpOptions = {
  baseURL: string;
  timeoutMs?: number;
  makeReferer?: (pathOrReferer: string) => string;
};

type Extra = {
  referer?: string;
  headers?: Record<string, string>;
};

const UA =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36";

export function createHttp(opts: CreateHttpOptions) {
  const http: AxiosInstance = axios.create({
    baseURL: opts.baseURL,
    timeout: opts.timeoutMs ?? 15_000,
    withCredentials: true,
    validateStatus: (s) => s >= 200 && s < 400,
  });

  function normalizeError(err: unknown): never {
    if (!isAxiosError(err)) throw new ApiError("Unknown error", { data: err });

    const ae = err as AxiosError<any>;
    const status = ae.response?.status;
    const data = ae.response?.data;
    const url = ae.config?.baseURL
      ? `${ae.config.baseURL}${ae.config.url ?? ""}`
      : ae.config?.url ?? "";

    const message =
      (typeof data === "object" && data && (data.message || data.msg)) ||
      ae.message ||
      (status ? `Request failed (${status})` : "Network error");

    throw new ApiError(String(message), { status, url, data });
  }

  async function rawRequest<T>(
    config: AxiosRequestConfig,
    extra?: Extra
  ): Promise<AxiosResponse<T>> {
    const referer = extra?.referer ?? config.url ?? "";
    const headers: Record<string, string> = {
      "User-Agent": UA,
      ...(extra?.headers ?? {}),
      ...(config.headers as any),
    };

    if (opts.makeReferer) headers.Referer = opts.makeReferer(referer);

    try {
      return await http.request<T>({ ...config, headers });
    } catch (e) {
      normalizeError(e);
    }
  }

  return {
    async get<T>(
      url: string,
      extra?: Extra,
      config?: AxiosRequestConfig
    ): Promise<T> {
      const res = await rawRequest<T>({ url, method: "GET", ...config }, extra);
      return res.data;
    },

    async post<T>(
      url: string,
      body?: any,
      extra?: Extra,
      config?: AxiosRequestConfig
    ): Promise<T> {
      const res = await rawRequest<T>(
        { url, method: "POST", data: body, ...config },
        extra
      );
      return res.data;
    },

    async getText(url: string, extra?: Extra): Promise<string> {
      const res = await rawRequest<string>(
        { url, method: "GET", responseType: "text" },
        extra
      );
      return res.data as any;
    },

    async postForm<T>(
      url: string,
      form: URLSearchParams,
      extra?: Extra
    ): Promise<T> {
      return this.post<T>(url, form, {
        ...extra,
        headers: {
          Accept: "application/json, text/javascript, */*; q=0.01",
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          "X-Requested-With": "XMLHttpRequest",
          ...(extra?.headers ?? {}),
        },
      });
    },
  };
}
