# Plano de arquitetura e performance do backend

**Status atualizado em 2026-10-18:** alvo modular seletivo conforme ADR 0005. O lote Prisma/ALS foi implementado e focalmente verificado. O full E2E inicialmente falhou por configuração de teste; follow-up passou 50/50 com chaves CPF efêmeras no setup. Evidência, gates e limitações consolidados no [relatório datado](test-runs/2026-10-18/backend-infra/REPORT.md). Não implica contagem de conexões ativas nem runtime/produção. UnitOfWork/TxContext/events estão revogados; demais transações continuam por fatias aprovadas.
**Base inspecionada:** árvore de trabalho em `feat/production-hardening`, revisão `235b5ce8d270a7e03e8988985e369616c3ce9721`, com alterações locais preexistentes. A auditoria desta sessão comparou hashes de 1.664 arquivos; os fingerprints finais dos 14 arquivos de produção/testes alterados estão no relatório. O snapshot não é um commit da árvore dirty; não houve fetch nem confirmação de atualização no GitHub.
**Escopo:** direção arquitetural e performance mensurável. O lote infra autorizado foi implementado e passou nos gates de backend/root registrados no relatório; full E2E follow-up passou 8 suites/50 tests com chaves de teste. Não autoriza moves de ownership, busca/índices/migrations, outras fatias financeiras ou mudanças de regra. Ver [guia](BACKEND_IMPLEMENTATION_GUIDE.md) para receitas não autorizativas.

## Autoridade e leitura do status

### Decisão do owner — infraestrutura primeiro (2026-10-18)

- Na entrevista de arquitetura, o owner escolheu **infraestrutura primeiro**: um dono para `PrismaService`, saneamento do lifecycle e prova de rollback/isolamento do ALS antes de reorganizar módulos ou otimizar a busca. Regras financeiras permanecem inalteradas; não há autorização para migrations, índices, provider-policy ou retorno de UnitOfWork/eventos.
- Baseline era oito class registrations (SharedModule + sete locais); atual é uma classe registrada somente em SharedModule. AppModule lifecycle focal passou; registros/hooks não medem pool/conexões ativas. Veja o relatório para testes e limites.
- Probe isolado com Nest/CLS instalados, sem banco: registro global + registro local produziram duas instâncias distintas. Com `enableTransactionProxy: true`, o provider global recebeu dois hooks de init/destroy; com `false`, um. O proxy expõe os hooks do client fallback; o alias `useExisting`, sozinho, não repetiu o hook. A explicação de teardown do handoff deve ser lida com essa correção; o antigo guard de teardown não eliminava pools duplicados.
- **Rollback/ALS:** focused integration verificou falha P2025 depois da primeira escrita, snapshots inalterados e isolamento concorrente. **Acesso implementado:** proxy desligado, dois consumers em `TransactionHost.tx`, restante da lógica financeira preservado. Lifecycle E2E e mutation control passaram conforme [relatório](test-runs/2026-10-18/backend-infra/REPORT.md).
- **Lote autorizado:** single owner de Prisma, lifecycle/release, dois consumers transacionais existentes, rollback real e isolamento ALS. Não ampliar para reorganização de módulos, índices, migrations ou novas regras financeiras.

### Referências e limites

- [`../AGENTS.md`](../AGENTS.md) define regras compartilhadas; [`HARDENING_PLAN.md`](HARDENING_PLAN.md) define fases, segurança e cadência; [ADR 0004](adr/0004-selective-modular-backend-architecture.md) e [ADR 0005](adr/0005-module-template-public-api-uow-events.md) são as autoridades de arquitetura. Este plano é fonte para iterações de arquitetura/performance e decisões pendentes aqui listadas; exemplos estão no [guia](BACKEND_IMPLEMENTATION_GUIDE.md).
- [`FEATURE_TRUTH.md`](FEATURE_TRUTH.md) continua sendo a referência para capacidades verificadas. Este plano não atualiza status de produto.
- O relatório datado registra o E2E focado da busca: 4/4 passaram no `freebay_test_db` em 2026-10-16. A suite completa teve tentativa histórica 49/50; follow-up em 2026-10-18 passou 50/50 com chaves CPF efêmeras no setup de teste. Nenhuma medição de desempenho foi feita.
- A árvore local já continha alterações antes desta edição. Não limpar, descartar, restaurar ou sobrescrever essas alterações como parte de uma futura execução.
- O gate existente não é detector geral de ciclos/dependências. As duas fatias de disputes usam ALS; outras transações não foram migradas. Events/DomainEvents foram revogados; P8 continua restrito a webhook design; P10 migrations owner-only.
- `CONTEXT.md` na raiz registra conceitos de experiência social e identidade pública; arquitetura e contratos de busca ficam neste plano, não no glossário.
- A decisão DA-01 está registrada em [ADR 0004](adr/0004-selective-modular-backend-architecture.md); demais decisões e gates continuam separados.

