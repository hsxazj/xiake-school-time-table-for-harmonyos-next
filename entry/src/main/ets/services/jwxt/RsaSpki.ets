/**
 * RSA SPKI (SubjectPublicKeyInfo) DER 编码工具
 *
 * 用途：
 * - 将裸 RSA 公钥参数 (n, e) 转换为 X.509 SubjectPublicKeyInfo DER 格式
 * - 手动构造 DER 编码，确保格式完全正确
 * - 支持长度字段的短格式（< 128）和长格式（>= 128）
 *
 * SubjectPublicKeyInfo 结构：
 * ```
 * SubjectPublicKeyInfo ::= SEQUENCE {
 *   algorithm         AlgorithmIdentifier,
 *   subjectPublicKey  BIT STRING (包含 RSAPublicKey)
 * }
 *
 * RSAPublicKey ::= SEQUENCE {
 *   modulus           INTEGER,  -- n
 *   publicExponent    INTEGER   -- e
 * }
 * ```
 *
 * @since 2026-01-07
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x3005;
const TAG: string = 'RsaSpki';

/**
 * DER 编码长度字段
 *
 * DER 长度编码规则：
 * - 如果长度 < 128：直接用 1 个字节表示
 * - 如果长度 >= 128：
 *   - 第一个字节：0x80 + 后续字节数
 *   - 后续字节：长度的大端序表示
 *
 * @param length 长度值
 * @returns DER 编码的长度字节数组
 */
function encodeDerLength(length: number): Uint8Array {
  if (length < 128) {
    // 短格式：直接用 1 个字节
    return new Uint8Array([length]);
  } else if (length < 256) {
    // 长格式：1 字节长度
    return new Uint8Array([0x81, length]);
  } else {
    // 长格式：2 字节长度
    const highByte = (length >> 8) & 0xFF;
    const lowByte = length & 0xFF;
    return new Uint8Array([0x82, highByte, lowByte]);
  }
}

/**
 * DER 编码 INTEGER
 *
 * 规则：
 * - Tag: 0x02
 * - 如果最高位是 1，需要在前面添加 0x00（保证正数）
 *
 * @param value 整数字节数组（大端序）
 * @returns DER 编码的 INTEGER
 */
function encodeDerInteger(value: Uint8Array): Uint8Array {
  // 如果最高位是 1，需要添加 0x00 前缀
  const needsPadding = value[0] >= 0x80;
  const contentLength = value.length + (needsPadding ? 1 : 0);

  // 编码长度字段
  const lengthBytes = encodeDerLength(contentLength);

  // 构造完整的 INTEGER
  const result = new Uint8Array(1 + lengthBytes.length + contentLength);
  let offset = 0;

  result[offset++] = 0x02; // INTEGER tag
  result.set(lengthBytes, offset);
  offset += lengthBytes.length;

  if (needsPadding) {
    result[offset++] = 0x00;
  }
  result.set(value, offset);

  return result;
}

/**
 * DER 编码 SEQUENCE
 *
 * @param tag SEQUENCE tag (0x30)
 * @param contents SEQUENCE 内容字节数组列表
 * @returns DER 编码的 SEQUENCE
 */
function encodeDerSequence(tag: number, contents: Uint8Array[]): Uint8Array {
  // 计算总内容长度
  const totalLength = contents.reduce((sum: number, item: Uint8Array) => sum + item.length, 0);

  // 编码长度字段
  const lengthBytes = encodeDerLength(totalLength);

  // 构造完整的 SEQUENCE
  const result = new Uint8Array(1 + lengthBytes.length + totalLength);
  let offset = 0;

  result[offset++] = tag; // SEQUENCE tag
  result.set(lengthBytes, offset);
  offset += lengthBytes.length;

  // 拼接所有内容
  for (const content of contents) {
    result.set(content, offset);
    offset += content.length;
  }

  return result;
}

/**
 * 将裸 RSA (n, e) 构造成 X.509 SPKI DER 格式
 *
 * @param n RSA 模数字节数组（大端序）
 * @param e RSA 指数字节数组（大端序）
 * @returns X.509 SubjectPublicKeyInfo DER 编码的字节数组
 * @throws Error 如果编码失败
 */
