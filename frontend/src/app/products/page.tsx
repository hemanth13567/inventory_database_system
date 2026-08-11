"use client";

import { useEffect, useState } from "react";
import { motion } from "motion/react";
import { Search } from "lucide-react";

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetch('/api/products')
      .then(res => res.json())
      .then(data => {
        if (data.error) {
          setProducts([]);
        } else {
          setProducts(data);
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const filtered = products.filter(p => 
    p.product_name?.toLowerCase().includes(search.toLowerCase()) || 
    p.sku?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 selection:bg-blue-500/30 font-sans">
      <header className="px-8 py-6 border-b border-zinc-800 flex justify-between items-end sticky top-0 bg-zinc-950/80 backdrop-blur-md z-10">
        <div>
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="text-xs uppercase tracking-widest text-zinc-500 mb-2 font-mono">
            Directory
          </motion.div>
          <motion.h1 initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }} className="text-2xl font-medium tracking-tight">
            Product Roster
          </motion.h1>
        </div>
        <motion.div initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 }} className="relative w-72">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-zinc-500" />
          <input
            placeholder="Search SKUs or names..."
            className="w-full pl-9 pr-4 py-2 bg-transparent border border-zinc-800 text-sm focus:outline-none focus:border-zinc-500 transition-colors rounded-none placeholder:text-zinc-600 font-mono"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </motion.div>
      </header>

      <div className="px-8 py-8 w-full max-w-[1400px]">
        {loading ? (
          <div className="h-64 flex items-center justify-center text-zinc-600 font-mono text-sm">
            [ indexing records ]
          </div>
        ) : (
          <div className="border border-zinc-800">
            <table className="w-full text-sm text-left">
              <thead className="bg-zinc-900/50 border-b border-zinc-800 font-mono text-xs uppercase tracking-wider text-zinc-500">
                <tr>
                  <th className="px-6 py-4 font-normal">Product</th>
                  <th className="px-6 py-4 font-normal">SKU</th>
                  <th className="px-6 py-4 font-normal">Category</th>
                  <th className="px-6 py-4 font-normal text-right">Stock</th>
                  <th className="px-6 py-4 font-normal text-right">Value</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800 font-mono text-[13px]">
                {filtered.length > 0 ? filtered.map((product, i) => (
                  <motion.tr 
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.02, ease: "easeOut" }}
                    key={product.product_id || product.sku || i} 
                    className="hover:bg-zinc-900/30 transition-colors group"
                  >
                    <td className="px-6 py-3 font-sans font-medium text-zinc-100">{product.product_name}</td>
                    <td className="px-6 py-3 text-zinc-400">{product.sku}</td>
                    <td className="px-6 py-3">
                      <span className="text-zinc-500 border border-zinc-800 px-2 py-0.5 group-hover:border-zinc-700 transition-colors">
                        {product.category_name}
                      </span>
                    </td>
                    <td className={`px-6 py-3 text-right ${product.current_stock < 10 ? 'text-rose-400' : 'text-zinc-400'}`}>
                      {String(product.current_stock).padStart(4, '0')}
                    </td>
                    <td className="px-6 py-3 text-right text-zinc-300">
                      ${product.stock_value ? Number(product.stock_value).toFixed(2) : "0.00"}
                    </td>
                  </motion.tr>
                )) : (
                  <tr>
                    <td colSpan={5} className="text-center py-12 text-zinc-600">
                      No matches found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
