# SDD Progress Ledger — Backend Codebase Cleanup & Hardening

Branch: master
Baseline commit: abaa8ff

## Tasks

- [x] Phase 1: Security — verifyWebhook bypass fix + OnModuleInit guard (abaa8ff..c38bbac, review clean)
- [x] Phase 2: Correctness fixes (c38bbac..6e5c590, review clean — pre-existing WIP also committed: PhoneCode* errors + WithdrawUseCase $tx pattern)
- [ ] Phase 3: File Splits — payment, wallet, notifications usecases
- [ ] Phase 4: Repository Abstractions — 6 repos to domain/data split
- [ ] Phase 5: ProcessWebhookUseCase Decomposition — tx? pattern + repo injection
- [ ] Phase 6: N+1 Fix — UserRepository.findPaymentInfo
- [ ] Phase 7: Weak Boolean Returns → void (~30 usecases)
- [ ] Phase 8: RegisterBankAccountUseCase stub + GitHub issue
- [ ] Phase 9: Infrastructure Leaks — P2002 from usecases to repos
- [ ] Phase 10: Documentation Pass — all .md files
