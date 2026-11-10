import { api } from '../../core/api';

export type AuthUserPayload = { user?: { username?: string | null } };
export type StepUpPayload = { stepUpToken: string; expiresAt: string };
export type Proof = Record<string, unknown>;

export const authApi = {
  login: (email: string, password: string) =>
    api.post<AuthUserPayload>('/auth/web/login', { email, password }, { auth: false }),
  register: (input: { displayName: string; username: string; email: string; password: string }) =>
    api.post('/auth/web/register', input, { auth: false }),
  requestMagicLink: (input: { email: string; consent: boolean; locale: string }) =>
    api.post('/auth/web/magic-link/request', input, { auth: false }),
  consumeMagicLink: (token: string) =>
    api.post<AuthUserPayload>('/auth/web/magic-link/consume', { token }, { auth: false }),
  requestPasswordReset: (email: string, locale: string) =>
    api.post('/auth/web/password-reset/request', { email, locale }, { auth: false }),
  consumePasswordReset: (token: string, newPassword: string) =>
    api.post('/auth/web/password-reset/consume', { token, newPassword }, { auth: false }),
  verifyResetCode: (email: string, code: string) =>
    api.post('/auth/verify-reset-code', { email, code }, { auth: false }),
  resetPassword: (input: { email: string; code: string; newPassword: string }) =>
    api.post('/auth/reset-password', input, { auth: false }),
  completeProfile: (input: {
    username: string;
    displayName?: string;
    city?: string;
    state?: string;
  }) => api.post('/auth/complete-profile', input),
  usernameAvailable: (username: string) =>
    api.get<{ available: boolean; suggestions: string[] }>(
      `/auth/username-available?u=${encodeURIComponent(username)}`,
      { auth: false },
    ),
  oauth: (pathname: string, credential: Record<string, unknown>) =>
    api.post<AuthUserPayload>(pathname, credential, { auth: false }),
  stepUp: (input: { purpose: string; resourceId?: string; proof: Proof }, signal?: AbortSignal) =>
    api.post<StepUpPayload>('/auth/web/step-up', input, { signal }),
  requestStepUpMagicLink: (
    input: { purpose: string; resourceId?: string; locale: string; consent: boolean },
    signal?: AbortSignal,
  ) => api.post('/auth/web/step-up/magic-link/request', input, { signal }),
};
