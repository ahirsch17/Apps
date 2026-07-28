const crypto = require('crypto');

const DEMO_KEY = process.env.BETWEEN_DEMO_KEY || 'between-vt-pilot-encryption-demo-key-32b!';

function encryptPayload(obj, context = '') {
  const iv = crypto.randomBytes(12);
  const key = crypto.createHash('sha256').update(DEMO_KEY + context).digest();
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const plaintext = JSON.stringify(obj);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    algorithm: 'AES-256-GCM',
    iv: iv.toString('base64'),
    tag: tag.toString('base64'),
    ciphertext: encrypted.toString('base64'),
    decryptedOnDevice: false,
  };
}

function decryptPayload(bundle, context = '') {
  const key = crypto.createHash('sha256').update(DEMO_KEY + context).digest();
  const decipher = crypto.createDecipheriv(
    'aes-256-gcm',
    key,
    Buffer.from(bundle.iv, 'base64')
  );
  decipher.setAuthTag(Buffer.from(bundle.tag, 'base64'));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(bundle.ciphertext, 'base64')),
    decipher.final(),
  ]);
  return JSON.parse(decrypted.toString('utf8'));
}

module.exports = { encryptPayload, decryptPayload };
