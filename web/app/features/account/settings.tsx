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
    <div className="grid gap-[18px]">
      <section className="grid gap-1 border-[1.5px] border-ink bg-surface p-[18px] [&>h2]:mb-1.5 [&>h2]:font-display [&>h2]:text-lg [&>h2]:font-bold" aria-labelledby="settings-appearance">
        <h2 id="settings-appearance">{t('appearance')}</h2>
        <div className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&+*]:border-t [&+*]:border-ink/30">
          <span className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="palette" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('theme')}</span></span>
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
        <div className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&+*]:border-t [&+*]:border-ink/30">
          <span className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="globe" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('locale')}</span></span>
        </div>
        <SegmentedControl
          label={t('locale')}
          value={locale}
          onChange={(next) => { if (next !== locale) navigate(`/${next}/settings`); }}
          options={[{ value: 'en', label: 'EN' }, { value: 'pt-BR', label: 'PT-BR' }]}
        />
      </section>

      <section className="grid gap-1 border-[1.5px] border-ink bg-surface p-[18px] [&>h2]:mb-1.5 [&>h2]:font-display [&>h2]:text-lg [&>h2]:font-bold" aria-labelledby="settings-notifications">
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
        <p className="grid min-w-0 flex-1 gap-0.5"><small className="text-[11px] text-muted">{t('preferenceDeliveryNote')}</small></p>
        {preferencesError || preferencesQuery.isError ? <p role="alert" className="text-danger">{t('preferencesError')}</p> : null}
      </section>

      <section className="grid gap-1 border-[1.5px] border-ink bg-surface p-[18px] [&>h2]:mb-1.5 [&>h2]:font-display [&>h2]:text-lg [&>h2]:font-bold [&>a+a]:border-t [&>a+a]:border-ink/30 [&>button]:border-t [&>button]:border-ink/30" aria-labelledby="settings-more">
        <h2 id="settings-more">{t('more')}</h2>
        <Link className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&_svg:last-child]:shrink-0 [&_svg:last-child]:text-muted hover:**:data-row-icon:bg-surface-high" to={path(paths.privacy)}>
          <span data-row-icon="" className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="lock" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('privacy')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&_svg:last-child]:shrink-0 [&_svg:last-child]:text-muted hover:**:data-row-icon:bg-surface-high" to={path(paths.closeFriends)}>
          <span data-row-icon="" className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="follow" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('closeFriends')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&_svg:last-child]:shrink-0 [&_svg:last-child]:text-muted hover:**:data-row-icon:bg-surface-high" to={path(paths.blocked)}>
          <span data-row-icon="" className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="shield" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('safety')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <Link className="flex min-h-[50px] items-center gap-3 py-1.5 text-ink [&_svg:last-child]:shrink-0 [&_svg:last-child]:text-muted hover:**:data-row-icon:bg-surface-high" to={path(paths.help)}>
          <span data-row-icon="" className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="info" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{t('help')}</span></span>
          <Icon name="chevronRight" size={16} />
        </Link>
        <button type="button" className="flex min-h-[50px] w-full items-center gap-3 border-0 bg-transparent py-1.5 text-left text-danger" disabled={signingOut} onClick={() => void logout()}>
          <span className="grid size-9 shrink-0 place-items-center border border-ink bg-surface-mid"><Icon name="signOut" size={18} /></span>
          <span className="grid min-w-0 flex-1 gap-0.5"><span>{signingOut ? t('loading') : t('signOut')}</span></span>
        </button>
        {signOutError ? <p role="alert" className="text-danger">{t('signOutError')}</p> : null}
      </section>
    </div>
  </Panel></Frame>;
}
