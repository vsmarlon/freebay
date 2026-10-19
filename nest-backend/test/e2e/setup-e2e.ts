import { randomBytes } from 'node:crypto';

// Test-only defaults for credentials the journey never exercises over the
// network. Real values win when the environment provides them (CI, staging).
// The payment rail is out of this journey's scope: StripeProvider is
// constructed but never called, so no Stripe traffic can occur.
if (!process.env.GOOGLE_CLIENT_ID) {
  process.env.GOOGLE_CLIENT_ID = 'e2e-placeholder.apps.googleusercontent.com';
}
if (!process.env.STRIPE_SECRET_KEY) {
  process.env.STRIPE_SECRET_KEY = 'sk_test_e2e_not_a_real_key';
}
if (!process.env.STRIPE_WEBHOOK_SECRET) {
  process.env.STRIPE_WEBHOOK_SECRET = 'e2e_fake_webhook_secret_not_real';
}
if (!process.env.CPF_ENCRYPTION_KEY) {
  process.env.CPF_ENCRYPTION_KEY = randomBytes(32).toString('base64');
}
if (!process.env.CPF_HMAC_KEY) {
  process.env.CPF_HMAC_KEY = randomBytes(32).toString('base64');
}
