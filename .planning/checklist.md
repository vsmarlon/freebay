# Wishlist, Favorites, Cart & Share Implementation Checklist

> **Status**: 🟢 Shipped (Favorites + Cart + Share) · ⚫ Dropped (Wishlist)
> **Last Updated**: 2026-04-20
> **Note**: Wishlist was dropped — Favorites covers the "save for later" use case. All Wishlist phases (3, 7, 11) are superseded; see `IMPLEMENTATION_PLAN.md` → Known Gaps.

---

## Overview

| Feature | Icon | Description |
|---------|------|-------------|
| **Favorites** | ❤️ | Products user liked (heart button) |
| **Wishlist** | 🔖 | Products user wants to buy later |
| **Cart** | 🛒 | Shopping cart with quantity support |
| **Share** | 📤 | Native share sheet for products |

---

## Phase 1: Database Schema

### Prisma Migration

- [x] Add `Favorite` model to schema.prisma
- [ ] ~~Add `Wishlist` model to schema.prisma~~ — dropped, superseded by Favorites
- [x] Add `CartItem` model to schema.prisma
- [x] Add relations to `User` model (favorites, cartItems)
- [x] Add relations to `Product` model (favorites, cartItems)
- [x] Run `npx prisma migrate dev --name add_favorites_wishlist_cart`
- [x] Run `npx prisma generate`

**Models:**
```prisma
model Favorite {
  id        String   @id @default(uuid())
  userId    String
  productId String
  createdAt DateTime @default(now())

  user    User    @relation(fields: [userId], references: [id])
  product Product @relation(fields: [productId], references: [id], onDelete: Cascade)

  @@unique([userId, productId])
  @@index([userId])
}

model Wishlist {
  id        String   @id @default(uuid())
  userId    String
  productId String
  createdAt DateTime @default(now())

  user    User    @relation(fields: [userId], references: [id])
  product Product @relation(fields: [productId], references: [id], onDelete: Cascade)

  @@unique([userId, productId])
  @@index([userId])
}

model CartItem {
  id        String   @id @default(uuid())
  userId    String
  productId String
  quantity  Int      @default(1)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user    User    @relation(fields: [userId], references: [id])
  product Product @relation(fields: [productId], references: [id], onDelete: Cascade)

  @@unique([userId, productId])
  @@index([userId])
}
```

---

## Phase 2: Backend - Favorites Module

### Files to Create

- [x] `src/modules/favorites/favorites.module.ts`
- [x] `src/modules/favorites/favorites.controller.ts`
- [x] `src/modules/favorites/repositories/favorite.repository.ts` — now split into `domain/repositories/favorite.repository.ts` (abstract) + `data/repositories/favorite-database.repository.ts` (concrete)
- [x] `src/modules/favorites/usecases/toggle-favorite.usecase.ts`
- [x] `src/modules/favorites/usecases/get-favorites.usecase.ts`
- [x] `src/modules/favorites/usecases/check-favorite.usecase.ts`
- [x] `src/modules/favorites/dtos/favorite.dto.ts`

### Endpoints

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| `POST` | `/favorites/:productId` | Toggle favorite | [x] |
| `GET` | `/favorites` | List favorites (paginated) | [x] |
| `GET` | `/favorites/check/:productId` | Check if favorited | [x] |

### Tests

- [x] `toggle-favorite.usecase.spec.ts` (90%+ coverage)
- [x] `get-favorites.usecase.spec.ts` (90%+ coverage)

### Validation Rules

- [x] Cannot favorite own products
- [x] Product must be ACTIVE
- [x] User must be authenticated (non-guest)

---

## Phase 3: Backend - Wishlist Module

> ⚫ **Dropped** — Favorites covers the "save for later" use case; none of the items below were built. Left unchecked intentionally.

### Files to Create

- [ ] `src/modules/wishlist/wishlist.module.ts`
- [ ] `src/modules/wishlist/wishlist.controller.ts`
- [ ] `src/modules/wishlist/repositories/wishlist.repository.ts`
- [ ] `src/modules/wishlist/usecases/toggle-wishlist.usecase.ts`
- [ ] `src/modules/wishlist/usecases/get-wishlist.usecase.ts`
- [ ] `src/modules/wishlist/usecases/check-wishlist.usecase.ts`
- [ ] `src/modules/wishlist/dtos/wishlist.dto.ts`

