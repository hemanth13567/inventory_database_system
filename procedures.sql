-- =============================================
-- Inventory Database System 2025
-- Stored Procedures
-- =============================================

-- =============================================
-- Procedure: add_new_product
-- Description: Inserts a new product into the products table
-- Parameters:
--   p_product_name - Name of the product
--   p_sku - Stock Keeping Unit (unique)
--   p_category_id - Foreign key to categories
--   p_supplier_id - Foreign key to suppliers
--   p_unit_price - Unit price of the product
--   p_reorder_level - Minimum stock level before reordering
--   p_description - Optional product description
-- =============================================
CREATE OR REPLACE FUNCTION add_new_product(
    p_product_name VARCHAR(200),
    p_sku VARCHAR(50),
    p_category_id INTEGER,
    p_supplier_id INTEGER,
    p_unit_price DECIMAL(12,2),
    p_reorder_level INTEGER DEFAULT 10,
    p_description TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_product_id INTEGER;
BEGIN
    -- Validate required parameters
    IF p_product_name IS NULL OR p_product_name = '' THEN
        RAISE EXCEPTION 'Product name cannot be empty';
    END IF;

    IF p_sku IS NULL OR p_sku = '' THEN
        RAISE EXCEPTION 'SKU cannot be empty';
    END IF;

    IF p_unit_price < 0 THEN
        RAISE EXCEPTION 'Unit price cannot be negative';
    END IF;

    IF p_reorder_level < 0 THEN
        RAISE EXCEPTION 'Reorder level cannot be negative';
    END IF;

    -- Check if category exists
    IF NOT EXISTS (SELECT 1 FROM categories WHERE category_id = p_category_id) THEN
        RAISE EXCEPTION 'Category with ID % does not exist', p_category_id;
    END IF;

    -- Check if supplier exists
    IF NOT EXISTS (SELECT 1 FROM suppliers WHERE supplier_id = p_supplier_id) THEN
        RAISE EXCEPTION 'Supplier with ID % does not exist', p_supplier_id;
    END IF;

    -- Check for duplicate SKU
    IF EXISTS (SELECT 1 FROM products WHERE sku = p_sku) THEN
        RAISE EXCEPTION 'SKU "%" already exists', p_sku;
    END IF;

    -- Insert the product
    INSERT INTO products (product_name, sku, category_id, supplier_id, unit_price, reorder_level, description)
    VALUES (p_product_name, p_sku, p_category_id, p_supplier_id, p_unit_price, p_reorder_level, p_description)
    RETURNING product_id INTO v_product_id;

    RAISE NOTICE 'Product created successfully with ID: %', v_product_id;
    RETURN v_product_id;

END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Procedure: record_purchase
-- Description: Records a stock purchase - increases inventory and logs transaction
-- Parameters:
--   p_product_id - Foreign key to products
--   p_warehouse_id - Foreign key to warehouses
--   p_quantity - Quantity purchased (must be positive)
--   p_supplier_id - Foreign key to suppliers (for reference)
-- =============================================
CREATE OR REPLACE FUNCTION record_purchase(
    p_product_id INTEGER,
    p_warehouse_id INTEGER,
    p_quantity INTEGER,
    p_supplier_id INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_current_quantity INTEGER;
BEGIN
    -- Validate required parameters
    IF p_product_id IS NULL THEN
        RAISE EXCEPTION 'Product ID cannot be null';
    END IF;

    IF p_warehouse_id IS NULL THEN
        RAISE EXCEPTION 'Warehouse ID cannot be null';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be a positive number';
    END IF;

    -- Check if product exists
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'Product with ID % does not exist', p_product_id;
    END IF;

    -- Check if warehouse exists
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id) THEN
        RAISE EXCEPTION 'Warehouse with ID % does not exist', p_warehouse_id;
    END IF;

    -- Check if supplier exists (if provided)
    IF p_supplier_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM suppliers WHERE supplier_id = p_supplier_id) THEN
        RAISE EXCEPTION 'Supplier with ID % does not exist', p_supplier_id;
    END IF;

    -- Check if inventory record exists, if not create one
    IF NOT EXISTS (SELECT 1 FROM inventory WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id) THEN
        INSERT INTO inventory (product_id, warehouse_id, quantity)
        VALUES (p_product_id, p_warehouse_id, 0);
    END IF;

    -- Update inventory quantity
    UPDATE inventory
    SET quantity = quantity + p_quantity,
        last_updated = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Get current quantity for logging
    SELECT quantity INTO v_current_quantity
    FROM inventory
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Log the transaction
    INSERT INTO stock_transactions (product_id, warehouse_id, transaction_type, quantity, notes)
    VALUES (p_product_id, p_warehouse_id, 'Purchase', p_quantity, 
            CASE WHEN p_supplier_id IS NOT NULL THEN 'Purchased from supplier ID: ' || p_supplier_id ELSE 'Purchase recorded' END);

    RAISE NOTICE 'Purchase recorded: Product ID %, Warehouse ID %, Quantity +, New stock: %', 
                 p_product_id, p_warehouse_id, v_current_quantity;

