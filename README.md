# FreeBay

FreeBay é uma plataforma de marketplace híbrida C2C (Customer to Customer), projetada para unir o melhor de duas abordagens: a interatividade social do **Instagram** com a robustez e segurança de transações do **Mercado Livre**.

##  O que é o projeto?

O objetivo do FreeBay é oferecer um ambiente onde usuários podem vender e comprar produtos enquanto interagem em uma rede social integrada. 

**Principais Funcionalidades:**
- **Perfis Sociais e Feed:** Usuários podem criar posts, stories e interagir (curtir e comentar) com publicações de produtos ou conteúdos de outros vendedores.
- **Marketplace e Produtos:** Catálogo de produtos com sistema de busca e detalhes avançados.
- **Pagamentos via Escrow (Garantia):** O dinheiro da compra fica retido em segurança ("held") até que a entrega do produto seja confirmada, protegendo quem compra e quem vende.
- **Carteira Digital (Wallet):** Saldo, histórico de transações e saques.
- **Sistema de Disputas:** Resolução de conflitos entre compradores e vendedores.
- **Chat:** Mensagens diretas para negociar e tirar dúvidas sobre os produtos.

##  Stack Tecnológica

- **Backend:** Node.js, TypeScript, Fastify, Prisma (ORM), PostgreSQL, e Redis. Arquitetura baseada em Clean Architecture e injeção de dependências.
- **Frontend:** Flutter (Mobile App para iOS e Android) usando componentização focada em Design System.

##  Como funciona

A arquitetura do projeto é dividida em duas partes principais:

1. **API / Backend (`/backend`):** Centraliza toda a regra de negócios (Use Cases), acesso ao banco de dados relacional via Prisma e serviços de cache com Redis. Utiliza o padrão *Either* para tratamento fortemente tipado de erros e valida entradas usando o Zod.
2. **App Mobile (`/frontend`):** Um aplicativo Flutter que consome a API REST do backend. Os usuários navegam pelo feed (para descoberta) e pela loja (para intenção de compra direta). É construído com foco em UX/UI, com suporte total a *Dark Mode*.

##  Setup e Como Rodar Localmente

### Pré-requisitos
- Node.js (v18 ou superior recomendado)
- Flutter SDK (versão mais recente)
- PostgreSQL e Redis rodando localmente (ou via Docker). Há um `docker-compose.yml` disponível na pasta do backend para subir os serviços rapidamente.

### Iniciando o Backend

1. Acesse a pasta do backend e instale as dependências:
   ```bash
   cd backend
   npm install
   ```

2. Suba o banco de dados via Docker (opcional, caso não tenha local):
   ```bash
   docker-compose up -d
   ```

3. Configure as variáveis de ambiente (crie um arquivo `.env` baseado no `.env.example` caso exista).

4. Rode as migrations e gere os clients do Prisma:
   ```bash
   npm run prisma:generate
   npm run prisma:migrate
   ```

5. Inicie o servidor em modo de desenvolvimento:
   ```bash
   npm run dev
   ```

### Iniciando o Frontend (Flutter)

1. Acesse a pasta do frontend e instale as dependências:
   ```bash
   cd frontend
   flutter pub get
   ```

2. Certifique-se de ter um emulador rodando ou um dispositivo físico conectado e execute:
   ```bash
   flutter run
   ```

### Testes
Para rodar os testes da aplicação:
- **Backend:** `npm run test`
- **Frontend:** `flutter test`

---
