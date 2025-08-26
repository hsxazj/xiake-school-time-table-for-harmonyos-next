// RsaPkcs1Util.ts
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

export class RsaPkcs1Util {
  /**
   * RSA/ECB/PKCS1Padding 加密
   * @param publicKeyB64  Base64 公钥（不含 PEM 头尾）
   * @param plainText     明文 UTF-8 字符串
   * @returns Base64 密文字符串
   */
  public static async encrypt(publicKeyB64: string, plainText: string): Promise<string> {
    // 1. 创建密钥生成器（位数必须与密钥匹配，这里以 2048 为例）
    const keyGen = cryptoFramework.createAsyKeyGenerator('RSA2048');

    // 2. 把 Base64 公钥转成 Uint8Array，再转成 PubKey
    const pubBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(publicKeyB64, 'base64').buffer) };
    const keyPair = await keyGen.convertKey(pubBlob, null);

    // 3. 创建 Cipher：RSA2048 | PKCS1
    const cipher = cryptoFramework.createCipher('RSA2048|PKCS1');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPair.pubKey, null);

    // 4. 加密
    const plainBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(plainText, 'utf-8').buffer) };
    const cipherBlob = await cipher.doFinal(plainBlob);

    // 5. 返回 Base64 结果
    return buffer.from(cipherBlob.data).toString('base64');
  }

  /**
   * RSA/ECB/PKCS1Padding 解密
   * @param privateKeyB64 Base64 私钥（不含 PEM 头尾）
   * @param cipherB64     Base64 密文字符串
   * @returns 解密后的 UTF-8 明文
   */
  public static async decrypt(privateKeyB64: string, cipherB64: string): Promise<string> {
    // 1. 创建密钥生成器
    const keyGen = cryptoFramework.createAsyKeyGenerator('RSA2048');

    // 2. 把 Base64 私钥转成 PriKey
    const priBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(privateKeyB64, 'base64').buffer) };
    const keyPair = await keyGen.convertKey(null, priBlob);

    // 3. 创建 Cipher
    const cipher = cryptoFramework.createCipher('RSA2048|PKCS1');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, keyPair.priKey, null);

    // 4. 解密
    const cipherBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(cipherB64, 'base64').buffer) };
    const plainBlob = await cipher.doFinal(cipherBlob);

    // 5. 返回 UTF-8 字符串
    return buffer.from(plainBlob.data).toString('utf-8');
  }
}