## Política arquitetural aceita

DA-01 aprovou o monólito modular com fronteiras seletivas. O alvo, limites e distinções entre decisão e implementação estão em [ADR 0004](adr/0004-selective-modular-backend-architecture.md); não reabrir a comparação A/B nem inferir autorização de execução.

Use case/application recebe e retorna tipos simples próprios, não DTO de framework, classe ORM ou record Prisma. DTOs de entrada HTTP continuam na apresentação, com validação e documentação locais. Domínio puro não importa NestJS ou Prisma, nem mesmo como `import type`.

### Direção desejada de dependências

```text
presentation (controller, DTO) ──> application ──> domain (quando houver regra)
infrastructure (Prisma, provider, adapter) ──> contratos públicos / domain
feature.module.ts ──> compõe aplicação, contratos e adapters concretos
```

| Regra | Aplicação prática proposta |
|---|---|
| Dependências de compilação | `presentation -> application -> domain/contracts`; infraestrutura implementa/usa contratos sem importar controllers/use cases; o módulo Nest compõe os providers. |
| Chamadas em runtime | Application chama dependências injetadas; controller valida/encaminha e preserva o tratamento de erro local e o contrato HTTP existente. |
| Integração entre módulos | Consumir contrato público nomeado/facade/porta do módulo dono. Não importar `data`, `usecases` ou `services` internos de outro módulo. |
| Exceção de CRUD | Um use case simples pode depender de repositório concreto próprio. Limitar o output à projeção necessária; não expor ORM para application/controller. É exceção explícita, não inversão uniforme. |
| Persistência | Prisma, SQL e transações ficam na infraestrutura/persistência. Chamadas a serviços externos não são responsabilidade de repositórios de banco. |
| Controllers | Não chamam repositórios diretamente. Preservam `AppError`, status e mapeamento existentes; não introduzem resposta 400 genérica. |
| Provider binding | Um único binding por token; preservar tokens e contratos atuais, sem provider duplicado ou barrel universal. |
| Leituras cross-module | Definir ownership e fronteira antes de alterar query/join. Não trocar JOIN/batch por N chamadas a facades. Aplicar privacidade antes de paginação e contagem. |

Árvore-alvo mínima, a materializar somente onde necessário:

```text
nest-backend/src/modules/<feature>/
  <feature>.module.ts
  index.ts                # superfície pública estreita entre módulos
  presentation/           # controllers e DTOs
  application/            # use cases/queries; contratos conforme perfil aprovado
  domain/                  # políticas/VOs quando houver regra real
  infrastructure/          # Prisma, providers e adapters concretos
```

Não criar diretórios vazios nem scaffolding uniforme. `domain/` é opcional por regra real; contratos/portas seguem o perfil A aprovado, somente em fronteiras justificadas. A estrutura existente pode divergir até migrações planejadas, aprovadas por lote e verificadas.

## Evidências de código e oportunidades a verificar

Tabela histórica da inspeção pré-lote; caminhos Auth em A01/A02 descrevem a localização anterior à extração. A localização ativa de search é `nest-backend/src/modules/users/data/repositories/user-database.repository.ts`; a composição do provider ainda está em `AuthUseCasesModule`. Linhas deslocam. Estes fatos estáticos não provam latência, plano ou comportamento de banco em produção.

