import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { Frame, Panel, useAccountText } from './account';
import { usePreferences, type Theme } from '../../core/preferences';
import { paths } from '../../core/routes';
import { useSession } from '../../core/session';
import { userKey } from '../../core/query-client';
import { useApiMutation, useApiQuery } from '../../core/api-hooks';
import { Icon, SegmentedControl, Toggle } from '../../components';
import { parseNotificationPreferences, preferenceKeys, type NotificationPreferences, type PreferenceKey } from './notification-preferences';

const preferenceLabels: Record<PreferenceKey, string> = { orders: 'prefOrders', follows: 'prefFollows', messages: 'prefMessages', disputes: 'prefDisputes' };

export default function SettingsPage() {
  const { t, path, locale } = useAccountText();
  const navigate = useNavigate();
  const { theme, setTheme, animatedBackground, setAnimatedBackground } = usePreferences();
  const { signOut, user } = useSession();
  const [signingOut, setSigningOut] = useState(false);
  const [signOutError, setSignOutError] = useState(false);
  const [overrides, setOverrides] = useState<NotificationPreferences>({});
  const [saving, setSaving] = useState<PreferenceKey | null>(null);
  const [preferencesError, setPreferencesError] = useState(false);

  const preferencesQuery = useApiQuery<{ notificationPrefs?: unknown }>(userKey(user?.id ?? 'anonymous', 'settings'), '/users/me', { enabled: Boolean(user), staleTime: 30_000 });
  const remote = parseNotificationPreferences(preferencesQuery.data?.notificationPrefs);
  const preferences = { ...remote, ...overrides };

  const savePreference = useApiMutation<{ key: PreferenceKey; enabled: boolean }, unknown>({
    method: 'PATCH',
    path: '/users/me/fcm-token',
    body: ({ key, enabled }) => ({ notificationPrefs: { [key]: enabled } }),
  });

  async function setPreference(key: PreferenceKey, enabled: boolean) {
    setSaving(key);
    setPreferencesError(false);
    setOverrides((current) => ({ ...current, [key]: enabled }));
    try {
      await savePreference.mutateAsync({ key, enabled });
    } catch {
      setOverrides((current) => {
        const next = { ...current };
        delete next[key];
        return next;
      });
      setPreferencesError(true);
    } finally {
      setSaving(null);
    }
  }

  async function logout() {
    setSigningOut(true);
    setSignOutError(false);
    try { await signOut(); } catch { setSignOutError(true); } finally { setSigningOut(false); }
  }

  return <Frame title={t('settings')}><Panel>
    <div className="settings-page">
      <section className="settings-section" aria-labelledby="settings-appearance">
        <h2 id="settings-appearance">{t('appearance')}</h2>
        <div className="settings-row">
          <span className="settings-row-icon"><Icon name="palette" size={18} /></span>
          <span className="settings-row-copy"><span>{t('theme')}</span></span>
        </div>
        <SegmentedControl<Theme>
          label={t('theme')}
          value={theme}
          onChange={setTheme}
          options={[
            { value: 'light', label: t('light'), icon: 'light' },
            { value: 'dark', label: t('dark'), icon: 'dark' },
            { value: 'system', label: t('system'), icon: 'system' },
          ]}
        />
        <Toggle label={t('animated')} checked={animatedBackground} onChange={setAnimatedBackground} />
        <div className="settings-row">
          <span className="settings-row-icon"><Icon name="globe" size={18} /></span>
          <span className="settings-row-copy"><span>{t('locale')}</span></span>
        </div>
        <SegmentedControl
          label={t('locale')}
          value={locale}
          onChange={(next) => { if (next !== locale) navigate(`/${next}/settings`); }}
          options={[{ value: 'en', label: 'EN' }, { value: 'pt-BR', label: 'PT-BR' }]}
        />
      </section>

      <section className="settings-section" aria-labelledby="settings-notifications">
        <h2 id="settings-notifications">{t('notificationPreferences')}</h2>
        {preferencesQuery.isPending ? <p role="status">{t('loading')}</p> : preferenceKeys.map((key) => (
          <Toggle
            key={key}
            label={t(preferenceLabels[key])}
            checked={preferences[key] === true}
            disabled={saving === key}
            onChange={(enabled) => void setPreference(key, enabled)}
          />
        ))}
        <p className="settings-row-copy"><small>{t('preferenceDeliveryNote')}</small></p>
        {preferencesError || preferencesQuery.isError ? <p role="alert" className="settings-danger">{t('preferencesError')}</p> : null}
      </section>

      <section className="settings-section" aria-labelledby="settings-more">
        <h2 id="settings-more">{t('more')}</h2>
        <Link className="settings-row" to={path(paths.privacy)}>
          <span className="settings-row-icon"><Icon name="lock" size={18} /></span>
          <span className="settings-row-copy"><span>{t('privacy')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="settings-row" to={path(paths.closeFriends)}>
          <span className="settings-row-icon"><Icon name="follow" size={18} /></span>
          <span className="settings-row-copy"><span>{t('closeFriends')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="settings-row" to={path(paths.blocked)}>
          <span className="settings-row-icon"><Icon name="shield" size={18} /></span>
          <span className="settings-row-copy"><span>{t('safety')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="settings-row" to={path(paths.help)}>
          <span className="settings-row-icon"><Icon name="info" size={18} /></span>
          <span className="settings-row-copy"><span>{t('help')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <button type="button" className="settings-row settings-danger" disabled={signingOut} onClick={() => void logout()}>
          <span className="settings-row-icon"><Icon name="signOut" size={18} /></span>
          <span className="settings-row-copy"><span>{signingOut ? t('loading') : t('signOut')}</span></span>
        </button>
        {signOutError ? <p role="alert" className="settings-danger">{t('signOutError')}</p> : null}
      </section>
    </div>
  </Panel></Frame>;
}