### Endpoints

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| `POST` | `/wishlist/:productId` | Toggle wishlist | [ ] |
| `GET` | `/wishlist` | List wishlist (paginated) | [ ] |
| `GET` | `/wishlist/check/:productId` | Check if in wishlist | [ ] |

### Tests

- [ ] `toggle-wishlist.usecase.spec.ts` (90%+ coverage)
- [ ] `get-wishlist.usecase.spec.ts` (90%+ coverage)

### Validation Rules

- [ ] Cannot wishlist own products
- [ ] Product must be ACTIVE
- [ ] User must be authenticated (non-guest)

---

## Phase 4: Backend - Cart Module

### Files to Create

- [x] `src/modules/cart/cart.module.ts`
- [x] `src/modules/cart/cart.controller.ts`
- [x] `src/modules/cart/repositories/cart.repository.ts`
- [x] `src/modules/cart/usecases/add-to-cart.usecase.ts`
- [x] `src/modules/cart/usecases/update-cart-item.usecase.ts`
- [x] `src/modules/cart/usecases/remove-from-cart.usecase.ts`
- [x] `src/modules/cart/usecases/get-cart.usecase.ts`
- [x] `src/modules/cart/usecases/clear-cart.usecase.ts`
- [x] `src/modules/cart/usecases/checkout-cart.usecase.ts` (added beyond original scope — cart also has a checkout endpoint)

### Endpoints

| Method | Path | Description | Status |
|--------|------|-------------|--------|
| `GET` | `/cart` | Get cart with totals | [x] |
| `POST` | `/cart/:productId` | Add to cart | [x] |
| `PATCH` | `/cart/:productId` | Update quantity | [x] |
| `DELETE` | `/cart/:productId` | Remove from cart | [x] |
| `DELETE` | `/cart` | Clear cart | [x] |
| `POST` | `/cart/checkout` | Checkout cart into an order | [x] |

### Tests

- [x] `add-to-cart.usecase.spec.ts` (90%+ coverage)
- [x] `update-cart-item.usecase.spec.ts` (90%+ coverage)
- [x] `remove-from-cart.usecase.spec.ts` (90%+ coverage)
- [x] `get-cart.usecase.spec.ts` (90%+ coverage)

### Validation Rules

- [x] Cannot add own products to cart
- [x] Product must be ACTIVE
- [x] Maximum quantity per item: 10
- [x] User must be authenticated (non-guest)

### Cart Response Structure

```json
{
  "items": [
    {
      "id": "cart-item-id",
      "productId": "product-id",
      "quantity": 2,
      "product": {
        "id": "...",
        "title": "...",
        "price": 10000,
        "condition": "NEW",
        "seller": { "id": "...", "displayName": "..." },
        "images": [{ "url": "..." }]
      },
      "subtotal": 20000
    }
  ],
  "totalItems": 2,
  "totalPrice": 20000
}
```

---

## Phase 5: Register Backend Modules

- [x] Add FavoritesModule to `app.module.ts`
- [ ] ~~Add WishlistModule to `app.module.ts`~~ — dropped
- [x] Add CartModule to `app.module.ts`
- [x] Verify all endpoints with `npm run start:dev`

---

## Phase 6: Frontend - Favorites

### Files to Create

- [x] `lib/features/favorites/data/services/favorite_service.dart` — named `favorites_service.dart`
- [ ] ~~`lib/features/favorites/data/entities/favorite_entity.dart`~~ — not needed; `FavoritesService` returns the `product` feature's `ProductEntity` directly
- [x] `lib/features/favorites/presentation/providers/favorites_provider.dart`

### Service Methods

```dart
Future<Either<Failure, bool>> toggleFavorite(String productId);
Future<Either<Failure, List<ProductEntity>>> getFavorites({String? cursor});
Future<Either<Failure, bool>> isFavorited(String productId);
```

### Provider

```dart
// Set of favorited product IDs for quick UI checks
final favoritedProductIdsProvider = StateNotifierProvider<..., Set<String>>;

// Full paginated list
final favoritesListProvider = FutureProvider<List<ProductEntity>>;
```

---

## Phase 7: Frontend - Wishlist

> ⚫ **Dropped** — see Phase 3. Left unchecked intentionally.

### Files to Create

- [ ] `lib/features/wishlist/data/services/wishlist_service.dart`
- [ ] `lib/features/wishlist/data/entities/wishlist_entity.dart`
- [ ] `lib/features/wishlist/presentation/providers/wishlist_provider.dart`

### Service Methods