export function buildRsaSpki(n: Uint8Array, e: Uint8Array): Uint8Array {
  try {
    hilog.info(DOMAIN, TAG, '🔧 [Build SPKI] 开始构造 RSA SPKI...');
    hilog.info(DOMAIN, TAG, '🔧 [Build SPKI] n 长度: %{public}d bytes, e 长度: %{public}d bytes',
      n.length, e.length);

    // 步骤1: 编码 modulus (n) 和 exponent (e) 为 DER INTEGER
    const nDer = encodeDerInteger(n);
    const eDer = encodeDerInteger(e);

    // 步骤2: 构造 RSA 公钥 SEQUENCE { n, e }
    const rsaPublicKey = encodeDerSequence(0x30, [nDer, eDer]);

    hilog.info(DOMAIN, TAG, '✅ [Build SPKI] RSA 公钥序列长度: %{public}d bytes', rsaPublicKey.length);

    // 步骤3: 构造 AlgorithmIdentifier
    // RSA 加密算法 OID: 1.2.840.113549.1.1.1
    const algorithmIdentifier = new Uint8Array([
      0x30, 0x0d, // SEQUENCE, length=13
      0x06, 0x09, // OID tag, length=9
      0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, // rsaEncryption OID
      0x05, 0x00  // NULL
    ]);

    // 步骤4: 将公钥序列包装为 BIT STRING
    // BIT STRING: Tag(0x03) + Length + UnusedBits(0x00) + Content
    const bitStringContent = rsaPublicKey;
    const bitStringLength = 1 + bitStringContent.length; // 1 字节未使用位 + 内容
    const lengthBytes = encodeDerLength(bitStringLength);

    const bitString = new Uint8Array(1 + lengthBytes.length + bitStringLength);
    let offset = 0;
    bitString[offset++] = 0x03; // BIT STRING tag
    bitString.set(lengthBytes, offset);
    offset += lengthBytes.length;
    bitString[offset++] = 0x00; // 未使用位数 = 0
    bitString.set(bitStringContent, offset);

    // 步骤5: 构造最外层 SubjectPublicKeyInfo SEQUENCE
    const spkiDer = encodeDerSequence(0x30, [algorithmIdentifier, bitString]);

    hilog.info(DOMAIN, TAG, '✅ [Build SPKI] SPKI DER 长度: %{public}d bytes', spkiDer.length);

    // 调试：输出 SPKI DER 的十六进制表示（前64字节）
    const hexPreview = Array.from(spkiDer.slice(0, Math.min(64, spkiDer.length)))
      .map((b: number) => b.toString(16).padStart(2, '0'))
      .join(' ');
    hilog.info(DOMAIN, TAG, '🔍 [Build SPKI] DER 前64字节: %{public}s...', hexPreview);

    return spkiDer;
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    hilog.error(DOMAIN, TAG, '❌ [Build SPKI] 构造失败: %{public}s', errorMsg);
    throw new Error(`构造 RSA SPKI 失败: ${errorMsg}`);
  }
}

/**
 * 根据模数长度判断 RSA 密钥位长
 *
 * @param modulusBytes RSA 模数字节数组
 * @returns RSA 密钥位长字符串（如 'RSA1024', 'RSA2048'）
 */
export function detectRsaKeySize(modulusBytes: Uint8Array): string {
  const byteLength = modulusBytes.length;

  // RSA 密钥位长 = 字节数 × 8
  // 考虑到可能有填充字节（如最高位为0x00）
  if (byteLength >= 127 && byteLength <= 129) {
    return 'RSA1024'; // 128 字节 = 1024 bit
  } else if (byteLength >= 255 && byteLength <= 257) {
    return 'RSA2048'; // 256 字节 = 2048 bit
  } else if (byteLength >= 383 && byteLength <= 385) {
    return 'RSA3072'; // 384 字节 = 3072 bit
  } else if (byteLength >= 511 && byteLength <= 513) {
    return 'RSA4096'; // 512 字节 = 4096 bit
  }

  // 默认返回 RSA2048（最常见）
  hilog.warn(DOMAIN, TAG, '⚠️ [Detect] 无法精确判断密钥位长（%{public}d bytes），默认 RSA2048', byteLength);
  return 'RSA2048';
}
