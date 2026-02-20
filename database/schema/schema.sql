-- ============================================================
-- PONTO DO LANCHE — PostgreSQL Schema
-- Versão: 1.0
-- ============================================================

-- Limpeza para re-execução segura (ordem inversa de dependência)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS product_sizes CASCADE;
DROP TABLE IF EXISTS product_flavors CASCADE;
DROP TABLE IF EXISTS product_addons CASCADE;
DROP TABLE IF EXISTS product_ingredients CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS store_settings CASCADE;

-- ============================================================
-- TIPOS ENUM
-- ============================================================

DROP TYPE IF EXISTS delivery_type_enum CASCADE;
DROP TYPE IF EXISTS payment_method_enum CASCADE;
DROP TYPE IF EXISTS order_status_enum CASCADE;

CREATE TYPE delivery_type_enum  AS ENUM ('delivery', 'pickup');
CREATE TYPE payment_method_enum AS ENUM ('pix', 'card', 'cash');
CREATE TYPE order_status_enum   AS ENUM (
  'pending',
  'confirmed',
  'preparing',
  'delivering',
  'completed',
  'cancelled'
);

-- ============================================================
-- 1. STORE_SETTINGS
-- ============================================================

CREATE TABLE store_settings (
  id                SERIAL       PRIMARY KEY,
  store_name        VARCHAR(150) NOT NULL DEFAULT 'Ponto do Lanche',
  whatsapp_number   VARCHAR(20)  NOT NULL,
  delivery_fee      DECIMAL(10,2) NOT NULL DEFAULT 5.00,
  max_addons        INTEGER      NOT NULL DEFAULT 3,
  business_hours    JSONB        NOT NULL DEFAULT '{}'::jsonb,
  social_links      JSONB        DEFAULT '{}'::jsonb,
  is_store_open     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_store_settings_singleton ON store_settings ((TRUE));

-- ============================================================
-- 2. CATEGORIES
-- ============================================================

CREATE TABLE categories (
  id             SERIAL        PRIMARY KEY,
  name           VARCHAR(100)  NOT NULL UNIQUE,
  slug           VARCHAR(100)  NOT NULL UNIQUE,
  icon           VARCHAR(255),
  display_order  INTEGER       NOT NULL DEFAULT 0,
  is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_display_order ON categories(display_order);
CREATE INDEX idx_categories_active        ON categories(is_active) WHERE is_active = TRUE;

-- ============================================================
-- 3. PRODUCTS
-- ============================================================

CREATE TABLE products (
  id             SERIAL        PRIMARY KEY,
  category_id    INTEGER       NOT NULL REFERENCES categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  name           VARCHAR(150)  NOT NULL,
  description    TEXT          NOT NULL DEFAULT '',
  price          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  image_url      VARCHAR(500),
  is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
  is_featured    BOOLEAN       NOT NULL DEFAULT FALSE,
  display_order  INTEGER       NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_products_price_positive CHECK (price >= 0)
);

CREATE INDEX idx_products_category    ON products(category_id);
CREATE INDEX idx_products_active      ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_featured    ON products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_products_display     ON products(category_id, display_order);

-- ============================================================
-- 4. PRODUCT_INGREDIENTS
-- ============================================================

CREATE TABLE product_ingredients (
  id             SERIAL       PRIMARY KEY,
  product_id     INTEGER      NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name           VARCHAR(100) NOT NULL,
  is_removable   BOOLEAN      NOT NULL DEFAULT TRUE,
  display_order  INTEGER      NOT NULL DEFAULT 0,
  CONSTRAINT uq_ingredient_per_product UNIQUE (product_id, name)
);

CREATE INDEX idx_ingredients_product ON product_ingredients(product_id);

-- ============================================================
-- 5. PRODUCT_ADDONS
-- ============================================================

CREATE TABLE product_addons (
  id             SERIAL        PRIMARY KEY,
  product_id     INTEGER       NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name           VARCHAR(100)  NOT NULL,
  price          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
  display_order  INTEGER       NOT NULL DEFAULT 0,
  CONSTRAINT uq_addon_per_product UNIQUE (product_id, name),
  CONSTRAINT ck_addons_price_non_negative CHECK (price >= 0)
);

CREATE INDEX idx_addons_product ON product_addons(product_id);

-- ============================================================
-- 6. PRODUCT_FLAVORS
-- ============================================================

CREATE TABLE product_flavors (
  id             SERIAL       PRIMARY KEY,
  product_id     INTEGER      NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name           VARCHAR(100) NOT NULL,
  is_available   BOOLEAN      NOT NULL DEFAULT TRUE,
  display_order  INTEGER      NOT NULL DEFAULT 0,
  CONSTRAINT uq_flavor_per_product UNIQUE(product_id, name)
);

CREATE INDEX idx_flavors_product ON product_flavors(product_id);

-- ============================================================
-- 7. PRODUCT_SIZES
-- ============================================================

CREATE TABLE product_sizes (
  id             SERIAL        PRIMARY KEY,
  product_id     INTEGER       NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name           VARCHAR(50)   NOT NULL,
  ml             VARCHAR(20),
  price          DECIMAL(10,2) NOT NULL,
  is_available   BOOLEAN       NOT NULL DEFAULT TRUE,
  display_order  INTEGER       NOT NULL DEFAULT 0,
  CONSTRAINT uq_size_per_product UNIQUE(product_id, name),
  CONSTRAINT ck_sizes_price_positive CHECK(price >= 0)
);

CREATE INDEX idx_sizes_product ON product_sizes(product_id);

-- ============================================================
-- 8. CUSTOMERS
-- ============================================================

CREATE TABLE customers (
  id           SERIAL       PRIMARY KEY,
  name         VARCHAR(150) NOT NULL,
  phone        VARCHAR(20)  NOT NULL UNIQUE,
  street       VARCHAR(255),
  number       VARCHAR(20),
  neighborhood VARCHAR(100),
  complement   VARCHAR(255),
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customers_phone ON customers(phone);

-- ============================================================
-- 9. ORDERS
-- ============================================================

CREATE TABLE orders (
  id               SERIAL             PRIMARY KEY,
  customer_id      INTEGER REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE,
  customer_name    VARCHAR(150) NOT NULL,
  customer_phone   VARCHAR(20)  NOT NULL,
  delivery_type    delivery_type_enum NOT NULL DEFAULT 'delivery',
  delivery_address TEXT,
  payment_method   payment_method_enum NOT NULL,
  change_for       DECIMAL(10,2),
  subtotal         DECIMAL(10,2) NOT NULL,
  delivery_fee     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total            DECIMAL(10,2) NOT NULL,
  status           order_status_enum NOT NULL DEFAULT 'pending',
  whatsapp_sent    BOOLEAN NOT NULL DEFAULT FALSE,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_orders_subtotal_positive CHECK(subtotal >= 0),
  CONSTRAINT ck_orders_total_positive    CHECK(total >= 0),
  CONSTRAINT ck_orders_delivery_fee_non_negative CHECK(delivery_fee >= 0),
  CONSTRAINT ck_orders_delivery_address CHECK(
    delivery_type = 'pickup' OR (delivery_type = 'delivery' AND delivery_address IS NOT NULL AND TRIM(delivery_address) <> '')
  ),
  CONSTRAINT ck_orders_change_for CHECK(change_for IS NULL OR (payment_method = 'cash' AND change_for >= total))
);

CREATE INDEX idx_orders_customer    ON orders(customer_id);
CREATE INDEX idx_orders_status      ON orders(status);
CREATE INDEX idx_orders_created     ON orders(created_at DESC);
CREATE INDEX idx_orders_status_date ON orders(status, created_at DESC);

-- ============================================================
-- 10. ORDER_ITEMS
-- ============================================================

CREATE TABLE order_items (
  id                  SERIAL        PRIMARY KEY,
  order_id            INTEGER       NOT NULL REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
  product_id          INTEGER       NOT NULL REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  product_name        VARCHAR(150)  NOT NULL,
  product_image_url   VARCHAR(500),
  quantity            INTEGER       NOT NULL DEFAULT 1,
  base_price          DECIMAL(10,2) NOT NULL,
  addons_total        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  final_price         DECIMAL(10,2) NOT NULL,
  removed_ingredients JSONB         DEFAULT '[]'::jsonb,
  selected_addons     JSONB         DEFAULT '[]'::jsonb,
  selected_flavor     VARCHAR(100),
  selected_size       VARCHAR(100),
  observation         TEXT,
  CONSTRAINT ck_order_items_quantity_positive CHECK(quantity >= 1),
  CONSTRAINT ck_order_items_base_price_positive CHECK(base_price >= 0),
  CONSTRAINT ck_order_items_final_price_positive CHECK(final_price >= 0),
  CONSTRAINT ck_order_items_addons_total_positive CHECK(addons_total >= 0),
  CONSTRAINT ck_order_items_observation_length CHECK(observation IS NULL OR LENGTH(observation) <= 200)
);

CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ============================================================
-- 11. TRIGGERS: Atualização automática do updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_settings_updated BEFORE UPDATE ON store_settings FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_categories_updated     BEFORE UPDATE ON categories     FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_products_updated       BEFORE UPDATE ON products       FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_customers_updated      BEFORE UPDATE ON customers      FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_orders_updated         BEFORE UPDATE ON orders         FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();