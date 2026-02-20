-- ============================================================
-- SEEDS COMPLETOS - Ponto do Lanche
-- ============================================================

-- =========================
-- 1. Categorias
-- =========================
INSERT INTO categories (id, name, slug, display_order, is_active)
VALUES
  (1, 'Hambúrguer', 'hamburguer', 1, TRUE),
  (2, 'Bebidas', 'bebidas', 2, TRUE),
  (3, 'Porções', 'porcoes', 3, TRUE),
  (4, 'Acompanhamentos', 'acompanhamentos', 4, TRUE);

-- =========================
-- 2. Produtos
-- =========================
INSERT INTO products (id, category_id, name, description, price, image_url, is_active, is_featured, display_order)
VALUES
  (1, 1, 'Hambúrguer de Carne', 'Pão brioche, hambúrguer artesanal 180g, queijo cheddar, alface, tomate, cebola roxa e molho especial da casa.', 15.99, 'https://tse3.mm.bing.net/th/id/OIP.rUsCsDUIFzVSBGZQ0MUlGQHaLH?cb=defcachec2&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 1),
  (2, 1, 'Hambúrguer de Frango', 'Pão com gergelim, filé de frango grelhado, queijo prato, alface americana, tomate e maionese temperada.', 12.99, 'https://tse3.mm.bing.net/th/id/OIP.kiX438AmpGPnBeTSeuqyqgHaEj?cb=defcachec2&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 2),
  (3, 1, 'Hambúrguer Vegetariano', 'Pão integral, hambúrguer de grão-de-bico e quinoa, queijo muçarela, rúcula, tomate seco e molho pesto.', 10.99, 'https://th.bing.com/th/id/R.ff5222755605c9f728fc627fb5e63f73?rik=kq%2b86fGdW%2bUH0Q&riu=http%3a%2f%2fwww.mundoboaforma.com.br%2fwp-content%2fuploads%2f2015%2f11%2fhamburguer-vegetariano.jpg&ehk=BTuFawO%2bG3gZwfp5HF%2fe82i61WmT7cz7JHLp1KW8XJU%3d&risl=&pid=ImgRaw&r=0', TRUE, FALSE, 3),
  (4, 1, 'Hambúrguer de Picanha', 'Pão brioche, hambúrguer de picanha 200g, queijo provolone, cebola caramelizada, alface e molho barbecue.', 20.99, 'https://www.seara.com.br/wp-content/uploads/2022/12/hamburguer-destaque.jpg', TRUE, FALSE, 4),
  (5, 1, 'Hambúrguer de Bacon', 'Pão australiano, hambúrguer artesanal 180g, fatias de bacon crocante, queijo cheddar duplo, cebola crispy e molho defumado.', 18.99, 'https://www.comidaereceitas.com.br/wp-content/uploads/2020/08/hamburguer_bacon.jpg', TRUE, FALSE, 5),
  (6, 1, 'Hambúrguer de Queijo', 'Pão brioche, hambúrguer artesanal 180g, queijo cheddar, queijo muçarela, queijo provolone e molho especial.', 16.99, 'https://tse3.mm.bing.net/th/id/OIP.4QM_K5fkaqjmuxdZmsUOfAHaGI?cb=defcachec2&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 6),
  (7, 2, 'Refrigerante Lata', 'Coca-Cola, Guaraná Antarctica ou Fanta Laranja — bem gelado.', 5.99, 'https://a-static.mlcdn.com.br/800x560/refrigerante-lata-diversas/mfdepositoemercearia/977d7a9c338e11edae444201ac185019/afb6b35b2d3f81b111fbb0a2aba939ab.jpeg', TRUE, FALSE, 1),
  (8, 2, 'Suco Natural', 'Suco da fruta feito na hora — laranja, abacaxi com hortelã ou maracujá.', 8.99, 'https://s2.glbimg.com/64QeEkjeZkr4WG0cQY0gFzTCAC4=/1200x/smart/filters:cover():strip_icc()/i.s3.glbimg.com/v1/AUTH_bc8228b6673f488aa253bbcb03c80ec5/internal_photos/bs/2022/3/3/92w4EYREyRINApxl77eQ/suco-frutas.jpg', TRUE, FALSE, 2),
  (9, 2, 'Milkshake', 'Milkshake cremoso com chantilly — chocolate, morango ou baunilha.', 14.99, 'https://tse1.explicit.bing.net/th/id/OIP.xAGAGNK0scYE-E3O2muM4QHaLS?cb=defcachec2&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 3),
  (10, 3, 'Batata Frita', 'Porção de batata frita crocante temperada com sal e páprica, acompanhada de ketchup e maionese.', 12.99, 'https://guiadacozinha.com.br/wp-content/uploads/2020/11/batata-frita-press%C3%A3o-1.jpg', TRUE, FALSE, 1),
  (11, 3, 'Onion Rings', 'Anéis de cebola empanados e fritos, crocantes por fora e macios por dentro, com molho barbecue.', 14.99, 'https://tse4.mm.bing.net/th/id/OIP.Vu1SGNA-B7Tu0DfrhDqc2AHaE8?cb=defcachec2&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 2),
  (12, 3, 'Nuggets de Frango', '10 unidades de nuggets de frango crocantes, acompanhados de molho barbecue e mostarda e mel.', 16.99, 'https://tse4.mm.bing.net/th/id/OIP.mNW3-l2dime-E-SJmuqW3wHaHa?cb=defcachec2&w=768&h=768&rs=1&pid=ImgDetMain&o=7&rm=3', TRUE, FALSE, 3),
  (13, 4, 'Salada Caesar', 'Mix de alfaces, croutons, queijo parmesão ralado, frango grelhado e molho caesar.', 9.99, 'https://www.thespruceeats.com/thmb/DRaBINVopeoHOpjJn66Yh7pMBSc=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/classic-caesar-salad-recipe-996054-Hero_01-33c94cc8b8e841ee8f2a815816a0af95.jpg', TRUE, FALSE, 1),
  (14, 4, 'Coleslaw', 'Salada cremosa de repolho, cenoura e cebola com molho agridoce.', 6.99, 'https://www.jessicagavin.com/wp-content/uploads/2019/08/coleslaw-5-1200-2.jpg', TRUE, FALSE, 2),
  (15, 4, 'Molhos Extras', 'Porção extra de molhos: barbecue, cheddar cremoso, maionese da casa ou mostarda e mel.', 3.99, 'https://www.dicasdemulher.com.br/wp-content/uploads/2017/04/receitas-de-molhos.jpg', TRUE, FALSE, 3);

-- =========================
-- 3. Ingredientes
-- =========================
INSERT INTO product_ingredients (product_id, name, is_removable, display_order)
VALUES
  -- Hambúrguer de Carne
  (1, 'Pão brioche', FALSE, 1),
  (1, 'Hambúrguer 180g', FALSE, 2),
  (1, 'Queijo cheddar', TRUE, 3),
  (1, 'Alface', TRUE, 4),
  (1, 'Tomate', TRUE, 5),
  (1, 'Cebola roxa', TRUE, 6),
  (1, 'Molho especial', TRUE, 7),
  
  -- Hambúrguer de Frango
  (2, 'Pão com gergelim', FALSE, 1),
  (2, 'Filé de frango grelhado', FALSE, 2),
  (2, 'Queijo prato', TRUE, 3),
  (2, 'Alface americana', TRUE, 4),
  (2, 'Tomate', TRUE, 5),
  (2, 'Maionese temperada', TRUE, 6),
  
  -- Hambúrguer Vegetariano
  (3, 'Pão integral', FALSE, 1),
  (3, 'Hambúrguer de grão-de-bico', FALSE, 2),
  (3, 'Queijo muçarela', TRUE, 3),
  (3, 'Rúcula', TRUE, 4),
  (3, 'Tomate seco', TRUE, 5),
  (3, 'Molho pesto', TRUE, 6),
  
  -- Hambúrguer de Picanha
  (4, 'Pão brioche', FALSE, 1),
  (4, 'Hambúrguer de picanha 200g', FALSE, 2),
  (4, 'Queijo provolone', TRUE, 3),
  (4, 'Cebola caramelizada', TRUE, 4),
  (4, 'Alface', TRUE, 5),
  (4, 'Molho barbecue', TRUE, 6),
  
  -- Hambúrguer de Bacon
  (5, 'Pão australiano', FALSE, 1),
  (5, 'Hambúrguer 180g', FALSE, 2),
  (5, 'Bacon crocante', FALSE, 3),
  (5, 'Queijo cheddar duplo', TRUE, 4),
  (5, 'Cebola crispy', TRUE, 5),
  (5, 'Molho defumado', TRUE, 6),
  
  -- Hambúrguer de Queijo
  (6, 'Pão brioche', FALSE, 1),
  (6, 'Hambúrguer 180g', FALSE, 2),
  (6, 'Queijo cheddar', TRUE, 3),
  (6, 'Queijo muçarela', TRUE, 4),
  (6, 'Queijo provolone', TRUE, 5),
  (6, 'Molho especial', TRUE, 6),
  
  -- Batata Frita
  (10, 'Batata frita', FALSE, 1),
  (10, 'Ketchup', TRUE, 2),
  (10, 'Maionese', TRUE, 3),
  
  -- Onion Rings
  (11, 'Anéis de cebola', FALSE, 1),
  (11, 'Molho barbecue', TRUE, 2),
  
  -- Nuggets de Frango
  (12, 'Nuggets (10un)', FALSE, 1),
  (12, 'Molho barbecue', TRUE, 2),
  (12, 'Mostarda e mel', TRUE, 3),
  
  -- Salada Caesar
  (13, 'Mix de alfaces', FALSE, 1),
  (13, 'Croutons', TRUE, 2),
  (13, 'Queijo parmesão', TRUE, 3),
  (13, 'Frango grelhado', TRUE, 4),
  (13, 'Molho caesar', TRUE, 5);

-- =========================
-- 4. Adicionais
-- =========================
INSERT INTO product_addons (product_id, name, price, is_active, display_order)
VALUES
  -- Adicionais Hambúrgueres
  (1, 'Bacon crocante', 4.00, TRUE, 1),
  (1, 'Cheddar extra', 3.00, TRUE, 2),
  (1, 'Ovo frito', 2.50, TRUE, 3),
  (1, 'Onion rings (3un)', 5.00, TRUE, 4),
  (1, 'Hambúrguer extra', 8.00, TRUE, 5),
  
  (2, 'Bacon crocante', 4.00, TRUE, 1),
  (2, 'Cheddar extra', 3.00, TRUE, 2),
  (2, 'Ovo frito', 2.50, TRUE, 3),
  (2, 'Onion rings (3un)', 5.00, TRUE, 4),
  (2, 'Hambúrguer extra', 8.00, TRUE, 5),
  
  (3, 'Cheddar extra', 3.00, TRUE, 1),
  (3, 'Ovo frito', 2.50, TRUE, 2),
  (3, 'Onion rings (3un)', 5.00, TRUE, 3),
  (3, 'Guacamole', 4.50, TRUE, 4),
  
  (4, 'Bacon crocante', 4.00, TRUE, 1),
  (4, 'Cheddar extra', 3.00, TRUE, 2),
  (4, 'Ovo frito', 2.50, TRUE, 3),
  (4, 'Onion rings (3un)', 5.00, TRUE, 4),
  (4, 'Hambúrguer extra', 8.00, TRUE, 5),
  
  (5, 'Cheddar extra', 3.00, TRUE, 1),
  (5, 'Ovo frito', 2.50, TRUE, 2),
  (5, 'Onion rings (3un)', 5.00, TRUE, 3),
  (5, 'Hambúrguer extra', 8.00, TRUE, 4),
  (5, 'Bacon extra', 5.00, TRUE, 5),
  
  (6, 'Bacon crocante', 4.00, TRUE, 1),
  (6, 'Cheddar extra', 3.00, TRUE, 2),
  (6, 'Ovo frito', 2.50, TRUE, 3),
  (6, 'Onion rings (3un)', 5.00, TRUE, 4),
  (6, 'Hambúrguer extra', 8.00, TRUE, 5),
  
  -- Bebidas
  (7, 'Gelo extra', 0.00, TRUE, 1),
  (7, 'Limão', 0.50, TRUE, 2),
  (8, 'Açúcar extra', 0.00, TRUE, 1),
  (8, 'Adoçante', 0.00, TRUE, 2),
  (8, 'Hortelã', 0.50, TRUE, 3),
  (9, 'Chantilly extra', 1.50, TRUE, 1),
  (9, 'Calda de chocolate', 2.00, TRUE, 2),
  (9, 'Calda de morango', 2.00, TRUE, 3),
  (9, 'Granulado', 1.00, TRUE, 4),
  
  -- Porções
  (10, 'Cheddar cremoso', 3.00, TRUE, 1),
  (10, 'Bacon bits', 4.00, TRUE, 2),
  (11, 'Cheddar cremoso', 3.00, TRUE, 1),
  (12, 'Cheddar cremoso', 3.00, TRUE, 1),
  (12, 'Molho extra', 1.50, TRUE, 2),
  
  -- Acompanhamentos
  (15, 'Porção dupla', 2.50, TRUE, 1);

-- =========================
-- 5. Sabores (apenas para bebidas e molhos extras)
-- =========================
INSERT INTO product_flavors (product_id, name, is_available, display_order)
VALUES
  -- Refrigerante
  (7, 'Coca-Cola', TRUE, 1),
  (7, 'Guaraná Antarctica', TRUE, 2),
  (7, 'Fanta Laranja', TRUE, 3),
  -- Suco Natural
  (8, 'Laranja', TRUE, 1),
  (8, 'Abacaxi com Hortelã', TRUE, 2),
  (8, 'Maracujá', TRUE, 3),
  -- Milkshake
  (9, 'Chocolate', TRUE, 1),
  (9, 'Morango', TRUE, 2),
  (9, 'Baunilha', TRUE, 3),
  -- Molhos Extras
  (15, 'Barbecue', TRUE, 1),
  (15, 'Cheddar cremoso', TRUE, 2),
  (15, 'Maionese da casa', TRUE, 3),
  (15, 'Mostarda e mel', TRUE, 4);

-- =========================
-- 6. Tamanhos (apenas para bebidas)
-- =========================
INSERT INTO product_sizes (product_id, name, ml, price, is_available, display_order)
VALUES
  -- Refrigerante
  (7, 'Pequeno', '250ml', 4.49, TRUE, 1),
  (7, 'Médio', '350ml', 5.99, TRUE, 2),
  (7, 'Grande', '600ml', 8.49, TRUE, 3),
  -- Suco Natural
  (8, 'Pequeno', '300ml', 6.99, TRUE, 1),
  (8, 'Médio', '400ml', 8.99, TRUE, 2),
  (8, 'Grande', '500ml', 10.99, TRUE, 3),
  -- Milkshake
  (9, 'Pequeno', '300ml', 12.49, TRUE, 1),
  (9, 'Médio', '400ml', 14.99, TRUE, 2),
  (9, 'Grande', '500ml', 17.49, TRUE, 3);
