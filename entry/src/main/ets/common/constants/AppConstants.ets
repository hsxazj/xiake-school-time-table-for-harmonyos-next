export interface ApiConfig {
  BASE_URL: string;
  VERSION: string;
  TIMEOUT: number;
}

export interface HttpMethodConfig {
  GET: string;
  POST: string;
  PUT: string;
  DELETE: string;
}

export interface ResponseCodeConfig {
  SUCCESS: number;
  UNAUTHORIZED: number;
  FORBIDDEN: number;
  NOT_FOUND: number;
  SERVER_ERROR: number;
}

export interface StorageKeysConfig {
  TOKEN: string;
  USER_INFO: string;
  COLLEGE_ID: string;
  MAJOR_ID: string;
  CLASS_ID: string;
  COLLEGE_NAME: string;
  MAJOR_NAME: string;
  CLASS_NAME: string;
  LOGIN_STATUS: string;
  NEED_LOGIN: string;
}

export const API_CONFIG: ApiConfig = {
  BASE_URL: 'https://school-time.fjutxiake.com',
  VERSION: '2.1.8',
  TIMEOUT: 10000
};

export const HTTP_METHOD: HttpMethodConfig = {
  GET: 'GET',
  POST: 'POST',
  PUT: 'PUT',
  DELETE: 'DELETE'
};

export const RESPONSE_CODE: ResponseCodeConfig = {
  SUCCESS: 200,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  SERVER_ERROR: 500
};

export const STORAGE_KEYS: StorageKeysConfig = {
  TOKEN: 'token',
  USER_INFO: 'userInfo',
  COLLEGE_ID: 'collegeId',
  MAJOR_ID: 'majorId',
  CLASS_ID: 'classId',
  COLLEGE_NAME: 'collegeName',
  MAJOR_NAME: 'majorName',
  CLASS_NAME: 'className',
  LOGIN_STATUS: 'loginStatus',
  NEED_LOGIN: 'needLogin'
};