# Freebay Web

Living design and product contract for Freebay's complete responsive buyer and
seller browser marketplace. The browser client is also Freebay's public
product-marketing and onboarding surface, reusing the existing NestJS backend.

This document defines the web product boundary and its intended experience. It
does not claim that the web client or any capability marked as future exists.
For the visual source of truth, reuse [`frontend/DESIGN.md`](../frontend/DESIGN.md)
instead of creating a second token system.

## Product

Freebay is a **C2C social marketplace**: community discovery and social
interaction meet marketplace commerce. People discover products through people,
profiles, feed content, and search; they buy and sell through listings, chat,
checkout, escrow-backed orders, reviews, and dispute flows.

The web client should make the product understandable before sign-in, useful
for browsing without friction, and capable of reaching buyer and seller parity
with the Flutter app over time.

## Scope by horizon

### Now

- Define and build a complete buyer/seller responsive browser marketplace and
  marketing surface in `web/`.
- Use the existing NestJS/PostgreSQL/Prisma backend as the source of marketplace
  data and business rules.
- Provide public marketing, product discovery, listing detail, and graceful
  onboarding entry points.
- Launch in PT-BR and English using JSON translation catalogs.
- Make registration an immediate account-entry flow, not a waitlist.
- Collect only email and explicit consent initially.
- Authenticate with passwordless email authentication using a magic link only,
  then establish the normal web session.
- Use React 19 with React Router framework mode. Prerender or server-render
  indexable public, marketing, and product pages where appropriate; use client
  rendering for authenticated app flows.
- Keep business rules in the existing backend; do not duplicate backend
  business logic in `web/`.
- Treat beautiful UI, responsive behavior, and accessibility as release
  requirements, not polish to add later.

### Later

- Reach eventual parity with all buyer and seller Flutter flows: marketing,
  auth, feed/social, discovery/search, listings, profile, favorites, chat, cart,
  checkout, orders, wallet, reviews, disputes, and notifications.
- Add richer registration/profile completion after the minimal beta entry flow
  proves the product path.
- Decide and implement the web data-fetching strategy and deployment shape.
- Add admin and moderation screens as a separate future product scope; they are
  explicitly not part of the initial marketplace.

### Not yet production-ready

Do not market these as complete production capabilities until their backend,
operational, and client contracts are finished and verified:

- Stripe Connect, payouts, refunds, and webhook handling.
- Private paid media.
- Push notifications and deep links for the browser experience.
- Device-bound biometric authentication.

The current backend supports email/password authentication, Google auth,
password recovery, JWTs, and biometric-related flows. It does **not** currently
implement passwordless email authentication or a waitlist. Those are required
backend changes for this web contract; they must not be represented as existing
endpoints or finished functionality.

## Vocabulary

| Term | Meaning | Do not call it |
|---|---|---|
| **Account entry** | An immediate account-entry flow for a person who provides an email and explicit consent. | Waitlist, interest list |
| **Passwordless email authentication** | A one-time magic link delivered by email; confirmation and POST consumption establish the normal web session. | SSO, password recovery, OTP |
| **Magic link** | A high-entropy, single-use authentication token delivered by email and consumed only after explicit confirmation. | Numeric code, password recovery token |
| **SSO** | Sign-in delegated to an external identity provider, such as Google. | Passwordless email authentication |
| **Password recovery** | Recovery of an existing password. | Passwordless email authentication |
| **Authenticated account** | An account with a successfully consumed magic link and a normal web session. | Registered-but-authenticated lead |

The first release has no numeric email-code fallback. The web flow must never
reuse password recovery for passwordless authentication.

## Design principles

1. **Digital Brutalism, not decoration.** Preserve the Freebay identity in
   [`frontend/DESIGN.md`](../frontend/DESIGN.md): 0px radius, tonal depth, no
   regular shadows or divider lines, Space Grotesk headlines, Inter body text,
   restrained purple, and fast direct motion.
2. **One clear surface.** Prefer a strong parent surface with tonal sections;
   avoid nested-card abundance and ornamental containers.
3. **Commerce follows discovery.** Make the path from community signal to product
   detail to trusted transaction obvious.
