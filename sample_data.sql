-- =============================================
-- Sample Data for Inventory Database System 2025
-- =============================================

-- 1. Categories
INSERT INTO categories (category_name, description) VALUES
('Furniture', 'Decorative and functional items for home and office'),
('Electronics', 'Portable and high-tech gadgets'),
('Stationery', 'Office supplies and writing materials'),
('Appliances', 'Home and kitchen appliances');

-- 2. Suppliers
INSERT INTO suppliers (supplier_name, contact_person, email, phone, address, status) VALUES
('TechSupply Co.', 'John Doe', 'john.doe@techsupply.com', '9876543210', 'Mumbai, Maharashtra', 'Active'),
('OfficeWorld Ltd.', 'Emily Smith', 'emily@officeworld.com', '9123456789', 'Chennai, Tamil Nadu', 'Active'),
('FurniMart', 'Rahul Sharma', 'rahul@furnimart.in', '9988776655', 'Bangalore, Karnataka', 'Active');

-- 3. Warehouses
INSERT INTO warehouses (warehouse_name, location, capacity, status) VALUES
('Chennai Main Warehouse', 'Ambattur Industrial Estate, Chennai', 5000, 'Active'),
('Mumbai Regional Hub', 'Andheri East, Mumbai', 3000, 'Active'),
('Bangalore Storage', 'Whitefield, Bangalore', 4000, 'Active');

-- 4. Products
INSERT INTO products (sku, product_name, category_id, supplier_id, unit_price, reorder_level, description) VALUES
('FUR-DESK-001', 'Folding Office Desk', 1, 3, 12999.00, 15, 'Height adjustable wooden desk'),
('ELE-SPH-001', 'Samsung Galaxy S24', 2, 1, 74999.00, 10, 'Latest flagship smartphone'),
('ELE-LAP-001', 'Dell XPS 13 Laptop', 2, 1, 124999.00, 8, 'Ultra-thin business laptop'),
('STA-CHG-001', 'Fast USB-C Charger', 2, 2, 899.00, 50, '65W PD charger'),
('FUR-CHR-001', 'Ergonomic Office Chair', 1, 3, 8999.00, 20, 'Mesh back with lumbar support'),
('APP-MIC-001', 'LG Microwave Oven', 4, 2, 12499.00, 12, '30L convection microwave');

-- 5. Inventory (Stock)
INSERT INTO inventory (product_id, warehouse_id, quantity) VALUES
(1, 1, 45),   -- Folding Desk in Chennai
(2, 1, 28),   -- Smartphone in Chennai
(3, 2, 12),   -- Laptop in Mumbai
(4, 1, 180),  -- Charger in Chennai
(5, 1, 35),   -- Office Chair in Chennai
(6, 3, 22);   -- Microwave in Bangalore

-- 6. Customers
INSERT INTO customers (customer_name, email, phone, address) VALUES
('Aarav Enterprises', 'aarav@company.in', '9876543211', 'Anna Nagar, Chennai'),
('Infosys Solutions', 'procurement@infosys.com', '9123456780', 'Electronic City, Bangalore'),
('Home Decor Store', 'contact@homedecor.in', '9988776644', 'MG Road, Mumbai');

-- Note: You can add more data for purchase_orders, sales_orders, etc. later

-- 1. Add a Sales Order
INSERT INTO sales_orders (customer_id, order_date, total_amount, status)
VALUES 
(1, '2025-03-01', 0, 'Shipped'),
(2, '2025-03-10', 0, 'Shipped'),
(1, '2025-03-15', 0, 'Shipped');

-- 2. Add Sales Order Items
INSERT INTO sales_order_items (so_id, product_id, quantity, unit_price)
VALUES 
(1, 1, 5, 12999.00),   -- Folding Desk
(1, 2, 3, 74999.00),   -- Smartphone
(2, 3, 2, 124999.00),  -- Laptop
(2, 4, 10, 899.00),    -- Charger
(3, 5, 4, 8999.00);    -- Office Chair

-- 3. Update total_amount in sales_orders
UPDATE sales_orders 
SET total_amount = (
    SELECT SUM(subtotal) 
    FROM sales_order_items 
    WHERE so_id = sales_orders.so_id
);

-- 4. Also add some Purchase Orders (optional but good)
INSERT INTO purchase_orders (supplier_id, order_date, expected_delivery_date, total_amount, status)
VALUES 
(1, '2025-02-20', '2025-03-05', 0, 'Received'),
(3, '2025-03-01', '2025-03-15', 0, 'Received');

INSERT INTO purchase_order_items (po_id, product_id, quantity, unit_price)
VALUES 
(1, 2, 20, 70000.00),
(1, 4, 50, 800.00),
(2, 1, 15, 12000.00);

UPDATE purchase_orders 
SET total_amount = (
    SELECT SUM(subtotal) 
    FROM purchase_order_items 
    WHERE po_id = purchase_orders.po_id
);

-- Refresh inventory quantities after sales (optional - to simulate real stock change)
UPDATE inventory 
SET quantity = quantity - 5 
WHERE product_id = 1 AND warehouse_id = 1;

UPDATE inventory 
SET quantity = quantity - 3 
WHERE product_id = 2 AND warehouse_id = 1;

COMMIT;