| ID | Evidência observada | Consequência / limite |
|---|---|---|
| A01 | `nest-backend/src/modules/auth/usecases/login.usecase.ts:18-20` autentica por email (`findByEmail`). `nest-backend/src/modules/auth/data/repositories/user-database.repository.ts:64-69` faz lookup exato de username normalizado; `nest-backend/prisma/schema.prisma:161` declara username único. `findByUsername` é chamado por cadastro, disponibilidade e atualização/complemento de perfil. | O lookup por username observado atende cadastro/disponibilidade/perfil, não login. Não alterar como busca textual. Unicidade case-sensitive e writers precisam ser auditados antes de qualquer índice normalizado/DDL. |
| A02 | Na base pré-lote, `searchUsers` estava em `auth/data/repositories/user-database.repository.ts:163-213`, com `ILIKE`, Prisma SQL e exclusão de bloqueios em ambas direções. | Hoje o arquivo está em `users/data/repositories`; o provider ainda é registrado em Auth. `%`, `_` e `\\` são literais. Auditoria estática incremental não encontrou SQLi; não é certificação de runtime. |
| A03 | Na base pré-lote, a ordenação incluía username, followers e id; `followingCount` era projeção, e a query usava `limit+1`. | Ranking/projeção permanecem preservados. Sem plano/benchmark, não inferir trabalho ou latência da query. |
| A04 | Na base pré-lote, use case/controller não consumiam corretamente o item extra de paginação. | Corrigido no primeiro lote. O relatório datado registra E2E focado 4/4; suite completa 49/50 com uma falha ambiental fora do lote. |
| A05 | Na base pré-lote, DTO aceitava `q` opcional/máximo 100, `limit` 1–50 e `offset >= 0`; `q` podia ser vazio e não havia teto de offset. | Defaults de vazio e termo de 1 caractere foram mantidos; o trim preexistente foi preservado. Sem novo mínimo de 2 caracteres. |
| A06 | Flutter: `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_discovery.dart:6-32`, `frontend/lib/features/social/presentation/providers/user_search_provider.dart`, `frontend/lib/features/chat/presentation/pages/new_chat_page.dart`. Web: `web/app/features/social/feed.tsx`, `web/app/features/chat/repository.ts`, `web/app/features/chat/inbox.tsx`, `web/app/features/account/people.tsx`. | Mudança de shape/semântica exige verificar consumidores Flutter e Web. `social_repository.dart` é barrel/part, não implementação desta busca. |
| A07 | `nest-backend/src/modules/orders/usecases/cancel-order.usecase.ts:8-20,58-149` coordena pagamentos, Stripe e notificações; há lógica de cancelamento/reconciliação/refund no mesmo fluxo. | Candidato de alto risco para fronteiras e transações. Esboço de “salvar refund” não é prova de equivalência comportamental. Preservar identidade do provider atual, claims, ordem e recuperação. |
| A08 | `nest-backend/src/modules/orders/orders.controller.ts:20,40,77,187`; `nest-backend/src/modules/wallet/wallet.controller.ts:5,14,32` mostram controllers acoplados a repositórios; `nest-backend/src/modules/wallet/domain/repositories/wallet.repository.ts:1-6` e `nest-backend/src/modules/auth/domain/repositories/magic-link.repository.ts:1-10` expõem contratos com Prisma. | São pontos de investigação, não autorização para refatorar. O vazamento de tipo transacional deve ser decidido antes de declarar a fronteira financeira compatível. |
| A09 | A inspeção inicial não encontrou `unwrap`; P2 depois adicionou `nest-backend/src/shared/http/unwrap.ts`, hoje usado por controllers Auth e demais controllers convertidos. | Reutilize o helper atual junto ao `EitherInterceptor`; preserve `AppError`, envelope/status e exception filter. Não recrie unwrap local nem alegue comportamento de 400 universal. |
| A10 | `nest-backend/src/modules/reviews/usecases/create-review/create-review.usecase.ts:28-149`, `nest-backend/src/modules/reviews/data/repositories/review-database.repository.ts:10-93`, `nest-backend/src/modules/reviews/reviews.module.ts:10-21`, `nest-backend/src/modules/reviews/reviews.service.ts:14-22,62-84`. Review+images são nested create; reputation update segue fora. | Estado atual preserva essa separação; não alegar atomicidade entre criação e reputação nem uni-las em refactor futuro sem decisão/teste. |
| A11 | `nest-backend/src/modules/notifications/services/notification.service.ts:30-65` persiste e chama FCM; persistência relança erro em 39-51 e chamada FCM é aguardada. Cancelamento chama notificação em `nest-backend/src/modules/orders/usecases/cancel-order.usecase.ts:154-160`. | Erro de execução não observado aqui. Classificar todos os callers awaited/best-effort e mapear tratamento antes de alterar captura global. Evento em memória não é durable/outbox. |
| A12 | `nest-backend/src/modules/products/data/repositories/product-database.repository.ts:39-66` cobre busca de catálogo; `nest-backend/src/modules/users/data/repositories/safety-list-database.repository.ts:13-41` trata elegibilidade; `nest-backend/src/modules/social/data/repositories/post-query-helpers.ts:171-236` usa duas queries limitadas para timeline. | Comparar com dados sintéticos representativos em banco isolado autorizado. A inspeção não demonstra N+1 nem regressão de latência. |