4. **Direct language and action.** Use concrete labels, visible state, and one
   primary action per region. Do not hide essential onboarding or transaction
   information behind clever interaction.
5. **Trust is part of the interface.** Show seller identity, listing state,
   order/escrow state, consent meaning, and recovery paths without overpromising
   protection that the current backend does not provide.
6. **Responsive by construction.** Desktop is not a stretched mobile layout;
   mobile is not a clipped desktop layout.

## Design tokens

`frontend/DESIGN.md` is the canonical token contract. Web implementation should
map its CSS variables and components to those roles rather than inventing
parallel values.

- **Shape:** 0px radius everywhere, including controls, media, avatars, and
  focus treatments.
- **Depth:** tonal surface steps first; use hard offset depth only where it
  communicates a pressable surface. No blurred shadows and no decorative
  separator lines.
- **Brand:** use the existing restrained purple roles (`#660062` and `#8A1083`)
  as defined by the Flutter contract. Purple is a signal for primary action,
  focus, and active state—not a wash over every surface.
- **Type:** Space Grotesk for headlines and action/display labels; Inter for
  readable body copy and supporting text.
- **Motion:** fast, direct, named-role motion. Presses and toggles should feel
  immediate; arrivals may decelerate. No bounce or overshoot.
- **Layout:** use the existing 8px spacing logic as the starting grid; establish
  web-specific container widths only when responsive content requires them.
- **Content:** keep body copy readable, use all caps selectively for navigation
  and labels, and preserve sufficient contrast in every theme/surface pairing.

## Route and capability map

These are capability boundaries, not a claim that routes currently exist.

| Area | Representative routes | Capability |
|---|---|---|
| Public/marketing | `/`, `/about`, `/how-it-works` | Product explanation, trust model, public entry points |
| Auth/onboarding | `/register`, `/verify-email`, `/login`, `/complete-profile` | Account entry, magic-link confirmation, session entry, profile completion |
| Discovery | `/feed`, `/explore`, `/search`, `/categories` | Social discovery, product search, category browsing |
| Commerce | `/products/:id`, `/sell`, `/products/:id/edit`, `/favorites` | Listing detail, create/edit listing, saved products |
| Community | `/people/:username`, `/messages` | Public profiles, follow/social context, direct chat |
| Purchase | `/cart`, `/checkout`, `/orders`, `/orders/:id` | Cart, checkout, order lifecycle, transaction context |
| Account | `/wallet`, `/notifications`, `/settings` | Balance/withdrawal views, in-app notifications, preferences |
| Trust and resolution | `/orders/:id/review`, `/orders/:id/dispute` | Reviews, evidence, dispute entry and status |
| Future operations | `/admin/*`, `/moderation/*` | Explicitly future; not initial web scope |

The route names may change during implementation. The capability boundaries
should not be casually narrowed to the first screen set.

## Onboarding state model

Onboarding is a state machine, not a waitlist.

```text
anonymous
  └─ submit email + explicit consent
       ├─ accepted → link_sent
       └─ throttled/invalid → show non-enumerating retry state

link_sent
  └─ open magic link → confirmation_page

confirmation_page
  ├─ confirm → POST consume → authenticated_account → web_session
  ├─ expired/consumed/invalid link → safe failure → request a new link
  └─ GET alone → no authentication

web_session
  └─ profile incomplete → complete_profile → ready_account
```

The UI should make the next safe action clear, preserve entered email where
appropriate, and avoid revealing whether an email is already registered. A
successful magic-link consumption must be atomic and single-use on the backend.

## Passwordless email authentication contract

This contract requires new backend work in the existing NestJS backend. The web
client must not emulate it with password recovery or client-only state. The
existing backend does not currently implement this contract, and password
recovery must not be reused.

### Request

- Accept an email and explicit consent for beta/product communications as
  separate, understandable inputs.
- Return a non-enumerating response whether or not the email belongs to an
  existing account.
- Generate a cryptographically random, high-entropy magic-link token.
- Persist only the token hash, with a 10-minute expiry and an auditable request
  timestamp.
