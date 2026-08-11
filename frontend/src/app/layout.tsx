import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import Link from "next/link";
import { Package, LayoutDashboard } from "lucide-react";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Inventory Dashboard",
  description: "Next.js Inventory Management System",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased dark`}>
      <body className="min-h-full flex h-screen overflow-hidden bg-zinc-950 text-zinc-100">
        <aside className="w-64 border-r border-zinc-800 bg-zinc-950 flex flex-col">
          <div className="flex items-center h-20 px-8 font-medium text-lg border-b border-zinc-800/50">
            <Package className="w-5 h-5 mr-3 text-zinc-100"/>
            Inventory
          </div>
          <nav className="flex-1 py-6 px-4 space-y-1">
            <Link href="/" className="flex items-center px-4 py-2.5 text-sm font-medium rounded-none hover:bg-zinc-900 text-zinc-400 hover:text-zinc-100 transition-colors">
              <LayoutDashboard className="w-4 h-4 mr-3" /> Dashboard
            </Link>
            <Link href="/products" className="flex items-center px-4 py-2.5 text-sm font-medium rounded-none hover:bg-zinc-900 text-zinc-400 hover:text-zinc-100 transition-colors">
              <Package className="w-4 h-4 mr-3" /> Directory
            </Link>
          </nav>
        </aside>
        <main className="flex-1 overflow-y-auto w-full selection:bg-blue-500/30">
          {children}
        </main>
      </body>
    </html>
  );
}
