# ADR 0005: Template modular, API pública e transações ALS

- **Status:** accepted (owner, 2026-10-16)
- **Emenda (2026-10-16, owner — mesmo dia): R4 (UnitOfWork opaco/`TxContext` selado) e a lane de eventos (R6 hub→events, port `DomainEvents` + `InProcessEventBus` + `DomainNotificationHandlers`) foram REMOVIDAS por instrução do owner ("unitOfWork hack ... domain events não faz sentido, remove").** Use cases voltam a injetar `PrismaService` com `$transaction` inline, e os callers de notificações voltam a injetar `NotificationService` direto. Rebase da baseline de fronteiras 1:1 (242 → 246): as entradas B1/B2/B4 removidas por esses lanes foram recolocadas idênticas. R1–R3 e R5 (template, tiers, fronteira por `index.ts`) permanecem vigentes. O mapa awaited vs best-effort por caller permanece registro factual no relatório datado; correção por caller segue pendente lane a lane.
- **Emenda 2 (2026-10-16, owner — histórica, parcialmente supersedida pela emenda 3): eixo transacional ALS.** A decisão original adotou `@Transactional()` em providers por DI e o proxy Prisma habilitado, com `@InjectTransaction()`. O código e a política de transação então entregues estão registrados como história; esses detalhes de proxy/injeção não são mais o alvo vigente. Permanecem: não decorar use case que mistura banco e Stripe/push; efeitos externos fora do span; operação Prisma aninhada de review+images é atômica e reputação permanece separada.
- **Emenda 3 (2026-10-18, owner — entrevista): infraestrutura primeiro e menos código redundante.** Manter `@Transactional()`/ALS, usar **`TransactionHost<TransactionalAdapterPrisma>.tx`**, desligar proxy e manter uma única classe `PrismaService` em `SharedModule`. Implementado na árvore dirty: sete registros locais removidos e dois consumers usam `txHost.tx`, sem mudança de query/argumentos/opções/money. AppModule lifecycle, rollback P2025/readback e isolamento concorrente foram focalmente verificados; full E2E teve uma falha de configuração CPF. Comandos, outros gates, limites e status consolidado em [relatório 2026-10-18](../test-runs/2026-10-18/backend-infra/REPORT.md). Hook 1/1 não mede conexões/pools ativos em produção. Não autoriza próxima fatia financeira, migrations ou mudança de regra.
- **Data:** 2026-10-16
- **Receitas de implementação:** [guia do backend](../BACKEND_IMPLEMENTATION_GUIDE.md). Exemplos não substituem status, autorização ou evidência registrados no plano.
- **Supersedes parcialmente:** D1 do [hardening plan](../HARDENING_PLAN.md) e a exceção genérica de CRUD de [ADR 0004](0004-selective-modular-backend-architecture.md). ADR 0004 permanece a base (monólito modular); este ADR define o **template por módulo** e as regras de composição.
- **Origem:** owner instruiu "melhore a organização e melhore a arquitetura, seja brutalmente honesto e defina uma arquitetura definida" a partir de análise registrada no [plano](../BACKEND_ARCHITECTURE_PLAN.md); executada com as emendas de raciocínio da execução (abaixo).

## Contexto

O backend tem convenção de nomes de camada sem regra: a maioria dos use cases injeta repositório concreto por path, `PrismaService` aparece fora de persistência, controllers importam repositórios, `$transaction` fora de infraestrutura (incluindo código de dinheiro), `@prisma/client` vaza em use cases/controllers/domain, notificação é hub com efeito colateral fire-and-forget, `types/` é gaveta, e há três caminhos de erro. A própria análise externa confirma o diagnóstico já registrado como A01–A12 no plano. Rede de decisão: ADR 0004 decidiu *para onde* ir (fronteiras seletivas); faltava definir *o template* e *como o código de dinheiro sai da infraestrutura espalhada* — este ADR fecha isso.

## Decisão

### 1. Template por módulo (tiers declarados)

```text
nest-backend/src/modules/<feature>/
  <feature>.module.ts
  index.ts               # API pública: ÚNICO arquivo importável por outro módulo
  domain/                # regra pura; proibido importar @nestjs/* e @prisma/client (nem import type)
  application/           # commands (use cases) e queries; I/O tipos simples próprios
  infrastructure/        # portas implementadas; Prisma, SQL, mappers
  presentation/          # controllers + DTOs (request/response)
```

| Tier | Módulos | Template |
|---|---|---|
| A — estado/dinheiro | `orders`, `payments`, `cart`, `wallet`, `disputes` (+ auth conforme fatia de ownership) | entity com comportamento + port `*Repository` (domain) + mapper; máquina de estados na entity |
| B — CRUD/config | reports, favorites, bug-reports, category, stories, notifications, reviews | sem entity; use case + saída plain; port apenas quando cruza fronteira de módulo |
| C — leitura pesada | feed/timeline, chat (leitura), busca, listagens | CQRS-lite: read repository com select Prisma devolvendo DTO direto; sem mapper de entidade |

