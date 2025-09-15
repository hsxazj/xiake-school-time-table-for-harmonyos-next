
export interface ApiConfig {
  BASE_URL: string;
  TIMEOUT: number;
}

export const API_CONFIG: ApiConfig = {
  BASE_URL: 'https://school-time.fjutxiake.com',
  // BASE_URL: 'http://192.168.1.4:12001',
  TIMEOUT: 10000
};

export const RSA_PUBLIC_KEY =
  "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCe7zMfNLHX8wCgYZW6Uzo0XdNDX4FneS0n0i/Tl5db40FeNlA7KTB2xb7AtRfrPb8RSMVutFjW/R4dV/sUzEc+T5Vb0ME/gxql9kUil2dhxzlRuxxXbGKo8kWeh0X5xViiFaaevsmmyyqBWgL9OqMtOSduiDgfCdrLCylxtAvL/wIDAQAB";