import { useCallback, useRef, useState } from 'react';
import { useNavigate } from 'react-router';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useAuthText, AuthButton, AuthMessage } from './auth-frame';

type GoogleCredential = { credential?: string };
type AppleAuthorization = { code?: string; id_token?: string; state?: string };
type AppleName = { firstName?: string; lastName?: string };
type AppleResponse = { authorization?: AppleAuthorization; user?: { name?: AppleName } };
type AppleAuth = { init: (options: { clientId: string; scope: string; redirectURI: string; state: string; nonce: string; usePopup: boolean }) => void; signIn: () => Promise<AppleResponse> };

declare global {
  interface Window {
    google?: { accounts: { id: { initialize: (options: { client_id: string; ux_mode?: 'popup' | 'redirect'; login_uri?: string; callback?: (response: GoogleCredential) => void }) => void; renderButton: (element: HTMLElement, options: { theme: string; size: string; shape: string; width: number }) => void } } };
    AppleID?: { auth: AppleAuth };
  }
}

const googleClientId = typeof import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID === 'string' ? import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID : '';
const appleClientId = typeof import.meta.env.VITE_APPLE_WEB_CLIENT_ID === 'string' ? import.meta.env.VITE_APPLE_WEB_CLIENT_ID : '';
const appleRedirectUri = typeof import.meta.env.VITE_APPLE_WEB_REDIRECT_URI === 'string' ? import.meta.env.VITE_APPLE_WEB_REDIRECT_URI : '';

export async function requestGoogleCredential(target: HTMLElement | null, signal?: AbortSignal): Promise<string> {
  if (!googleClientId) throw new Error('provider_unavailable');
  if (!target) throw new Error('provider_control_unavailable');
  await loadScript('google-identity-services', 'https://accounts.google.com/gsi/client');
  if (!window.google) throw new Error('provider_unavailable');
  return new Promise((resolve, reject) => {
    target.replaceChildren();
    let settled = false;
    const finish = (credential?: string) => {
      if (settled) return;
      settled = true;
      target.replaceChildren();
      if (credential) resolve(credential);
      else reject(new Error('provider_cancelled'));
    };
    const abort = () => { if (settled) return; settled = true; target.replaceChildren(); reject(new DOMException('Provider request cancelled', 'AbortError')); };
    if (signal?.aborted) { abort(); return; }
    signal?.addEventListener('abort', abort, { once: true });
    window.google?.accounts.id.initialize({ client_id: googleClientId, callback: (response) => finish(response.credential) });
    window.google?.accounts.id.renderButton(target, { theme: 'outline', size: 'large', shape: 'rectangular', width: Math.max(240, Math.floor(target.getBoundingClientRect().width)) });
    window.setTimeout(() => finish(), 120_000);
  });
}

export async function requestAppleCredential(signal?: AbortSignal): Promise<{ identityToken: string; rawNonce: string }> {
  if (!appleClientId || !appleRedirectUri) throw new Error('provider_unavailable');
  await loadScript('apple-signin-js', 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid.auth.js');
  if (!window.AppleID) throw new Error('provider_unavailable');
  const state = Array.from(crypto.getRandomValues(new Uint8Array(24)), (byte) => byte.toString(16).padStart(2, '0')).join('');
  const nonce = await randomNonce();
  window.AppleID.auth.init({ clientId: appleClientId, scope: 'email', redirectURI: appleRedirectUri, state, nonce: nonce.hashed, usePopup: true });
  const response = await window.AppleID.auth.signIn();
  if (signal?.aborted) throw new DOMException('Provider request cancelled', 'AbortError');
  const authorization = response.authorization;
  if (authorization?.state !== state || !authorization.id_token) throw new Error('provider_cancelled');
  return { identityToken: authorization.id_token, rawNonce: nonce.raw };
}

function loadScript(id: string, src: string): Promise<void> {
  const existing = document.getElementById(id);
  if (existing instanceof HTMLScriptElement && existing.dataset.loaded === 'true') return Promise.resolve();
  return new Promise((resolve, reject) => {
    const script = existing instanceof HTMLScriptElement ? existing : document.createElement('script');
    script.id = id;
    script.src = src;
    script.async = true;
    script.onload = () => { script.dataset.loaded = 'true'; resolve(); };
    script.onerror = () => reject(new Error('provider_script_unavailable'));
    if (!existing) document.head.append(script);
  });
}

async function randomNonce(): Promise<{ raw: string; hashed: string }> {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const raw = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw));
  const hashed = Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('');
  return { raw, hashed };
}