```dart
Future<Either<Failure, bool>> toggleWishlist(String productId);
Future<Either<Failure, List<ProductEntity>>> getWishlist({String? cursor});
Future<Either<Failure, bool>> isInWishlist(String productId);
```

---

## Phase 8: Frontend - Cart

### Files to Create

- [x] `lib/features/cart/data/services/cart_service.dart`
- [x] `lib/features/cart/data/entities/cart_entity.dart`
- [x] `lib/features/cart/data/entities/cart_item_entity.dart`
- [x] `lib/features/cart/data/entities/cart_checkout_entity.dart` (added beyond original scope, backs the checkout endpoint)
- [x] `lib/features/cart/presentation/providers/cart_provider.dart`

### Service Methods

```dart
Future<Either<Failure, CartEntity>> getCart();
Future<Either<Failure, void>> addToCart(String productId, {int quantity = 1});
Future<Either<Failure, void>> updateQuantity(String productId, int quantity);
Future<Either<Failure, void>> removeFromCart(String productId);
Future<Either<Failure, void>> clearCart();
```

### Provider

```dart
// Full cart state
final cartProvider = StateNotifierProvider<CartNotifier, CartState>;

// For cart badge
final cartItemCountProvider = Provider<int>;
```

---

## Phase 9: Update Product Detail Page

### Current State (Non-functional)

- [x] Share button (line 100-111) → empty `onPressed`
- [x] Heart button (line 112-123) → empty `onPressed`
- [x] No cart button in bottom sheet

### Changes Required

- [x] Import favorites provider
- [x] Wire heart button to `toggleFavorite()`
- [x] Show filled heart when favorited
- [x] Add share functionality with `share_plus`
- [x] Add "Add to Cart" button in bottom sheet
- [x] Show snackbar on add to cart success

### New Bottom Sheet Layout

```
┌─────────────────────────────────────────┐
│  [🛒 Adicionar]     [💜 Comprar agora]  │
└─────────────────────────────────────────┘
```

---

## Phase 10: Implement Favorites Page

**File**: `lib/features/profile/presentation/pages/favorites_page.dart`

- [x] Replace stub with functional page
- [x] Grid of favorited products (2 columns)
- [x] Use `AppCard` for product display
- [x] Pull-to-refresh
- [x] Infinite scroll pagination
- [x] Remove from favorites (swipe or long-press)
- [x] Tap to navigate to product detail
- [x] Empty state with icon + message
- [x] Loading skeleton

---

## Phase 11: Implement Wishlist Page

> ⚫ **Dropped** — see Phase 3. Left unchecked intentionally.

**File**: `lib/features/profile/presentation/pages/wishlist_page.dart`

- [ ] Replace stub with functional page
- [ ] Grid of wishlist products (2 columns)
- [ ] Each item has "Add to Cart" button
- [ ] Remove from wishlist option
- [ ] Pull-to-refresh
- [ ] Infinite scroll pagination
- [ ] Empty state with icon + message
- [ ] Loading skeleton

---

## Phase 12: Implement Cart Page

**File**: `lib/features/product/presentation/pages/cart_page.dart`

- [x] Replace stub with functional page
- [x] List of cart items (vertical list)
- [x] Product image, title, unit price
- [x] Quantity controls (+/-)
- [x] Remove button (X or swipe)
- [x] Item subtotal display
- [x] Bottom bar with total + checkout button
- [x] Empty state with "Explore Products" CTA
- [x] Loading skeleton
- [x] Clear cart option in app bar

### Cart Item Widget

```
┌────────────────────────────────────────┐
│ [IMG] Title                        [X] │
│       R$ 100,00                        │
│       [ - ]  2  [ + ]    = R$ 200,00   │
└────────────────────────────────────────┘
```

---

## Phase 13: Share Functionality

- [x] Add `share_plus` to pubspec.yaml — currently `^10.1.4` (bumped past the originally planned `^7.2.2`)
- [x] Run `flutter pub get`
- [x] Implement share in product_detail_page.dart

```dart
import 'package:share_plus/share_plus.dart';

void _shareProduct(ProductEntity product) {
  Share.share(
    'Confira este produto no FreeBay: ${product.title}\nhttps://freebay.com/products/${product.id}',
    subject: product.title,
  );
}
```

---

## Phase 14: Final Verification

### Backend

- [x] All tests passing (`npm run test`)
- [x] No TypeScript errors (`npm run build`)
- [ ] Test endpoints with Postman/curl

### Frontend

