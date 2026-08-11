import { generateKeyPairSync } from 'node:crypto';

const { privateKey, publicKey } = generateKeyPairSync('ed25519');
const privateKeyBase64 = privateKey
  .export({ format: 'der', type: 'pkcs8' })
  .toString('base64');
const publicKeyDer = publicKey.export({ format: 'der', type: 'spki' });
const publicKeyBase64 = publicKeyDer.subarray(publicKeyDer.length - 32).toString('base64url');

console.log('ENTITLEMENT_PRIVATE_KEY_BASE64=' + privateKeyBase64);
console.log('ENTITLEMENT_PUBLIC_KEY_BASE64=' + publicKeyBase64);
