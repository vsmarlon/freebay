# FreeBay

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44-02569B?style=flat&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/React-19-61DAFB?style=flat&logo=react" alt="React">
  <img src="https://img.shields.io/badge/NestJS-11-E23C56?style=flat&logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/Stripe-635BFF?style=flat&logo=stripe" alt="Stripe">
</p>

**FreeBay é um marketplace C2C com uma camada social.** Anuncie o que não usa
mais, descubra produtos de pessoas reais, converse pelo chat e combine a entrega
em mãos — com pagamento protegido via Stripe. O app Flutter e o cliente web
compartilham a mesma API NestJS.

## Diagrama

> No preview do editor, os nós são clicáveis e abrem a pasta correspondente.

```mermaid
flowchart LR
    subgraph clientes["Clientes"]
        app["📱 App Flutter<br/>Android · iOS"]
        web["🖥️ Web React<br/>SSR · PT-BR / EN"]
    end

    pessoa(["👤 Pessoa"]) --> app & web
    app <-->|"HTTP · Socket.IO"| api["⚙️ API NestJS<br/>auth · social · chat<br/>marketplace · pedidos"]
    web <-->|"HTTP · SSR"| api
    api <--> db[("🐘 PostgreSQL<br/>Prisma")]
    api <--> redis[("⚡ Redis<br/>sessão · cache · filas")]
    api -. "webhooks" .-> stripe["💳 Stripe<br/>Checkout · Connect"]
    api -. "e-mail · push" .-> ext["✉️ Provedores externos"]

    click app href "frontend/" "App Flutter"
    click web href "web/" "Web React"
    click api href "nest-backend/src/modules/" "Módulos da API"
    click db href "nest-backend/prisma/schema.prisma" "Schema Prisma"
    click redis href "nest-backend/src/modules/" "Módulos da API"
    click stripe href "nest-backend/src/modules/payments/" "Pagamentos"
```

## Telas

<table>
  <tr>
    <td align="center"><img src="docs/test-runs/2026-10-24/qa-cart-app/explore-before.png" width="220" alt="Explorar no app"><br><sub><b>Explorar</b> · app</sub></td>
    <td align="center"><img src="docs/screenshots/marketplace-tailwind-catalog.png" width="380" alt="Catálogo web"><br><sub><b>Catálogo</b> · web</sub></td>
    <td align="center"><img src="docs/device-runs/2026-11-08/profile_stats_icons_smaller_numbers.png" width="220" alt="Perfil no app"><br><sub><b>Perfil</b> · app</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/test-runs/2026-10-25/a30-cart-stories/cart-checkout-summary.png" width="220" alt="Carrinho no app"><br><sub><b>Carrinho</b> · app</sub></td>
    <td align="center"><img src="docs/screenshots/auth-login-aurora-inputs.png" width="380" alt="Login web"><br><sub><b>Login</b> · web</sub></td>
    <td align="center"><img src="docs/test-runs/2026-10-25/a30-cart-stories/onboarding-step1.png" width="220" alt="Onboarding no app"><br><sub><b>Onboarding</b> · app</sub></td>
  </tr>
</table>

## Stack

Flutter · React Router · NestJS · Prisma/PostgreSQL · Redis · Socket.IO · Stripe

## Rodando localmente

```bash
# API — http://localhost:3000
cd nest-backend
npm ci
cp .env.example .env   # preencha os valores locais
npm run db:sync && npx cross-env NODE_ENV=development npm run db:seed
npm run start:dev
```

```bash
# Web — http://localhost:5173
cd web && npm ci && npm run dev
```

```bash
# App
cd frontend && flutter pub get && flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

## Documentação

- [`docs/FEATURE_TRUTH.md`](docs/FEATURE_TRUTH.md) — o que está implementado, limites e evidências.
- [`AGENTS.md`](AGENTS.md) — convenções, gates e regras de contribuição.
- [`web/README.md`](web/README.md) — cliente web, SSR, OAuth e variáveis de ambiente.
- [`docs/adr/`](docs/adr/) — decisões de arquitetura e escopo do produto.

## Licença

MIT License.