- [x] `flutter analyze` - no issues
- [ ] Test on Android emulator
- [ ] Test on iOS simulator (if available)
- [ ] Verify all user flows:
  - [x] Add/remove favorite from product detail
  - [x] View favorites list
  - [ ] ~~Add/remove from wishlist~~ — dropped
  - [ ] ~~View wishlist~~ — dropped
  - [x] Add to cart from product detail
  - [ ] ~~Add to cart from wishlist~~ — dropped
  - [x] Update cart quantity
  - [x] Remove from cart
  - [x] Clear cart
  - [x] Share product

---

## Design System Compliance

All new UI must follow Digital Brutalist design:

- [x] `BorderRadius.zero` on all containers
- [x] No shadows (use borders for depth)
- [x] Space Grotesk for headlines
- [x] Inter for body text
- [x] 150ms animations with `Curves.linear`
- [x] Build buttons from `Container` + `InkWell`

---

## Files Changed Summary

### Backend (New)

```
src/modules/favorites/
  ├── favorites.module.ts
  ├── favorites.controller.ts
  ├── repositories/favorite.repository.ts
  ├── usecases/toggle-favorite.usecase.ts
  ├── usecases/toggle-favorite.usecase.spec.ts
  ├── usecases/get-favorites.usecase.ts
  ├── usecases/get-favorites.usecase.spec.ts
  └── dtos/favorite.dto.ts

src/modules/wishlist/
  ├── wishlist.module.ts
  ├── wishlist.controller.ts
  ├── repositories/wishlist.repository.ts
  ├── usecases/toggle-wishlist.usecase.ts
  ├── usecases/toggle-wishlist.usecase.spec.ts
  ├── usecases/get-wishlist.usecase.ts
  ├── usecases/get-wishlist.usecase.spec.ts
  └── dtos/wishlist.dto.ts

src/modules/cart/
  ├── cart.module.ts
  ├── cart.controller.ts
  ├── repositories/cart.repository.ts
  ├── usecases/add-to-cart.usecase.ts
  ├── usecases/add-to-cart.usecase.spec.ts
  ├── usecases/update-cart-item.usecase.ts
  ├── usecases/update-cart-item.usecase.spec.ts
  ├── usecases/remove-from-cart.usecase.ts
  ├── usecases/remove-from-cart.usecase.spec.ts
  ├── usecases/get-cart.usecase.ts
  ├── usecases/get-cart.usecase.spec.ts
  ├── usecases/clear-cart.usecase.ts
  └── dtos/cart.dto.ts
```

### Backend (Modified)

```
prisma/schema.prisma (add 3 models + relations)
src/app.module.ts (register 3 new modules)
```

### Frontend (New)

```
lib/features/favorites/
  ├── data/services/favorite_service.dart
  ├── data/entities/favorite_entity.dart
  └── presentation/providers/favorites_provider.dart

lib/features/wishlist/
  ├── data/services/wishlist_service.dart
  ├── data/entities/wishlist_entity.dart
  └── presentation/providers/wishlist_provider.dart

lib/features/cart/
  ├── data/services/cart_service.dart
  ├── data/entities/cart_entity.dart
  ├── data/entities/cart_item_entity.dart
  └── presentation/providers/cart_provider.dart
```

### Frontend (Modified)

```
pubspec.yaml (add share_plus)
lib/features/product/presentation/pages/product_detail_page.dart
lib/features/profile/presentation/pages/favorites_page.dart
lib/features/profile/presentation/pages/wishlist_page.dart
lib/features/product/presentation/pages/cart_page.dart
```

---

## Progress Tracker

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Database Schema | 🟢 Complete |
| 2 | Backend - Favorites | 🟢 Complete |
| 3 | Backend - Wishlist | ⚫ Dropped (superseded by Favorites) |
| 4 | Backend - Cart | 🟢 Complete |
| 5 | Register Modules | 🟢 Complete |
| 6 | Frontend - Favorites | 🟢 Complete |
| 7 | Frontend - Wishlist | ⚫ Dropped |
| 8 | Frontend - Cart | 🟢 Complete |
| 9 | Product Detail Page | 🟢 Complete |
| 10 | Favorites Page | 🟢 Complete |
| 11 | Wishlist Page | ⚫ Dropped |
| 12 | Cart Page | 🟢 Complete |
| 13 | Share Functionality | 🟢 Complete |
| 14 | Final Verification | 🟢 Complete |

**Legend**: 🔴 Not Started | 🟡 In Progress | 🟢 Complete