END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Procedure: record_sale
-- Description: Records a stock sale - decreases inventory if sufficient stock exists
-- Parameters:
--   p_product_id - Foreign key to products
--   p_warehouse_id - Foreign key to warehouses
--   p_quantity - Quantity sold (must be positive)
--   p_customer_id - Foreign key to customers
-- =============================================
CREATE OR REPLACE FUNCTION record_sale(
    p_product_id INTEGER,
    p_warehouse_id INTEGER,
    p_quantity INTEGER,
    p_customer_id INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_current_quantity INTEGER;
BEGIN
    -- Validate required parameters
    IF p_product_id IS NULL THEN
        RAISE EXCEPTION 'Product ID cannot be null';
    END IF;

    IF p_warehouse_id IS NULL THEN
        RAISE EXCEPTION 'Warehouse ID cannot be null';
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be a positive number';
    END IF;

    -- Check if product exists
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'Product with ID % does not exist', p_product_id;
    END IF;

    -- Check if warehouse exists
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id) THEN
        RAISE EXCEPTION 'Warehouse with ID % does not exist', p_warehouse_id;
    END IF;

    -- Check if customer exists (if provided)
    IF p_customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;

    -- Check if inventory record exists
    IF NOT EXISTS (SELECT 1 FROM inventory WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id) THEN
        RAISE EXCEPTION 'No inventory record found for product ID % in warehouse ID %', p_product_id, p_warehouse_id;
    END IF;

    -- Get current quantity
    SELECT quantity INTO v_current_quantity
    FROM inventory
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Check if sufficient stock is available
    IF v_current_quantity < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', v_current_quantity, p_quantity;
    END IF;

    -- Update inventory quantity
    UPDATE inventory
    SET quantity = quantity - p_quantity,
        last_updated = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Log the transaction
    INSERT INTO stock_transactions (product_id, warehouse_id, transaction_type, quantity, notes)
    VALUES (p_product_id, p_warehouse_id, 'Sale', -p_quantity, 
            CASE WHEN p_customer_id IS NOT NULL THEN 'Sold to customer ID: ' || p_customer_id ELSE 'Sale recorded' END);

    RAISE NOTICE 'Sale recorded: Product ID %, Warehouse ID %, Quantity -, Remaining stock: %', 
                 p_product_id, p_warehouse_id, v_current_quantity - p_quantity;

END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Procedure: adjust_stock
-- Description: Manual stock adjustment with a reason for corrections
-- Parameters:
--   p_product_id - Foreign key to products
--   p_warehouse_id - Foreign key to warehouses
--   p_quantity_change - Positive for increase, negative for decrease
--   p_reason - Reason for the adjustment (required)
-- =============================================
CREATE OR REPLACE FUNCTION adjust_stock(
    p_product_id INTEGER,
    p_warehouse_id INTEGER,
    p_quantity_change INTEGER,
    p_reason TEXT
)
RETURNS VOID AS $$
DECLARE
    v_current_quantity INTEGER;
    v_new_quantity INTEGER;
BEGIN
    -- Validate required parameters
    IF p_product_id IS NULL THEN
        RAISE EXCEPTION 'Product ID cannot be null';
    END IF;

    IF p_warehouse_id IS NULL THEN
        RAISE EXCEPTION 'Warehouse ID cannot be null';
    END IF;

    IF p_quantity_change IS NULL OR p_quantity_change = 0 THEN
        RAISE EXCEPTION 'Quantity change cannot be zero';
    END IF;

    IF p_reason IS NULL OR p_reason = '' THEN
        RAISE EXCEPTION 'Adjustment reason is required';
    END IF;

    -- Check if product exists
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'Product with ID % does not exist', p_product_id;
    END IF;

    -- Check if warehouse exists
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id) THEN
        RAISE EXCEPTION 'Warehouse with ID % does not exist', p_warehouse_id;
    END IF;

    -- Check if inventory record exists, if not create one with zero quantity
    IF NOT EXISTS (SELECT 1 FROM inventory WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id) THEN
        INSERT INTO inventory (product_id, warehouse_id, quantity)
        VALUES (p_product_id, p_warehouse_id, 0);
    END IF;

    -- Get current quantity
    SELECT quantity INTO v_current_quantity
    FROM inventory
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Calculate new quantity
    v_new_quantity := v_current_quantity + p_quantity_change;

    -- Check if resulting quantity would be negative
    IF v_new_quantity < 0 THEN
        RAISE EXCEPTION 'Adjustment would result in negative stock. Current: %, Change: %, Result: %', 
                        v_current_quantity, p_quantity_change, v_new_quantity;
    END IF;

    -- Update inventory quantity
    UPDATE inventory
    SET quantity = v_new_quantity,
        last_updated = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;

    -- Log the transaction
    INSERT INTO stock_transactions (product_id, warehouse_id, transaction_type, quantity, notes)
    VALUES (p_product_id, p_warehouse_id, 'Adjustment', p_quantity_change, 'Reason: ' || p_reason);

    IF p_quantity_change > 0 THEN
        RAISE NOTICE 'Stock increased: Product ID %, Warehouse ID %, Change: +, New stock: %', 
                     p_product_id, p_warehouse_id, v_new_quantity;
    ELSE
        RAISE NOTICE 'Stock decreased: Product ID %, Warehouse ID %, Change: %, New stock: %', 
                     p_product_id, p_warehouse_id, p_quantity_change, v_new_quantity;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Grant execute permissions to typical users (adjust as needed)
-- =============================================
-- GRANT EXECUTE ON FUNCTION add_new_product(...) TO inventory_user;
-- GRANT EXECUTE ON FUNCTION record_purchase(...) TO inventory_user;
-- GRANT EXECUTE ON FUNCTION record_sale(...) TO inventory_user;
-- GRANT EXECUTE ON FUNCTION adjust_stock(...) TO inventory_user;