# Context Map

This repo is organized as vertical NestJS feature modules, not formal bounded contexts — but as domain
modeling work lands on individual modules, each gets its own glossary (`CONTEXT.md`) rather than one giant
shared document. This file is the index.

| Context  | Glossary                                       | Module path             |
|----------|-------------------------------------------------|--------------------------|
| Disputes | [src/modules/disputes/CONTEXT.md](src/modules/disputes/CONTEXT.md) | `src/modules/disputes/` |
| Chat     | [src/modules/chat/CONTEXT.md](src/modules/chat/CONTEXT.md)         | `src/modules/chat/`     |

<!--
Orders, Payments, and Cart are not documented here yet — see TODO.md. Disputes was modeled first as the
flagship bounded context; the others should follow the same pattern (glossary + ADRs colocated under
modules/<feature>/docs/adr/) once work touches them, not all at once.
-->
