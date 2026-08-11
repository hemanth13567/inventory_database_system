import pool from '@/lib/db';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const rawSql = `
      SELECT
          p.product_id,
          p.product_name,
          p.sku,
          c.category_name,
          s.supplier_name,
          COALESCE(SUM(i.quantity), 0) AS current_stock,
          ROUND(p.unit_price * COALESCE(SUM(i.quantity), 0)::numeric, 2) AS stock_value
      FROM products p
      JOIN categories c ON p.category_id = c.category_id
      JOIN suppliers s ON p.supplier_id = s.supplier_id
      LEFT JOIN inventory i ON p.product_id = i.product_id
      GROUP BY p.product_id, p.product_name, p.sku, c.category_name, s.supplier_name, p.unit_price
      ORDER BY p.product_name;
    `;
    const result = await pool.query(rawSql);
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error('Database Error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}
