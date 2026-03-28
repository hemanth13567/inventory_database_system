-- =============================================
-- Inventory Database System 2025
-- Analytical Queries (Fixed Version)
-- =============================================

-- 1. Current Total Inventory Value
-- Calculates the total value of all stock across all warehouses
SELECT 
    ROUND(SUM(i.quantity * p.unit_price)::numeric, 2) AS total_inventory_value,
    COUNT(DISTINCT p.product_id) AS total_products
FROM inventory i
JOIN products p ON i.product_id = p.product_id;

-- 2. Low Stock Alert Report (Fixed)
-- Shows products that are below reorder level with deficit amount
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    p.reorder_level,
    COALESCE(SUM(i.quantity), 0) AS current_stock,
    (p.reorder_level - COALESCE(SUM(i.quantity), 0)) AS deficit,
    w.warehouse_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN warehouses w ON i.warehouse_id = w.warehouse_id
GROUP BY p.product_id, p.product_name, p.sku, c.category_name, 
         p.reorder_level, w.warehouse_name
HAVING COALESCE(SUM(i.quantity), 0) < p.reorder_level
ORDER BY deficit DESC;

-- 3. Top 5 Best-Selling Products (Fixed)
-- Uses direct calculation instead of subtotal column
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    SUM(soi.quantity) AS total_quantity_sold,
    ROUND(SUM(soi.quantity * soi.unit_price)::numeric, 2) AS total_revenue
FROM products p
JOIN sales_order_items soi ON p.product_id = soi.product_id
GROUP BY p.product_id, p.product_name, p.sku
ORDER BY total_quantity_sold DESC
LIMIT 5;

-- 4. Supplier Performance Report (Fixed)
SELECT 
    s.supplier_id,
    s.supplier_name,
    COUNT(DISTINCT po.po_id) AS total_orders,
    ROUND(SUM(poi.quantity * poi.unit_price)::numeric, 2) AS total_purchase_value
FROM suppliers s
LEFT JOIN purchase_orders po ON s.supplier_id = po.supplier_id
LEFT JOIN purchase_order_items poi ON po.po_id = poi.po_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY total_purchase_value DESC NULLS LAST;

-- 5. Current Stock Levels with Details
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    s.supplier_name,
    w.warehouse_name,
    COALESCE(i.quantity, 0) AS current_stock,
    ROUND(p.unit_price * COALESCE(i.quantity, 0)::numeric, 2) AS stock_value
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN warehouses w ON i.warehouse_id = w.warehouse_id
ORDER BY c.category_name, p.product_name;

-- 6. Monthly Sales Summary (Fixed)
SELECT 
    TO_CHAR(so.order_date, 'YYYY-MM') AS month,
    COUNT(DISTINCT so.so_id) AS number_of_orders,
    ROUND(SUM(soi.quantity * soi.unit_price)::numeric, 2) AS total_sales_amount,
    ROUND(AVG(soi.quantity * soi.unit_price)::numeric, 2) AS average_order_value
FROM sales_orders so
JOIN sales_order_items soi ON so.so_id = soi.so_id
WHERE so.status != 'Cancelled'
GROUP BY TO_CHAR(so.order_date, 'YYYY-MM')
ORDER BY month DESC;

-- 7. Warehouse-wise Stock Summary
SELECT 
    w.warehouse_name,
    w.location,
    COUNT(DISTINCT i.product_id) AS unique_products,
    SUM(i.quantity) AS total_quantity,
    ROUND(SUM(i.quantity * p.unit_price)::numeric, 2) AS total_stock_value
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name, w.location
ORDER BY total_stock_value DESC NULLS LAST;

-- 8. Products That Have Never Been Sold
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    s.supplier_name,
    COALESCE(SUM(i.quantity), 0) AS current_stock
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
LEFT JOIN sales_order_items soi ON p.product_id = soi.product_id
LEFT JOIN inventory i ON p.product_id = i.product_id
WHERE soi.so_item_id IS NULL
GROUP BY p.product_id, p.product_name, p.sku, c.category_name, s.supplier_name
ORDER BY p.product_name;

-- 9. Stock Movement History (Example for product_id = 1)
-- Change the product_id as needed
SELECT 
    st.transaction_id,
    st.transaction_date,
    st.transaction_type,
    st.quantity,
    w.warehouse_name,
    st.notes,
    st.reference_id
FROM stock_transactions st
JOIN warehouses w ON st.warehouse_id = w.warehouse_id
WHERE st.product_id = 1        -- ← Change this value
ORDER BY st.transaction_date DESC;

-- 10. Overall Dashboard Statistics (Clean Version)
WITH inventory_stats AS (
    SELECT 
        ROUND(SUM(i.quantity * p.unit_price)::numeric, 2) AS total_inventory_value,
        COUNT(DISTINCT p.product_id) AS total_products
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
),
low_stock AS (
    SELECT COUNT(*) AS low_stock_count
    FROM products p
    LEFT JOIN inventory i ON p.product_id = i.product_id
    GROUP BY p.product_id
    HAVING COALESCE(SUM(i.quantity), 0) < p.reorder_level
)
SELECT 
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM suppliers WHERE status = 'Active') AS active_suppliers,
    (SELECT COUNT(*) FROM warehouses WHERE status = 'Active') AS active_warehouses,
    (SELECT COUNT(*) FROM customers) AS total_customers,
    inv.total_inventory_value,
    ls.low_stock_count
FROM inventory_stats inv
CROSS JOIN low_stock ls;