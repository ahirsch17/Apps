const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { encryptPayload, decryptPayload } = require('./crypto');

describe('crypto', () => {
  it('round-trips JSON payloads with context', () => {
    const original = [{ displayName: 'Alex', year: 'Senior' }];
    const encrypted = encryptPayload(original, 'evt-vb-im');
    const decrypted = decryptPayload(encrypted, 'evt-vb-im');
    assert.deepEqual(decrypted, original);
  });

  it('fails decrypt with wrong context', () => {
    const encrypted = encryptPayload({ secret: true }, 'ctx-a');
    assert.throws(() => decryptPayload(encrypted, 'ctx-b'));
  });
});
