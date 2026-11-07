# FreeBay QA — 07/11/2026 (atualização pós-campanha de lançamento)

**Regra de ouro desta atualização: o código é a verdade.** Toda afirmação abaixo foi
verificada contra diff/código atual, saída de gates ou screenshots; o que não foi
verificado está marcado como pendente. Auditoria histórica de 21/10/2026 permanece em
`docs/test-runs/2026-10-21/qa-audit/`.

## Gates atuais (medidos nesta campanha)

| Gate | Resultado |
|---|---|
| Backend `npx tsc --noEmit` | ✅ 0 erros |
| Backend jest (auth/cart/chat/orders/users) | ✅ 76 suites / 518 testes |
| Backend `prisma validate` | ✅ |
| Backend lint (focado) | ✅ |
| Web `tsc` / `lint` / `vitest` / `build` | ✅ 0 / 0 / 75 testes / 0 |
| Web E2E fixture (Playwright) | ✅ 12/12 |
| Flutter `flutter analyze --fatal-infos lib` | ✅ No issues found |
| Flutter `dart format` repo-wide | ⚠️ 1 arquivo pré-existente (`chat_routes.dart`, trabalho alheio em andamento) |
| Flutter tests | 🚫 proibidos por regra do dono — verificação = format + analyze + build + device |
| Backend integration/E2E | ⛔ bloqueados (Stripe key prefix / autenticação `test` P1000) — nunca reportar como verdes |

## Corrigido nesta campanha (todas as lanes revisadas por diff, não por relato)

- **Backend:** DoS de travamento de estoque (pedido não pago expira em 30 min, teto de 10
  pedidos pendentes/buyer, throttle em `POST /orders`); 4 índices em hot paths (Transaction,
  Dispute, Order); upload de imagem de review com checagem de elegibilidade; throttles
  reais (`short` bucket) em uploads/posts/produtos; verificação de e-mail (ADR 0007) com
  link de provedor seguro (Google/Apple nunca ligam a conta local não verificada) e gate
  de e-mail verificado para vender.
- **Flutter:** 16 defeitos de auth corrigidos (401 de negócio não derruba mais sessão;
  logout revoga mesmo com access token expirado; register lembra conta; lock de inatividade
  não prende usuário recém-logado; FCM sem token pinado; etc.). Chat: oferta invisível
  renderiza, block/report/theme consistentes, rótulos no composer. Feed/stories: CTA de
  empty state, FAB de compor, menu "..." com report/delete, stories por ID. Perfil/settings:
  logout confirmado, tema segmentado, telas Bloqueados/Salvos/Favoritos/Compras alcançáveis.
  Compra: "Comprar agora" respeita quantidade, guards de double-tap no carrinho.
- **Web:** follow/block liam campos errados (corrigido); paginação de orders/sales/wallet
  acumula páginas; viewer de stories fecha no último slide; diálogos destrutivos padronizados;
  nav mobile de marketing; seletor de idioma segmentado; aurora visível nas páginas de auth
  (fundo opaco cobria); overflows mobile de explore/perfil corrigidos (390px limpo).
- **Codificação:** mojibake sistêmico no backend (UTF-8 re-salvo via cp1252, pré-existente —
  mtimes de 02/11) reparado por script com dry-run: 47 linhas em 9 arquivos; resto do repo
  varrido e limpo.
- **Código morto removido (verificado sem referências):** `PostShareBottomSheet`,
  `FeedTypeDropdown`, `post_details_comment_tree.dart`.

## Pendente (não afirmar como pronto)

- **Device:** evidência em aparelho real de todas as correções Flutter (dono optou por
  verificação visual web primeiro; regra de screenshots adicionada ao AGENTS.md).
- APK debug build gate (batch após lanes de UI).
- Verificação de e-mail: UI Flutter/web ainda não construída; gates em orders/Connect
  documentados mas não ligados.
- Deferred: step-up na tile de biometria (falha >5min após login), gating de lock sem
  biometria, retry de revogação offline.
- Smells backend em aberto: throttles `{limit,ttl}` inertes (sweep pendente), mapa
  `tempImages` sem dono, pedidos PENDING com transação mas `checkoutExpiresAt` null nunca
  reclamados.
- Keys de l10n pendentes dos lanes Flutter (passada única de catálogos pendente).
