"use client";

import { useEffect, useState } from "react";
import { motion } from "motion/react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { Layers, Building2, Package, AlertTriangle } from 'lucide-react';

export default function Dashboard() {
  const [data, setData] = useState<{stats: any, topSelling: any[]}>({ stats: {}, topSelling: [] });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/dashboard')
      .then(res => res.json())
      .then(json => {
        if (json.error) {
          setData({ stats: {}, topSelling: [] });
        } else {
          setData(json);
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="h-full w-full flex items-center justify-center bg-zinc-950 text-zinc-500 font-mono text-sm">
        [ system.loading ]
      </div>
    );
  }

  const { stats, topSelling } = data;

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 selection:bg-blue-500/30">
      <header className="px-8 py-6 border-b border-zinc-800 flex justify-between items-end">
        <div>
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="text-xs uppercase tracking-widest text-zinc-500 mb-2 font-mono">
            Command Center
          </motion.div>
          <motion.h1 initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }} className="text-2xl font-medium tracking-tight">
            Inventory Status
          </motion.h1>
        </div>
      </header>

      {/* Cockpit / Packed Data layout - Level 8 Density */}
      <div className="grid grid-cols-1 md:grid-cols-4 border-b border-zinc-800 divide-y md:divide-y-0 md:divide-x divide-zinc-800">
        {[
          { label: "Asset Value", val: `$${stats.total_inventory_value || '0.00'}`, icon: Layers, hue: "text-zinc-100" },
          { label: "Products", val: stats.total_products || '0', icon: Package, hue: "text-zinc-100" },
          { label: "Warehouses", val: stats.active_warehouses || '0', icon: Building2, hue: "text-zinc-100" },
          { label: "Alerts", val: stats.low_stock_count || '0', icon: AlertTriangle, hue: stats.low_stock_count > 0 ? "text-rose-500" : "text-zinc-500" }
        ].map((kpi, idx) => (
          <motion.div 
            key={kpi.label}
            initial={{ opacity: 0, y: 10 }} 
            animate={{ opacity: 1, y: 0 }} 
            transition={{ delay: 0.1 + (idx * 0.05) }}
            className="p-6 md:p-8 flex flex-col justify-between hover:bg-zinc-900/50 transition-colors"
          >
            <div className="flex justify-between items-center mb-12 text-zinc-500">
              <span className="text-sm font-medium">{kpi.label}</span>
              <kpi.icon className={`w-4 h-4 ${kpi.hue === 'text-zinc-100' ? 'opacity-50' : kpi.hue}`} />
            </div>
            <div className={`text-4xl font-mono tracking-tighter ${kpi.hue}`}>{kpi.val}</div>
          </motion.div>
        ))}
      </div>

      <div className="p-8">
        <motion.div 
          initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}
          className="border border-zinc-800 bg-zinc-950/50 rounded-none overflow-hidden"
        >
          <div className="px-6 py-4 border-b border-zinc-800 flex items-center justify-between">
            <h2 className="text-sm font-medium">Top Volumes</h2>
            <span className="text-xs font-mono text-zinc-500">Units moved</span>
          </div>
          <div className="h-[300px] w-full p-6">
             {topSelling.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={topSelling} margin={{ top: 0, right: 0, left: -24, bottom: 0 }}>
                    <XAxis dataKey="product_name" stroke="#52525b" fontSize={11} tickLine={false} axisLine={false} />
                    <YAxis stroke="#52525b" fontSize={11} tickLine={false} axisLine={false} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#09090b', border: '1px solid #27272a', borderRadius: '0', color: '#f4f4f5', fontFamily: 'monospace', fontSize: '12px' }}
                      itemStyle={{ color: '#ffffff', fontWeight: 'normal' }}
                      cursor={{ fill: '#27272a', opacity: 0.4 }}
                    />
                    <Bar dataKey="total_quantity_sold" fill="#3b82f6" radius={0} maxBarSize={48} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-full flex items-center justify-center text-zinc-600 text-sm font-mono">No telemetry found</div>
              )}
          </div>
        </motion.div>
      </div>
    </div>
  );
}
