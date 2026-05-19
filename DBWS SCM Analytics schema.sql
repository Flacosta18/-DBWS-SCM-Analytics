-- ============================================================
--  Dade Bevs, Wines and Spirits — SCM Analytics Database
--  Author: Bon
--  Description: Supply chain analytics database for a regional
--               beverage distributor covering inventory management,
--               demand forecasting, replenishment, supplier
--               performance, and logistics KPI reporting.
--               Designed to support Tableau dashboards and
--               ad-hoc SQL analysis across SCM functions.
-- ============================================================

CREATE DATABASE IF NOT EXISTS dbws_scm;
USE dbws_scm;

-- ------------------------------------------------------------
-- SUPPLIERS
-- ------------------------------------------------------------
CREATE TABLE Suppliers (
    supplier_id         INT           NOT NULL AUTO_INCREMENT,
    supplier_name       VARCHAR(60)   NOT NULL,
    supplier_type       VARCHAR(20)   NOT NULL,  -- Winery, Brewery, Distillery, Import
    country             VARCHAR(30),
    region              VARCHAR(30),
    contact_name        VARCHAR(40),
    contact_email       VARCHAR(60),
    contact_phone       CHAR(10),
    lead_time_days      INT           NOT NULL DEFAULT 7,
    payment_terms_days  INT           NOT NULL DEFAULT 30,
    active              BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (supplier_id)
);

-- ------------------------------------------------------------
-- PRODUCT CATEGORIES
-- ------------------------------------------------------------
CREATE TABLE Categories (
    category_id         INT           NOT NULL AUTO_INCREMENT,
    category_name       VARCHAR(30)   NOT NULL,  -- Wine, Beer, Spirits, Non-Alcoholic
    subcategory         VARCHAR(30),              -- Red Wine, IPA, Bourbon, etc.
    PRIMARY KEY (category_id)
);

