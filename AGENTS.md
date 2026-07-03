# AGENTS.md - FreeBay Architecture Diagrams

> For conventions and current architecture rules, see [CLAUDE.md](./CLAUDE.md). This file only diagrams the schema and request-flow shape.

---

## Database Schema

The database is structured on PostgreSQL using Prisma ORM. Below is the systematic mapping of all core database models and their relational dependencies:

```mermaid
erDiagram
    User ||--o| Wallet : "1:1 owns wallet"
    User ||--o{ Product : "1:N sells products"
    User ||--o{ Post : "1:N creates social posts"
    User ||--o{ Order : "1:N buys or sells orders"
    User ||--o{ Follow : "1:N follower/following"
    User ||--o{ Block : "1:N blocker/blocked"
    User ||--o{ Dispute : "1:N initiates disputes"
    User ||--o{ Review : "1:N review giver/receiver"
    User ||--o{ DirectMessage : "1:N sends chat messages"
    User ||--o{ ConversationPreference : "1:N configures preferences"
    User ||--o{ Notification : "1:N receives notifications"

    Product ||--o{ ProductImage : "1:N contains images"
    Product ||--o{ Order : "1:N referenced in orders"
    Product ||--o{ Favorite : "1:N favorited by users"
    Product ||--o{ CartItem : "1:N added to shopping carts"
    Product ||--o| Post : "1:1 optionally featured in post cards"

    Post ||--o{ Comment : "1:N commented under"
    Post ||--o{ Like : "1:N liked by users"
    Post ||--o{ Share : "1:N shared by users"
    Post ||--o{ SavedPost : "1:N bookmarked by users"

    Order ||--o| Transaction : "1:1 holds payment details"
    Order ||--o| Dispute : "1:1 opens conflict case"
    Order ||--o{ ChatMessage : "1:N order-chat messages"
    Order ||--o{ Review : "1:N reviewed once per order"

    Wallet ||--o{ Withdrawal : "1:N requests money cashouts"

    DirectConversation ||--o{ DirectMessage : "1:N holds messages"
    DirectConversation ||--o{ ConversationPreference : "1:N holds user chat preferences"
```

## Request Flow

High-level execution flow for any API endpoint:

```mermaid
graph TD
    Client[HTTP Client / WebSocket Client] -->|1. Request JSON / Payload| Controller[NestJS Controller]
    Controller -->|2. Calls Usecase| Usecase[Single-use Usecase execute]
    Usecase -->|3. Requests Data| AbstractRepo[Abstract Repository interface/class]
    AbstractRepo -->|4. Implementation lookup| DataRepo[Concrete Data Repository Prisma]
    DataRepo -->|5. SQL Query| DB[(PostgreSQL Database)]
    DB -->|6. Prisma Entity Model| DataRepo
    DataRepo -->|7. Either Failure or Entity| Usecase
    Usecase -->|8. Either Failure or DTO Output| Controller
    Controller -->|9. API response status 200/201/4xx| Client
```
