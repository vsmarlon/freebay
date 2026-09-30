# FreeBay

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-11-E23C56?style=flat&logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/Flutter-3.6-02569B?style=flat&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Prisma-7.4-2D3748?style=flat&logo=prisma" alt="Prisma">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis" alt="Redis">
</p>

FreeBay é uma plataforma C2C que combina marketplace e interação social. O app Flutter consome uma API NestJS; o backend usa Prisma e PostgreSQL, com Redis e Socket.IO em fluxos que dependem desses serviços.

## Implementação e status

Consulte [`docs/FEATURE_TRUTH.md`](docs/FEATURE_TRUTH.md) para capacidades verificadas no código, jornadas incompletas, limites e evidências. Um endpoint ou teste isolado não comprova uma jornada completa nem prontidão de produção. O schema atual está em `nest-backend/prisma/schema.prisma`; este README não replica modelos, enums ou status que podem ficar desatualizados.

## Arquitetura

```text
frontend/                 Flutter app
nest-backend/src/modules/ NestJS feature modules
nest-backend/prisma/      Prisma schema and development seed
docs/                     Feature truth, operations, design and test evidence
```

Os módulos backend não têm todos a mesma divisão interna de repositórios. No Flutter, as features também variam em camadas; consulte a estrutura existente antes de contribuir. Orientações para agentes estão em [`AGENTS.md`](AGENTS.md), e os tokens de UI em [`frontend/DESIGN.md`](frontend/DESIGN.md).

## Pré-requisitos

- Node.js compatível com o projeto e npm.
- Flutter/Dart disponíveis no `PATH`.
- PostgreSQL e Redis nativos ou em serviço externo para jornadas backend que os usam.

## Começar

### Backend

```bash
cd nest-backend
npm install
# Configure nest-backend/.env com os valores necessários ao ambiente local.
npm run db:sync
npm run db:seed
npm run start:dev
```

O seed contém dados de desenvolvimento. Não use seed de desenvolvimento para inicializar produção. O schema-sync é o fluxo de desenvolvimento atual; alterações em banco compartilhado/produção exigem processo aprovado pelo owner.

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Testes e gates

Integração e E2E usam PostgreSQL/Redis explicitamente configurados e os scripts de teste guardados; consulte `nest-backend/.env.test` e [`AGENTS.md`](AGENTS.md). Os entry points são executáveis sem Docker quando esses serviços nativos/externos estão disponíveis.

```bash
# Backend (em nest-backend)
npm test
npm run test:integration
npm run test:e2e

# Flutter (em frontend)
flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
flutter test

# Repositório (raiz)
node scripts/ci-check.js
npm run test:ci-scripts
make test
```

`make test` é o alvo local agregado; E2E e builds têm comandos próprios descritos em `AGENTS.md`. O workflow de CI está em `.github/workflows/ci.yml`. Este repositório não configura deploy automático.

## Configuração

Use [`nest-backend/.env.example`](nest-backend/.env.example) como referência; não coloque credenciais em commits. O frontend recebe configuração por Flutter build defines conforme o recurso usado. Consulte os módulos e suas documentações próprias para provider-specific setup; este README não declara qual pagamento/provedor está aprovado como produto.

## Licença

MIT License.
