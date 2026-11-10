# Plano FreeBay — lançamento e consolidação

**Data:** 2026-11-07. **Regra:** o código é a verdade — atualize este plano quando o
estado verificado mudar. O plano anterior de QA/idioma/CI (2026-10-22) foi absorvido:
itens ainda válidos aparecem abaixo; `docs/test-runs/2026-10-22/qa-fixes/` guarda o
histórico. `QA.md` é o ledger de estado atual.

## Decisões de dono (grilling 06/11)

1. Entrega **meetup-only** na v1; envio/correio fica pós-lançamento (ADR 0006).
2. **Mobile-first**; web recebe correções críticas, paridade total pós-lançamento.
3. Customização profunda na v1 (tema+acento, idioma persistido, prefs de notificação,
   temas de chat consistentes).
4. Verificação de e-mail endurecida (ADR 0007) — sem auto-link de provedor em conta não
   verificada; vender/payout/pedido exigem e-mail verificado.
5. Admin UI para staff; auditoria de auth do frontend.
6. Ranking/feed medido antes de pesos (ADR 0008).
7. Ops completo; dono detém auth dos consoles (Chrome debug bridge), chaves nunca expostas.
8. **Evidência visual é teste** (regra adicionada ao AGENTS.md): mudanças visíveis fecham
   com screenshots revisados contra o design system.

## Fases

| # | Fase | Estado |
|---|---|---|
| 1 | Money-trust: estoque, índices, e-mail verificado, auth frontend | ✅ código+testes; gates de orders/Connect e UI de verificação pendentes |
| 2 | Jornada de compra (quantidade, guards, carrinho) | ✅ código; device pendente |
| 3 | Chat (oferta, block/report, temas, composer) | ✅ código; device pendente |
| 4 | Feed/stories/explore (CTA, FAB, menu "…", stories por ID) | ✅ código; ranker v2 depende de instrumentação (ADR 0008) |
| 5 | Perfil/settings/customização | ✅ núcleo; idioma persistido, acento, quiet-hours pendentes |
| 6 | Diálogos + conformidade de design system | parcial (sweep de DS Flutter + borão web em andamento) |
| 7 | Admin console | não iniciada |
| 8 | Web críticas + polimento | ✅ críticas; polimento (emoji hover, textareas, perfil, coleções) em andamento |
| 9 | Produção: S3, backup/restore, deploy, Stripe live, lojas | não iniciada; migrações/backup exigem fase autorizada pelo dono |

## Pendências técnicas conhecidas (registradas em `REVIEWS.md` do scratchpad)

- Throttles `{limit,ttl}` inertes (normalizam para bucket `default` não registrado) —
  sweep para buckets nomeados.
- `ReviewsService.tempImages` sem dono (qualquer usuário pode referenciar imageId alheio).
- Pedidos PENDING com transação sem `checkoutExpiresAt` nunca são reclamados.
- Passada única de chaves l10n pendentes (lanes deixaram lista em cada proof).
- Mojibake: raiz no toolchain do dono (editor/hook salvando UTF-8 como cp1252) — verificar
  configuração para não recorrer.
- `dart format` repo-wide: 1 arquivo pré-existente alheio pendente.

## Critério de fechamento

Cada fase fecha quando: código passa os gates da área, mudanças visíveis têm screenshot
revisado (web) e/ou evidência de device (Flutter), e `FEATURE_TRUTH.md`/`QA.md` refletem
apenas o que foi verificado.
