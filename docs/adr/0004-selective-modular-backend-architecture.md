# ADR 0004: Arquitetura modular seletiva do backend

- **Status:** accepted
- **Data:** 2026-10-16
- **Decisão:** resposta explícita do owner “A” à pergunta DA-01.
- **Complemento vigente:** [ADR 0005](0005-module-template-public-api-uow-events.md) define tiers, template por módulo, API pública e a decisão transacional ALS atual. Em caso de conflito sobre esses detalhes, prevalece o ADR 0005; este ADR continua autoridade para a política seletiva e para a exceção restrita de CRUD.

## Contexto

D1 do hardening exigia repositórios concretos para todos os use cases, exceto o `TransactionRunner` de P5. A alternativa uniforme criaria contratos também para CRUD simples. O owner escolheu fronteiras hexagonais seletivas dentro de um monólito modular pragmático: contratos/ports pequenos onde regras relevantes, coordenação externa, agregados críticos ou isolamento de implementação justificarem; CRUD interno simples pode usar seu próprio repositório concreto, com saída plain e limitada. Isso é uma exceção deliberada à inversão uniforme, não acesso irrestrito.

## Decisão

- Fronteiras entre módulos e controllers são obrigatórias. Controllers delegam à aplicação, nunca ao repositório.
- Domínio permanece puro, inclusive sem `import type` de NestJS ou Prisma. Application usa IO próprio, sem DTO HTTP ou shape Prisma.
- Módulos consomem API pública estreita/contratos nomeados, nunca internals de outro módulo. O módulo Nest compõe adapters sem barrel universal ou provider duplicado.
- Contratos não implicam entity/mapper por tabela, layers obrigatórias ou diretórios vazios.

## Consequências e limites

Esta é uma política-alvo, não descrição da implementação atual nem autorização de lote. A decisão substitui somente a proibição absoluta de novos ports em D1. Detalhes de layout e transações foram complementados pelo ADR 0005: UnitOfWork/TxContext e barramento de domínio não fazem parte do alvo; transações aprovadas usam ALS conforme esse ADR. Este ADR não autoriza migrations, provider changes ou refatoração financeira.

## Referências

- [Plano de arquitetura do backend](../BACKEND_ARCHITECTURE_PLAN.md)
- [Plano de hardening](../HARDENING_PLAN.md)
