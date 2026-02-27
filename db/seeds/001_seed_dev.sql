SET search_path TO public;

INSERT INTO "User" ("id", "displayName", "email", "emailVerified", "passwordHash", "city", "state", "isVerified", "reputationScore", "totalReviews", "updatedAt")
VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Maria Silva',   'maria@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'São Paulo',      'SP', TRUE, 4.8, 45, NOW()),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'João Santos',   'joao@example.com',  TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Rio de Janeiro', 'RJ', FALSE, 3.5, 12, NOW()),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'Ana Oliveira',  'ana@example.com',   TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Belo Horizonte', 'MG', TRUE, 4.9, 78, NOW()),
  ('d4e5f6a7-b8c9-0123-defa-234567890123', 'Carlos Pereira', 'carlos@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Curitiba',       'PR', TRUE, 4.6, 32, NOW()),
  ('e5f6a7b8-c9d0-1234-efab-345678901234', 'Juliana Costa', 'juliana@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Salvador',      'BA', FALSE, 4.2, 18, NOW()),
  ('f6a7b8c9-d0e1-2345-fabc-456789012345', 'Pedro Almeida', 'pedro@example.com',  TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Fortaleza',     'CE', FALSE, 3.8, 8, NOW()),
  ('a7b8c9d0-e1f2-3456-abcd-567890123456', 'Fernanda Lima', 'fernanda@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Brasília',      'DF', TRUE, 4.7, 56, NOW()),
  ('b8c9d0e1-f2a3-4567-bcde-678901234567', 'Lucas Rodrigues','lucas@example.com',  TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Manaus',        'AM', FALSE, 4.0, 22, NOW()),
  ('c9d0e1f2-a3b4-5678-cdef-789012345678', 'Patrícia Souza','patricia@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Recife',        'PE', TRUE, 4.5, 34, NOW()),
  ('d0e1f2a3-b4c5-6789-defa-890123456789', 'Ricardo Ferreira','ricardo@example.com',TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Porto Alegre',  'RS', FALSE, 3.9, 15, NOW()),
  ('e1f2a3b4-c5d6-7890-efab-901234567890', 'Camila Dias',   'camila@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'São Luís',      'MA', TRUE, 4.4, 28, NOW()),
  ('f2a3b4c5-d6e7-8901-fabc-012345678901', 'Gabriel Martins','gabriel@example.com',TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Natal',         'RN', FALSE, 4.1, 19, NOW()),
  ('a3b4c5d6-e7f8-9012-abcd-123456789012', 'Beatriz Araujo','beatriz@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Goiânia',       'GO', TRUE, 4.8, 42, NOW()),
  ('b4c5d6e7-f8a9-0123-bcde-234567890123', 'Marcos Vieira', 'marcos@example.com', TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'Campinas',      'SP', FALSE, 3.7, 9, NOW()),
  ('c5d6e7f8-a9b0-1234-cdef-345678901234', 'Larissa Castro','larissa@example.com',TRUE, '$2b$12$eUKF3KMS82bf38BZIimJ.e9KMduQlOysfIQ/g5ViCuO9NzMTxAq12', 'São José dos Campos','SP', TRUE, 4.6, 51, NOW())
ON CONFLICT DO NOTHING;

-- ─── Categories ───────────────────────────────────────────

INSERT INTO "Category" ("id", "name", "slug", "createdAt", "updatedAt")
VALUES
  ('cat001-0000-0000-0000-000000000001', 'Eletrônicos',       'eletronicos',       NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000002', 'Roupas',            'roupas',            NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000003', 'Calçados',          'calcados',          NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000004', 'Acessórios',        'acessorios',        NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000005', 'Celulares',         'celulares',         NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000006', 'Informática',       'informatica',       NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000007', 'Móveis',             'moveis',            NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000008', 'Livros',            'livros',            NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000009', 'Esportes',          'esportes',          NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000010', 'Beleza',            'beleza',            NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000011', 'Games',             'games',             NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000012', 'Instrumentos Musicais','instrumentos',   NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000013', 'Pets',              'pets',              NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000014', 'Decoração',         'decoracao',         NOW(), NOW()),
  ('cat001-0000-0000-0000-000000000015', 'Veículos',          'veiculos',          NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ─── Wallets ────────────────────────────────────────────

INSERT INTO "Wallet" ("id", "userId", "availableBalance", "pendingBalance", "totalEarned")
VALUES
  ('w1000000-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 50000, 0,     150000),
  ('w2000000-0000-0000-0000-000000000002', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 0,     0,     0),
  ('w3000000-0000-0000-0000-000000000003', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 25000, 10000, 75000),
  ('w4000000-0000-0000-0000-000000000004', 'd4e5f6a7-b8c9-0123-defa-234567890123', 80000, 15000, 200000),
  ('w5000000-0000-0000-0000-000000000005', 'e5f6a7b8-c9d0-1234-efab-345678901234', 15000, 5000, 45000),
  ('w6000000-0000-0000-0000-000000000006', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 5000,  0,     12000),
  ('w7000000-0000-0000-0000-000000000007', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 120000, 25000, 380000),
  ('w8000000-0000-0000-0000-000000000008', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 30000, 8000, 95000),
  ('w9000000-0000-0000-0000-000000000009', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 45000, 12000, 156000),
  ('w1000000-0000-0000-0000-000000000010', 'd0e1f2a3-b4c5-6789-defa-890123456789', 20000, 0,     65000),
  ('w1100000-0000-0000-0000-000000000011', 'e1f2a3b4-c5d6-7890-efab-901234567890', 65000, 18000, 210000),
  ('w1200000-0000-0000-0000-000000000012', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 18000, 3000, 52000),
  ('w1300000-0000-0000-0000-000000000013', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 95000, 22000, 320000),
  ('w1400000-0000-0000-0000-000000000014', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 8000,  0,     18000),
  ('w1500000-0000-0000-0000-000000000015', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 78000, 15000, 275000)
ON CONFLICT DO NOTHING;

-- ─── Posts ───────────────────────────────────────────────

INSERT INTO "Post" ("id", "content", "imageUrl", "type", "userId", "likesCount", "commentsCount", "updatedAt")
VALUES
  ('p0010000-0000-0000-0000-000000000001', 'Vendendo iPhone 14 Pro Max 256GB! Estado perfeito, quase novo.', 'https://picsum.photos/400/400?random=1', 'PRODUCT', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 45, 12, NOW()),
  ('p0010000-0000-0000-0000-000000000002', 'Tênis Nike Air Max 90 tamanho 42, usado apenas 2 vezes. Original!', 'https://picsum.photos/400/400?random=2', 'PRODUCT', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 23, 8, NOW()),
  ('p0010000-0000-0000-0000-000000000003', 'Alguém conhece bons brechós em São Paulo?', 'https://picsum.photos/400/400?random=3', 'REGULAR', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 12, 25, NOW()),
  ('p0010000-0000-0000-0000-000000000004', 'MacBook Pro 2021 M1 16GB RAM - venda ou troco', 'https://picsum.photos/400/400?random=4', 'PRODUCT', 'd4e5f6a7-b8c9-0123-defa-234567890123', 67, 19, NOW()),
  ('p0010000-0000-0000-0000-000000000005', 'Vestido vintage anos 80 - linda peça!', 'https://picsum.photos/400/400?random=5', 'PRODUCT', 'e5f6a7b8-c9d0-1234-efab-345678901234', 34, 6, NOW()),
  ('p0010000-0000-0000-0000-000000000006', 'PS5 com 2 jogos + controle adicional', 'https://picsum.photos/400/400?random=6', 'PRODUCT', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 89, 31, NOW()),
  ('p0010000-0000-0000-0000-000000000007', 'Bom dia pessoal! Alguém indic um lugar bom pra comprar móveis usados?', 'https://picsum.photos/400/400?random=7', 'REGULAR', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 8, 14, NOW()),
  ('p0010000-0000-0000-0000-000000000008', 'iPad Air 4 geração 64GB WiFi - like new', 'https://picsum.photos/400/400?random=8', 'PRODUCT', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 41, 11, NOW()),
  ('p0010000-0000-0000-0000-000000000009', 'Coleção de livros de Harry Potter - todos os volumes', 'https://picsum.photos/400/400?random=9', 'PRODUCT', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 56, 22, NOW()),
  ('p0010000-0000-0000-0000-000000000010', 'Bicicleta mountain bike Aro 29 - perfeita para trilhas', 'https://picsum.photos/400/400?random=10', 'PRODUCT', 'd0e1f2a3-b4c5-6789-defa-890123456789', 72, 18, NOW()),
  ('p0010000-0000-0000-0000-000000000011', 'O que vocês acham do novo iPhone 16?', 'https://picsum.photos/400/400?random=11', 'REGULAR', 'e1f2a3b4-c5d6-7890-efab-901234567890', 156, 89, NOW()),
  ('p0010000-0000-0000-0000-000000000012', 'Guitarra Fender Stratocaster - som incrível!', 'https://picsum.photos/400/400?random=12', 'PRODUCT', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 38, 9, NOW()),
  ('p0010000-0000-0000-0000-000000000013', 'Meu setup de home office completa', 'https://picsum.photos/400/400?random=13', 'REGULAR', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 201, 45, NOW()),
  ('p0010000-0000-0000-0000-000000000014', 'Vendo Watch Series 9 45mm - funcionando perfeitamente', 'https://picsum.photos/400/400?random=14', 'PRODUCT', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 29, 7, NOW()),
  ('p0010000-0000-0000-0000-000000000015', 'Mesa de jantar 6 cadeiras - madeira maciça', 'https://picsum.photos/400/400?random=15', 'PRODUCT', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 15, 4, NOW())
ON CONFLICT DO NOTHING;

-- ─── Products ───────────────────────────────────────────

INSERT INTO "Product" ("id", "title", "description", "price", "condition", "categoryId", "status", "sellerId", "postId", "updatedAt")
VALUES
  ('prod001-0000-0000-0000-000000000001', 'iPhone 14 Pro Max 256GB', 'iPhone 14 Pro Max em estado perfeito, 95% bateria, acompanha capinha e película.', 650000, 'USED', 'cat001-0000-0000-0000-000000000005', 'ACTIVE', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('prod001-0000-0000-0000-000000000002', 'Nike Air Max 90', 'Tamanho 42, usado apenas 2 vezes, originais com nota fiscal.', 45000, 'USED', 'cat001-0000-0000-0000-000000000003', 'ACTIVE', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000002', NOW()),
  ('prod001-0000-0000-0000-000000000003', 'MacBook Pro 2021 M1', '16GB RAM, 512GB SSD, teclado PT-BR, sem detalhes.', 750000, 'USED', 'cat001-0000-0000-0000-000000000006', 'ACTIVE', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'p0010000-0000-0000-0000-000000000004', NOW()),
  ('prod001-0000-0000-0000-000000000004', 'Vestido Vintage Anos 80', 'Lindíssimo vestido retrô, tamanho M, tecido de alta qualidade.', 15000, 'USED', 'cat001-0000-0000-0000-000000000002', 'ACTIVE', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'p0010000-0000-0000-0000-000000000005', NOW()),
  ('prod001-0000-0000-0000-000000000005', 'PlayStation 5 + 2 Jogos', 'PS5 padrão, jogos inclusos: God of War e Spider-Man.', 320000, 'USED', 'cat001-0000-0000-0000-000000000011', 'ACTIVE', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'p0010000-0000-0000-0000-000000000006', NOW()),
  ('prod001-0000-0000-0000-000000000006', 'iPad Air 4 64GB', '4ª geração, WiFi, espaço cinza, com Magic Keyboard.', 280000, 'USED', 'cat001-0000-0000-0000-000000000005', 'ACTIVE', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'p0010000-0000-0000-0000-000000000008', NOW()),
  ('prod001-0000-0000-0000-000000000007', 'Coleção Harry Potter', 'Todos os 7 volumes, edição hardcover, condições mínimas de uso.', 18000, 'USED', 'cat001-0000-0000-0000-000000000008', 'ACTIVE', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'p0010000-0000-0000-0000-000000000009', NOW()),
  ('prod001-0000-0000-0000-000000000008', 'Bicicleta Mountain Bike Aro 29', 'Quadro alumínio, suspensão DiBL, freios a disco hidráulicos.', 120000, 'USED', 'cat001-0000-0000-0000-000000000009', 'ACTIVE', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'p0010000-0000-0000-0000-000000000010', NOW()),
  ('prod001-0000-0000-0000-000000000009', 'Guitarra Fender Stratocaster', 'Stratocaster Standard, sonora, case rígido inclusso.', 380000, 'USED', 'cat001-0000-0000-0000-000000000012', 'ACTIVE', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'p0010000-0000-0000-0000-000000000012', NOW()),
  ('prod001-0000-0000-0000-000000000010', 'Apple Watch Series 9 45mm', 'Caixa de alumínio midnight, bracelete esportiva, funcionando 100%.', 220000, 'USED', 'cat001-0000-0000-0000-000000000005', 'ACTIVE', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'p0010000-0000-0000-0000-000000000014', NOW()),
  ('prod001-0000-0000-0000-000000000011', 'Mesa de Jantar 6 Cadeiras', 'Mesa de madeira maciça, 6 cadeiras estofadas,的状态良好.', 85000, 'USED', 'cat001-0000-0000-0000-000000000007', 'ACTIVE', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'p0010000-0000-0000-0000-000000000015', NOW()),
  ('prod001-0000-0000-0000-000000000012', 'Samsung Galaxy S23 Ultra', '256GB, estado excelente, sem riscos, bateria 95%.', 480000, 'USED', 'cat001-0000-0000-0000-000000000005', 'ACTIVE', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('prod001-0000-0000-0000-000000000013', 'Jaqueta de Couro Vintage', 'Jaqueta de couro legítimo tamanho G, estilo motociclista.', 22000, 'USED', 'cat001-0000-0000-0000-000000000002', 'ACTIVE', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000002', NOW()),
  ('prod001-0000-0000-0000-000000000014', 'Fone Sony WH-1000XM4', 'Cancelamento de ruído, bateria excelente, completo.', 35000, 'USED', 'cat001-0000-0000-0000-000000000001', 'ACTIVE', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'p0010000-0000-0000-0000-000000000004', NOW()),
  ('prod001-0000-0000-0000-000000000015', 'Mochila Nike Original', 'Mochila esportiva, capacidade 30L, resistente à água.', 8000, 'NEW', 'cat001-0000-0000-0000-000000000004', 'ACTIVE', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'p0010000-0000-0000-0000-000000000005', NOW())
ON CONFLICT DO NOTHING;

-- ─── Stories ─────────────────────────────────────────────

INSERT INTO "Story" ("id", "userId", "imageUrl", "expiresAt", "createdAt")
VALUES
  ('stry001-0000-0000-0000-0000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'https://picsum.photos/300/500?random=21', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000002', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'https://picsum.photos/300/500?random=22', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000003', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'https://picsum.photos/300/500?random=23', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000004', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'https://picsum.photos/300/500?random=24', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000005', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'https://picsum.photos/300/500?random=25', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000006', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'https://picsum.photos/300/500?random=26', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000007', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'https://picsum.photos/300/500?random=27', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000008', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'https://picsum.photos/300/500?random=28', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000009', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'https://picsum.photos/300/500?random=29', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000010', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'https://picsum.photos/300/500?random=30', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000011', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 'https://picsum.photos/300/500?random=31', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000012', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'https://picsum.photos/300/500?random=32', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000013', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'https://picsum.photos/300/500?random=33', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000014', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'https://picsum.photos/300/500?random=34', NOW() + INTERVAL '24 hours', NOW()),
  ('stry001-0000-0000-0000-0000000015', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'https://picsum.photos/300/500?random=35', NOW() + INTERVAL '24 hours', NOW())
ON CONFLICT DO NOTHING;

-- ─── Follows ────────────────────────────────────────────

INSERT INTO "Follow" ("id", "followerId", "followingId")
VALUES
  ('flw001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
  ('flw001-0000-0000-0000-0000000002', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'c3d4e5f6-a7b8-9012-cdef-123456789012'),
  ('flw001-0000-0000-0000-0000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'c3d4e5f6-a7b8-9012-cdef-123456789012'),
  ('flw001-0000-0000-0000-0000000004', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
  ('flw001-0000-0000-0000-0000000005', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
  ('flw001-0000-0000-0000-0000000006', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'c3d4e5f6-a7b8-9012-cdef-123456789012'),
  ('flw001-0000-0000-0000-0000000007', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'd4e5f6a7-b8c9-0123-defa-234567890123'),
  ('flw001-0000-0000-0000-0000000008', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'e5f6a7b8-c9d0-1234-efab-345678901234'),
  ('flw001-0000-0000-0000-0000000009', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'f6a7b8c9-d0e1-2345-fabc-456789012345'),
  ('flw001-0000-0000-0000-0000000010', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'a7b8c9d0-e1f2-3456-abcd-567890123456'),
  ('flw001-0000-0000-0000-0000000011', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'b8c9d0e1-f2a3-4567-bcde-678901234567'),
  ('flw001-0000-0000-0000-0000000012', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'c9d0e1f2-a3b4-5678-cdef-789012345678'),
  ('flw001-0000-0000-0000-0000000013', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 'd0e1f2a3-b4c5-6789-defa-890123456789'),
  ('flw001-0000-0000-0000-0000000014', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'e1f2a3b4-c5d6-7890-efab-901234567890'),
  ('flw001-0000-0000-0000-0000000015', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
ON CONFLICT DO NOTHING;

-- ─── Likes ──────────────────────────────────────────────

INSERT INTO "Like" ("id", "userId", "postId", "createdAt")
VALUES
  ('lik001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('lik001-0000-0000-0000-0000000002', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('lik001-0000-0000-0000-0000000003', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('lik001-0000-0000-0000-0000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'p0010000-0000-0000-0000-000000000003', NOW()),
  ('lik001-0000-0000-0000-0000000005', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000006', NOW()),
  ('lik001-0000-0000-0000-0000000006', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'p0010000-0000-0000-0000-000000000009', NOW()),
  ('lik001-0000-0000-0000-0000000007', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'p0010000-0000-0000-0000-000000000010', NOW()),
  ('lik001-0000-0000-0000-0000000008', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'p0010000-0000-0000-0000-000000000011', NOW()),
  ('lik001-0000-0000-0000-0000000009', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'p0010000-0000-0000-0000-000000000011', NOW()),
  ('lik001-0000-0000-0000-0000000010', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'p0010000-0000-0000-0000-000000000011', NOW()),
  ('lik001-0000-0000-0000-0000000011', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'p0010000-0000-0000-0000-000000000013', NOW()),
  ('lik001-0000-0000-0000-0000000012', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'p0010000-0000-0000-0000-000000000013', NOW()),
  ('lik001-0000-0000-0000-0000000013', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 'p0010000-0000-0000-0000-000000000013', NOW()),
  ('lik001-0000-0000-0000-0000000014', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'p0010000-0000-0000-0000-000000000004', NOW()),
  ('lik001-0000-0000-0000-0000000015', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'p0010000-0000-0000-0000-000000000005', NOW())
ON CONFLICT DO NOTHING;

-- ─── Comments ───────────────────────────────────────────

INSERT INTO "Comment" ("id", "content", "userId", "postId", "createdAt")
VALUES
  ('cmt001-0000-0000-0000-0000000001', 'Interessado! Qual o menor preço?', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('cmt001-0000-0000-0000-0000000002', 'Parcela no cartão?', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('cmt001-0000-0000-0000-0000000003', 'Linda peça! ainda disponível?', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'p0010000-0000-0000-0000-000000000002', NOW()),
  ('cmt001-0000-0000-0000-0000000004', 'Recomendo o brechó da Rua Augusta!', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'p0010000-0000-0000-0000-000000000003', NOW()),
  ('cmt001-0000-0000-0000-0000000005', 'Show de setup!', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'p0010000-0000-0000-0000-000000000013', NOW()),
  ('cmt001-0000-0000-0000-0000000006', 'Muito bonito!', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'p0010000-0000-0000-0000-000000000013', NOW()),
  ('cmt001-0000-0000-0000-0000000007', 'Qual o tamanho?', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'p0010000-0000-0000-0000-000000000005', NOW()),
  ('cmt001-0000-0000-0000-0000000008', 'Bateria original?', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'p0010000-0000-0000-0000-000000000001', NOW()),
  ('cmt001-0000-0000-0000-0000000009', 'Vem com Nota Fiscal?', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'p0010000-0000-0000-0000-000000000004', NOW()),
  ('cmt001-0000-0000-0000-0000000010', 'Qual a marca do quadro?', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'p0010000-0000-0000-0000-000000000010', NOW()),
  ('cmt001-0000-0000-0000-0000000011', 'Me interesa!', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'p0010000-0000-0000-0000-000000000006', NOW()),
  ('cmt001-0000-0000-0000-0000000012', 'Qual a cor?', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'p0010000-0000-0000-0000-000000000014', NOW()),
  ('cmt001-0000-0000-0000-0000000013', 'Tem interesse em troca?', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'p0010000-0000-0000-0000-000000000012', NOW()),
  ('cmt001-0000-0000-0000-0000000014', 'Lindão!', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 'p0010000-0000-0000-0000-000000000002', NOW()),
  ('cmt001-0000-0000-0000-0000000015', 'Show de laptop!', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'p0010000-0000-0000-0000-000000000004', NOW())
ON CONFLICT DO NOTHING;