export function OAuthButtons({ returnTo }: { returnTo?: string }) {
  const { t, path } = useAuthText();
  const session = useSession();
  const navigate = useNavigate();
  const [error, setError] = useState('');
  const [pending, setPending] = useState(false);
  const unavailable = useRef(t('auth.provider.unavailable'));
  unavailable.current = t('auth.provider.unavailable');
  // ponytail: GIS redirect flow, rendered on mount so Google owns the click (no popup, no double click).
  const googleMount = useCallback((node: HTMLDivElement | null) => {
    if (!node || !googleClientId) return;
    let cancelled = false;
    void loadScript('google-identity-services', 'https://accounts.google.com/gsi/client').then(() => {
      if (cancelled || !window.google) return;
      window.google.accounts.id.initialize({
        client_id: googleClientId,
        ux_mode: 'redirect',
        login_uri: `${window.location.origin}/auth/web/google/redirect`,
        // GIS validates the callback even in redirect mode; the credential arrives by POST.
        callback: () => {},
      });
      window.google.accounts.id.renderButton(node, { theme: 'outline', size: 'large', shape: 'rectangular', width: Math.max(240, Math.floor(node.getBoundingClientRect().width)) });
    }).catch(() => { if (!cancelled) setError(unavailable.current); });
    return () => { cancelled = true; node.replaceChildren(); };
  }, []);
  async function finish(pathname: string, credential: object) {
    setPending(true);
    setError('');
    try {
      const result = await api.post<{ user?: { username?: string | null } }>(pathname, credential, { auth: false });
      await session.reload();
      const destination = returnTo ?? path('feed');
      await navigate(result.user?.username ? destination : `${path('complete-profile')}?returnTo=${encodeURIComponent(destination)}`);
    } catch {
      setError(t('auth.error'));
    } finally {
      setPending(false);
    }
  }
  async function apple() {
    if (!appleClientId || !appleRedirectUri) { setError(t('auth.provider.unavailable')); return; }
    setPending(true);
    setError('');
    try {
      await loadScript('apple-signin-js', 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid.auth.js');
      if (!window.AppleID) throw new Error('apple_sdk_unavailable');
      const state = Array.from(crypto.getRandomValues(new Uint8Array(24)), (byte) => byte.toString(16).padStart(2, '0')).join('');
      const nonce = await randomNonce();
      window.AppleID.auth.init({ clientId: appleClientId, scope: 'name email', redirectURI: appleRedirectUri, state, nonce: nonce.hashed, usePopup: true });
      const response = await window.AppleID.auth.signIn();
      const authorization = response.authorization;
      if (authorization?.state !== state || !authorization.id_token || !authorization.code) throw new Error('apple_auth_cancelled');
      const name = response.user?.name;
      const fullName = [name?.firstName, name?.lastName].filter((part): part is string => typeof part === 'string' && part.trim().length > 0).join(' ');
      await finish('/auth/web/apple', { identityToken: authorization.id_token, authorizationCode: authorization.code, rawNonce: nonce.raw, ...(fullName.length >= 2 ? { fullName } : {}) });
    } catch {
      setError(t('auth.provider.cancelled'));
      setPending(false);
    }
  }
  const googleConfigured = Boolean(googleClientId);
  const appleConfigured = Boolean(appleClientId && appleRedirectUri);
  if (!googleConfigured && !appleConfigured) return null;
  return <div className="mt-6 grid gap-3">
    <div className="relative text-center text-xs text-muted"><span className="bg-surface px-3">{t('auth.or')}</span></div>
    {googleConfigured ? <div ref={googleMount} className="min-h-11 w-full" /> : null}
    {appleConfigured ? <AuthButton type="button" disabled={pending} onClick={() => void apple()}>{t('auth.apple')}</AuthButton> : null}
    {error ? <AuthMessage error>{error}</AuthMessage> : null}
  </div>;
}
