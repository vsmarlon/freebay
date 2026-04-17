-- ─── Categories ────────────────────────────────────────────

INSERT INTO "Category" ("id", "name", "slug", "parentId", "createdAt", "updatedAt")
VALUES
  ('cat001-0000-0000-0000-000000000001', 'Eletrônicos',           'eletronicos',           NULL, NOW(), NOW()),
  ('cat002-0000-0000-0000-000000000002', 'Moda',                  'moda',                  NULL, NOW(), NOW()),
  ('cat003-0000-0000-0000-000000000003', 'Games',                 'games',                 NULL, NOW(), NOW()),
  ('cat004-0000-0000-0000-000000000004', 'Instrumentos Musicais', 'instrumentos-musicais', NULL, NOW(), NOW()),
  ('cat005-0000-0000-0000-000000000005', 'Móveis e Decoração',    'moveis-decoracao',      NULL, NOW(), NOW()),
  ('cat006-0000-0000-0000-000000000006', 'Livros',                'livros',                NULL, NOW(), NOW()),
  ('cat007-0000-0000-0000-000000000007', 'Esportes',              'esportes',              NULL, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ─── Users ─────────────────────────────────────────────────

INSERT INTO "User" ("id", "displayName", "email", "emailVerified", "passwordHash", "isVerified", "isGuest", "role", "reputationScore", "totalReviews", "createdAt", "updatedAt")
VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Carlos Silva',    'carlos.silva@email.com',    true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', true,  false, 'USER', 4.8, 12, NOW() - INTERVAL '180 days', NOW()),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Ana Beatriz',     'ana.beatriz@email.com',     true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.5,  5, NOW() - INTERVAL '120 days', NOW()),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'Rafael Mendes',   'rafael.mendes@email.com',   true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.2,  8, NOW() - INTERVAL '90 days',  NOW()),
  ('d4e5f6a7-b8c9-0123-defa-234567890123', 'Juliana Costa',   'juliana.costa@email.com',   true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', true,  false, 'USER', 4.9, 20, NOW() - INTERVAL '200 days', NOW()),
  ('e5f6a7b8-c9d0-1234-efab-345678901234', 'Mateus Oliveira', 'mateus.oliveira@email.com', true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 3.8,  4, NOW() - INTERVAL '60 days',  NOW()),
  ('f6a7b8c9-d0e1-2345-fabc-456789012345', 'Fernanda Lima',   'fernanda.lima@email.com',   true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', true,  false, 'USER', 4.7, 15, NOW() - INTERVAL '150 days', NOW()),
  ('a7b8c9d0-e1f2-3456-abcd-567890123456', 'Pedro Alves',     'pedro.alves@email.com',     true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.1,  3, NOW() - INTERVAL '45 days',  NOW()),
  ('b8c9d0e1-f2a3-4567-bcde-678901234567', 'Larissa Santos',  'larissa.santos@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.0,  6, NOW() - INTERVAL '75 days',  NOW()),
  ('c9d0e1f2-a3b4-5678-cdef-789012345678', 'Diego Ferreira',  'diego.ferreira@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.3,  9, NOW() - INTERVAL '100 days', NOW()),
  ('d0e1f2a3-b4c5-6789-defa-890123456789', 'Gabriela Rocha',  'gabriela.rocha@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.6, 11, NOW() - INTERVAL '130 days', NOW()),
  ('e1f2a3b4-c5d6-7890-efab-901234567890', 'Lucas Martins',   'lucas.martins@email.com',   true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 3.5,  2, NOW() - INTERVAL '30 days',  NOW()),
  ('f2a3b4c5-d6e7-8901-fabc-012345678901', 'Thiago Barbosa',  'thiago.barbosa@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.4,  7, NOW() - INTERVAL '85 days',  NOW()),
  ('a3b4c5d6-e7f8-9012-abcd-123456789012', 'Camila Pereira',  'camila.pereira@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.0,  4, NOW() - INTERVAL '55 days',  NOW()),
  ('b4c5d6e7-f8a9-0123-bcde-234567890123', 'Henrique Souza',  'henrique.souza@email.com',  true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 4.2,  6, NOW() - INTERVAL '70 days',  NOW()),
  ('c5d6e7f8-a9b0-1234-cdef-345678901234', 'Isabela Gomes',   'isabela.gomes@email.com',   true, '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', false, false, 'USER', 3.9,  5, NOW() - INTERVAL '65 days',  NOW())
ON CONFLICT DO NOTHING;

-- ─── Products ──────────────────────────────────────────────

INSERT INTO "Product" ("id", "title", "description", "price", "condition", "categoryId", "status", "sellerId", "createdAt", "updatedAt")
VALUES
  ('prod001-0000-0000-0000-000000000001', 'iPhone 13 Pro Max 256GB',       'iPhone 13 Pro Max na cor grafite, 256GB. Bateria com 89% de saúde. Acompanha carregador original e caixa.',                  650000, 'USED', 'cat001-0000-0000-0000-000000000001', 'SOLD',   'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NOW() - INTERVAL '30 days', NOW()),
  ('prod001-0000-0000-0000-000000000002', 'Tênis Nike Air Max 270',         'Tênis Nike Air Max 270 tamanho 42, cor branco. Usado poucas vezes, em ótimo estado.',                                          45000, 'USED', 'cat002-0000-0000-0000-000000000002', 'SOLD',   'c3d4e5f6-a7b8-9012-cdef-123456789012', NOW() - INTERVAL '25 days', NOW()),
  ('prod001-0000-0000-0000-000000000003', 'MacBook Pro M1 2021',            'MacBook Pro M1 com 16GB RAM e 512GB SSD. Em perfeito estado, sem arranhões. Acompanha carregador original.',                   750000, 'USED', 'cat001-0000-0000-0000-000000000001', 'SOLD',   'd4e5f6a7-b8c9-0123-defa-234567890123', NOW() - INTERVAL '40 days', NOW()),
  ('prod001-0000-0000-0000-000000000004', 'Vestido Floral Midi',            'Vestido floral midi tamanho M, nunca usado, ainda com etiqueta.',                                                               15000, 'NEW',  'cat002-0000-0000-0000-000000000002', 'SOLD',   'e5f6a7b8-c9d0-1234-efab-345678901234', NOW() - INTERVAL '20 days', NOW()),
  ('prod001-0000-0000-0000-000000000005', 'PS5 + 2 Controles DualSense',   'PlayStation 5 edição padrão com 2 controles DualSense. Todos os jogos funcionando perfeitamente.',                             320000, 'USED', 'cat003-0000-0000-0000-000000000003', 'SOLD',   'f6a7b8c9-d0e1-2345-fabc-456789012345', NOW() - INTERVAL '35 days', NOW()),
  ('prod001-0000-0000-0000-000000000006', 'Headset Sony WH-1000XM4',       'Headset Sony WH-1000XM4 com cancelamento de ruído ativo. Seminovo, acompanha case e cabo.',                                   120000, 'USED', 'cat001-0000-0000-0000-000000000001', 'ACTIVE', 'a7b8c9d0-e1f2-3456-abcd-567890123456', NOW() - INTERVAL '15 days', NOW()),
  ('prod001-0000-0000-0000-000000000007', 'Kit Livros de Programação',     'Kit com 5 livros técnicos: Clean Code, Clean Architecture, DDD, SICP e Pragmatic Programmer.',                                  18000, 'USED', 'cat006-0000-0000-0000-000000000006', 'ACTIVE', 'c9d0e1f2-a3b4-5678-cdef-789012345678', NOW() - INTERVAL '18 days', NOW()),
  ('prod001-0000-0000-0000-000000000008', 'iPad Pro 12.9" M2',             'iPad Pro 12.9" com chip M2, 256GB Wi-Fi + Cellular. Acompanha Apple Pencil 2ª geração.',                                      120000, 'USED', 'cat001-0000-0000-0000-000000000001', 'ACTIVE', 'd0e1f2a3-b4c5-6789-defa-890123456789', NOW() - INTERVAL '22 days', NOW()),
  ('prod001-0000-0000-0000-000000000009', 'Guitarra Fender Stratocaster',  'Guitarra Fender Stratocaster Player Series em cor sunburst. Excelente estado, com case incluído.',                             380000, 'USED', 'cat004-0000-0000-0000-000000000004', 'ACTIVE', 'f2a3b4c5-d6e7-8901-fabc-012345678901', NOW() - INTERVAL '28 days', NOW()),
  ('prod001-0000-0000-0000-000000000010', 'Bicicleta Trek FX3 Disc',       'Bicicleta Trek FX3 Disc aro 700c, tamanho M. Perfeita para uso na cidade e ciclovias.',                                        220000, 'USED', 'cat007-0000-0000-0000-000000000007', 'ACTIVE', 'b4c5d6e7-f8a9-0123-bcde-234567890123', NOW() - INTERVAL '12 days', NOW()),
  ('prod001-0000-0000-0000-000000000011', 'Mesa de Jantar Madeira 6L',     'Mesa de jantar em madeira maciça para 6 pessoas. Pequeno risco na lateral conforme fotos.',                                    85000, 'USED', 'cat005-0000-0000-0000-000000000005', 'ACTIVE', 'c5d6e7f8-a9b0-1234-cdef-345678901234', NOW() - INTERVAL '50 days', NOW()),
  ('prod001-0000-0000-0000-000000000012', 'Nintendo Switch OLED + Jogos',  'Nintendo Switch OLED na cor branca. Acompanha 5 jogos físicos. Zerado, sem marcas de uso.',                                    480000, 'NEW',  'cat003-0000-0000-0000-000000000003', 'SOLD',   'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NOW() - INTERVAL '60 days', NOW()),
  ('prod001-0000-0000-0000-000000000013', 'Câmera Canon EOS R5',           'Câmera mirrorless Canon EOS R5 corpo. Apenas 5.000 disparos. Acompanha bateria e carregador.',                                 950000, 'USED', 'cat001-0000-0000-0000-000000000001', 'ACTIVE', 'b8c9d0e1-f2a3-4567-bcde-678901234567', NOW() - INTERVAL '10 days', NOW()),
  ('prod001-0000-0000-0000-000000000014', 'Sofá 3 Lugares Veludo',         'Sofá 3 lugares em veludo cinza. Bom estado, pequenos desgastes normais de uso.',                                                280000, 'USED', 'cat005-0000-0000-0000-000000000005', 'ACTIVE', 'e1f2a3b4-c5d6-7890-efab-901234567890', NOW() - INTERVAL '8 days',  NOW()),
  ('prod001-0000-0000-0000-000000000015', 'Vestido de Festa Longo',        'Vestido de festa longo na cor vinho, tamanho P. Usado apenas uma vez em casamento.',                                             25000, 'USED', 'cat002-0000-0000-0000-000000000002', 'ACTIVE', 'a3b4c5d6-e7f8-9012-abcd-123456789012', NOW() - INTERVAL '5 days',  NOW())
ON CONFLICT DO NOTHING;

-- ─── ProductImages ────────────────────────────────────────

INSERT INTO "ProductImage" ("id", "url", "order", "productId")
VALUES
  ('pimg001-0000-0000-0000-0000000001', 'https://picsum.photos/800/800?random=101', 0, 'prod001-0000-0000-0000-000000000001'),
  ('pimg001-0000-0000-0000-0000000002', 'https://picsum.photos/800/800?random=102', 1, 'prod001-0000-0000-0000-000000000001'),
  ('pimg001-0000-0000-0000-0000000003', 'https://picsum.photos/800/800?random=103', 2, 'prod001-0000-0000-0000-000000000001'),
  ('pimg001-0000-0000-0000-0000000004', 'https://picsum.photos/800/800?random=104', 0, 'prod001-0000-0000-0000-000000000002'),
  ('pimg001-0000-0000-0000-0000000005', 'https://picsum.photos/800/800?random=105', 1, 'prod001-0000-0000-0000-000000000002'),
  ('pimg001-0000-0000-0000-0000000006', 'https://picsum.photos/800/800?random=106', 0, 'prod001-0000-0000-0000-000000000003'),
  ('pimg001-0000-0000-0000-0000000007', 'https://picsum.photos/800/800?random=107', 1, 'prod001-0000-0000-0000-000000000003'),
  ('pimg001-0000-0000-0000-0000000008', 'https://picsum.photos/800/800?random=108', 2, 'prod001-0000-0000-0000-000000000003'),
  ('pimg001-0000-0000-0000-0000000009', 'https://picsum.photos/800/800?random=109', 3, 'prod001-0000-0000-0000-000000000003'),
  ('pimg001-0000-0000-0000-0000000010', 'https://picsum.photos/800/800?random=110', 0, 'prod001-0000-0000-0000-000000000004'),
  ('pimg001-0000-0000-0000-0000000011', 'https://picsum.photos/800/800?random=111', 1, 'prod001-0000-0000-0000-000000000004'),
  ('pimg001-0000-0000-0000-0000000012', 'https://picsum.photos/800/800?random=112', 0, 'prod001-0000-0000-0000-000000000005'),
  ('pimg001-0000-0000-0000-0000000013', 'https://picsum.photos/800/800?random=113', 1, 'prod001-0000-0000-0000-000000000005'),
  ('pimg001-0000-0000-0000-0000000014', 'https://picsum.photos/800/800?random=114', 2, 'prod001-0000-0000-0000-000000000005'),
  ('pimg001-0000-0000-0000-0000000015', 'https://picsum.photos/800/800?random=115', 0, 'prod001-0000-0000-0000-000000000006'),
  ('pimg001-0000-0000-0000-0000000016', 'https://picsum.photos/800/800?random=116', 1, 'prod001-0000-0000-0000-000000000006'),
  ('pimg001-0000-0000-0000-0000000017', 'https://picsum.photos/800/800?random=117', 0, 'prod001-0000-0000-0000-000000000007'),
  ('pimg001-0000-0000-0000-0000000018', 'https://picsum.photos/800/800?random=118', 1, 'prod001-0000-0000-0000-000000000007'),
  ('pimg001-0000-0000-0000-0000000019', 'https://picsum.photos/800/800?random=119', 2, 'prod001-0000-0000-0000-000000000007'),
  ('pimg001-0000-0000-0000-0000000020', 'https://picsum.photos/800/800?random=120', 0, 'prod001-0000-0000-0000-000000000008'),
  ('pimg001-0000-0000-0000-0000000021', 'https://picsum.photos/800/800?random=121', 1, 'prod001-0000-0000-0000-000000000008'),
  ('pimg001-0000-0000-0000-0000000022', 'https://picsum.photos/800/800?random=122', 0, 'prod001-0000-0000-0000-000000000009'),
  ('pimg001-0000-0000-0000-0000000023', 'https://picsum.photos/800/800?random=123', 1, 'prod001-0000-0000-0000-000000000009'),
  ('pimg001-0000-0000-0000-0000000024', 'https://picsum.photos/800/800?random=124', 0, 'prod001-0000-0000-0000-000000000010'),
  ('pimg001-0000-0000-0000-0000000025', 'https://picsum.photos/800/800?random=125', 1, 'prod001-0000-0000-0000-000000000010'),
  ('pimg001-0000-0000-0000-0000000026', 'https://picsum.photos/800/800?random=126', 0, 'prod001-0000-0000-0000-000000000011'),
  ('pimg001-0000-0000-0000-0000000027', 'https://picsum.photos/800/800?random=127', 1, 'prod001-0000-0000-0000-000000000011'),
  ('pimg001-0000-0000-0000-0000000028', 'https://picsum.photos/800/800?random=128', 2, 'prod001-0000-0000-0000-000000000011'),
  ('pimg001-0000-0000-0000-0000000029', 'https://picsum.photos/800/800?random=129', 0, 'prod001-0000-0000-0000-000000000012'),
  ('pimg001-0000-0000-0000-0000000030', 'https://picsum.photos/800/800?random=130', 1, 'prod001-0000-0000-0000-000000000012'),
  ('pimg001-0000-0000-0000-0000000031', 'https://picsum.photos/800/800?random=131', 0, 'prod001-0000-0000-0000-000000000013'),
  ('pimg001-0000-0000-0000-0000000032', 'https://picsum.photos/800/800?random=132', 1, 'prod001-0000-0000-0000-000000000013'),
  ('pimg001-0000-0000-0000-0000000033', 'https://picsum.photos/800/800?random=133', 0, 'prod001-0000-0000-0000-000000000014'),
  ('pimg001-0000-0000-0000-0000000034', 'https://picsum.photos/800/800?random=134', 1, 'prod001-0000-0000-0000-000000000014'),
  ('pimg001-0000-0000-0000-0000000035', 'https://picsum.photos/800/800?random=135', 2, 'prod001-0000-0000-0000-000000000014'),
  ('pimg001-0000-0000-0000-0000000036', 'https://picsum.photos/800/800?random=136', 0, 'prod001-0000-0000-0000-000000000015'),
  ('pimg001-0000-0000-0000-0000000037', 'https://picsum.photos/800/800?random=137', 1, 'prod001-0000-0000-0000-000000000015')
ON CONFLICT DO NOTHING;

-- ─── Orders ───────────────────────────────────────────────

INSERT INTO "Order" ("id", "buyerId", "sellerId", "productId", "amount", "platformFee", "sellerAmount", "status", "escrowStatus", "meetingScheduledAt", "deliveryConfirmedAt", "createdAt", "updatedAt")
VALUES
  -- Completed orders
  ('ord001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'prod001-0000-0000-0000-000000000001', 650000, 65000, 585000, 'COMPLETED', 'RELEASED', NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '7 days'),
  ('ord001-0000-0000-0000-0000000002', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'prod001-0000-0000-0000-000000000002', 45000, 4500, 40500, 'COMPLETED', 'RELEASED', NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 days'),
  ('ord001-0000-0000-0000-0000000003', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'prod001-0000-0000-0000-000000000003', 750000, 75000, 675000, 'COMPLETED', 'RELEASED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day'),
  ('ord001-0000-0000-0000-0000000004', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'prod001-0000-0000-0000-000000000004', 15000, 1500, 13500, 'COMPLETED', 'RELEASED', NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '6 days'),
  ('ord001-0000-0000-0000-0000000005', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'prod001-0000-0000-0000-000000000005', 320000, 32000, 288000, 'COMPLETED', 'RELEASED', NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '6 days'),
  -- Confirmed (in progress)
  ('ord001-0000-0000-0000-0000000006', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'prod001-0000-0000-0000-000000000007', 18000, 1800, 16200, 'CONFIRMED', 'HELD', NOW() + INTERVAL '2 days', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
  ('ord001-0000-0000-0000-0000000007', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'prod001-0000-0000-0000-000000000008', 120000, 12000, 108000, 'CONFIRMED', 'HELD', NOW() + INTERVAL '1 day', NULL, NOW() - INTERVAL '1 day', NOW()),
  -- Pending
  ('ord001-0000-0000-0000-0000000008', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'prod001-0000-0000-0000-000000000009', 380000, 38000, 342000, 'PENDING', 'HELD', NULL, NULL, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
  ('ord001-0000-0000-0000-0000000009', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'b4c5d6e7-f8a9-0123-bcde-234567890123', 'prod001-0000-0000-0000-000000000010', 220000, 22000, 198000, 'PENDING', 'HELD', NULL, NULL, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),
  -- Disputed
  ('ord001-0000-0000-0000-0000000010', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'prod001-0000-0000-0000-000000000011', 85000, 8500, 76500, 'DISPUTED', 'HELD', NULL, NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '2 days'),
  -- Cancelled
  ('ord001-0000-0000-0000-0000000011', 'a3b4c5d6-e7f8-9012-abcd-123456789012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'prod001-0000-0000-0000-000000000012', 480000, 48000, 432000, 'CANCELLED', 'REFUNDED', NULL, NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days')
ON CONFLICT DO NOTHING;

-- ─── Transactions ─────────────────────────────────────────

INSERT INTO "Transaction" ("id", "orderId", "externalId", "amount", "platformFee", "sellerAmount", "paymentMethod", "provider", "status", "idempotencyKey", "pixQrCode", "pixExpiresAt", "paidAt", "releasedAt", "createdAt", "updatedAt")
VALUES
  ('txn001-0000-0000-0000-0000000001', 'ord001-0000-0000-0000-0000000001', 'ext_abc123', 650000, 65000, 585000, 'PIX', 'PAGARME', 'RELEASED', 'idem_abc123', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '7 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '5 days'),
  ('txn001-0000-0000-0000-0000000002', 'ord001-0000-0000-0000-0000000002', 'ext_def456', 45000, 4500, 40500, 'PIX', 'PAGARME', 'RELEASED', 'idem_def456', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days'),
  ('txn001-0000-0000-0000-0000000003', 'ord001-0000-0000-0000-0000000003', 'ext_ghi789', 750000, 75000, 675000, 'CREDIT_CARD', 'PAGARME', 'RELEASED', 'idem_ghi789', NULL, NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day'),
  ('txn001-0000-0000-0000-0000000004', 'ord001-0000-0000-0000-0000000004', 'ext_jkl012', 15000, 1500, 13500, 'PIX', 'WOOVI', 'RELEASED', 'idem_jkl012', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '6 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '4 days'),
  ('txn001-0000-0000-0000-0000000005', 'ord001-0000-0000-0000-0000000005', 'ext_mno345', 320000, 32000, 288000, 'PIX', 'PAGARME', 'RELEASED', 'idem_mno345', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '12 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '6 days'),
  ('txn001-0000-0000-0000-0000000006', 'ord001-0000-0000-0000-0000000006', 'ext_pqr678', 18000, 1800, 16200, 'PIX', 'WOOVI', 'HELD', 'idem_pqr678', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '2 days', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
  ('txn001-0000-0000-0000-0000000007', 'ord001-0000-0000-0000-0000000007', 'ext_stu901', 120000, 12000, 108000, 'PIX', 'PAGARME', 'HELD', 'idem_stu901', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '1 day', NULL, NOW() - INTERVAL '1 day', NOW()),
  ('txn001-0000-0000-0000-0000000008', 'ord001-0000-0000-0000-0000000008', 'ext_vwx234', 380000, 38000, 342000, 'PIX', 'PAGARME', 'PENDING', 'idem_vwx234', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NULL, NULL, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
  ('txn001-0000-0000-0000-0000000009', 'ord001-0000-0000-0000-0000000009', 'ext_yza567', 220000, 22000, 198000, 'PIX', 'WOOVI', 'PENDING', 'idem_yza567', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NULL, NULL, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),
  ('txn001-0000-0000-0000-0000000010', 'ord001-0000-0000-0000-0000000010', 'ext_bcd890', 85000, 8500, 76500, 'PIX', 'PAGARME', 'HELD', 'idem_bcd890', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '4 days', NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '2 days'),
  ('txn001-0000-0000-0000-0000000011', 'ord001-0000-0000-0000-0000000011', 'ext_efg123', 480000, 48000, 432000, 'PIX', 'PAGARME', 'REFUNDED', 'idem_efg123', '00020126580014br.gov.bcb.pix', NOW() + INTERVAL '1 day', NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days')
ON CONFLICT DO NOTHING;

-- ─── ChatMessages ─────────────────────────────────────────

INSERT INTO "ChatMessage" ("id", "orderId", "senderId", "content", "readAt", "createdAt")
VALUES
  -- Order 1 (completed)
  ('msg001-0000-0000-0000-0000000001', 'ord001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Olá! Gostaria de comprar o iPhone.', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('msg001-0000-0000-0000-0000000002', 'ord001-0000-0000-0000-0000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Olá! Sim, ainda está disponível. Pode fazer o pagamento via PIX.', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('msg001-0000-0000-0000-0000000003', 'ord001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Ok, já realizei o pagamento!', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('msg001-0000-0000-0000-0000000004', 'ord001-0000-0000-0000-0000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Perfeito! Vou confirmar e enviar o produto amanhã.', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  ('msg001-0000-0000-0000-0000000005', 'ord001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Recebi! Tudo certo, muito obrigado!', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  -- Order 2 (completed)
  ('msg001-0000-0000-0000-0000000006', 'ord001-0000-0000-0000-0000000002', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'O tênis ainda está disponível no tamanho 42?', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('msg001-0000-0000-0000-0000000007', 'ord001-0000-0000-0000-0000000002', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Sim, está disponível!', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('msg001-0000-0000-0000-0000000008', 'ord001-0000-0000-0000-0000000002', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Perfeito! Vou comprar.', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  -- Order 3 (completed - with meeting)
  ('msg001-0000-0000-0000-0000000009', 'ord001-0000-0000-0000-0000000003', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'Oi,vim buscar o notebook. Onde podemos nos encontrar?', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
  ('msg001-0000-0000-0000-0000000010', 'ord001-0000-0000-0000-0000000003', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Podemos nos encontrar na Av. Paulista às 15h. Está bom?', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
  ('msg001-0000-0000-0000-0000000011', 'ord001-0000-0000-0000-0000000003', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'Perfeito! Vou estar lá.', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
  ('msg001-0000-0000-0000-0000000012', 'ord001-0000-0000-0000-0000000003', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'Já recebi o notebook, está tudo funcionando perfeitamente!', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  -- Order 6 (confirmed - with scheduled meeting)
  ('msg001-0000-0000-0000-0000000013', 'ord001-0000-0000-0000-0000000006', 'b8c9d0e1-f2a3-4567-bcde-678901234567', 'Olá! Posso buscar os livros amanhã?', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('msg001-0000-0000-0000-0000000014', 'ord001-0000-0000-0000-0000000006', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'Claro! Que horário?', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('msg001-0000-0000-0000-0000000015', 'ord001-0000-0000-0000-0000000006', 'b8c9d0e1-f2a3-4567-bcde-678901234567', '14h está bom?', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('msg001-0000-0000-0000-0000000016', 'ord001-0000-0000-0000-0000000006', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 'Perfeito! Até amanhã então.', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  -- Order 8 (pending - just started)
  ('msg001-0000-0000-0000-0000000017', 'ord001-0000-0000-0000-0000000008', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'Olá! Tenho interesse na guitarra.', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
  ('msg001-0000-0000-0000-0000-0000000018', 'ord001-0000-0000-0000-0000000008', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'Olá! Sim, ainda tenho. Já toca algum instrumento?', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours'),
  ('msg001-0000-0000-0000-0000000019', 'ord001-0000-0000-0000-0000000008', 'd0e1f2a3-b4c5-6789-defa-890123456789', 'Toco violão, sempre quis aprender guitarra!', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
  -- Order 10 (disputed)
  ('msg001-0000-0000-0000-0000000020', 'ord001-0000-0000-0000-0000000010', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'A mesa veio com um raya, não estava descrito.', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  ('msg001-0000-0000-0000-0000000021', 'ord001-0000-0000-0000-0000000010', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'Entendo, posso oferecer um desconto ou você pode devolver.', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('msg001-0000-0000-0000-0000000022', 'ord001-0000-0000-0000-0000000010', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'Prefiro abrir disputa e devolver. O produto não corresponde ao anúncio.', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- ─── Reviews ───────────────────────────────────────────────

INSERT INTO "Review" ("id", "reviewerId", "reviewedId", "orderId", "type", "score", "comment", "createdAt")
VALUES
  -- Order 1 reviews
  ('rev001-0000-0000-0000-0000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'ord001-0000-0000-0000-0000000001', 'BUYER_REVIEWING_SELLER', 5, 'Produto exatamente como descrito, vendedor muito atencioso!', NOW() - INTERVAL '5 days'),
  ('rev001-0000-0000-0000-0000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'ord001-0000-0000-0000-0000000001', 'SELLER_REVIEWING_BUYER', 5, 'Pagamento rápido, buyer muito educado!', NOW() - INTERVAL '5 days'),
  -- Order 2 reviews
  ('rev001-0000-0000-0000-0000000003', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'ord001-0000-0000-0000-0000000002', 'BUYER_REVIEWING_SELLER', 4, 'Tênis bonito, mas demorou um pouco para enviar.', NOW() - INTERVAL '3 days'),
  ('rev001-0000-0000-0000-0000000004', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'ord001-0000-0000-0000-0000000002', 'SELLER_REVIEWING_BUYER', 5, 'Ótimo buyer, recomendo!', NOW() - INTERVAL '3 days'),
  -- Order 3 reviews
  ('rev001-0000-0000-0000-0000000005', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'ord001-0000-0000-0000-0000000003', 'BUYER_REVIEWING_SELLER', 5, 'MacBook Perfeito! Funciona muito bem.', NOW() - INTERVAL '1 day'),
  ('rev001-0000-0000-0000-0000000006', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'ord001-0000-0000-0000-0000000003', 'SELLER_REVIEWING_BUYER', 5, 'Excelente buyer, pontual e educado!', NOW() - INTERVAL '1 day'),
  -- Order 4 reviews
  ('rev001-0000-0000-0000-0000000007', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'ord001-0000-0000-0000-0000000004', 'BUYER_REVIEWING_SELLER', 4, 'Vestido lindo, mas pequeno.', NOW() - INTERVAL '4 days'),
  -- Order 5 reviews
  ('rev001-0000-0000-0000-0000000008', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'ord001-0000-0000-0000-0000000005', 'BUYER_REVIEWING_SELLER', 5, 'PS5 Original, jogos funcionando. Recomendo!', NOW() - INTERVAL '6 days'),
  ('rev001-0000-0000-0000-0000000009', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'a7b8c9d0-e1f2-3456-abcd-567890123456', 'ord001-0000-0000-0000-0000000005', 'SELLER_REVIEWING_BUYER', 5, 'Buyer muito educado, realizou o pagamento rapidamente!', NOW() - INTERVAL '6 days')
ON CONFLICT DO NOTHING;
-- ─── Wallets ───────────────────────────────────────────────

INSERT INTO "Wallet" ("id", "userId", "availableBalance", "pendingBalance", "totalEarned", "recipientId")
VALUES
  ('wal001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 150000, 0, 585000, 'rec_123456'),
  ('wal001-0000-0000-0000-000000000002', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 40500, 0, 40500, 'rec_234567'),
  ('wal001-0000-0000-0000-000000000003', 'd4e5f6a7-b8c9-0123-defa-234567890123', 600000, 0, 675000, 'rec_345678'),
  ('wal001-0000-0000-0000-000000000004', 'c9d0e1f2-a3b4-5678-cdef-789012345678', 0, 16200, 0, NULL),
  ('wal001-0000-0000-0000-000000000005', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 0, 342000, 0, NULL)
ON CONFLICT DO NOTHING;

-- ─── Withdrawals ───────────────────────────────────────────

INSERT INTO "Withdrawal" ("id", "walletId", "amount", "status", "createdAt")
VALUES
  ('wth001-0000-0000-0000-000000000001', 'wal001-0000-0000-0000-000000000001', 435000, 'COMPLETED', NOW() - INTERVAL '4 days'),
  ('wth001-0000-0000-0000-000000000002', 'wal001-0000-0000-0000-000000000003', 75000, 'PENDING', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;

-- ─── Posts ─────────────────────────────────────────────────

INSERT INTO "Post" ("id", "content", "imageUrl", "type", "userId", "likesCount", "commentsCount", "sharesCount", "createdAt", "updatedAt")
VALUES
  ('pst001-0000-0000-0000-000000000001', 'Acabei de postar um iPhone 13 novinho! Confiram na minha loja.', 'https://picsum.photos/800/800?random=201', 'PRODUCT', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 5, 2, 1, NOW() - INTERVAL '30 days', NOW()),
  ('pst001-0000-0000-0000-000000000002', 'Alguém procurando um MacBook M1 em perfeito estado?', NULL, 'PRODUCT', 'd4e5f6a7-b8c9-0123-defa-234567890123', 12, 1, 3, NOW() - INTERVAL '40 days', NOW()),
  ('pst001-0000-0000-0000-000000000003', 'Muito feliz com as vendas deste mês! Agradeço a todos os clientes.', NULL, 'REGULAR', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 8, 0, 0, NOW() - INTERVAL '2 days', NOW())
ON CONFLICT DO NOTHING;

-- (Optional) Link the Products to their respective Posts
UPDATE "Product" SET "postId" = 'pst001-0000-0000-0000-000000000001' WHERE "id" = 'prod001-0000-0000-0000-000000000001';
UPDATE "Product" SET "postId" = 'pst001-0000-0000-0000-000000000002' WHERE "id" = 'prod001-0000-0000-0000-000000000003';

-- ─── Comments ──────────────────────────────────────────────

INSERT INTO "Comment" ("id", "content", "userId", "postId", "parentId", "createdAt")
VALUES
  ('cmt001-0000-0000-0000-000000000001', 'Aceita troca?', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'pst001-0000-0000-0000-000000000001', NULL, NOW() - INTERVAL '29 days'),
  ('cmt001-0000-0000-0000-000000000002', 'Apenas venda, amigo.', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'pst001-0000-0000-0000-000000000001', 'cmt001-0000-0000-0000-000000000001', NOW() - INTERVAL '29 days'),
  ('cmt001-0000-0000-0000-000000000003', 'Qual a duração da bateria?', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'pst001-0000-0000-0000-000000000002', NULL, NOW() - INTERVAL '39 days')
ON CONFLICT DO NOTHING;

-- ─── Likes ─────────────────────────────────────────────────

INSERT INTO "Like" ("id", "userId", "postId", "createdAt")
VALUES
  ('lik001-0000-0000-0000-000000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'pst001-0000-0000-0000-000000000001', NOW() - INTERVAL '29 days'),
  ('lik001-0000-0000-0000-000000000002', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'pst001-0000-0000-0000-000000000002', NOW() - INTERVAL '39 days'),
  ('lik001-0000-0000-0000-000000000003', 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'pst001-0000-0000-0000-000000000002', NOW() - INTERVAL '38 days')
ON CONFLICT DO NOTHING;

-- ─── Follows ───────────────────────────────────────────────

INSERT INTO "Follow" ("id", "followerId", "followingId", "createdAt")
VALUES
  ('fol001-0000-0000-0000-000000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NOW() - INTERVAL '60 days'),
  ('fol001-0000-0000-0000-000000000002', 'e5f6a7b8-c9d0-1234-efab-345678901234', 'd4e5f6a7-b8c9-0123-defa-234567890123', NOW() - INTERVAL '50 days'),
  ('fol001-0000-0000-0000-000000000003', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'c5d6e7f8-a9b0-1234-cdef-345678901234', NOW() - INTERVAL '10 days')
ON CONFLICT DO NOTHING;

-- ─── Disputes ──────────────────────────────────────────────

-- Resolving the disputed order #10 between Thiago (buyer) and Isabela (seller)
INSERT INTO "Dispute" ("id", "orderId", "openedById", "status", "reason", "buyerEvidence", "sellerEvidence", "resolution", "resolvedAt", "createdAt", "expiresAt")
VALUES
  ('dsp001-0000-0000-0000-000000000001', 'ord001-0000-0000-0000-0000000010', 'f2a3b4c5-d6e7-8901-fabc-012345678901', 'OPEN', 'Mesa danificada / Diferente do anúncio', '{"photos": ["https://picsum.photos/id/1/200/300"]}', NULL, NULL, NULL, NOW() - INTERVAL '2 days', NOW() + INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- ─── Stories ───────────────────────────────────────────────

INSERT INTO "Story" ("id", "userId", "imageUrl", "expiresAt", "createdAt")
VALUES
  ('sty001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'https://picsum.photos/1080/1920?random=301', NOW() + INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
  ('sty001-0000-0000-0000-000000000002', 'd4e5f6a7-b8c9-0123-defa-234567890123', 'https://picsum.photos/1080/1920?random=302', NOW() + INTERVAL '20 hours', NOW() - INTERVAL '4 hours')
ON CONFLICT DO NOTHING;

-- ─── StoryViews ────────────────────────────────────────────

INSERT INTO "StoryView" ("id", "storyId", "viewerId", "viewedAt")
VALUES
  ('svw001-0000-0000-0000-000000000001', 'sty001-0000-0000-0000-000000000001', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', NOW() - INTERVAL '10 hours'),
  ('svw001-0000-0000-0000-000000000002', 'sty001-0000-0000-0000-000000000001', 'f6a7b8c9-d0e1-2345-fabc-456789012345', NOW() - INTERVAL '5 hours')
ON CONFLICT DO NOTHING;

-- ─── Blocks ────────────────────────────────────────────────

INSERT INTO "Block" ("id", "blockerId", "blockedId", "createdAt")
VALUES
  ('blk001-0000-0000-0000-000000000001', 'c5d6e7f8-a9b0-1234-cdef-345678901234', 'f2a3b4c5-d6e7-8901-fabc-012345678901', NOW() - INTERVAL '1 day') -- Seller blocked buyer after dispute
ON CONFLICT DO NOTHING;

-- ─── Reports ───────────────────────────────────────────────

INSERT INTO "Report" ("id", "reporterId", "reportedUserId", "reportedPostId", "reason", "description", "hideFromUser", "status", "createdAt", "reviewedAt")
VALUES
  ('rpt001-0000-0000-0000-000000000001', 'e1f2a3b4-c5d6-7890-efab-901234567890', 'b4c5d6e7-f8a9-0123-bcde-234567890123', NULL, 'FAKE_ACCOUNT', 'Usuário parou de responder após eu pedir mais fotos do produto.', false, 'PENDING', NOW() - INTERVAL '2 hours', NULL),
  ('rpt001-0000-0000-0000-000000000002', 'a3b4c5d6-e7f8-9012-abcd-123456789012', NULL, 'pst001-0000-0000-0000-000000000001', 'SPAM', 'Postagem duplicada em vários feeds.', true, 'RESOLVED', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days')
ON CONFLICT DO NOTHING;