### Consulta de busca: contrato observado e hipóteses (sem medição)

O código ativo em `users/data/repositories/user-database.repository.ts` usa parâmetros bound e fragmentos `Prisma.sql` estáticos: username por igualdade/prefixo (`ILIKE` com curingas de entrada escapados), **ou** cada termo whitespace-separated como prefixo de alguma palavra de `displayName` via `EXISTS`/`regexp_split_to_table`; termos diferentes combinam por AND. Bloqueios nas duas direções são excluídos antes de paginação. Ordem: username exato, username prefix, displayName; depois `followersCount DESC`, `id ASC`. `followingCount` é projeção, não rank. Busca `limit + 1` para `hasMore`; o item extra não é retornado. `%`, `_`, `\\` são literais; não há accent folding. Isto descreve query/contrato, não prova custo do plano ou runtime.

Schema já declara `Follow @@unique([followerId, followingId])` e índice em `followingId`; `Block @@unique([blockerId, blockedId])` e índices nas duas direções. Não propor duplicatas sem comparar coluna, ordem, predicado e plano efetivo.

| Próxima hipótese | Limite que não pode ser omitido | Gate antes de adotar |
|---|---|---|
| Índice para username prefix | Username lookup `@unique` é igualdade normalizada de cadastro/disponibilidade/perfil, não login (login é email) nem busca textual. Índice B-tree comum não se presume capaz de otimizar `ILIKE`; índice de expressão/pattern ops depende da expressão, collation e writers. | Medir query OR completa; auditar normalização/case e todos os writers; proposta separada e autorização de DDL/migration. |
| Acelerar `displayName` palavra-prefixo | Índice trigram pode ser fraco em termos curtos e não garante que o ramo OR deixe de dominar. Um índice trigram simples sobre displayName não indexa diretamente o `regexp_split_to_table` por palavra. Full-text `simple` tokenizer não é equivalente à semântica whitespace-prefixo. | Comparar prefilter trigram com residual exato, ou tabela/tokenização materializada; provar mesmos resultados/ordem/privacidade em toda query. Medir custo de escrita e armazenamento. |
| Adiar `followingCount` | Pode ser enriquecido depois da página, mas só se a consistência entre queries/snapshot for aceitável e o custo cair. | Medir com fixture representativa e verificar contrato de snapshot/projeção. |
| Limite de offset/cursor ou termo mínimo | Alteraria comportamento/API atual (vazio, 1 caractere e offsets profundos são aceitos). Não é otimização invisível. | Decisão de produto/owner e verificação de clientes Flutter/Web. |

Não há `EXPLAIN`, benchmark em 1k/100k ou SLO medido neste plano. Volume, distribuição, concorrência e SLO (DA-03) são desconhecidos; nenhuma hipótese abaixo é implementação aprovada.

### Hipóteses de performance para pesquisa, não mudanças aprovadas

| ID | Hipótese/alternativa | Critério de decisão |
|---|---|---|
| PERF-01 | Implementado: item extra usado somente para `hasMore`; lista limitada a `limit`. | E2E de busca histórico 4/4; full E2E follow-up 50/50 (relatório datado). Não é produção nem benchmark. |
| PERF-02 | Lookup exato por username permanece em cadastro/disponibilidade/perfil; login usa email. | Sem alteração; índice declarado não prova uso runtime. Não tratar como busca textual nem sugerir login por username. |
| PERF-03 | Implementado; contrato da busca passou 4/4 no E2E recente. Username-prefix; termos whitespace por AND e prefixo de qualquer palavra whitespace em displayName; ILIKE, sem accent folding, curingas literais. | Sem medição de desempenho. Vazio/1 caractere e trim preservados; sem tokenizer/index/migration novo. Source em `users/data/repositories`; provider continua composto em Auth. |
| PERF-04 | Medir a consulta e avaliar estratégia compatível com username-prefix e displayName-word-prefix. | Índice deve corresponder à expressão real; username prefixo não determina a estratégia para prefixo de qualquer palavra em displayName. Medir a consulta OR completa antes de propor índice/SQL; `pg_trgm` é alternativa técnica, não decisão. Nenhum `EXPLAIN` ou índice foi verificado/aprovado. |
| PERF-05 | `followersCount` participa da ordenação; `followingCount` não participa e pode ser enriquecimento tardio. | Medir query completa. Enriquecer followingCount depois da página é candidato; followersCount não pode ser movido após limite sem alterar ranking. |
| PERF-06 | Comparar materialização de follows em `nest-backend/src/modules/users/data/repositories/user-database.repository.ts:218-257` com JOIN/EXISTS ou outra estratégia. | Usar plano e dados sintéticos representativos em banco isolado autorizado; manter bloqueios/privacidade e saída. |
| PERF-07 | Revisar catálogo, safety-list e timeline como alvos secundários. | Só priorizar após evidência; timeline já tem duas queries limitadas no trecho observado. |

