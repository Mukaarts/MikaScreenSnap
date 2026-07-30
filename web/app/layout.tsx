import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { product } from "@/lib/content";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

/**
 * Absolute base for social images. Vercel injects the deployment domain, so a
 * custom domain only needs NEXT_PUBLIC_SITE_URL set in the project settings.
 */
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: `${product.name} — macOS screenshots, annotated in place`,
  description: product.description,
  applicationName: product.name,
  keywords: [
    "macOS screenshot",
    "screenshot annotation",
    "menu bar app",
    "OCR",
    "colour picker",
    "screen measurement",
  ],
  openGraph: {
    title: `${product.name} — macOS screenshots, annotated in place`,
    description: product.description,
    type: "website",
    locale: "en",
  },
  twitter: {
    card: "summary_large_image",
    title: `${product.name} for macOS`,
    description: product.description,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      data-scroll-behavior="smooth"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="font-sans min-h-full flex flex-col">{children}</body>
    </html>
  );
}