-- ------------------------------------------------------------
-- PRODUCTS (SKU Master)
-- ------------------------------------------------------------
CREATE TABLE Products (
    product_id          INT           NOT NULL AUTO_INCREMENT,
    supplier_id         INT           NOT NULL,
    category_id         INT           NOT NULL,
    sku                 VARCHAR(20)   NOT NULL UNIQUE,
    product_name        VARCHAR(80)   NOT NULL,
    brand               VARCHAR(50)   NOT NULL,
    unit_size           VARCHAR(20),              -- 750ml, 12oz, 1L, etc.
    pack_size           TINYINT       NOT NULL DEFAULT 12,  -- Units per case
    unit_cost           DECIMAL(10,2) NOT NULL,
    unit_price          DECIMAL(10,2) NOT NULL,
    weight_lbs          DECIMAL(5,2),
    active              BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (product_id),
    CONSTRAINT fk_prod_supplier FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- ------------------------------------------------------------
-- WAREHOUSES
-- ------------------------------------------------------------
CREATE TABLE Warehouses (
    warehouse_id        INT           NOT NULL AUTO_INCREMENT,
    warehouse_name      VARCHAR(50)   NOT NULL,
    city                VARCHAR(30)   NOT NULL,
    state               CHAR(2)       NOT NULL,
    region              VARCHAR(20),              -- Southeast, Southwest, etc.
    capacity_cases      INT,
    PRIMARY KEY (warehouse_id)
);

-- ------------------------------------------------------------
-- INVENTORY (Current snapshot per warehouse per SKU)
-- ------------------------------------------------------------
CREATE TABLE Inventory (
    inventory_id        INT           NOT NULL AUTO_INCREMENT,
    product_id          INT           NOT NULL,
    warehouse_id        INT           NOT NULL,
    qty_on_hand         INT           NOT NULL DEFAULT 0,   -- Cases on hand
    qty_on_order        INT           NOT NULL DEFAULT 0,   -- Cases in open POs
    qty_allocated       INT           NOT NULL DEFAULT 0,   -- Cases committed to orders
    reorder_point       INT           NOT NULL DEFAULT 10,  -- Cases — trigger reorder
    safety_stock        INT           NOT NULL DEFAULT 5,   -- Cases — minimum buffer
    max_stock_level     INT,                                -- Cases — max capacity
    last_updated        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (inventory_id),
    CONSTRAINT fk_inv_product   FOREIGN KEY (product_id)   REFERENCES Products(product_id),
    CONSTRAINT fk_inv_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    UNIQUE KEY uq_inv_prod_wh (product_id, warehouse_id)
);

-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------
CREATE TABLE Customers (
    customer_id         INT           NOT NULL AUTO_INCREMENT,
    customer_name       VARCHAR(80)   NOT NULL,
    customer_type       VARCHAR(20)   NOT NULL,  -- Restaurant, Retail, Bar, Hotel
    city                VARCHAR(30)   NOT NULL,
    state               CHAR(2)       NOT NULL,
    sales_territory     VARCHAR(30),
    account_manager     VARCHAR(40),
    PRIMARY KEY (customer_id)
);

-- ------------------------------------------------------------
-- SALES ORDERS
-- ------------------------------------------------------------
CREATE TABLE Sales_Orders (
    order_id            INT           NOT NULL AUTO_INCREMENT,
    customer_id         INT           NOT NULL,
    warehouse_id        INT           NOT NULL,
    order_date          DATE          NOT NULL,
    requested_ship_date DATE,
    actual_ship_date    DATE,
    order_status        VARCHAR(15)   NOT NULL DEFAULT 'Open',  -- Open, Shipped, Cancelled
    total_cases         INT,
    total_revenue       DECIMAL(12,2),
    PRIMARY KEY (order_id),
    CONSTRAINT fk_so_customer  FOREIGN KEY (customer_id)  REFERENCES Customers(customer_id),
    CONSTRAINT fk_so_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

-- ------------------------------------------------------------
-- SALES ORDER LINES
-- ------------------------------------------------------------
CREATE TABLE Sales_Order_Lines (
    line_id             INT           NOT NULL AUTO_INCREMENT,
    order_id            INT           NOT NULL,
    product_id          INT           NOT NULL,
    qty_ordered         INT           NOT NULL,   -- Cases
    qty_shipped         INT           NOT NULL DEFAULT 0,
    unit_price          DECIMAL(10,2) NOT NULL,
    line_total          DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (line_id),
    CONSTRAINT fk_sol_order   FOREIGN KEY (order_id)   REFERENCES Sales_Orders(order_id),
    CONSTRAINT fk_sol_product FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- ------------------------------------------------------------
-- PURCHASE ORDERS (Replenishment)
-- ------------------------------------------------------------
CREATE TABLE Purchase_Orders (
    po_id               INT           NOT NULL AUTO_INCREMENT,
    supplier_id         INT           NOT NULL,
    warehouse_id        INT           NOT NULL,
    po_date             DATE          NOT NULL,
    expected_receipt    DATE,
    actual_receipt      DATE,
    po_status           VARCHAR(15)   NOT NULL DEFAULT 'Open',  -- Open, Received, Cancelled
    total_cases         INT,
    total_cost          DECIMAL(12,2),
    PRIMARY KEY (po_id),
    CONSTRAINT fk_po_supplier  FOREIGN KEY (supplier_id)  REFERENCES Suppliers(supplier_id),
    CONSTRAINT fk_po_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

-- ------------------------------------------------------------
-- PURCHASE ORDER LINES
-- ------------------------------------------------------------
CREATE TABLE PO_Lines (
    po_line_id          INT           NOT NULL AUTO_INCREMENT,
    po_id               INT           NOT NULL,
    product_id          INT           NOT NULL,
    qty_ordered         INT           NOT NULL,
    qty_received        INT           NOT NULL DEFAULT 0,
    unit_cost           DECIMAL(10,2) NOT NULL,
    line_total          DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (po_line_id),
    CONSTRAINT fk_pol_po      FOREIGN KEY (po_id)      REFERENCES Purchase_Orders(po_id),
    CONSTRAINT fk_pol_product FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- ------------------------------------------------------------
-- DEMAND FORECAST (Monthly, by SKU by Warehouse)
-- ------------------------------------------------------------
CREATE TABLE Demand_Forecast (
    forecast_id         INT           NOT NULL AUTO_INCREMENT,
    product_id          INT           NOT NULL,
    warehouse_id        INT           NOT NULL,
    forecast_month      DATE          NOT NULL,   -- First day of month
    forecasted_cases    INT           NOT NULL,
    actual_cases        INT,                      -- Filled in after month closes
    forecast_method     VARCHAR(20),              -- Moving_Avg, ML_Model, Manual
    PRIMARY KEY (forecast_id),
    CONSTRAINT fk_fc_product   FOREIGN KEY (product_id)   REFERENCES Products(product_id),
    CONSTRAINT fk_fc_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

-- ------------------------------------------------------------
-- LOGISTICS (Delivery Performance)
-- ------------------------------------------------------------
CREATE TABLE Logistics (
    delivery_id         INT           NOT NULL AUTO_INCREMENT,
    order_id            INT           NOT NULL,
    carrier             VARCHAR(40),
    promised_date       DATE          NOT NULL,
    actual_delivery     DATE,
    on_time             BOOLEAN,
    delivery_status     VARCHAR(15)   NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (delivery_id),
    CONSTRAINT fk_log_order FOREIGN KEY (order_id) REFERENCES Sales_Orders(order_id)
);


-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO Suppliers (supplier_name, supplier_type, country, region, lead_time_days, payment_terms_days) VALUES
    ('Napa Valley Cellars',     'Winery',    'USA',    'California',   5,  30),
    ('Modelo Group',            'Brewery',   'Mexico', 'National',     7,  30),
    ('Jack Daniel Distillery',  'Distillery','USA',    'Tennessee',    10, 45),
    ('Moët Hennessy',           'Import',    'France', 'Champagne',    21, 60),
    ('Boston Beer Company',     'Brewery',   'USA',    'National',     7,  30),
    ('Constellation Brands',    'Winery',    'USA',    'National',     5,  30);

INSERT INTO Categories (category_name, subcategory) VALUES
    ('Wine',    'Red Wine'),
    ('Wine',    'White Wine'),
    ('Wine',    'Sparkling'),
    ('Beer',    'Import Lager'),
    ('Beer',    'Craft IPA'),
    ('Spirits', 'Whiskey'),
    ('Spirits', 'Cognac'),
    ('Beer',    'Hard Seltzer');

INSERT INTO Products (supplier_id, category_id, sku, product_name, brand, unit_size, pack_size, unit_cost, unit_price) VALUES
    (1, 1, 'NVC-CAB-001', 'Cabernet Sauvignon Reserve',  'Napa Valley Cellars', '750ml', 12, 14.50, 24.99),
    (1, 2, 'NVC-CHD-002', 'Chardonnay Estate',           'Napa Valley Cellars', '750ml', 12, 11.00, 18.99),
    (2, 4, 'MOD-CER-003', 'Modelo Especial',             'Modelo',              '12oz',  24,  1.20,  2.49),
    (2, 4, 'MOD-NEG-004', 'Modelo Negra',                'Modelo',              '12oz',  24,  1.30,  2.69),
    (3, 6, 'JD-TEN-005',  'Jack Daniels Old No. 7',      'Jack Daniels',        '750ml', 12, 18.00, 29.99),
    (4, 7, 'MH-HEN-006',  'Hennessy VS Cognac',          'Hennessy',            '750ml', 12, 28.00, 44.99),
    (4, 3, 'MH-DOM-007',  'Dom Perignon Vintage',        'Dom Perignon',        '750ml',  6, 95.00,159.99),
    (5, 5, 'BBC-SA-008',  'Samuel Adams Boston Lager',   'Samuel Adams',        '12oz',  24,  1.10,  2.29),
    (6, 8, 'CON-COO-009', 'Corona Hard Seltzer',         'Corona',              '12oz',  24,  1.15,  2.39),
    (5, 5, 'BBC-IPA-010', 'Samuel Adams New England IPA','Samuel Adams',        '16oz',  24,  1.40,  2.89);

INSERT INTO Warehouses (warehouse_name, city, state, region, capacity_cases) VALUES
    ('Miami Distribution Center',       'Miami',       'FL', 'Southeast',  50000),
    ('Orlando Fulfillment Hub',         'Orlando',     'FL', 'Southeast',  35000),
    ('Tampa Bay Warehouse',             'Tampa',       'FL', 'Southeast',  28000),
    ('Atlanta Regional Center',         'Atlanta',     'GA', 'Southeast',  45000);

INSERT INTO Inventory (product_id, warehouse_id, qty_on_hand, qty_on_order, qty_allocated, reorder_point, safety_stock, max_stock_level) VALUES
    (1,  1, 320,  0,  45, 100,  50,  600),
    (2,  1, 180,  0,  30,  80,  40,  400),
    (3,  1, 850, 200, 120, 300, 150, 2000),
    (4,  1, 220,  0,  40, 150,  75,  800),
    (5,  1, 290,  0,  60, 120,  60,  700),
    (6,  1,  95,  50,  20,  60,  30,  300),
    (7,  1,  18,  0,   5,  15,   8,   80),
    (8,  2, 640, 100,  80, 250, 125, 1500),
    (9,  2, 410,  0,  50, 200, 100, 1200),
    (10, 2, 155,  0,  25, 100,  50,  600),
    (1,  3, 210,  0,  30,  80,  40,  400),
    (3,  3, 520,  0,  90, 200, 100, 1000),
    (5,  4, 380, 100,  70, 150,  75,  900),
    (6,  4,  40,  30,  10,  40,  20,  200);

INSERT INTO Customers (customer_name, customer_type, city, state, sales_territory, account_manager) VALUES
    ('Prime Steakhouse Group',    'Restaurant', 'Miami',     'FL', 'South Florida',   'Carlos M.'),
    ('Total Wine & More FL',      'Retail',     'Miami',     'FL', 'South Florida',   'Carlos M.'),
    ('Marriott Biscayne Bay',     'Hotel',      'Miami',     'FL', 'South Florida',   'Carlos M.'),
    ('World of Beer Orlando',     'Bar',        'Orlando',   'FL', 'Central Florida', 'Ashley T.'),
    ('Publix Liquors Central',    'Retail',     'Orlando',   'FL', 'Central Florida', 'Ashley T.'),
    ('Tampa Bay Brewing Co.',     'Bar',        'Tampa',     'FL', 'West Florida',    'Marco R.'),
    ('Whole Foods Market Atlanta','Retail',     'Atlanta',   'GA', 'Georgia',         'Diana C.'),
    ('Hilton Peachtree',          'Hotel',      'Atlanta',   'GA', 'Georgia',         'Diana C.');

INSERT INTO Sales_Orders (customer_id, warehouse_id, order_date, requested_ship_date, actual_ship_date, order_status, total_cases, total_revenue) VALUES
    (1, 1, '2025-01-05', '2025-01-07', '2025-01-07', 'Shipped',   45, 4820.55),
    (2, 1, '2025-01-08', '2025-01-10', '2025-01-10', 'Shipped',   120,7540.80),
    (3, 1, '2025-01-12', '2025-01-14', '2025-01-15', 'Shipped',   30, 2910.70),
    (4, 2, '2025-01-15', '2025-01-17', '2025-01-17', 'Shipped',   60, 3420.40),
    (5, 2, '2025-01-20', '2025-01-22', '2025-01-22', 'Shipped',   200,9850.00),
    (6, 3, '2025-02-01', '2025-02-03', '2025-02-03', 'Shipped',   55, 4120.25),
    (7, 4, '2025-02-05', '2025-02-07', '2025-02-08', 'Shipped',   180,8960.50),
    (8, 4, '2025-02-10', '2025-02-12', NULL,          'Open',      40, 3200.00),
    (1, 1, '2025-02-15', '2025-02-17', '2025-02-17', 'Shipped',   50, 5100.00),
    (2, 1, '2025-03-01', '2025-03-03', NULL,          'Open',      150,9200.00);

INSERT INTO Sales_Order_Lines (order_id, product_id, qty_ordered, qty_shipped, unit_price, line_total) VALUES
    (1, 1,  20, 20, 24.99,  499.80),
    (1, 5,  15, 15, 29.99,  449.85),
    (1, 6,  10, 10, 44.99,  449.90),
    (2, 3,  60, 60,  2.49,  149.40),
    (2, 4,  40, 40,  2.69,  107.60),
    (2, 8,  20, 20,  2.29,   45.80),
    (3, 7,   5,  5, 159.99, 799.95),
    (3, 1,  25, 25, 24.99,  624.75),
    (4, 9,  30, 30,  2.39,   71.70),
    (4, 10, 30, 30,  2.89,   86.70),
    (5, 3, 100,100,  2.49,  249.00),
    (5, 9,  60, 60,  2.39,  143.40),
    (5, 8,  40, 40,  2.29,   91.60),
    (6, 5,  30, 30, 29.99,  899.70),
    (6, 2,  25, 25, 18.99,  474.75),
    (7, 3,  80, 80,  2.49,  199.20),
    (7, 8,  60, 60,  2.29,  137.40),
    (7, 1,  40, 40, 24.99,  999.60),
    (8, 6,  20,  0, 44.99,  899.80),
    (8, 7,   5,  0,159.99,  799.95),
    (9, 1,  30, 30, 24.99,  749.70),
    (9, 5,  20, 20, 29.99,  599.80),
   (10, 3,  80,  0,  2.49,  199.20),
   (10, 4,  40,  0,  2.69,  107.60),
   (10, 9,  30,  0,  2.39,   71.70);

INSERT INTO Purchase_Orders (supplier_id, warehouse_id, po_date, expected_receipt, actual_receipt, po_status, total_cases, total_cost) VALUES
    (2, 1, '2025-01-02', '2025-01-09',  '2025-01-09',  'Received',  500,  6000.00),
    (1, 1, '2025-01-10', '2025-01-15',  '2025-01-16',  'Received',  200,  2900.00),
    (3, 1, '2025-01-20', '2025-01-30',  '2025-01-30',  'Received',  150,  2700.00),
    (4, 1, '2025-02-01', '2025-02-22',  NULL,           'Open',       50,  6150.00),
    (2, 2, '2025-02-05', '2025-02-12',  '2025-02-12',  'Received',  400,  4800.00),
    (5, 2, '2025-02-10', '2025-02-17',  '2025-02-19',  'Received',  300,  3300.00),
    (3, 4, '2025-02-15', '2025-02-25',  '2025-02-25',  'Received',  200,  3600.00),
    (6, 3, '2025-03-01', '2025-03-06',  NULL,           'Open',      300,  3450.00);

INSERT INTO PO_Lines (po_id, product_id, qty_ordered, qty_received, unit_cost, line_total) VALUES
    (1, 3, 300, 300, 1.20,  360.00),
    (1, 4, 200, 200, 1.30,  260.00),
    (2, 1, 120, 120, 14.50, 1740.00),
    (2, 2,  80,  80, 11.00,  880.00),
    (3, 5, 150, 150, 18.00, 2700.00),
    (4, 6,  30,   0, 28.00,  840.00),
    (4, 7,  20,   0, 95.00, 1900.00),
    (5, 3, 200, 200,  1.20,  240.00),
    (5, 9, 200, 200,  1.15,  230.00),
    (6, 8, 200, 200,  1.10,  220.00),
    (6,10, 100, 100,  1.40,  140.00),
    (7, 5, 200, 200, 18.00, 3600.00),
    (8, 9, 200,   0,  1.15,  230.00),
    (8, 3, 100,   0,  1.20,  120.00);

INSERT INTO Demand_Forecast (product_id, warehouse_id, forecast_month, forecasted_cases, actual_cases, forecast_method) VALUES
    (1, 1, '2025-01-01', 150, 145, 'Moving_Avg'),
    (2, 1, '2025-01-01',  90,  85, 'Moving_Avg'),
    (3, 1, '2025-01-01', 500, 520, 'ML_Model'),
    (4, 1, '2025-01-01', 200, 190, 'ML_Model'),
    (5, 1, '2025-01-01', 180, 175, 'Moving_Avg'),
    (6, 1, '2025-01-01',  60,  55, 'Manual'),
    (7, 1, '2025-01-01',  20,  18, 'Manual'),
    (3, 2, '2025-01-01', 400, 420, 'ML_Model'),
    (8, 2, '2025-01-01', 300, 280, 'Moving_Avg'),
    (9, 2, '2025-01-01', 250, 260, 'ML_Model'),
    (1, 1, '2025-02-01', 160, 155, 'Moving_Avg'),
    (3, 1, '2025-02-01', 520, 540, 'ML_Model'),
    (5, 1, '2025-02-01', 190, 185, 'Moving_Avg'),
    (3, 3, '2025-02-01', 300, 310, 'ML_Model'),
    (5, 4, '2025-02-01', 220, 215, 'Moving_Avg'),
    (1, 1, '2025-03-01', 170, NULL, 'ML_Model'),
    (3, 1, '2025-03-01', 550, NULL, 'ML_Model'),
    (5, 1, '2025-03-01', 195, NULL, 'Moving_Avg');

INSERT INTO Logistics (order_id, carrier, promised_date, actual_delivery, on_time, delivery_status) VALUES
    (1, 'FedEx Freight',    '2025-01-07', '2025-01-07', TRUE,  'Delivered'),
    (2, 'UPS Supply Chain', '2025-01-10', '2025-01-10', TRUE,  'Delivered'),
    (3, 'FedEx Freight',    '2025-01-14', '2025-01-15', FALSE, 'Delivered'),
    (4, 'XPO Logistics',    '2025-01-17', '2025-01-17', TRUE,  'Delivered'),
    (5, 'UPS Supply Chain', '2025-01-22', '2025-01-22', TRUE,  'Delivered'),
    (6, 'FedEx Freight',    '2025-02-03', '2025-02-03', TRUE,  'Delivered'),
    (7, 'XPO Logistics',    '2025-02-07', '2025-02-08', FALSE, 'Delivered'),
    (8, 'FedEx Freight',    '2025-02-12', NULL,          NULL,  'Pending'),
    (9, 'UPS Supply Chain', '2025-02-17', '2025-02-17', TRUE,  'Delivered'),
   (10, 'XPO Logistics',    '2025-03-03', NULL,          NULL,  'Pending');


-- ============================================================
--  SCM ANALYTICS QUERY LIBRARY
--  Mapped to key responsibilities in the SCM Analytics
--  Developer role: inventory KPIs, forecast accuracy,
--  replenishment alerts, supplier performance, logistics.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- QUERY 1: Inventory Status Dashboard
-- Purpose: Real-time inventory position per SKU per warehouse.
--          Shows available qty, on-order, allocated, and
--          days-of-supply based on avg daily demand.
--          Core input for Tableau inventory scorecard.
-- ─────────────────────────────────────────────────────────────
SELECT
    w.warehouse_name,
    p.sku,
    p.product_name,
    p.brand,
    c.category_name,
    c.subcategory,
    i.qty_on_hand,
    i.qty_on_order,
    i.qty_allocated,
    i.qty_on_hand - i.qty_allocated                         AS qty_available,
    i.reorder_point,
    i.safety_stock,
    ROUND(i.qty_on_hand * p.unit_cost, 2)                   AS inventory_value,
    CASE
        WHEN i.qty_on_hand <= i.safety_stock               THEN 'Critical'
        WHEN i.qty_on_hand <= i.reorder_point              THEN 'Reorder Now'
        WHEN i.qty_on_hand >= i.max_stock_level * 0.9      THEN 'Overstocked'
        ELSE 'Healthy'
    END                                                     AS stock_status
FROM Inventory i
JOIN Products   p ON i.product_id   = p.product_id
JOIN Warehouses w ON i.warehouse_id = w.warehouse_id
JOIN Categories c ON p.category_id  = c.category_id
ORDER BY
    FIELD(stock_status,'Critical','Reorder Now','Healthy','Overstocked'),
    w.warehouse_name,
    p.brand;


-- ─────────────────────────────────────────────────────────────
-- QUERY 2: Reorder Alert Report
-- Purpose: Identifies all SKUs at or below reorder point.
--          Calculates recommended order quantity (up to max
--          stock level) and flags urgency level. Used to
--          trigger replenishment purchase orders.
-- ─────────────────────────────────────────────────────────────
SELECT
    w.warehouse_name,
    p.sku,
    p.product_name,
    p.brand,
    s.supplier_name,
    s.lead_time_days,
    i.qty_on_hand,
    i.qty_on_order,
    i.qty_on_hand + i.qty_on_order                          AS total_supply,
    i.reorder_point,
    i.safety_stock,
    i.max_stock_level - (i.qty_on_hand + i.qty_on_order)   AS recommended_order_qty,
    ROUND((i.max_stock_level - (i.qty_on_hand + i.qty_on_order)) * p.unit_cost, 2) AS est_po_cost,
    CASE
        WHEN i.qty_on_hand <= i.safety_stock               THEN '🔴 URGENT'
        WHEN i.qty_on_hand <= i.reorder_point              THEN '🟡 REORDER'
        ELSE '🟢 OK'
    END                                                     AS alert_level
FROM Inventory i
JOIN Products   p ON i.product_id   = p.product_id
JOIN Warehouses w ON i.warehouse_id = w.warehouse_id
JOIN Suppliers  s ON p.supplier_id  = s.supplier_id
WHERE (i.qty_on_hand + i.qty_on_order) <= i.reorder_point
ORDER BY
    FIELD(alert_level,'🔴 URGENT','🟡 REORDER','🟢 OK'),
    est_po_cost DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 3: Forecast Accuracy — MAPE by SKU
-- Purpose: Calculates Mean Absolute Percentage Error (MAPE)
--          per SKU to measure demand planning accuracy.
--          Highlights underforecasted vs overforecasted items.
--          Drives continuous improvement in forecast methods.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.sku,
    p.product_name,
    p.brand,
    c.category_name,
    df.forecast_method,
    COUNT(df.forecast_id)                                   AS months_evaluated,
    SUM(df.forecasted_cases)                                AS total_forecasted,
    SUM(df.actual_cases)                                    AS total_actual,
    SUM(df.actual_cases) - SUM(df.forecasted_cases)         AS total_variance,
    ROUND(
        AVG(ABS(df.actual_cases - df.forecasted_cases)
            / NULLIF(df.actual_cases, 0)) * 100, 2
    )                                                       AS mape_pct,
    CASE
        WHEN AVG(ABS(df.actual_cases - df.forecasted_cases)
             / NULLIF(df.actual_cases, 0)) * 100 <= 10     THEN 'Excellent'
        WHEN AVG(ABS(df.actual_cases - df.forecasted_cases)
             / NULLIF(df.actual_cases, 0)) * 100 <= 20     THEN 'Acceptable'
        ELSE 'Needs Review'
    END                                                     AS accuracy_rating
FROM Demand_Forecast df
JOIN Products   p ON df.product_id   = p.product_id
JOIN Categories c ON p.category_id   = c.category_id
WHERE df.actual_cases IS NOT NULL
GROUP BY p.product_id, df.forecast_method
ORDER BY mape_pct DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 4: Supplier Performance Scorecard
-- Purpose: Measures on-time delivery rate and fill rate
--          per supplier. Key KPI for vendor management
--          and procurement negotiations.
-- ─────────────────────────────────────────────────────────────
SELECT
    s.supplier_name,
    s.supplier_type,
    s.lead_time_days                                        AS quoted_lead_time,
    COUNT(po.po_id)                                         AS total_pos,
    SUM(CASE WHEN po.po_status = 'Received' THEN 1 ELSE 0 END) AS received_pos,
    SUM(pol.qty_ordered)                                    AS total_cases_ordered,
    SUM(pol.qty_received)                                   AS total_cases_received,
    ROUND(SUM(pol.qty_received) / NULLIF(SUM(pol.qty_ordered),0) * 100, 1) AS fill_rate_pct,
    SUM(CASE WHEN po.actual_receipt <= po.expected_receipt
             AND po.po_status = 'Received' THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(
        SUM(CASE WHEN po.actual_receipt <= po.expected_receipt
                 AND po.po_status = 'Received' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN po.po_status='Received' THEN 1 ELSE 0 END),0) * 100, 1
    )                                                       AS on_time_pct,
    ROUND(AVG(DATEDIFF(po.actual_receipt, po.po_date)),1)   AS avg_actual_lead_days
FROM Suppliers s
LEFT JOIN Purchase_Orders po  ON s.supplier_id = po.supplier_id
LEFT JOIN PO_Lines        pol ON po.po_id       = pol.po_id
GROUP BY s.supplier_id
ORDER BY fill_rate_pct DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 5: Revenue & Volume KPIs by Category
-- Purpose: Sales performance by beverage category.
--          Shows revenue, cases sold, avg price per case,
--          and margin. Core Tableau dashboard metric.
-- ─────────────────────────────────────────────────────────────
SELECT
    c.category_name,
    c.subcategory,
    COUNT(DISTINCT sol.order_id)                            AS total_orders,
    SUM(sol.qty_shipped)                                    AS cases_sold,
    ROUND(SUM(sol.line_total), 2)                           AS total_revenue,
    ROUND(SUM(sol.qty_shipped * p.unit_cost), 2)            AS total_cogs,
    ROUND(SUM(sol.line_total) - SUM(sol.qty_shipped * p.unit_cost), 2) AS gross_profit,
    ROUND((SUM(sol.line_total) - SUM(sol.qty_shipped * p.unit_cost))
          / NULLIF(SUM(sol.line_total),0) * 100, 1)         AS margin_pct,
    ROUND(SUM(sol.line_total) / NULLIF(SUM(sol.qty_shipped),0), 2) AS avg_revenue_per_case
FROM Sales_Order_Lines sol
JOIN Products   p ON sol.product_id  = p.product_id
JOIN Categories c ON p.category_id   = c.category_id
JOIN Sales_Orders so ON sol.order_id = so.order_id
WHERE so.order_status = 'Shipped'
GROUP BY c.category_id
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 6: Inventory Turnover Rate by SKU
-- Purpose: Measures how efficiently inventory is being sold.
--          Low turnover = slow-moving / potential deadstock.
--          High turnover = risk of stockout. KPI for
--          inventory optimization and reorder planning.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.sku,
    p.product_name,
    p.brand,
    c.category_name,
    SUM(sol.qty_shipped)                                    AS total_cases_sold,
    ROUND(SUM(sol.qty_shipped * p.unit_cost), 2)            AS cogs,
    ROUND(AVG(i.qty_on_hand * p.unit_cost), 2)              AS avg_inventory_value,
    ROUND(
        SUM(sol.qty_shipped * p.unit_cost)
        / NULLIF(AVG(i.qty_on_hand * p.unit_cost), 0), 2
    )                                                       AS inventory_turnover_ratio,
    CASE
        WHEN SUM(sol.qty_shipped * p.unit_cost)
             / NULLIF(AVG(i.qty_on_hand * p.unit_cost),0) >= 4 THEN 'Fast Moving'
        WHEN SUM(sol.qty_shipped * p.unit_cost)
             / NULLIF(AVG(i.qty_on_hand * p.unit_cost),0) >= 2 THEN 'Normal'
        WHEN SUM(sol.qty_shipped * p.unit_cost)
             / NULLIF(AVG(i.qty_on_hand * p.unit_cost),0) >= 1 THEN 'Slow Moving'
        ELSE 'Dead Stock Risk'
    END                                                     AS velocity_class
FROM Sales_Order_Lines sol
JOIN Products     p  ON sol.product_id   = p.product_id
JOIN Categories   c  ON p.category_id    = c.category_id
JOIN Sales_Orders so ON sol.order_id     = so.order_id
JOIN Inventory    i  ON p.product_id     = i.product_id
WHERE so.order_status = 'Shipped'
GROUP BY p.product_id
ORDER BY inventory_turnover_ratio DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 7: On-Time Delivery (OTD) Rate by Carrier
-- Purpose: Logistics KPI — measures carrier on-time
--          performance. Supports carrier contract reviews
--          and SLA monitoring for the logistics team.
-- ─────────────────────────────────────────────────────────────
SELECT
    l.carrier,
    COUNT(l.delivery_id)                                    AS total_shipments,
    SUM(CASE WHEN l.delivery_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN l.on_time = TRUE  THEN 1 ELSE 0 END)      AS on_time_count,
    SUM(CASE WHEN l.on_time = FALSE THEN 1 ELSE 0 END)      AS late_count,
    ROUND(SUM(CASE WHEN l.on_time = TRUE THEN 1 ELSE 0 END)
          / NULLIF(SUM(CASE WHEN l.delivery_status='Delivered' THEN 1 ELSE 0 END),0)
          * 100, 1)                                         AS otd_rate_pct,
    ROUND(AVG(CASE WHEN l.on_time = FALSE
              THEN DATEDIFF(l.actual_delivery, l.promised_date) END), 1) AS avg_days_late
FROM Logistics l
GROUP BY l.carrier
ORDER BY otd_rate_pct DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 8: Forecast vs Actual — Monthly Trend
-- Purpose: Side-by-side comparison of forecasted vs actual
--          demand by month and category. Supports demand
--          planning review meetings and trend analysis.
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(df.forecast_month, '%Y-%m')                 AS month,
    c.category_name,
    df.forecast_method,
    SUM(df.forecasted_cases)                                AS forecasted_cases,
    SUM(df.actual_cases)                                    AS actual_cases,
    SUM(df.actual_cases) - SUM(df.forecasted_cases)         AS variance_cases,
    ROUND((SUM(df.actual_cases) - SUM(df.forecasted_cases))
          / NULLIF(SUM(df.forecasted_cases),0) * 100, 1)    AS variance_pct
FROM Demand_Forecast df
JOIN Products   p ON df.product_id  = p.product_id
JOIN Categories c ON p.category_id  = c.category_id
WHERE df.actual_cases IS NOT NULL
GROUP BY DATE_FORMAT(df.forecast_month,'%Y-%m'), c.category_name, df.forecast_method
ORDER BY month, category_name;


-- ─────────────────────────────────────────────────────────────
-- QUERY 9: Order Fill Rate by Customer
-- Purpose: Measures what % of ordered cases were actually
--          shipped per customer. Low fill rate = service
--          level issues that risk customer relationship.
-- ─────────────────────────────────────────────────────────────
SELECT
    cu.customer_name,
    cu.customer_type,
    cu.sales_territory,
    cu.account_manager,
    COUNT(DISTINCT so.order_id)                             AS total_orders,
    SUM(sol.qty_ordered)                                    AS total_cases_ordered,
    SUM(sol.qty_shipped)                                    AS total_cases_shipped,
    SUM(sol.qty_ordered) - SUM(sol.qty_shipped)             AS cases_unfulfilled,
    ROUND(SUM(sol.qty_shipped)
          / NULLIF(SUM(sol.qty_ordered),0) * 100, 1)        AS fill_rate_pct,
    ROUND(SUM(sol.line_total), 2)                           AS total_revenue
FROM Customers cu
JOIN Sales_Orders      so  ON cu.customer_id  = so.customer_id
JOIN Sales_Order_Lines sol ON so.order_id     = sol.order_id
GROUP BY cu.customer_id
ORDER BY fill_rate_pct ASC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 10: Days of Supply (DOS) by SKU
-- Purpose: Calculates how many days of stock remain based
--          on average daily demand. Critical metric for
--          replenishment planning and stockout prevention.
-- ─────────────────────────────────────────────────────────────
SELECT
    w.warehouse_name,
    p.sku,
    p.product_name,
    p.brand,
    i.qty_on_hand,
    i.qty_on_order,
    i.qty_on_hand + i.qty_on_order                          AS total_supply_cases,
    ROUND(SUM(sol.qty_shipped) / 90.0, 2)                   AS avg_daily_demand_cases,
    ROUND((i.qty_on_hand + i.qty_on_order)
          / NULLIF(SUM(sol.qty_shipped) / 90.0, 0), 0)      AS days_of_supply,
    CASE
        WHEN (i.qty_on_hand + i.qty_on_order)
             / NULLIF(SUM(sol.qty_shipped)/90.0,0) <= 7     THEN 'Critical — < 1 week'
        WHEN (i.qty_on_hand + i.qty_on_order)
             / NULLIF(SUM(sol.qty_shipped)/90.0,0) <= 14    THEN 'Low — < 2 weeks'
        WHEN (i.qty_on_hand + i.qty_on_order)
             / NULLIF(SUM(sol.qty_shipped)/90.0,0) <= 30    THEN 'Adequate'
        ELSE 'Well Stocked'
    END                                                     AS dos_status
FROM Inventory i
JOIN Products          p   ON i.product_id   = p.product_id
JOIN Warehouses        w   ON i.warehouse_id = w.warehouse_id
JOIN Sales_Order_Lines sol ON p.product_id   = sol.product_id
JOIN Sales_Orders      so  ON sol.order_id   = so.order_id
WHERE so.order_status = 'Shipped'
GROUP BY i.inventory_id
ORDER BY days_of_supply ASC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 11: Warehouse Inventory Value Summary
-- Purpose: Total inventory value and utilization per
--          warehouse. Supports working capital analysis
--          and warehouse capacity planning.
-- ─────────────────────────────────────────────────────────────
SELECT
    w.warehouse_name,
    w.city,
    w.state,
    w.region,
    w.capacity_cases,
    SUM(i.qty_on_hand)                                      AS total_cases_on_hand,
    ROUND(SUM(i.qty_on_hand) / w.capacity_cases * 100, 1)  AS utilization_pct,
    ROUND(SUM(i.qty_on_hand * p.unit_cost), 2)              AS inventory_value,
    COUNT(DISTINCT i.product_id)                            AS distinct_skus,
    SUM(CASE WHEN i.qty_on_hand <= i.safety_stock THEN 1 ELSE 0 END) AS critical_skus,
    SUM(CASE WHEN i.qty_on_hand <= i.reorder_point THEN 1 ELSE 0 END) AS skus_to_reorder
FROM Warehouses w
JOIN Inventory  i ON w.warehouse_id = i.warehouse_id
JOIN Products   p ON i.product_id   = p.product_id
GROUP BY w.warehouse_id
ORDER BY inventory_value DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 12: Top SKUs by Revenue Contribution (Pareto / ABC)
-- Purpose: Ranks SKUs by revenue share to support ABC
--          inventory classification. Top 20% of SKUs
--          typically drive 80% of revenue (Pareto principle).
--          Used for prioritizing replenishment and safety stock.
-- ─────────────────────────────────────────────────────────────
WITH sku_revenue AS (
    SELECT
        p.sku,
        p.product_name,
        p.brand,
        c.category_name,
        SUM(sol.line_total)                                 AS sku_revenue,
        SUM(sol.qty_shipped)                                AS cases_sold
    FROM Sales_Order_Lines sol
    JOIN Products     p  ON sol.product_id  = p.product_id
    JOIN Categories   c  ON p.category_id   = c.category_id
    JOIN Sales_Orders so ON sol.order_id    = so.order_id
    WHERE so.order_status = 'Shipped'
    GROUP BY p.product_id
),
ranked AS (
    SELECT *,
        SUM(sku_revenue) OVER ()                            AS total_revenue,
        SUM(sku_revenue) OVER (ORDER BY sku_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM sku_revenue
)
SELECT
    sku, product_name, brand, category_name,
    ROUND(sku_revenue, 2)                                   AS revenue,
    cases_sold,
    ROUND(sku_revenue / total_revenue * 100, 1)             AS revenue_share_pct,
    ROUND(cumulative_revenue / total_revenue * 100, 1)      AS cumulative_pct,
    CASE
        WHEN cumulative_revenue / total_revenue <= 0.80     THEN 'A — Top Tier'
        WHEN cumulative_revenue / total_revenue <= 0.95     THEN 'B — Mid Tier'
        ELSE                                                     'C — Low Tier'
    END                                                     AS abc_class
FROM ranked
ORDER BY revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 13: Open Purchase Order Visibility
-- Purpose: Tracks all open POs with expected receipt dates,
--          quantities, and value. Used for inbound supply
--          planning and cash flow forecasting.
-- ─────────────────────────────────────────────────────────────
SELECT
    po.po_id,
    s.supplier_name,
    w.warehouse_name,
    po.po_date,
    po.expected_receipt,
    DATEDIFF(po.expected_receipt, CURDATE())                AS days_until_receipt,
    p.sku,
    p.product_name,
    pol.qty_ordered,
    pol.qty_received,
    pol.qty_ordered - pol.qty_received                      AS qty_outstanding,
    ROUND((pol.qty_ordered - pol.qty_received) * pol.unit_cost, 2) AS outstanding_value,
    po.po_status
FROM Purchase_Orders po
JOIN PO_Lines        pol ON po.po_id        = pol.po_id
JOIN Suppliers       s   ON po.supplier_id  = s.supplier_id
JOIN Warehouses      w   ON po.warehouse_id = w.warehouse_id
JOIN Products        p   ON pol.product_id  = p.product_id
WHERE po.po_status = 'Open'
ORDER BY po.expected_receipt ASC;


-- ─────────────────────────────────────────────────────────────
-- QUERY 14: Monthly Sales Trend (Tableau-Ready)
-- Purpose: Month-over-month revenue and volume trend.
--          Structured for direct use as a Tableau data source.
--          Supports rolling 12-month KPI dashboards.
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(so.order_date, '%Y-%m')                     AS month,
    w.region,
    c.category_name,
    COUNT(DISTINCT so.order_id)                             AS orders,
    SUM(sol.qty_shipped)                                    AS cases_shipped,
    ROUND(SUM(sol.line_total), 2)                           AS revenue,
    ROUND(SUM(sol.qty_shipped * p.unit_cost), 2)            AS cogs,
    ROUND(SUM(sol.line_total) - SUM(sol.qty_shipped * p.unit_cost), 2) AS gross_profit,
    COUNT(DISTINCT so.customer_id)                          AS active_customers
FROM Sales_Orders      so
JOIN Sales_Order_Lines sol ON so.order_id    = sol.order_id
JOIN Products          p   ON sol.product_id = p.product_id
JOIN Categories        c   ON p.category_id  = c.category_id
JOIN Warehouses        w   ON so.warehouse_id= w.warehouse_id
WHERE so.order_status = 'Shipped'
GROUP BY DATE_FORMAT(so.order_date,'%Y-%m'), w.region, c.category_name
ORDER BY month, region, category_name;
