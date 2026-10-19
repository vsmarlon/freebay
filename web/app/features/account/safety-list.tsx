import { useEffect, useState } from 'react';
import { useLocation } from 'react-router';
import { api } from '../../core/api';
import { Frame, Panel, PersonCard, useAccountText, type User } from './account';
export default function SafetyListPage() {
  const { t } = useAccountText(); const restricted = useLocation().pathname.endsWith('/restricted'); const [users, setUsers] = useState<User[]>([]); const [error, setError] = useState(false); const endpoint = restricted ? '/users/me/restricted' : '/users/blocked';
  async function load() { setError(false); try { const result = await api.get<{ users?: User[] } | User[]>(`${endpoint}?limit=50&offset=0`); setUsers(Array.isArray(result) ? result : result.users ?? []); } catch { setError(true); } }
  useEffect(() => { void load(); }, [endpoint]);
  async function remove(user: User) { try { await (restricted ? api.patch(`/users/me/restricted/${user.id}/remove`) : api.patch(`/users/${user.id}/unblock`)); await load(); } catch { setError(true); } }
  return <Frame title={restricted ? t('restricted') : t('blocked')}><Panel>{error ? <p role="alert" className="text-danger">{t('error')} <button onClick={() => void load()}>{t('retry')}</button></p> : null}{users.length ? <div className="grid gap-2">{users.map((user) => <PersonCard key={user.id} user={user} action={<button className="min-h-11 bg-surface-high px-3" onClick={() => void remove(user)}>{t('remove')}</button>} />)}</div> : !error ? <p>{t('empty')}</p> : null}</Panel></Frame>;
}
