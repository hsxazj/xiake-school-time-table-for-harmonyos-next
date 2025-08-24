export interface ApiConfig {
  BASE_URL: string;
  VERSION: string;
  TIMEOUT: number;
}

export const API_CONFIG: ApiConfig = {
  BASE_URL: 'https://school-time.fjutxiake.com',
  VERSION: '2.1.8',
  TIMEOUT: 10000
};