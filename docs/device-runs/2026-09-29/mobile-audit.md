# Android emulator audit — 2026-09-29

- Revision: `feat/production-hardening` working tree (including uncommitted changes); exact revision and diff recorded in `docs/test-runs/2026-09-29/feature-audit.md`.
- Device: `Small_Phone`, Android 16/API 36, x86_64 local emulator.
- App: locally built debug APK (`flutter build apk --debug --target-platform android-x64 --no-pub --dart-define=API_BASE_URL=http://localhost:3000`), package `com.freebay.app`.
- API: local `http://localhost:3000`, PostgreSQL and Redis readiness healthy; `adb reverse tcp:3000 tcp:3000`.
- Reset/fixtures: app freshly installed; development database already has seeded products and posts. No test account credentials are included here.
- PASS rule: observed expected state, safe screenshot where possible, no relevant crash. A page loading or a green test does not count as a completed provider/payment journey.

## Observations

| Journey | Result | Evidence |
|---|---|---|
| Cold boot / onboarding | In progress | Android notifications permission prompt shown before onboarding; declined for the run. |
| Cadastro e welcome | PASS parcial | Cadastro pelo app, modal nativo de biometria cancelado; welcome concluído. Sem screenshot do formulário para evitar dados da conta. [`welcome-bio-cancel.png`](welcome-bio-cancel.png). |
| Feed e descoberta | PASS navegação | Posts e cards vindos da API local; categorias e detalhe de produto abertos. Vídeo local FFmpeg `docs/tests/2026-09-29/catalog-to-product-ffmpeg.mp4` (20 s/200 quadros), excluído do Git. |
| Carteira | PASS estado inicial | Disponível e pendente zerados, histórico vazio, CTA de recebimento presente. Onboarding Connect não exercitado. [`wallet-zero.png`](wallet-zero.png). |
| Carrinho e checkout | PASS até gerar pedido | Produto real adicionado; badge 0→1; carrinho 1 item; resumo do checkout e pedido pendente aparecem. [`product-cart-badge.png`](product-cart-badge.png), [`checkout-before-payment.png`](checkout-before-payment.png), [`checkout-generated.png`](checkout-generated.png). |
| PaymentSheet e webhook | **BLOQUEADO para confirmação** | Ao tocar “PAGAR COM CARTÃO” Android abriu e fechou `PaymentSheetActivity` (logcat). Não houve confirmação nem prova de evento assinado; o processo da API já rodava com credenciais de modo não comprovado. Não digitar dados de cartão até fixar a configuração Stripe em teste e reiniciar. |
| Erro Stripe genérico após correção | **BLOQUEADO no device** | APK novo compilado, `flutter analyze` e oito testes existentes passaram; atualização do app bloqueada por falta de espaço (382 MB livres depois de limpar caches). |
| Chat, stories, postagem, favoritos, disputas, push, repasses | **NÃO EXECUTADOS E2E no emulador** | Código/testes não substituem dois usuários simultâneos, aparelho físico, Stripe/test mode e provider. |

Crashes: `mobile_list_crashes` não apresentou `com.freebay.app`; entradas antigas pertencem ao Bluetooth do sistema. `mobile_get_device_logs` filtrado por processo/erro não produziu exceções do app. O `logcat` revelou mensagens de injeção do agente `mobilecli.so` ARM em emulador x86_64, não uma exceção Stripe atribuível ao usuário. Navegação via gesto funcionou; o toque na barra inferior da Wallet não respondeu inicialmente neste tamanho de tela e merece reprodução isolada.
