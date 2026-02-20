-- ============================================================
-- PONTO DO LANCHE — PostgreSQL Schema
-- Gerado em: 2026-02-19
-- Versão: 1.0
-- ============================================================

-- Limpeza para re-execução segura (ordem inversa de dependência)
DROP TABLE IF EXISTS order_items      CASCADE;
DROP TABLE IF EXISTS orders           CASCADE;
DROP TABLE IF EXISTS customers        CASCADE;
DROP TABLE IF EXISTS product_sizes    CASCADE;
DROP TABLE IF EXISTS product_flavors  CASCADE;
DROP TABLE IF EXISTS product_addons   CASCADE;
DROP TABLE IF EXISTS product_ingredients CASCADE;
DROP TABLE IF EXISTS products         CASCADE;
DROP TABLE IF EXISTS categories       CASCADE;
DROP TABLE IF EXISTS store_settings   CASCADE;

-- ============================================================
-- TIPOS ENUM
-- ============================================================

DROP TYPE IF EXISTS delivery_type_enum   CASCADE;
DROP TYPE IF EXISTS payment_method_enum  CASCADE;
DROP TYPE IF EXISTS order_status_enum    CASCADE;

CREATE TYPE delivery_type_enum  AS ENUM ('delivery', 'pickup');
CREATE TYPE payment_method_enum AS ENUM ('pix', 'card', 'cash');
CREATE TYPE order_status_enum   AS ENUM (
  'pending',      -- Pedido recebido, aguardando confirmação
  'confirmed',    -- Confirmado pelo estabelecimento
  'preparing',    -- Em preparação na cozinha
  'delivering',   -- Saiu para entrega
  'completed',    -- Finalizado / entregue
  'cancelled'     -- Cancelado
);

-- ============================================================
-- 1. STORE_SETTINGS (Configurações do estabelecimento)
-- Tabela singleton — sempre id = 1
-- ============================================================

CREATE TABLE store_settings (
  id                SERIAL       PRIMARY KEY,
  store_name        VARCHAR(150) NOT NULL DEFAULT 'Ponto do Lanche',
  whatsapp_number   VARCHAR(20)  NOT NULL,
  delivery_fee      DECIMAL(10,2) NOT NULL DEFAULT 5.00,
  max_addons        INTEGER      NOT NULL DEFAULT 3,
  business_hours    JSONB        NOT NULL DEFAULT '{
    "weekday": "17:00-00:00",
    "weekend": "17:00-01:00"
  }'::jsonb,
  social_links      JSONB        DEFAULT '{}'::jsonb,
  is_store_open     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  store_settings IS 'Configurações globais do estabelecimento (singleton).';
COMMENT ON COLUMN store_settings.max_addons IS 'Limite global de adicionais por item do pedido.';
COMMENT ON COLUMN store_settings.business_hours IS 'Horário de funcionamento em JSON. Ex: {"weekday":"17:00-00:00","weekend":"17:00-01:00"}';
COMMENT ON COLUMN store_settings.social_links IS 'Links de redes sociais. Ex: {"whatsapp":"...","instagram":"..."}';

-- Garante que só exista 1 registro (singleton)
CREATE UNIQUE INDEX uq_store_settings_singleton ON store_settings ((TRUE));

-- ============================================================
-- 2. CATEGORIES
-- ============================================================

CREATE TABLE categories (
  id             SERIAL        PRIMARY KEY,
  name           VARCHAR(100)  NOT NULL,
  slug           VARCHAR(100)  NOT NULL,
  icon           VARCHAR(255),
  display_order  INTEGER       NOT NULL DEFAULT 0,
  is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_categories_name UNIQUE (name),
  CONSTRAINT uq_categories_slug UNIQUE (slug)
);

CREATE INDEX idx_categories_display_order ON categories (display_order);
CREATE INDEX idx_categories_active        ON categories (is_active) WHERE is_active = TRUE;

COMMENT ON TABLE  categories IS 'Categorias do cardápio (ex: Hambúrguer, Bebidas, Porções).';
COMMENT ON COLUMN categories.slug IS 'Slug para URLs amigáveis, gerado a partir do nome.';