- Apply strict throttling per IP and per email, including resend limits.
- Capture explicit consent with the request/registration event.

### Confirm and consume

- A GET to the link may only render a confirmation page; it must not
  authenticate the user. This prevents email-security scanners from consuming
  links as logins.
- Require explicit confirmation followed by a POST consumption request.
- Compare the submitted token against the stored hash without exposing account
  existence.
- Consume the token atomically so concurrent requests cannot reuse it.
- Reject expired, consumed, or otherwise invalid tokens.
- Issue the normal `HttpOnly`, `Secure`, `SameSite` web session only after
  successful POST consumption.
- Record consent and audit timestamps with the registration/authentication
  event.

The magic link is an authentication credential with a 10-minute lifetime, not a
password, a recovery token, an SSO assertion, or a client-side secret. Do not
add a numeric fallback until real usage justifies it.

## Localization contract

- PT-BR and English ship from launch; neither is a fallback-only locale.
- Store UI copy in JSON catalogs with stable message keys, for example
  `auth.register.title`, `auth.magicLink.expired`, and
  `common.actions.continue`.
- Keep translations out of components and avoid concatenating translated
  fragments. Messages with variables must declare and interpolate named values.
- Localize validation, throttling, expiry, consent, empty, loading, and error
  states—not only happy-path labels.
- Preserve product vocabulary consistently across catalogs, URLs where practical,
  metadata, emails, and accessibility names.
- Allow locale selection before registration and retain it through the magic-link
  flow.
- Use locale URL segments for public and authenticated web routes, such as
  `/pt-BR/...` and `/en/...`.

## Responsive and accessibility baseline

- Design from small screens through wide desktop without loss of task order or
  information.
- Use semantic landmarks, headings in order, real buttons/links, labeled form
  controls, and meaningful accessible names for icon actions.
- Provide visible keyboard focus, logical keyboard order, skip navigation, and
  usable dialogs/sheets without pointer-only behavior.
- Meet WCAG AA contrast as a baseline, including purple actions and text on
  tonal surfaces; never use color alone for status.
- Support zoom/reflow and touch targets appropriate for mobile use. Do not rely
  on hover for essential information.
- Respect reduced-motion preferences and provide clear loading, error, empty,
  success, and session-expiry states.
- Make magic-link request, resend, throttling, and confirmation errors understandable to
  screen readers without leaking account existence.

## Reuse boundary

### Reuse from the backend

Reuse the NestJS backend's authenticated business capabilities, domain data,
validation rules, order states, and JWT contract through documented HTTP/WebSocket
interfaces. Backend rules remain authoritative for prices, inventory, escrow,
orders, permissions, disputes, and notifications. Add the passwordless email
contract to the backend rather than duplicating authentication logic in `web/`.

### Reuse from Flutter

Reuse product vocabulary, capability intent, API semantics, and the Digital
Brutalist visual direction. Treat Flutter implementation details, Riverpod state,
go_router configuration, mobile storage, FCM behavior, and device-bound biometric
flows as platform-specific. The web client is not a Flutter port and must not
inherit mobile-only assumptions.

### Do not reuse blindly

Do not copy `frontend/DESIGN.md` into this file or create diverging token tables.
Do not advertise a Flutter-only capability as web-ready without checking its
backend and browser interaction contract. Do not add an adapter solely to make
the initial web architecture look symmetrical with Flutter.

## Unresolved decisions

- Web state/data-fetching and cache strategy: TBD.
- Browser session storage, refresh-token policy, and cross-tab logout behavior:
  TBD with backend security review.
- Email delivery provider, sender identity, template ownership, and delivery
  observability: TBD.
- Exact backend API/versioning shape for passwordless registration and login: TBD.
- Initial payment-provider/browser checkout boundary while Stripe Connect,
  payouts, refunds, and webhooks remain incomplete: TBD.
- Media storage, private paid-media authorization, and browser upload limits: TBD.
- Search indexing and ranking contract: TBD.
- Moderation/admin information architecture and permissions: future, not initial
  scope.

Any decision that changes authentication, consent, payment, trust, or the
capability map should update this document and the relevant backend contract
before implementation.