### DA-02.1 — username por prefixo (aprovada em 2026-10-16)

O owner escolheu A: o critério de username aceita igualdade ou início do identificador, não correspondência no meio. Para o termo literal `ana`, `ana` e `anacosta` correspondem; `mariana` não corresponde **pelo username**. Uma pessoa ainda poderá aparecer se seu displayName corresponder ao contrato de prefixo de palavra registrado em DA-02.2.

A decisão não altera lookup exato de cadastro/disponibilidade/perfil nem decide curingas, consulta vazia, mínimos, paginação, ranking ou índices. A semântica foi implementada no primeiro lote; consulte o status e a evidência histórica de PERF-03. O prefixo escolhido não precisa ser reaprovado.

### DA-02.2 — displayName por prefixo de palavra (aprovada em 2026-10-16)

O owner confirmou “sim” à proposta de correspondência por prefixo de palavra: o termo literal `sil` encontra `Ana Silva`; `ilv` não encontra **pelo displayName**. Cada palavra pode corresponder pelo início, sem substring arbitrária no meio; username ainda pode corresponder independentemente conforme DA-02.1.

Isto aprovou a semântica de correspondência, não tokenizer, índice ou ganho de desempenho. DA-02.3 e o primeiro lote autorizado definiram curingas literais e combinação de termos; detalhes de delimitadores, acentos/normalização, ranking e índices permanecem sujeitos aos limites registrados acima. Implementação do lote não prova desempenho/runtime.

### DA-02.3 — curingas e proteção SQL (aprovada em 2026-10-16)