Tier não é influência cosmética: Tier A exige entity; Tier C proíbe. Mapeamento módulo-por-tier fica no plano e se ajusta por evidência durante a migração.

### 2. Regras vigentes (R1–R9, incorporando as emendas)

- **R1 direção:** `presentation → application → domain`; `infrastructure` implementa contratos e é composta pelo módulo Nest. Domain não importa nada de framework/ORM.
- **R2 ports onde pagam aluguel:** port por fronteira real (`PaymentGateway`, `PushSender`, `EmailSender`, `SmsSender`, repositório de agregado Tier A, fronteira de módulo). Nunca "caso troque de ORM".
- **R3 tiers:** tabela acima, declarada por módulo no plano.
- **R4 transação:** spans curtos `@Transactional()` em providers de persistência chamados via DI; client por `TransactionHost<TransactionalAdapterPrisma>.tx`, sem proxy e sem `tx` nos contratos de aplicação. O use case orquestra fora do span; Stripe, FCM, e-mail e disco ficam fora da transação. Statements atômicos isolados não ganham wrapper. Erro que exige rollback deve escapar do método decorado; retornar `Left` resolve a Promise e pode commitar. O código legado conserva sua transação até fatia aprovada. UnitOfWork/TxContext estão revogados.
- **R5 fronteira entre módulos:** só via `index.ts` — contrato público estreito ou ação de aplicação exportada pelo dono. O módulo Nest importa o módulo dono, não re-registra sua implementação. Nunca `data/`/`infrastructure/` do outro módulo; o alvo não exporta repositório concreto. O barrel atual de users ainda exporta `UserDatabaseRepository`: exceção de transição explícita, não conclusão de R5.
- **R6 efeitos colaterais:** chamadas diretas, com política explícita por caller (aguardada ou best-effort com rejeição observada). Preservar a política existente durante refactor; transformar falha bloqueante em best-effort é mudança de comportamento separada. Barramento de eventos/DomainEvents não fazem parte do alvo. Outbox/durabilidade exigem desenho e autorização próprios; P8 continua limitado ao modelo dos webhooks, não aprova outbox automaticamente.
- **R7 controller:** sem repository, sem Prisma, sem política de negócio — `PlatformFeePolicy` e afins injetados no use case. Caminho de erro permanece `EitherInterceptor` + `unwrap` (D3); **o interceptor não é deletado**. Wrappers `*.service.ts` que só desembrulham são apoptóticos (P2).
- **R8 `types/` morre:** entity/VO → `domain/`, I/O → `application/`, response → `presentation/`. Manifesto por lote, não big-bang.
- **R9 enforcement:** estender o gate existente `scripts/ci-check.js --boundaries` (sem dependência nova — rejeito trocar por dependency-cruiser): **B4** use cases/controllers/services/tasks sem `import '@prisma/client'` de qualquer forma; **B5** `domain/**` sem `@nestjs/*` e sem `@prisma/client`. Baseline só-encolhe; o alvo é zero violações após a migração, virando regra de erro.

### 3. Migração (sem big-bang)

1. Saneamento da infraestrutura: Prisma com um dono, lifecycle e evidência de rollback/isolamento do ALS. Escopo de execução registrado no plano.
2. P2/erro e P3/DA-04: remover wrappers comprovadamente vazios e concluir ownership/API pública de users, sem ciclos.
3. Materializar o template por fatia; reviews é o piloto não financeiro. Não juntar reputação à criação como simples refactor.
4. Demais spans na ordem P5 do hardening; **cada fatia financeira com aprovação explícita do owner**. Orders/cancel não é autorizado por P5 implicitamente.
5. Corrigir políticas de notificação por caller, quando aprovadas, sem introduzir barramento.
6. Users/auth e leituras social/chat conforme ownership e medição; aproximar o ratchet de zero sem maquiar violações com barrels ou renames.

## Consequências e limites

- Tier A separa regra de estado e detalhes do provedor; contratos, entities e mappers precisam representar essa separação, não repetir o schema. Não há medição de custo de código nem prova de troca de PSP sem impacto.
- A ordem de queries/rollback do código atual é preservada nas migrações; este ADR **não corrige atomicidade entre banco e provedor**. O claim movido para dentro do span deve ser validado por rollback e concorrência, não descrito como preservação byte-a-byte.
- Migrations (P10), provider-policy (P1), PERF-00/DA-03 (SLO) e dependências (DA-06) continuam owner-gates do [plano](../BACKEND_ARCHITECTURE_PLAN.md). Nenhuma fatia de dinheiro migra sem go explícito do owner.
- Nenhuma contagem da análise externa foi copiada semânticamente como fato sem reconciliação com o baseline do gate.

## Referências

- [ADR 0004](0004-selective-modular-backend-architecture.md) — base e política seletiva
- [Plano de arquitetura do backend](../BACKEND_ARCHITECTURE_PLAN.md) — o planejamento e a fila de fases
- [Plano de hardening](../HARDENING_PLAN.md) — fases e lock de dinheiro
- Análise externa do owner (2026-10-16) — diagnóstico e proposta original, reconciliada aqui
