import { describe, expect, it } from 'vitest';
import { NotificationRequestScope } from './notifications';

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => { resolve = done; });
  return { promise, resolve };
}

describe('notification account request scope', () => {
  it('ignores late list and count responses after switching accounts', async () => {
    let activeUserId = 'account-a';
    let currentScope: NotificationRequestScope | undefined;
    const createScope = (userId: string) => {
      const holder: { scope?: NotificationRequestScope } = {};
      const scope = new NotificationRequestScope(() => activeUserId === userId && currentScope === holder.scope);
      holder.scope = scope;
      currentScope = scope;
      return scope;
    };
    const listA = deferred<{ items: string[] }>();
    const countA = deferred<{ count: number }>();
    const listB = deferred<{ items: string[] }>();
    const countB = deferred<{ count: number }>();
    let inbox: string[] = [];
    let unreadCount = 0;
    const scopeA = createScope('account-a');
    const lateList = scopeA.apply(listA.promise, (page) => { inbox = page.items; }, () => { inbox = ['A error']; });
    const lateCount = scopeA.apply(countA.promise, (count) => { unreadCount = count.count; }, () => { unreadCount = -1; });

    activeUserId = 'account-b';
    scopeA.cancel();
    const scopeB = createScope('account-b');
    const currentList = scopeB.apply(listB.promise, (page) => { inbox = page.items; }, () => { inbox = ['B error']; });
    const currentCount = scopeB.apply(countB.promise, (count) => { unreadCount = count.count; }, () => { unreadCount = -2; });
    listB.resolve({ items: ['B notice'] });
    countB.resolve({ count: 2 });
    await Promise.all([currentList, currentCount]);
    listA.resolve({ items: ['A notice'] });
    countA.resolve({ count: 1 });
    await Promise.all([lateList, lateCount]);

    expect(inbox).toEqual(['B notice']);
    expect(unreadCount).toBe(2);
    expect(scopeA.controller.signal.aborted).toBe(true);
  });
});
