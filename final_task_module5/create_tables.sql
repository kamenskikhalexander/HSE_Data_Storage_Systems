CREATE SCHEMA IF NOT EXISTS student22


-- Хаб продаж
CREATE TABLE IF NOT EXISTS hub_sale (
    sale_sk TEXT NOT NULL,
    sale_id INT,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (sale_sk);


-- Хаб товаров
CREATE TABLE IF NOT EXISTS hub_product (
    product_sk TEXT NOT NULL,
    product_id INT,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (product_sk);


-- Хаб отгрузок
CREATE TABLE IF NOT EXISTS hub_shipment (
    shipment_sk TEXT NOT NULL,
    shipment_id INT,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (shipment_sk);


-- Хаб клиентов
CREATE TABLE IF NOT EXISTS hub_customer (
    customer_sk TEXT NOT NULL,
    customer_id INT,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (customer_sk);


-- Линк продаж и товаров
CREATE TABLE IF NOT EXISTS link_sale_product (
    sale_product_sk TEXT NOT NULL,
    sale_sk TEXT NOT NULL,
    product_sk TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (sale_sk)
PARTITION BY RANGE (load_datetime)
(
    PARTITION p2023 START ('2023-01-01') END ('2024-01-01'),
    PARTITION p2024 START ('2024-01-01') END ('2025-01-01'),
    DEFAULT PARTITION future_dates
);

-- Линк продаж и отгрузок
CREATE TABLE IF NOT EXISTS link_sale_shipment (
    sale_shipment_sk TEXT NOT NULL,
    sale_sk TEXT NOT NULL,
    shipment_sk TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (sale_sk)
PARTITION BY RANGE (load_datetime)
(
    PARTITION p2023 START ('2023-01-01') END ('2024-01-01'),
    PARTITION p2024 START ('2024-01-01') END ('2025-01-01'),
    DEFAULT PARTITION future_dates
);

-- Линк продаж и клиентов
CREATE TABLE IF NOT EXISTS link_sale_customer (
    sale_customer_sk TEXT NOT NULL,
    sale_sk TEXT NOT NULL,
    customer_sk TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false,
    load_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT
)
WITH (APPENDONLY=true, ORIENTATION=row)
DISTRIBUTED BY (sale_sk)
PARTITION BY RANGE (load_datetime)
(
    PARTITION p2023 START ('2023-01-01') END ('2024-01-01'),
    PARTITION p2024 START ('2024-01-01') END ('2025-01-01'),
    DEFAULT PARTITION future_dates
);


-- Саттелит метрик продаж
CREATE TABLE sat_sale_metrics (
    sale_sk TEXT NOT NULL,
    load_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    sales DECIMAL(15,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(15,2),
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE DEFAULT '9999-12-31',
    hash_diff TEXT
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zlib, COMPRESSLEVEL=5)
DISTRIBUTED BY (sale_sk)
PARTITION BY RANGE (effective_from)
(
    PARTITION p2023 START (DATE '2023-01-01') END (DATE '2024-01-01'),
    PARTITION p2024 START (DATE '2024-01-01') END (DATE '2025-01-01'),
    PARTITION p_future START (DATE '2025-01-01') END (DATE '9999-12-31'),
    DEFAULT PARTITION other_dates
);

-- Саттелит категорий продуктов
CREATE TABLE sat_product_category (
    product_sk TEXT NOT NULL,
    load_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    category TEXT,
    sub_category TEXT,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE DEFAULT '9999-12-31',
    hash_diff TEXT
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zlib, COMPRESSLEVEL=5)
DISTRIBUTED BY (product_sk)
PARTITION BY RANGE (effective_from)
SUBPARTITION BY LIST (category)
(
    PARTITION p2023 START (DATE '2023-01-01') END (DATE '2024-01-01') 
    (
        SUBPARTITION p2023_furniture VALUES ('Furniture'),
        SUBPARTITION p2023_office_supplies VALUES ('Office Supplies'),
        SUBPARTITION p2023_technology VALUES ('Technology')
    ),
    PARTITION p2024 START (DATE '2024-01-01') END (DATE '2025-01-01')
    (
        SUBPARTITION p2024_furniture VALUES ('Furniture'),
        SUBPARTITION p2024_office_supplies VALUES ('Office Supplies'),
        SUBPARTITION p2024_technology VALUES ('Technology')
    ),
    PARTITION p_future START (DATE '2025-01-01') END (DATE '9999-12-31')
    (
        SUBPARTITION p_future_furniture VALUES ('Furniture'),
        SUBPARTITION p_future_office_supplies VALUES ('Office Supplies'),
        SUBPARTITION p_future_technology VALUES ('Technology')
    ),
    DEFAULT PARTITION other_dates 
    (
        SUBPARTITION other_dates_furniture VALUES ('Furniture'),
        SUBPARTITION other_dates_office_supplies VALUES ('Office Supplies'),
        SUBPARTITION other_dates_technology VALUES ('Technology')
    )
);

-- Саттелит режимов отгрузки
CREATE TABLE sat_shipment_mode (
    shipment_sk TEXT NOT NULL,
    load_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    ship_mode TEXT,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE DEFAULT '9999-12-31',
    hash_diff TEXT
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zlib, COMPRESSLEVEL=5)
DISTRIBUTED BY (shipment_sk)
PARTITION BY RANGE (effective_from)
SUBPARTITION BY LIST (ship_mode)
(
    PARTITION p2023 START (DATE '2023-01-01') END (DATE '2024-01-01') 
    (
        SUBPARTITION p2023_standard_class VALUES ('Standard Class'),
        SUBPARTITION p2023_second_class VALUES ('Second Class'),
        SUBPARTITION p2023_first_class VALUES ('First Class'),
        SUBPARTITION p2023_same_day VALUES ('Same Day')
    ),
    PARTITION p2024 START (DATE '2024-01-01') END (DATE '2025-01-01')
    (
        SUBPARTITION p2024_standard_class VALUES ('Standard Class'),
        SUBPARTITION p2024_second_class VALUES ('Second Class'),
        SUBPARTITION p2024_first_class VALUES ('First Class'),
        SUBPARTITION p2024_same_day VALUES ('Same Day')
    ),
    PARTITION p_future START (DATE '2025-01-01') END (DATE '9999-12-31')
    (
        SUBPARTITION p_future_standard_class VALUES ('Standard Class'),
        SUBPARTITION p_future_second_class VALUES ('Second Class'),
        SUBPARTITION p_future_first_class VALUES ('First Class'),
        SUBPARTITION p_future_same_day VALUES ('Same Day')
    )
);

-- Саттелит регионов клиентов
CREATE TABLE sat_customer_region (
    customer_sk TEXT NOT NULL,
    load_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    country TEXT,
    region TEXT,
    state TEXT,
    city TEXT,
    postal_code INT,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE DEFAULT '9999-12-31',
    hash_diff TEXT
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zlib, COMPRESSLEVEL=5)
DISTRIBUTED BY (customer_sk)
PARTITION BY RANGE (effective_from)
(
    PARTITION p2023 START (DATE '2023-01-01') END (DATE '2024-01-01'),
    PARTITION p2024 START (DATE '2024-01-01') END (DATE '2025-01-01'),
    PARTITION p_future START (DATE '2025-01-01') END (DATE '9999-12-31'),
    DEFAULT PARTITION other_dates
);


-- Саттелит сегментов клиентов
CREATE TABLE sat_customer_segment (
    customer_sk TEXT NOT NULL,
    load_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    segment TEXT,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE DEFAULT '9999-12-31',
    hash_diff TEXT
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zlib, COMPRESSLEVEL=5)
DISTRIBUTED BY (customer_sk)
PARTITION BY RANGE (effective_from)
(
    PARTITION p2023 START (DATE '2023-01-01') END (DATE '2024-01-01'),
    PARTITION p2024 START (DATE '2024-01-01') END (DATE '2025-01-01'),
    PARTITION p_future START (DATE '2025-01-01') END (DATE '9999-12-31'),
    DEFAULT PARTITION other_dates
);