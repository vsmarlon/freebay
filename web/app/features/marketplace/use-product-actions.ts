import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { ApiError } from '../../core/api';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { userKey } from '../../core/query-client';
import { useSession } from '../../core/session';
import { favoritesApi, productApi } from './api';
import { productInquiryDraftState } from './product-inquiry-draft';
import { productKeys, useFavoriteState, useFollowState } from './queries';
import type { ProductSummary } from './types';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

// Interaction logic for the detail action bar: cache keys, invalidations and the
// signed-out redirect live here so the bar itself stays markup.
export function useProductActions(product: ProductSummary) {
  const { user } = useSession();
  const { path } = useLocale();
  const { t } = useI18n(catalogs);
  const cache = useQueryClient();
  const navigate = useNavigate();
  const favorite = useFavoriteState(user?.id, product.id);
  const follow = useFollowState(user?.id, product.sellerId);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  const requireLogin = () => navigate(path(paths.login));

  async function run(task: () => Promise<void>, fallback: string) {
    setBusy(true);
    setMessage('');
    try {
      await task();
    } catch (cause) {
      if (cause instanceof ApiError && cause.status === 401) requireLogin();
      else setMessage(fallback);
    } finally {
      setBusy(false);
    }
  }

  function toggleFavorite() {
    if (!user) return requireLogin();
    return run(async () => {
      await favoritesApi.add(product.id);
      await cache.invalidateQueries({ queryKey: productKeys.favorite(user.id, product.id) });
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'favorites') });
    }, t('common.error'));
  }

  function addToCart(quantity: number) {
    if (!user) return requireLogin();
    return run(async () => {
      await productApi.addToCart(product.id, quantity);
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'commerce', 'cart') });
      setMessage(t('product.added'));
    }, t('common.error'));
  }

  function contactSeller() {
    if (!user) return requireLogin();
    return run(async () => {
      const conversation = await productApi.contactSeller({
        targetUserId: product.sellerId,
        productId: product.id,
      });
      navigate(path(pathsFor.conversation(conversation.conversationId)), {
        state: productInquiryDraftState(product.id, product.sellerId),
      });
    }, t('product.contactError'));
  }

  function toggleFollow() {
    if (!user) return requireLogin();
    return run(async () => {
      if (follow.data?.isFollowing) await productApi.unfollow(product.sellerId);
      else await productApi.follow(product.sellerId);
      await cache.invalidateQueries({ queryKey: productKeys.follow(user.id, product.sellerId) });
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'profile', product.sellerId) });
    }, t('common.error'));
  }

  return {
    t,
    favorite,
    follow,
    saved: favorite.data?.isFavorited === true,
    following: follow.data?.isFollowing === true,
    busy,
    message,
    toggleFavorite,
    addToCart,
    contactSeller,
    toggleFollow,
  };
}
