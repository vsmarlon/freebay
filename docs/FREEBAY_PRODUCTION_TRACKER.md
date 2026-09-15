# FreeBay — Production Tracker

Atualizado em **2026-09-10**. Documento durável para acompanhar o inventário de
risco do produto antes do lançamento. A execução aprovada está em andamento:
backend não-chat (A), backend de chat/schema (B) e baseline tester; não há claim de
teste, profiler ou device executado neste registro. Código existente é evidência de
existência, não de completude.

## 1. Escopo e leitura do estado

- Alvo herdado provisório: Android/iOS, `com.freebay.app`, Brasil; web apenas
  support-only. Funcionalidades adiadas permanecem adiadas, não foram cortadas.
- Há **31 issues abertas**: épicos [#1](https://github.com/vsmarlon/freebay/issues/1)
  e [#2](https://github.com/vsmarlon/freebay/issues/2), mais **29 filhas #3–#31**.
  Todas as referências apontam para o ticket correspondente em
  `https://github.com/vsmarlon/freebay/issues/N`; não há PR retornada.
- O handoff em `FREEBAY_RELEASE_HANDOFF.md:5-10` está superseded; Q1–Q21 foi
  encerrado. O plano externo não foi lido e Q9 não deve ser retomada.
- A revisão de 06/09 inclui Connect Express, Brasil e `com.freebay.app`; DM E2EE
  e shipping continuam adiados. O conflito antigo que ainda exclui Connect em
  #1 é stale.
- A recomendação de lançamento registrada é manter Stripe Connect Express e o
  recebimento real dos vendedores, com base no inventário de 06/09. Isso não
  infere afirmação legal nem prova escrow/payout.

### 1.1 Legendas independentes

**Evidência** (o que foi observado): `reported` (relato/ticket), `code-observed`
(ramo ou código localizado), `partially-implemented` (há parte explícita),
`implemented-unverified` (parece implementado, sem prova), `runtime-verified`
(prova em execução), `refuted` (a afirmação foi contrariada), `unknown`.

**Status de trabalho** (o que fazer): `unassessed`, `queued`, `active`,
`blocked`, `deferred`, `accepted`, `reopened`. As dimensões não formam pipeline:
um item pode ser `code-observed / unassessed`. As 31 issues continuam abertas no
GitHub; as 29 filhas estão em execução de implementação, ainda sem `accepted`.
Nenhum claim de runtime foi produzido por esta atualização.

**Fonte/ambiente comum:** inventário local FreeBay em 2026-09-10, Android/iOS
como alvo, Brasil e `com.freebay.app` como contexto herdado. O estado de cada
claim abaixo permanece separado do estado do ticket.

## 2. Pergunta de lançamento

**P01a — reported / deferred:** o usuário informou a opção **1**: a exigência
documental é da conta principal/platform do FreeBay. Isso é relato do usuário, não
prova de dashboard ou runtime; não foram solicitados IDs, documentos ou secrets.

P01 permanece **deferred**: o usuário delegou a continuidade das recomendações
existentes e a execução não deve tratar a conta como live. P01a resolve somente o
locus da exigência documental; não prova dashboard, runtime, escopo, semântica,
cortes, prazos ou payout.

### 2.1 Bloqueador operacional reportado

- **B01 — reported / deferred:** TODO do owner da conta principal Stripe do FreeBay:
  retomar depois para concluir diretamente na Stripe a verificação/documentação
  solicitada e validar a operação live. Os documentos/status exatos e o acesso a
  sandbox ainda são desconhecidos; não solicitar IDs, documentos ou secrets.
- O usuário explicitamente adiou a conversa de Connect para avançar as demais
  issues. B01 continua TODO da conta principal Stripe: verificação documental,
  payout real e operação live seguem bloqueados. Não há KYC nem auto-provisioning.

### 2.2 Decisões registradas

**P02 | #24 — respondida em 2026-09-10:** “1, porem com suporte a folders para
cada vendedor. mas conversas separadas para cada produto /pessoa (cvs unica)”.
Essa resposta registra **D01**: inquiries pré-compra são separadas por produto,
com uma conversa única por produto e par de participantes; a conversa não muda
de par conforme o iniciador. Pastas por vendedor também são requisito, mas seu
comportamento ainda não foi decidido.

 D01 é uma decisão de requisito, não aceitação de implementação ou runtime:
permanece **não implementada nem aceita em runtime**. A reutilização da conversa ao
reabrir é uma consequência derivada de “cvs unica”, não uma segunda confirmação
independente. Dois produtos entre o mesmo par continuam sendo duas conversas;
compradores diferentes não compartilham transcript.

**D02 — delegada e adotada em 2026-09-10:** pastas são calculadas por
interlocutor. O comprador vê a pasta do vendedor; o vendedor vê a pasta do
comprador. P03 foi respondida por delegação, não por uma resposta separada.

Não há CRUD/configuração de pastas como requisito. Permanecem em aberto somente
os comportamentos de ordenação, archive/unarchive, greeting/draft, evolução após
a compra e destino de order threads.

## 3. Categorias de risco (ordem de investigação)

| Categoria | Foco | Dependência mínima |
|---|---|---|
| C0 | escopo, evidência e decisões | nenhuma |
| C1 | dinheiro, consentimento e shell compartilhado | contrato; baseline só para shell |
| C2 | contratos, paginação e identidade de domínio | confirmar semântica |
| C3 | descoberta, social e perfil | C2 onde houver cursor/contagem |
| C4 | mensagens e inquiry | identidade/modelo antes de UX |
| C5 | mídia, áudio e localização | permissões, retenção e reuso |
| C6 | estética, contraste e acessibilidade | tokens compartilhados |
| C7 | jornada completa e operações | C1–C6, sem bloquear trilhas independentes |

As trilhas podem correr em paralelo depois que seus contratos forem conhecidos.
Não é necessário aguardar uma migração geral para corrigir um comportamento
isolado; decisões de domínio precedem correções que possam cristalizar semântica.

### 3.1 Plano aprovado e execução

O plano foi aprovado como orientação de execução, não como prova de correção.
Todos os 31 tickets continuam abertos e mapeados; nenhuma issue foi fechada ou
aceita somente por haver código. Os proprietários são: **A** backend não-chat,
**B** backend de chat + schema, **C** frontend não-chat e **D** frontend de chat
+ editor/native. O tester é owner somente de testes em device. Mudanças de schema
e código seguem serializadas com codegen.

Defaults técnicos delegados: tela nativa explícita de consentimento pós-auth;
título completo no Explore; semântica de offset/cursor conforme o contrato real;
metadata de cursor no perfil; greeting editável como `DRAFT`, com envio explícito;
localização medida sem fallback; editor com crop/draw/preview/cancel sem upload;
áudio limitado a 60s e composer de seis linhas. Não cristalizar constantes no
glossário.

Gates mais amplos permanecem visíveis: Cart é um pagamento; push/iOS security
audit estão `UNASSESSED` e bloqueados até testes reais. Não foram cortados
silenciosamente.

## 4. Inventário rastreável das issues

Cada linha conserva o pedido, sua evidência atual e a prova necessária. O número
do ticket é o link normativo; as fontes locais são ponteiros de investigação.

### C1 — dinheiro, consentimento e shell

- [#3](https://github.com/vsmarlon/freebay/issues/3) **C3.a** criação de order
  não pode quebrar no contrato nulo; **reported / queued**. O histórico observado
  foi POST `/orders` 201 seguido de `Null is not a subtype of String` em
  `_$OrderEntityFromJson`, no fluxo `PaymentPage._submit`; provar que o body 201
  é desserializado sem esse crash. As mudanças locais atuais de order/auth/wallet
  continuam sujas e não verificadas; sem IDs ou payloads reais aqui.
- [#4](https://github.com/vsmarlon/freebay/issues/4) **C4.a** wallet vazia deve
  ser estado determinístico, não tela em branco; **reported / queued**. **C4.b**
  wallet deve sair de fundo estático semelhante a login, sem dados fingidos;
  **reported / queued**. Provar loading, empty, error, retry e ciclo de autenticação
  em runtime, incluindo checks de acesso por papel/identidade.
- [#5](https://github.com/vsmarlon/freebay/issues/5) **C5.a** sem consentimento
  nunca abrir prompt nativo biométrico; **reported + code-observed / unassessed**.
  Provar cancel, off, sem enrollment, troca de conta e logout.
- [#6](https://github.com/vsmarlon/freebay/issues/6) **C6.a** consentimento
  opcional no primeiro login/registro; **reported + code-observed / unassessed**.
  A tela dedicada solicitada e a sheet atual de enrollment podem divergir; a
  decisão de produto ainda não foi tomada.
- [#7](https://github.com/vsmarlon/freebay/issues/7) **C7.a** overlay branco do
  teclado em todas as rotas de input do shell; **reported + code-observed /
  queued**. Login e Novo anúncio são controles negativos: o comportamento deve
  continuar funcionando. Reproduzir antes de alterar configuração global.
- [#25](https://github.com/vsmarlon/freebay/issues/25) **C25.a** email registrado
  preenche checkout; **reported + code-observed / unassessed**. Provar valor,
  edição, ausência de vazamento e submissão. (Cross-reference: payment journey.)
- [#8](https://github.com/vsmarlon/freebay/issues/8) **C8.a** navegação/render
  performance; **reported / unassessed**. Medir navegação/swipes e primeira
  abertura, distinguindo cold de warm; não há orçamento arbitrário aprovado.

### C2 — contratos, paginação e domínio

- [#9](https://github.com/vsmarlon/freebay/issues/9) **C9.a** primeira abertura
  do FeedDrawer e comentários; **reported + code-observed / unassessed**. **C9.b**
  Feed first-open e **C9.c** comment first-open são estados próprios. Comparar
  `const FeedDrawer()` e os três cold/warm opens; simplificar somente após medir
  causas compartilhadas.
- [#10](https://github.com/vsmarlon/freebay/issues/10) **C10.a** first-open cold da
  people-search; **reported / queued**. **C10.b** warm re-open depois de navegar
  de volta para a people-search; **reported / queued**. Medir cold e warm como
  cenários e baselines separados, anexando evidência de cada abertura. **C10.c**
  `Ver mais` deve acrescentar sem flash na busca; **reported + code-observed /
  queued**. **C10.d** `Ver mais` no perfil não pode piscar sem append; **reported /
  queued**. Provar páginas estáveis, sem duplicata, fim, retry e dataset grande;
  sugestões ainda não têm paginação.
- [#11](https://github.com/vsmarlon/freebay/issues/11) **C11.a** follow/unfollow
  atualiza contagens imediatamente; **reported + code-observed / queued**.
  Provar rollback em falha e consistência entre páginas.
- [#12](https://github.com/vsmarlon/freebay/issues/12) **C12.a** títulos completos
  no Explore, sem ellipsis; **reported / queued**. Decidir o limite backend sem
  inventar número e provar telas/datasets longos.
- [#13](https://github.com/vsmarlon/freebay/issues/13) **C13.a** slider mantém
  draft e só aplica após confirmação; **reported + code-observed / queued**.
  Provar que arrastar não dispara requests e que aplicar/cancelar preserva filtro.
- [#14](https://github.com/vsmarlon/freebay/issues/14) **C14.a** gesto de
  categoria é independente do swipe do grid de produtos; **reported / queued**.
  Provar scroll horizontal/vertical e mudança de categoria sem navegação acidental.

### C3 — identidade, descoberta, social e perfil (chat: cross-reference C4)

- [#15](https://github.com/vsmarlon/freebay/issues/15) **C15.a** header de chat
  usa nome real e avatar verdadeiro; **reported / queued**. **C15.b** back fica
  adjacente à mesma moldura do avatar; **reported / queued**. Provar identidade
  correta, replay do mesmo produto e conta bloqueada quando a regra estiver definida.
- [#16](https://github.com/vsmarlon/freebay/issues/16) **C16.a** input cresce
  sem clipping; **reported + code-observed / queued**. **C16.b** bubbles exibem
  texto longo completo; **reported / queued**. Provar multiline e usabilidade
  com teclado.
- [#17](https://github.com/vsmarlon/freebay/issues/17) **C17.a** mídia do
  transcript persiste inline após revisitar aba/reiniciar; **reported +
  code-observed / unassessed**. Provar upload, cache/recarga e ausência de perda.
- [#18](https://github.com/vsmarlon/freebay/issues/18) **C18.a** gravar/enviar
  áudio pelo microfone; **reported + code-observed / queued**. **C18.b** tocar
  áudio recebido é separado do envio; **reported / queued**. Provar permissões,
  cancelamento, falha e playback.
- [#19](https://github.com/vsmarlon/freebay/issues/19) **C19.a** tema persiste;
  **reported / queued**. **C19.b** fundo persiste; **reported / queued**. Provar
  cada restauração independentemente, em dark/light, após reabrir.
- [#20](https://github.com/vsmarlon/freebay/issues/20) **C20.a** ordenação por
  recente; **reported / queued**. **C20.b** ordenação por nome; **reported / queued**.
  **C20.c** archive/unarchive é retrieval próprio; **reported / queued**.
  **C20.d** busca é retrieval próprio; **reported + code-observed / queued**.
  Provar restauração, vazios e concorrência entre abas.
- [#22](https://github.com/vsmarlon/freebay/issues/22) **C22.a** posts do perfil
  usam cursor lazy no scroll, sem carregar tudo; **reported + code-observed /
  queued**. Provar append, fim, retry e páginas sem duplicatas.
- [#23](https://github.com/vsmarlon/freebay/issues/23) **C23.a** lista de saved
  posts; **reported + code-observed / queued**. Deve ser distinta de favoritos
  de produtos; provar listagem, vazio, save/unsave e reopen.
- [#26](https://github.com/vsmarlon/freebay/issues/26) **C26.a** story publicada
  aparece após refresh; **reported / queued**. Provar upload de imagem, sucesso,
  erro e persistência ao reabrir.
- [#27](https://github.com/vsmarlon/freebay/issues/27) **C27.a** filtro Following
  mostra exatamente as contas seguidas; **reported / blocked** até definir a
  semântica de “seguida”. Provar unfollow e paginação.
- [#28](https://github.com/vsmarlon/freebay/issues/28) **C28.a** Vendas filtra e
  pagina; **reported / blocked**. “Vendas” pode significar posts à venda ou
  vendas/orders do seller; não escolher silenciosamente.

### C4 — mensagens e inquiry

- [#24](https://github.com/vsmarlon/freebay/issues/24) **C24.a** conversa de
  produto carrega `productId`; **reported + code-observed / blocked**. **C24.b**
  inquiry usa “Oi, ainda está disponível?”; **reported / blocked**. Não criar nem
  reservar `Order` só para contactar seller: hoje existem modelos `DIRECT` e
  `ORDER`. Definir replay do mesmo/diferente produto, self-contact e concorrência.
- [#24](https://github.com/vsmarlon/freebay/issues/24) **C24.c** greeting automático
  versus draft pré-preenchido; **reported / blocked**. É decisão do usuário antes
  de enviar ao tocar.
- **C24.d — requisito registrado nesta sessão / unassessed:** pastas de conversas
  agrupam por interlocutor: comprador vê vendedor e vendedor vê comprador. São
  pastas calculadas; não há CRUD/configuração de pastas decidido.
- **C24.e — requisito registrado nesta sessão / unassessed:** uma conversa de
  produto é única por produto e por par de participantes. A mesma dupla e o
  mesmo produto reutilizam a conversa ao reabrir; dois produtos geram duas
  conversas. Produtos diferentes do mesmo par têm threads distintas, cada uma com
  seu produto único. A resposta do usuário é a fonte, não uma nova issue remota.
- Reconciliação com o código: `product_detail_page.dart` hoje inicia contato com
  `userId` somente; o backend já distingue `DIRECT`/`ORDER`, mas não se afirma que
  a identidade do produto esteja sendo aplicada. A lacuna de implementação
  permanece `runtime-unverified`.

### C5 — mídia, editor e localização

- [#21](https://github.com/vsmarlon/freebay/issues/21) **C21.a** preview/edit
  antes de upload/save para avatar e cover; **reported / queued**. **C21.b**
  componente compartilhado por post, produto e chat; **reported / queued**.
  Reusar seams existentes somente no mínimo necessário; provar cancelar,
  crop/edit/replace/save e falha, sem assumir uma lista arbitrária de recursos.
- [#29](https://github.com/vsmarlon/freebay/issues/29) **C29.a** background
  animado não degrada render; **reported / unassessed**. **C29.b** preservar
  animação nas superfícies auth/splash; **reported / unassessed**. **C29.c** pausar
  shader quando obscuro, em background ou fora da superfície; **reported /
  unassessed**. **C29.d** manter light/dark conforme design system; **reported /
  unassessed**. Provar com traces baseline/pós em device-alvo e frame budget
  acordado; medir cold/warm com #8/#9, sem inventar budget. (Cross-reference: C6
  performance.)
- [#30](https://github.com/vsmarlon/freebay/issues/30) **C30.a** localização ao
  vivo; **reported / unassessed**. **C30.b** permissão negada/GPS indisponível é
  recuperável e não envia; **reported / unassessed**. **C30.c** mapa centra na
  posição autorizada medida; **reported / unassessed**. **C30.d** confirmar envia
  exatamente uma mensagem com payload canônico validado de latitude/longitude;
  **reported / unassessed**. **C30.e** remetente e destinatário veem a mesma
  localização após reabrir; **reported / unassessed**. Não fabricar fallback.
- [#31](https://github.com/vsmarlon/freebay/issues/31) **C31.a** image composer
  sobre chat; **reported / queued**. **C31.b** abrir editor preserva draft e
  scroll; **reported / queued**. **C31.c** crop, drawing, preview, cancel e send
  atuam só na imagem pendente; **reported / queued**. **C31.d** view-once fica
  na bolha da mensagem pendente e contrato enviado; **reported / queued**.
  **C31.e** cancelar não faz upload nem cria transcript; **reported / queued**.
  Enviar cria exatamente uma mensagem de imagem durável.

**Fonte de #29–#31:** os critérios acima foram transcritos das issues GitHub
lidas em 2026-09-10, não apresentados como novas alegações da auditoria de 09/09.

### C6 — estética, contraste e acessibilidade compartilhada

- **C16.c** contraste de **“Envie a primeira mensagem...”** em dark mode;
  **reported / queued**. **C16.d** contraste de **“Direta”** em dark mode;
  **reported / queued**. **C16.e** consumidores dos mesmos tokens em outras
  telas; **reported / queued**. Validar contra `frontend/DESIGN.md`.
- “Like WhatsApp” é interpretação herdada/proposta de comportamento familiar e
  confiável, não decisão de domínio nem autorização para abandonar o brutalismo;
  **unknown / unassessed**. Não canonicalizar o termo, radius, sombra ou divider.

## 5. Jornada de dinheiro e lançamento

- O produto deve preservar centavos como inteiros e ledger imutável; provar stock,
  reservation, retries, eventos duplicados/fora de ordem, carrinho multisseller
  com alocações independentes, refund, dispute, release e reconciliação.
- Connect existente expõe onboarding/status/dashboard em
  `nest-backend/src/modules/payments/payments.controller.ts:67-96`. A criação de
  transfer está em `nest-backend/src/modules/payments/services/seller-payout.service.ts:21-66`
  e delega ao Stripe provider em
  `nest-backend/src/modules/payments/providers/stripe-provider.ts:207-223`;
  a UI está em
  `frontend/lib/features/wallet/presentation/pages/wallet_page.dart:139-144`.
  `ChatThreadType` distingue `ORDER`/`DIRECT` em
  `nest-backend/prisma/schema.prisma:108-111`.
  **code-observed / unassessed**, não payout verificado.
- A revisão de 06/09 descreve separate charges and transfers, sem
  `application_fee_amount`; fee fica na matemática do transfer. Accounts v2 usa
  `recipient`, dashboard/fees/losses Express/application. Validar contra o
  comportamento real e reconciliação antes de chamar isso de pronto.
- Fulfillment deve esclarecer handoff de services versus shipping, ownership e
  histórico de escopo. Shipping continua deferred; não marcar como corte tácito.

## 6. Áreas do produto ainda não avaliadas

Estas áreas não receberam issue nova nesta sessão. Cada uma precisa de cenário,
aceitação e evidência antes de um status de release:

- **Auth:** recuperação, Google, guest, exclusão/exportação de conta, bloqueio,
  logout em múltiplos dispositivos e account switch.
- **Notificações/deeplinks:** foreground, background, killed, autenticação,
  deduplicação, destino correto e múltiplos dispositivos.
- **Offline/resiliência:** reconexão, perda de dados, retry seguro e conflitos.
- **Privacidade/moderação:** permissões e retenção de mídia/localização,
  conteúdo proibido, denúncia, bloqueio, moderação e suporte/admin.
- **Disputas/operação:** abertura, evidência, decisão, refund/release, ownership,
  fila operacional e runbook de atendimento.
- **Dados/operação:** arquitetura e lacunas de testes, CI/build/deploy, env,
  migrações, backup/RESTORE, rollback, logs, alertas e crash support.
- **Store/legal/acessibilidade:** signing e gates de iOS (macOS depois),
  store metadata, revisão legal, screen readers, focus, contraste e text scale.
- **Performance:** cold/warm e render mensuráveis em pontos reais; metas só após
  decisão explícita, nunca inventar budget.

## 7. Registro de fontes

Ponteiros usados, sem transformar caminho em prova de runtime:

- Shell/rotas: `frontend/lib/core/components/app_shell.dart:156-185`,
  `frontend/lib/core/router/app_router.dart`; seam existente em
  `frontend/test/core/components/app_shell_test.dart`.
- Social: `frontend/lib/features/social/presentation/pages/feed_page.dart`,
  `people_search_page.dart`, `comment_bottom_sheet.dart`, `create_story_page.dart`;
  `widgets/feed_drawer.dart`; `providers/feed_provider.dart` e
  `providers/user_search_provider.dart`.
- Busca/perfil: `frontend/lib/features/profile/presentation/pages/saved_posts_page.dart:24-50`,
  `controllers/profile_controller.dart:25-40`; backend
  `nest-backend/src/modules/social/usecases/get-user-posts.usecase.ts:15-49` e
  `nest-backend/src/modules/users/usecases/follow-user.usecase.ts:39-47`.
- Produtos: `frontend/lib/features/product/presentation/widgets/product_filter_bar.dart:96-111`,
  `presentation/controllers/product_controller.dart:81-125` e
  `presentation/pages/product_detail_page.dart:245-281`. RangeSlider atualiza
  durante `onChanged`; isso é code-observed, não performance medida.
- Chat: `frontend/lib/features/chat/presentation/widgets/chat_input_bar.dart:78-109,125-134`,
  `pages/chat_conversation_page.dart:582-649`, `widgets/message_bubble.dart:334-388`;
  backend `nest-backend/src/modules/chat/usecases/{start-conversation,get-unified-conversations,archive-conversation}.usecase.ts`
  e `ChatThreadAccessService`.
- Pagamento/auth/wallet: `frontend/lib/features/payments/presentation/pages/payment_page.dart:45-57`,
  `frontend/lib/features/auth/domain/usecases/biometric_login_usecase.dart`,
  `presentation/widgets/enable_biometry_sheet.dart`,
  `frontend/lib/features/wallet/presentation/controllers/wallet_controller.dart`
  e `wallet_page.dart`. Alterações locais e testes sujos não foram tratados como
  correção verificada.

## 8. Termos ainda não resolvidos

O glossary de Chat foi criado em
[`nest-backend/src/modules/chat/CONTEXT.md`](../nest-backend/src/modules/chat/CONTEXT.md).
Ele registra os termos de domínio resolvidos por D01/D02; não transforma requisitos
em contrato técnico. Proprietários prováveis dos termos restantes, sem ratificação:

- **Chat:** `DIRECT` é conversa social e `ORDER` é thread de compra? Owner provável:
  módulo chat, com confirmação de products/orders.
- **Product inquiry:** contato pré-compra precisa `productId`, mas não `Order`.
  Owner provável: products/social, com contrato de chat.
- **Auth/biometria:** consentimento opcional é sheet, onboarding dedicado ou
  ambos? Owner provável: auth.
- **Wallet/orders/payments:** “receber”, escrow, transfer e payout são estados
  distintos; owner provável: payments/wallet, com invariantes de orders.
- **Vendas, Following e saved posts:** posts, sellers, orders e bookmarks não
  devem ser usados como sinônimos. Owners prováveis: social/profile/products.

Quando um termo for resolvido: identificar módulo proprietário, registrar a
decisão neste tracker e atualizar somente o `CONTEXT.md` daquele módulo. ADR só
se houver trade-off difícil de reverter, surpreendente e realmente decidido.

## 9. Protocolo de investigação

1. Mapear o código, contrato e seams existentes antes de propor mudança.
2. Obter uma reprodução red-capable do sintoma antes de atribuir causa.
3. Fazer profile baseline antes de otimizar performance; comparar somente traces
   realmente coletados.
4. Preferir o menor seam existente que preserve o comportamento pedido, sem
   inventar feature list ou cortar requisito silenciosamente.
5. Registrar somente comandos, output e ambiente realmente executados.
6. Antes de `accepted`, exigir suíte mais ampla, device/runtime, segurança e
   revisão de release conforme o cenário; o plano desta sessão não os executou.

## 10. Próximo estado da sessão

1. **P01a** foi registrada como opção 1; P01 continua **deferred**. A conversa de
   Connect foi adiada para avançar as demais issues; B01 permanece TODO, e toda
   verificação de payout/live continua bloqueada. Não tratar a conta como live.
2. **P03** não é mais pergunta ativa: foi resolvida pela delegação que registrou
   D02, sem resposta separada.
3. Para C1/C2, transformar claims em cenários de aceitação e baseline cold/warm;
   não chamar teste planejado de evidência.
4. Resolver os termos de inquiry, “Vendas”, Following e biometria antes de fixar
   contratos. Depois, investigar os tracks independentes em paralelo.
5. Fazer validação real posterior (backend/frontend, device e operação) antes de
   qualquer `runtime-verified`, `accepted` ou conclusão de lançamento.

### Registro de decisões desta investigação

- Decisões de feature/domínio do usuário: **D01** e **D02** foram registradas em
  2026-09-10. Inquiries pré-compra são separadas por produto, únicas por produto
  e par de participantes; pastas calculam o interlocutor (comprador vê vendedor,
  vendedor vê comprador). Isso não é aceitação de implementação/runtime; P01a
  foi respondida como opção 1, P01 continua **deferred** e P03 foi delegada.
- Instrução de sessão do usuário em **2026-09-10**: adiar a conversa de Connect e
  avançar as demais issues; B01 fica como TODO visível, não fechado/aceito.
- Processo/plano aprovado: tracker em português, organizado por categorias de
  risco e evidência; o glossary de Chat foi criado inline após D01/D02. A execução
  segue com owners A/B/C/D; o advisor aprovou o plano, não ratificou features,
  escopo ou payout.
- Advisor final: “Verified: current code does expose Stripe Express Connect
  onboarding/status/dashboard, transfer creation, and distinct ORDER/DIRECT
  models. The plan correctly treats payout behavior as unverified rather than
  proven. No remaining blockers. Verdict: APPROVE.”

### Regra de retomada

Preservar todos os arquivos locais dirty existentes, inclusive order/auth/wallet,
skills e docs; não rebasear, limpar ou interpretar alteração local como prova.
Executar somente nos owners aprovados, sem escrita remota, GH ou commit. Device é
responsabilidade exclusiva do tester; não registrar aprovação antes da evidência.

### Resumo de controle

| Medida | Estado |
|---|---|
| Issues rastreadas | 31 (épicos 1–2; filhas 3–31) |
| Filhas explicitamente listadas | 29 |
| PRs retornadas | 0 |
| Evidência desta sessão | code/GH/docs inventory |
| Runtime, profiler, device e testes | não executados |
| Claim aceito/runtime-verified | 0 |
| Perguntas ativas | 0 (P01 deferred; P02 respondida; P03 delegada) |
