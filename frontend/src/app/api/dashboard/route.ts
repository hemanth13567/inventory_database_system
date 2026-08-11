import pool from '@/lib/db';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // We execute a refined version of the complex analytical query to fetch dashboard stats
    const statsSql = `
      WITH inventory_stats AS (
          SELECT
              ROUND(SUM(i.quantity * p.unit_price)::numeric, 2) AS total_inventory_value,
              COUNT(DISTINCT p.product_id) AS total_products
          FROM inventory i
          JOIN products p ON i.product_id = p.product_id
      ),
      low_stock AS (
          SELECT COUNT(*) as low_stock_count FROM (
              SELECT p.product_id
              FROM products p
              LEFT JOIN inventory i ON p.product_id = i.product_id
              GROUP BY p.product_id, p.reorder_level
              HAVING COALESCE(SUM(i.quantity), 0) < p.reorder_level
          ) sub
      )
      SELECT
          (SELECT COUNT(*) FROM products) AS total_products,
          (SELECT COUNT(*) FROM suppliers) AS active_suppliers,
          (SELECT COUNT(*) FROM warehouses) AS active_warehouses,
          (SELECT COUNT(*) FROM customers) AS total_customers,
          inv.total_inventory_value,
          ls.low_stock_count
      FROM inventory_stats inv, low_stock ls;
    `;
    const statsResult = await pool.query(statsSql);

    // Fetch top 5 selling products
    const topSellingSql = `
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
    `;
    const topSellingResult = await pool.query(topSellingSql);

    return NextResponse.json({
        stats: statsResult.rows[0] || {},
        topSelling: topSellingResult.rows
    });
  } catch (error) {
    console.error('Database Error:', error);
    return NextResponse.json({ error: 'Failed to fetch dashboard data' }, { status: 500 });
  }
}