O owner confirmou: `%`, `_` e `\` são dados literais, não curingas; todos os valores continuam parametrizados por `Prisma.sql`/ORM. Identificadores e fragmentos SQL dinâmicos devem ser estáticos ou allowlisted, nunca derivados de entrada não confiável. Escapar curingas `LIKE` não substitui parametrização nem proteção contra SQL injection. A auditoria estática não encontrou vulnerabilidade SQLi no backend atual; isto não é certificação de runtime. Esta decisão não afirma implementação concluída.

### Primeiro lote de busca e fronteiras — implementação e evidência histórica

O owner autorizou delegação e escolhas de implementação reversíveis para este lote, sem gate adicional por editor:

| Fatia | Escopo autorizado | Limites |
|---|---|---|
| ARCH-02 / P4 | Implementado em `scripts/ci-check.js`; snapshot de 2026-10-18: 242 (F1 12, F2 64, **B1 61**, B2 18, B3 5, **B4 80**, B5 2). | B1: imports/reexports diretos que apontam para paths `data`/`usecases`/`services` configurados; não segue transitivamente exports de barrel. B4: roles/names de arquivos configurados (inclui usecase/controller, não qualquer `application`/query path). B5: imports diretos proibidos dentro de `domain/**`, não dependência transitiva. Não detecta ciclos gerais. Counts são snapshot, não promessa permanente; não zerar dívida por rename/barrel. |
| PERF-01 / PERF-03 | Busca/paginação implementadas; E2E focado 4/4 em `freebay_test_db` no relatório de 2026-10-16. | A execução histórica foi 49/50; follow-up full E2E 50/50 (relatório datado). Sem plano/benchmark/SLO medidos. |

O lote infra foi focalmente verificado; o follow-up do full E2E passou 50/50 com configuração efêmera de teste. Não é produção nem performance. Resultados e limites estão no [relatório](test-runs/2026-10-18/backend-infra/REPORT.md). Outras fatias financeiras não estão autorizadas.

## Sequência proposta e gates

O perfil arquitetural A e DA-05 já foram decididos; cada lote adicional continua exigindo autorização. Fase planejada não significa trabalho em andamento ou concluído.

| Fase | Escopo/fonte principal | Dependência e gate de saída |
|---|---|---|
| ARCH-01 — decisão e mapa | Este plano; ADR 0004; `AGENTS.md`; `docs/HARDENING_PLAN.md`; contratos de módulos citados. | DA-01 decidida como A e registrada em ADR 0004. Execução, limites por lote e demais decisões continuam pendentes; não altera D3/D5/P5. |
| ARCH-02 — ratchet de fronteiras | `scripts/ci-check.js` e baseline existente. | Snapshot 2026-10-18: 242 entradas; regras limitadas, não detector geral de ciclos, transitive exports ou todos os layers. Veja a seção de status P4 e estenda regra/testes antes de depender de cobertura maior. |
| PERF-00 — baseline mensurável | Endpoint `users` e query em `nest-backend/src/modules/users/data/repositories/user-database.repository.ts`; DB isolado previamente provisionado pelo owner. | Definir volume, concorrência e SLO com owner antes. Read-only; sem alteração de fonte/query durante medições-base. Não usar produção/runtime compartilhado nem preparar seed/schema automaticamente. |
| PERF-01 — paginação | Use case/controller e testes de boundary. | Implementado; E2E focado histórico 4/4 e follow-up full E2E 50/50 (relatório datado). Não é prova de performance. |
| PERF-02 — username | `nest-backend/src/modules/users/data/repositories/user-database.repository.ts`, schema somente leitura. | Sem tarefa presumida; reabrir por perfil medido, sem DDL/alteração sem audit de writers, colisões e aprovação. |
| PERF-03 — política de busca | Query em Users; provider ainda composto em Auth; clientes Flutter/Web em A06. | Implementado, E2E focado histórico 4/4 e follow-up full E2E 50/50 (relatório datado). Nenhuma medição de performance; não confundir file placement com provider ownership. |
| PERF-04/05 — query/ranking | Repository de users e eventual proposta de índice. | Depende de PERF-00 e PERF-03; plano real e comparação de custo de escrita. DDL exige autorização separada; migrations continuam owner-only. |
| PERF-06 — sugestões | `nest-backend/src/modules/users/data/repositories/user-database.repository.ts:218-257`. | Depois da baseline; mesma filtragem e resultado, medir alternativa antes de adotá-la. |
| PERF-07 — alvos secundários | Catálogo, safety-list e timeline citados em A12. | Baixa prioridade; executar somente com evidência de gargalo e escopo aprovado. |
| ARCH-03 — piloto reviews | Arquivos A10 e runner/`SharedModule` após DA-05. | **Revertido e re-decidido (2026-10-16, owner):** o piloto UnitOfWork/TxContext foi revertido na emenda 1; na emenda 2 (ALS) o use case de review ficou SEM `PrismaService` — `CreateReviewUseCase` chama `ReviewDatabaseRepository.create(data)` direto (wrapper `$transaction` de statement único removido; create aninhado review+images do Prisma é atômico). `findOrderSnapshot` no repositório permanece (leitura). Reputação segue FORA da transação como antes; integração em `freebay_test_db`. |
| ARCH-04 — ownership de usuário | `nest-backend/src/modules/auth/usecases/auth-usecases.module.ts`, `nest-backend/src/modules/users/data/repositories/user-database.repository.ts`, callers Auth/Users e `nest-backend/src/modules/users/users.module.ts`; ligado a P3/DA-04. | **Parcial, 2026-10-16:** repository/spec movidos a Users; busca ativa está em `users/data/repositories`; port `UserLookupRepository` sem Prisma; users barrel ainda exporta repository concreto. Provider ainda é registrado em `AuthUseCasesModule`, Users importa `AuthModule`, Auth use cases ainda consomem concreto. P3 target Users aprovado, ownership/provider não concluído. DA-04 decide API/composição para mover sem ciclo; não usar `forwardRef`. |
| ARCH-05 — contrato de notificações | `nest-backend/src/modules/notifications/services/notification.service.ts` e todos os callers. | **Mapa mantido; eventos revertidos (2026-10-16, owner).** O mapa awaited vs best-effort (relatório datado) continua o registro do estado. Piloto R6 (port `DomainEvents` + `InProcessEventBus` + eventos por produtor + `DomainNotificationHandlers`) foi **definitivamente revertido** porque o owner determinou "remove" — callers voltaram a injetar `NotificationService` direto (follow-user/disputes awaitam sem catch como antes; chat/payments best-effort como antes). Rebase da baseline 1:1 recolocou as B1 exatamente como estavam. Correções por caller continuam pendentes lane a lane. |
| ARCH-06 — fluxos financeiros | Revisão individual de cada fatia, fora do saneamento infra atual. | Aprovação explícita por fatia; preservar queries, rollback, cents, auth, idempotência, claims e recuperação. `Left` retornado não garante rollback. Orders/cancel e controllers orders/wallet exigem autorização separada. |
| ARCH-07 — leituras entre módulos | Casos concretos descobertos no trabalho autorizado. | Definir módulo dono e contrato por caso; manter privacidade e eficiência de joins/batches; não fazer split amplo antecipado. |
| ARCH-08 — sincronização documental | `AGENTS.md`, `nest-backend/CLAUDE.md`, skills backend/system-design e `docs/HARDENING_PLAN.md`. | Alinhamento documental não autoriza implementação; FEATURE_TRUTH só muda com nova evidência. `.agents/skills` é canônico; antes de tratar `.claude/skills` como link em novo checkout, verificar identidade e git mode (120000), além de `core.symlinks` no Windows. Editar apenas o caminho canônico. Preservar os três trackers listados em P1. |

### Paralelismo e integração

| Frente (executor proposto) | Arquivos permitidos | Predecessor/limite |
|---|---|---|
| CI | Scripts de CI e baseline. | Não edita módulos/DB. |
| Paginação | Use case/controller/output e regressões HTTP/DB. | Query e DTO só se necessidade demonstrada. |
| Busca | Repository e medição PERF-04/05/06. | Baseline PERF-00 congelada primeiro; não sobrepor alterações de fonte/query. |
| Infra ALS/Prisma | Shared/runner, dois consumers existentes e testes de integração necessários. | Lote atual autorizado; prova de lifecycle, rollback e isolamento antes de declarar concluído. Não inclui outros módulos/fluxos. |
| Integrador único | Shared/runner, schema/manifests, módulos globais/HTTP e documentos de autoridade. | Exclusivo para arquivos compartilhados; nenhum executor paralelo toca esses arquivos. |

O lote autorizado de CI/boundaries e busca/paginação foi executado em paralelo. Lotes futuros exigem sua própria autorização e arquivos sem overlap. Suítes DB usam fixture previamente provisionada pelo owner, uma execução por vez; sem reset, seed ou mudança de schema pelo executor. Preservar alterações locais preexistentes.

## Protocolo de medição proposto

O protocolo abaixo só se aplica após autorização de ambiente e fixtures. Não foi executado neste rascunho.

1. Usar banco isolado previamente provisionado pelo owner, com dados sintéticos explícitos e escalas acordadas; incluir distribuição uniforme/skew, follows/bloqueios e nomes comuns. Sem cópia de PII de produção; executor não cria seed/schema nem roda migrations.
2. Definir antes do teste concorrência, metas/SLO e volume esperado com owner. Sem esses valores, coleta exploratória não vira critério de aprovação.
3. Fixar revisão, versão/configuração do banco, collation/extensões, hardware, fixture, aquecimento, pool e duração. Esses dados são atualmente desconhecidos para o runtime que será medido.
4. Cobrir termos sem resultado, igualdade/prefixo/substrings, termos curtos, vazio/wildcards/case e offsets rasos/profundos, apenas sob política aprovada. Comparar mesma saída e mesma ordenação.
5. Coletar separadamente planos SQL read-only autorizados (`EXPLAIN`, e `EXPLAIN ANALYZE` apenas se a execução for aceita no ambiente), buffers/linhas e latência HTTP p50/p95/p99, throughput, erros, pool e quantidade de queries. Latência HTTP não se deduz subtraindo o tempo do plano.
6. Repetir com a mesma fixture e condições. Para índice futuro, comparar também custo de escrita/armazenamento e compatibilidade de versão/collation. Não exigir zero `Seq Scan` em tabela pequena sem justificativa.
7. Registrar revisão incluindo dirty state, ambiente sem credenciais, fixture/reset, passos/comandos exatos, resultados e limitações em `docs/test-runs/<data>/` conforme autoridade. Marcar execução bloqueada como bloqueada, nunca como sucesso.

## Contrato de verificação para trabalho futuro

- Manter mudanças de comportamento separadas de refactors puros. Não mudar defaults, ranking, API, schema, status HTTP, autorização/privacidade ou semântica de dinheiro sem decisão explícita.
- Antes de alterar testes, ler [`../.agents/skills/test-audit/SKILL.md`](../.agents/skills/test-audit/SKILL.md). Adicionar teste focado para lacuna concreta e preservar cobertura distinta de dinheiro, autorização, concorrência e recuperação.
- Usar boundary HTTP/DB quando necessário; mocks, testes unitários, DB sincronizado e benchmark isolado são evidências diferentes. Não afirmar runtime/provider/device por inferência.
- Executar gates aplicáveis exatamente conforme `AGENTS.md` e `HARDENING_PLAN.md`; integration/E2E requerem PostgreSQL/Redis explicitamente configurados e guardados. Os scripts `db:sync`/`db:seed` não são inicialização de produção.
- Backend que altere contrato de API deve ser verificado contra os clientes Flutter e Web afetados. Não alterar clientes durante este rascunho.
- Nenhuma mudança de banco/migration nesta etapa. P10 permanece owner-only; nenhuma sessão de desenho ou teste deste plano autoriza migration.

## Decisões pendentes

| ID | Pergunta pendente | Estado/efeito até decisão |
|---|---|---|
| DA-02 (parcial) | Delimitadores/tokenização, normalização, ranking e índice; novos contratos comportamentais exigem decisão. | DA-02.1 prefix username, DA-02.2 displayName word-prefix e DA-02.3 curingas literais implementados; quatro casos de busca passaram no E2E focado histórico. Full E2E follow-up 50/50 (relatório datado). Sem medição de performance. |
| DA-03 | Qual runtime/fixture, volume, concorrência e SLO devem orientar medição? | Desconhecidos; nenhuma afirmação de latência/gargalo ou threshold. |
| DA-04 | Qual API pública e composição de providers fazem Users exercer o ownership aprovado sem ciclo, preservando Auth/ResendService e verificação de perfil? | Users é o target owner (P3); source já está em Users, provider ainda em Auth e Users importa Auth. Resolver arranjo de API/DI antes do move; não usar `forwardRef`. Busca não precisa ser movida novamente. |
| DA-05 | Resolvida pelo owner (2026-10-18): manter `@Transactional()`, desligar proxy, obter client por `TransactionHost<TransactionalAdapterPrisma>.tx`; sem UoW/TxContext/getter/facade. | Aplicar somente aos dois consumers existentes no lote autorizado; provar rollback real e isolamento concorrente. Não autoriza migrar outras fatias. `Left` retornado pelo método decorado pode commitar; erro para rollback deve escapar. |
| DA-06 | Ferramentas/dependências e DDL necessários para inspeção/índices? | Sem dependências novas por padrão; validar tooling instalado e versão do banco quando houver autorização. |

DA-01 e DA-05 estão resolvidas; DA-02.1–DA-02.3 definem busca. DA-03, DA-04 e DA-06 permanecem pendentes. Infra autorizada implementada e focalmente verificada; status final de gates fica no [relatório](test-runs/2026-10-18/backend-infra/REPORT.md). Nenhum outro lote/migration está autorizado.

## Vocabulário

As definições de **Username** e **Display name** estão em [`CONTEXT.md`](../CONTEXT.md). Regras de correspondência, consultas e decisões arquiteturais pertencem a este plano, não ao glossário. O rótulo de interface “pessoas” não define a semântica da busca.

## Referências técnicas consultadas

- NestJS Modules: <https://docs.nestjs.com/modules>
- NestJS circular dependency: <https://docs.nestjs.com/fundamentals/circular-dependency>
- PostgreSQL 17 — índices de expressão: <https://www.postgresql.org/docs/17/indexes-expressional.html>
- PostgreSQL 17 — `pg_trgm`: <https://www.postgresql.org/docs/17/pgtrgm.html>
- PostgreSQL 17 — `EXPLAIN`: <https://www.postgresql.org/docs/17/using-explain.html>

As referências externas não identificam a versão/configuração do PostgreSQL deste projeto; confirmar ambiente antes de adotar sintaxe, índice ou expectativa de plano.