-- ============================================================
-- 3. PRODUCTS
-- ============================================================

CREATE TABLE products (
  id             SERIAL         PRIMARY KEY,
  category_id    INTEGER        NOT NULL,
  name           VARCHAR(150)   NOT NULL,
  description    TEXT           NOT NULL DEFAULT '',
  price          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  image_url      VARCHAR(500),
  is_active      BOOLEAN        NOT NULL DEFAULT TRUE,
  is_featured    BOOLEAN        NOT NULL DEFAULT FALSE,
  display_order  INTEGER        NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id)
    REFERENCES categories (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT ck_products_price_positive
    CHECK (price >= 0)
);

CREATE INDEX idx_products_category    ON products (category_id);
CREATE INDEX idx_products_active      ON products (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_featured    ON products (is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_products_display     ON products (category_id, display_order);

COMMENT ON TABLE  products IS 'Produtos do cardápio. Para bebidas, o preço base pode ser sobrescrito pelo tamanho selecionado.';
COMMENT ON COLUMN products.price IS 'Preço base. Para bebidas, o preço real vem de product_sizes.';
COMMENT ON COLUMN products.is_featured IS 'Se aparece na seção "Mais Pedidos" da Home.';

-- ============================================================
-- 4. PRODUCT_INGREDIENTS
-- ============================================================

CREATE TABLE product_ingredients (
  id             SERIAL        PRIMARY KEY,
  product_id     INTEGER       NOT NULL,
  name           VARCHAR(100)  NOT NULL,
  is_removable   BOOLEAN       NOT NULL DEFAULT TRUE,
  display_order  INTEGER       NOT NULL DEFAULT 0,

  CONSTRAINT fk_ingredients_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_ingredient_per_product
    UNIQUE (product_id, name)
);

CREATE INDEX idx_ingredients_product ON product_ingredients (product_id);

COMMENT ON TABLE  product_ingredients IS 'Ingredientes padrão de cada produto.';
COMMENT ON COLUMN product_ingredients.is_removable IS 'FALSE = ingrediente obrigatório (ex: pão, carne). Não pode ser removido pelo cliente.';

-- ============================================================
-- 5. PRODUCT_ADDONS
-- ============================================================

CREATE TABLE product_addons (
  id             SERIAL         PRIMARY KEY,
  product_id     INTEGER        NOT NULL,
  name           VARCHAR(100)   NOT NULL,
  price          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  is_active      BOOLEAN        NOT NULL DEFAULT TRUE,
  display_order  INTEGER        NOT NULL DEFAULT 0,

  CONSTRAINT fk_addons_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT ck_addons_price_non_negative
    CHECK (price >= 0)
);

CREATE INDEX idx_addons_product ON product_addons (product_id);

COMMENT ON TABLE  product_addons IS 'Adicionais pagos opcionais (ex: Bacon extra, Cheddar).';
COMMENT ON COLUMN product_addons.price IS 'Preço do adicional. Pode ser 0 para itens gratuitos (ex: gelo extra).';

-- ============================================================
-- 6. PRODUCT_FLAVORS
-- ============================================================

CREATE TABLE product_flavors (
  id             SERIAL        PRIMARY KEY,
  product_id     INTEGER       NOT NULL,
  name           VARCHAR(100)  NOT NULL,
  is_available   BOOLEAN       NOT NULL DEFAULT TRUE,
  display_order  INTEGER       NOT NULL DEFAULT 0,

  CONSTRAINT fk_flavors_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_flavor_per_product
    UNIQUE (product_id, name)
);

CREATE INDEX idx_flavors_product ON product_flavors (product_id);

COMMENT ON TABLE  product_flavors IS 'Sabores disponíveis para bebidas e molhos. A presença de sabores define se o produto é uma "bebida".';
COMMENT ON COLUMN product_flavors.is_available IS 'Permite desativar temporariamente um sabor sem excluir.';

-- ============================================================
-- 7. PRODUCT_SIZES
-- ============================================================

CREATE TABLE product_sizes (
  id             SERIAL         PRIMARY KEY,
  product_id     INTEGER        NOT NULL,
  name           VARCHAR(50)    NOT NULL,
  ml             VARCHAR(20),
  price          DECIMAL(10,2)  NOT NULL,
  is_available   BOOLEAN        NOT NULL DEFAULT TRUE,
  display_order  INTEGER        NOT NULL DEFAULT 0,

  CONSTRAINT fk_sizes_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_size_per_product
    UNIQUE (product_id, name),

  CONSTRAINT ck_sizes_price_positive
    CHECK (price >= 0)
);

CREATE INDEX idx_sizes_product ON product_sizes (product_id);

COMMENT ON TABLE  product_sizes IS 'Tamanhos disponíveis para bebidas, com preço próprio.';
COMMENT ON COLUMN product_sizes.price IS 'Preço da bebida neste tamanho — SUBSTITUI o products.price para bebidas.';
COMMENT ON COLUMN product_sizes.ml IS 'Volume em mililitros para exibição. Ex: "350ml".';

-- ============================================================
-- 8. CUSTOMERS
-- ============================================================

CREATE TABLE customers (
  id             SERIAL        PRIMARY KEY,
  name           VARCHAR(150)  NOT NULL,
  phone          VARCHAR(20)   NOT NULL,
  street         VARCHAR(255),
  number         VARCHAR(20),
  neighborhood   VARCHAR(100),
  complement     VARCHAR(255),
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_customers_phone UNIQUE (phone)
);

CREATE INDEX idx_customers_phone ON customers (phone);

COMMENT ON TABLE  customers IS 'Clientes identificados pelo telefone (WhatsApp).';
COMMENT ON COLUMN customers.phone IS 'Número no formato (XX) XXXXX-XXXX. Chave natural para identificação.';

-- ============================================================
-- 9. ORDERS
-- ============================================================

CREATE TABLE orders (
  id               SERIAL              PRIMARY KEY,
  customer_id      INTEGER,
  customer_name    VARCHAR(150)        NOT NULL,
  customer_phone   VARCHAR(20)         NOT NULL,
  delivery_type    delivery_type_enum  NOT NULL DEFAULT 'delivery',
  delivery_address TEXT,
  payment_method   payment_method_enum NOT NULL,
  change_for       DECIMAL(10,2),
  subtotal         DECIMAL(10,2)       NOT NULL,
  delivery_fee     DECIMAL(10,2)       NOT NULL DEFAULT 0.00,
  total            DECIMAL(10,2)       NOT NULL,
  status           order_status_enum   NOT NULL DEFAULT 'pending',
  whatsapp_sent    BOOLEAN             NOT NULL DEFAULT FALSE,
  notes            TEXT,
  created_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers (id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT ck_orders_subtotal_positive
    CHECK (subtotal >= 0),

  CONSTRAINT ck_orders_total_positive
    CHECK (total >= 0),

  CONSTRAINT ck_orders_delivery_fee_non_negative
    CHECK (delivery_fee >= 0),

  -- Se for entrega, endereço é obrigatório
  CONSTRAINT ck_orders_delivery_address
    CHECK (
      delivery_type = 'pickup'
      OR (delivery_type = 'delivery' AND delivery_address IS NOT NULL AND delivery_address <> '')
    ),

  -- Troco só faz sentido para pagamento em dinheiro
  CONSTRAINT ck_orders_change_for
    CHECK (
      change_for IS NULL
      OR payment_method = 'cash'
    )
);

CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_orders_created     ON orders (created_at DESC);
CREATE INDEX idx_orders_status_date ON orders (status, created_at DESC);

COMMENT ON TABLE  orders IS 'Pedidos realizados. Valores monetários são snapshots imutáveis do momento da criação.';
COMMENT ON COLUMN orders.customer_name IS 'Snapshot — nome do cliente no momento do pedido.';
COMMENT ON COLUMN orders.customer_phone IS 'Snapshot — telefone do cliente no momento do pedido.';
COMMENT ON COLUMN orders.delivery_address IS 'Endereço formatado: "Rua, Nº - Bairro (Complemento)". NULL se retirada.';
COMMENT ON COLUMN orders.subtotal IS 'Snapshot — soma dos itens (sem taxa de entrega).';
COMMENT ON COLUMN orders.delivery_fee IS 'Snapshot — taxa de entrega no momento do pedido.';
COMMENT ON COLUMN orders.total IS 'Snapshot — subtotal + delivery_fee. Imutável após criação.';

-- ============================================================
-- 10. ORDER_ITEMS
-- ============================================================

CREATE TABLE order_items (
  id                    SERIAL         PRIMARY KEY,
  order_id              INTEGER        NOT NULL,
  product_id            INTEGER        NOT NULL,
  product_name          VARCHAR(150)   NOT NULL,
  product_image_url     VARCHAR(500),
  quantity              INTEGER        NOT NULL DEFAULT 1,
  base_price            DECIMAL(10,2)  NOT NULL,
  addons_total          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  final_price           DECIMAL(10,2)  NOT NULL,
  removed_ingredients   JSONB          DEFAULT '[]'::jsonb,
  selected_addons       JSONB          DEFAULT '[]'::jsonb,
  selected_flavor       VARCHAR(100),
  selected_size         VARCHAR(100),
  observation           TEXT,

  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id)
    REFERENCES orders (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT ck_order_items_quantity_positive
    CHECK (quantity >= 1),

  CONSTRAINT ck_order_items_base_price_positive
    CHECK (base_price >= 0),

  CONSTRAINT ck_order_items_final_price_positive
    CHECK (final_price >= 0),

  CONSTRAINT ck_order_items_observation_length
    CHECK (observation IS NULL OR LENGTH(observation) <= 200)
);

CREATE INDEX idx_order_items_order   ON order_items (order_id);
CREATE INDEX idx_order_items_product ON order_items (product_id);

COMMENT ON TABLE  order_items IS 'Itens de um pedido com todas as customizações como snapshot.';
COMMENT ON COLUMN order_items.product_name IS 'Snapshot — nome do produto no momento da compra.';
COMMENT ON COLUMN order_items.base_price IS 'Snapshot — preço unitário (sem adicionais) no momento da compra.';
COMMENT ON COLUMN order_items.addons_total IS 'Snapshot — soma dos preços dos adicionais selecionados.';
COMMENT ON COLUMN order_items.final_price IS 'Snapshot — base_price + addons_total. Deve ser calculado pelo backend.';
COMMENT ON COLUMN order_items.removed_ingredients IS 'JSON array de nomes de ingredientes removidos. Ex: ["Tomate","Cebola"]';
COMMENT ON COLUMN order_items.selected_addons IS 'JSON array de objetos. Ex: [{"name":"Bacon","price":4.00}]';
COMMENT ON COLUMN order_items.observation IS 'Observação do cliente. Máximo 200 caracteres.';

-- ============================================================
-- TRIGGER: Atualização automática de updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplica o trigger em todas as tabelas que possuem updated_at
CREATE TRIGGER trg_store_settings_updated BEFORE UPDATE ON store_settings FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_categories_updated     BEFORE UPDATE ON categories     FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_products_updated       BEFORE UPDATE ON products       FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_customers_updated      BEFORE UPDATE ON customers      FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_orders_updated         BEFORE UPDATE ON orders         FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();

-- ============================================================
-- SEED: Configuração inicial do estabelecimento
-- ============================================================

INSERT INTO store_settings (store_name, whatsapp_number, delivery_fee, max_addons, business_hours, social_links)
VALUES (
  'Ponto do Lanche',
  '5577991153244',
  5.00,
  3,
  '{"weekday": "17:00-00:00", "weekend": "17:00-01:00"}'::jsonb,
  '{"whatsapp": "5577991153244", "instagram": "", "facebook": "", "email": ""}'::jsonb
);
================PONTO DO LANCHE — PostgreQL S
--Geraem: 2026-02-19
-- Versão: 1.0
-- ============================================================

-- Limpez para re-exeuçãsegura (orminvers e dependência)
DROP TABLE IF EXISTS rder_item    CASCADE;
DRO TABLE IF EXISTS rders           CASCADE;
DROP TABLE IF EXISTS cusmers       CASCADE;
DROP TABLE IF EXISTS prouct_sizes    CASCADE;
DROP TABLE IF EXISTS prduct_flavors CASCADE;
DROP TABE IF EXISTS product_ddos   CASCADE;
DROP TABLE IF EXISTS produt_ingredients CASCADE;
DROP TABLE IF EXISTS products         CASCADE;
DROP TABLE IF EXISTS categories       CASCADE;
DROP TABLE IF EXISTS store_sttings   CASCADE;
================
-- TIPOS ENUM ============================================================

DROP TYPE IF EXISTS delivery_type_enum   CASCADE;
DROP TYPE IF EXISTS payment_method_enum  CASCADE;
DROP TYPE IFXISTS order_taus_num    CASCADE;

CREATE TYPEdelivey_type_enm  AS ENUM ('delery','pikup');
CREATE TYPE paymet_mehod_enu AS ENUM ('pix', 'card','cash');
CREATE TYPE order_sttus_enum   AS ENUM (
  'pending',     -- Peido recbido, aguardando confirmação
  'confirmed',    -- Conrmado pelo estabelecimeto
  'preparng',    -- Em preparana zinha
  'delivering',   -- Saiu para entrega
  'coleted',    -- Finaizado / nregue
  'cncelled'    -- Cancelao
);

-- ============================================================
-- 1. STORE_SETTINGS (Configurções do etabelecimento)T singleton — emprei = 1
-- ============================================================

CREATETABLE tore_settng (
  id                SERIAL       PRIMARY KEY,
  sor_nae        VARCHAR(150) NOT NULL DEFAULT 'Ponto do Lanche',
  whatspp_number   VARCHAR(20)  NOT NULL,
  delivery_fee      DECIMAL(10,2) NOT NULLDEFULT 5.00,
  max_adons        INTEGER      NOT NULL DEFAULT 3,
  busness_hours    JSONB        NOT NULL DEFAULT '{
    "weekday": "17:00-00:00",
    "weekend": "17:00-01:00"
  }'::jsonb,
  soial_lnks      JSONB        DEFAULT '{}'::jsb,
  is_store_opn     BOOLEAN      NOTNULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  store_setting IS 'Configrações globi doesecimento (ingleton).';
COMMENT ON COLUMNstore_settings.max_ddons IS 'Limite glol de adcionais por item do pedido.';
COMMENT ON COLUMN store_settings.business_hours IS 'Horário de funcionamento em JSON. E: {"weekday":"17:00-00:00","weekend":"17:00-01:00"}';
COMMENT ON COLUMN store_settings.social_links IS 'Links de redes sciais Ex: {"whatsapp":"...","instagram":"..."}';

-- Garante que só exista 1 registro (singleton)
CREATE UNIQUE INDEX uq_store_settings_singleton ON store_settings ((TRUE));

-- ============================================================ 2. CATEGORIES============================================================

CREATE TABLE categories (
  id             SERIAL        RIMARY KEY,
  nme           VARCHAR(100)  NOT NULL,
  slug           VARCHAR(100)  NOT NULL,
  icon           VARCHAR(255),
  display_oder  INTEGER       NOT NULL DEFAULT 0,
  is_ctive     BOOLEAN       NOT NULL DEFAULT TRUE,
  creted_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  udated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_categories_name UNIQUE (name),
  CONSTRAINT uq_categories_sug UNIQUE (slug)
);

CREATE INDEX dx_tegoies_display_orderON categries(diplay_order);
CREATE INDEX idx_atgories_ctive        ON categories (is_active) WHERE is_active = TRUE;

COMMENT ON TABLE  categories IS 'Categorias do cardápio (ex Hambúrguer, Bebidas, Porções).';
COMMENT ON COLUMN categories.slug IS 'Slug para URLs amigáveis, gerado a partir do nome.';

-- ============================================================
-- 3. PRODUCTS============================================================

CREATETABLEroducts (
  id             SERIAL         PRIMARY KEY,
  category_id    INTEGER        NOT NULL,
  name           VARCHAR(150)   NOT NULL,
  decription    TEXT           NOT NULL DEFAULT '',
  price          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  image_ur     VARCHAR(500),
  is_active      BOOLEAN        NOT NLLDEFAULT TRUE,
  is_featured    BOOLEAN        NOT NULL DEFAULT FALSE,
  dislay_rder  INTEGER        NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_product_caeoy
    FOREIGN KEY (catgory_id)
    REFERENCES categorie(i)
   ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT ck_rducs_price_psitive
    CHECK (price >= 0)
);

CREATE INDEX idxproucts_categry    ON products (categoryid);
CREATE INDEX idx_products_tiv     ON products (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_eatured   ON proucts (is_feured) WHERE is_fetured = TRUE;
CREATE INDEX idx_products_display     ON products (category_id, display_order);

COMMENT ON TABLE  products IS 'Produtos do cardápio. Para ebid, o prço bae pode ser sobresrito plo tanho eleionado.';
COMMENT ON COLUMN products.pric IS 'Preço bse Para bebida, o preço rea vem de product_sizes.';
COMMENT ON COLUMN products.is_featured IS 'Se aparece na seção "Mais Pedidos" da Home.';
================-- 4. PRODUCT_INGREDIENTS ============================================================

CREATE TABLE product_ingredients (
  id             SERIAL        PRIMARY KEY,
  product_id     INTEGER       NOT NULL,
  name           VARCHAR(100)  NOT NULL,
  is_removable   BOOLEAN       NOT NULL DEFAULT TRUE,
  display_order  INTEGER       NOT NULL DEFAULT 0,

  CONSTRAINT fk_ingredients_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_ingredient_per_product
    UNIQUE (product_id, name)
);

CREATE INDEX idx_ingredients_product ON product_ingredients (product_id);

COMMENT ON TABLE  product_ingredients IS 'Ingredientes padrão de cada produto.';
COMMENT ON COLUMN product_ingredients.is_removable IS'FALS = ingrediente obrigatório (e: pão, carne). Não pode ser rovido e cliente.';

-- ============================================================
-- 5. PRODUCT_ADDONS============================================================

E product_addons (
  id             SERIAL         PRIMARY KEY,
  product_id     INTGER        NOT NULL,
  name          VARCHAR(100)   NOT NULL,
  price          DECMAL(10,2)  NOT NULL DEAULT0.00,
  is_active      BOOLEA        NNULL DFAULT TRUE,
  display_order  INTEGER        NOT NULL DEFAULT 0,

  CONSTRAINT fk_addons_product
    FOREGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONTRAINT ck_addons_price_non_negative
    CHECK (price >= 0)
);

CREATE INDEX idx_addons_product ON product_addons (product_id);

COMMEN ON TABLE  product_addons I 'Adicionais pagosocionais (ex: Bacon exta, Cheddar).';
COMMENT ON COLUMN prc_addn.priceIS 'Preço do adicional. Pode ser 0 para itens gratuitos ex: gelo extra).';

-- ============================================================6.PRODUCT_FLAVORS
--============================================================

CREATE TABLE product_flavors (
            product_id    INTEGER       NOT NULL,
  a   0NOTULL,
  is_available   BOLEAN       NO DEFAULT TRUEisplay_ordr  INTEGER       NOT NULL DEFAULT 0,

  CONSTRAINT fk_flavor_produt
    FOREIGN KEY (poduct_d)
    REFERENCES produts (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_flvr_per_product
 UNIQUE (product_id, name)
);

CREA INDE idx_flavors_product ON product_flavors (product_id);

COMMEN ON TABLE  product_flavors IS 'Sabores disponíveis para bebidas e molhos. A presença de sabores define se o produto é uma "bebida".';
COMMENT ON COLUMN product_flavors.is_available IS 'Permite desativar temporariamente um sabor sem excluir.';

-- ============================================================
-- 7. PRODUCT_SIZES============================================================

CREATETABLEodut_sizes (
  id             SERIAL         PRIMARY KEY,
  prduct_id     INTEGER        NOT NULL,
  name    VARCHAR(50)    NOT NULL,
  ml             VARCHAR(20),
  price            is_available   BOOLEAN        NOT NULL DEFAULT TRUE,
  display_order  INTEGER        NOT NULL DEFAULT 0,

  CONSTRAINT fk_sizes_product
    FOREIGN KEY (product_id)
    REFERENCES products (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT uq_size_per_product
    UNIQUE (product_id, name),

  CONSTRAINT ck_sizes_price_positive
    CHECK (price >= 0)
);

CREATE INDEX idx_sizes_product ON product_sizes (product_id);

COMMENT ON TABLE  product_sizes IS 'Tamanhos disponíveis para bebidas, com preço próprio.';
COMMENT ON COLUMN product_sizes.price IS 'Preço da bebida neste tamanho — SUBSTITUI o products.price para bebidas.';
COMMENT ON COLUMN product_sizes.ml IS 'Volume em mililitros para exibição. Ex: "350ml".';

============================================================
--8.CUSTOMERS
-- ============================================================

CREATE TABLE ustomers (
  id             SERIAL        PRIMARY KEY,
  nme           VARCHAR(150)  NOT NULL,
  phone          VARCHAR(20)   NOT NULL,
  stree         VARCHAR(255),
  number         VARCHAR(20),
  nihborhood   VARCHAR(100),
  complement     VARCHAR(255),
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_customers_phone UNIQUE (phone)
);

CREATE INDEX idx_customers_phone ON customers (phone);

COMMENT ON TABLE  customers IS 'Clientes identificados pelo telefone (WhatsApp).';
COMMENT ON COLUMN customers.phone IS 'Número no formato (XX) XXXXX-XXXX. Chave natural para identificação.';

-- ============================================================
-- 9. ORDERS
-- ============================================================

CREATE TABLE orders (
  id               SERIAL              PRIMARY KEY,
  custme_d      INTEGER,
  customer_nme 10)        NOT NULL,
  customer_phone   VARCHAR(2         NOT NULL  delivery_type    delivery_type_enum  NOT NULL DEFAULT'delivery',
elvery_addres TEXT,
  ayment_methd   paymet_method_enum NOT NULL,
  change_for       DECIMAL(10,2),
  subtotal         DECIMAL(10,2)       NOT NULL,
  delery_fe     DECIMAL(10,2)       NOT NULL DEFAULT 0.00,
  tota            DECIMAL(10,2)       NOT NULL,
  status           order_status_enum   NOT NULL DEFAULT 'pending',
  whatsapp_sent  OLEAN             NOT NULL DEFAULT FALSE,
  notes            TEXT,
  created_at       TIMESTAMPTZ         NT NUL DFULT OW(),
  updated_at       TIMESTAMPTZ   NOTNULLT NOW(),

  CONSRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
   REFERENCES cusomers (id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT ck_oders_sbtotal_positive
    CHECK (subtotal >= 0),

  CONSTRAINT ck_orders_total_positive
    CHECK (total >= 0),

  CONSTRAINT ck_orders_delivery_fee_non_negative
    CHECK (dlivery_fee >= 0)
   Se for entrega, endereço é obrigatório
  CONSTRAINT ck_orders_delivery_address
    CHECK (
   delvery_type = 'pickup'
      OR (delivery_type = 'delivery' AND delivery_address IS NOT NULL AND delivery_address <> '')
    ),

  -- Troco só faz sentido para pagaento em dinheiro
  CONSTRAINT ck_orders_change_for
    CHECK (
      chne_for IS NULL
      OR payment_method = 'cash'
    )
);

CREATE INDEX idx_ordrs_custoer    ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_orders_created     ON orders (created_at DESC);
CREATE INDEX idx_orders_status_date ON orders (status, created_at DESC);

COMMENT ON TABLE  orders IS 'Pedidos realizados. Valores monetários são snapshots imutáveis do momento da criação.';
COMMENT ON COLUMN orders.customer_name IS 'Snapshot — nome do cliente no momento do pedido.';
COMMENT ON COLUMN orders.customer_phone IS 'Snapshot — telefone do cliente no momento do pedido.';
COMMENT ON COLUMN orders.delivery_address IS 'Endereço formatado: "Rua, Nº - Bairro (Complemento)". NULL se retirada.';
COMMENT ON COLUMN orders.subtotal IS 'Snapshot — soma dos itens (sem taxa de entrega).';
COMMENT ON COLUMN orders.deliveryfee IS 'Snapshot — taxa de entrega no momento do pedido.';
COMMENT ON COLUMN orders.total IS 'Snapshot — sbtotal + delivey_fee. Imutáveapóscriação.';

-- ============================================================
-- 10. ORDER_ITEMS
-- ============================================================

CREATE TABLE order_items (
  id                    SERIAL         PRIMARY KEY,
  order_id              INTEGER        NOT NULL,
  product_id            INTEGER        NOT NULL,
  product_name          10)   NOT NULL,
  product_image_url     VARCHAR(00quantity             INTEGER        NOT NULL DEFAULT 1,
  base_pce            DECIMAL(10,2)  NOT NULL,
  dnstotal          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
  final_pric           DECIMAL(10,2)  NOT NULL,
  reoved_ingredientsJSONB          DEFAUL '[]'::jsonb,
  selected_addons       JSONB          DEFAULT '[]'::jsonb,
  selected_flavor       VARCHAR(100),
  selected_size         VARCHAR(100),
  observation           TEXT,

  CONSTRANT fk_order_items_order
    FOREIGN KEY (order_id)
    REFERENC orders (id)
    ON DELEE CASCDE
ONUPDATECASCAE,

  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id)
    RERENCES products (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT ck_order_items_quantity_positive
    CHECK (quantity >= 1),

  CONSTRAINT ck_order_items_base_price_positive
    CHECK (base_price >= 0),

  CONSTRAINT ck_order_items_final_price_positive
    CHECK (final_price >= 0),

  CONSTRINT ck_order_items_observation_length
    CHECK (observation IS NLL OR ENGH(observation) <=200)
);

EATE INDEX idx_order_items_order   ON order_items (order_id);
CEATE INDEX idx_order_items_product ON order_items (product_id);

COMMENT ON TABLE  order_items IS 'Itens de um pedido com todas as customizações como snapshot.';
COMMENT ON COLUMN order_items.product_name IS 'Snapshot — nome do produto no momento da compra.';
COMMENT ON COLUMN order_items.base_price IS 'Snapshot — preço unitário (sem adicionais) no momento da compra.';
COMM ON COLUMN orderitems.addons_total IS 'Snapshot — soma dos preços dos adicionais selecionados.';
COMMEN ON COLUMN order_items.final_price S 'Snapshot — base_price + addons_total. Deve ser calculado pelo backend.';
COMNT ON COLUMN order_items.removed_ingredients IS 'JON array de nomes de ingredientes removidos. Ex: ["Tomate","Cebola"]';
COMMEN ON COLUN order_items.selected_addons IS 'JSON array de objetos. Ex: [{"name":"Bacon""price":4.00}]';
COMMENT ON COLUMN order_items.observation IS 'Observação do cliente. Máximo 200 caracteres.';
============================================================
--TRIGGER:Aação utmática de updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION fn_updatetimstap()
RETURNSRGGR A $$
BEGIN
  NEW.updated_at = NOW();
  REURN NEW;
END;
$$ LNGUAGE plpgsql;

-- Aplica o trigger em todas as tabelas que possuem updated_at
CREATE TRIGGER trg_store_settings_updated BEFORE UDATE ON store_settings FOREACHROWEXECUTEFUNCTION fn_update_timestamp();
CREATE TRIGGER trg_categories_updated     BEFORE UPAT ON categories     OR ECH ROW EXECUTE FNCTION fn_update_timestamp();
CREATE TRIGGER trg_products_updated       BEFORE UPDAE ON products      FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
REATE TRIGGER trg_customers_updated      BEFORE PDATE ON customers      FO EACH OW XECUTE FUCION fnupdate_timestamp();
CREATE RGGER trg_orders_updated         BEFORE UPDATE ON orders         FOR EACH ROW EXECUT FUNCTION fn_update_timestamp();

-- ============================================================
-- EED: Configuração inicial do estabelecimento
-- ============================================================

INSER INTO store_settings (store_name, whatsapp_number, delivery_fee, max_addons, business_hours, social_links)
VLUES (
  'onto do Lanche',
  '5577991153244',
  5.00,
  3,  '{"weekday": "17:0000:00", "weekend": "17:0001:00"}'::jsonb,
  '{"whatsapp": "5577991153244", "instagram": "", "facebook": "", "email":""}'::jsonb

