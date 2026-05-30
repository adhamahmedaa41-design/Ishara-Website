import { API_BASE } from '../api/apiBase';

// Resolves product image URLs so they work in both dev and production.
//
// Strategy:
//  1. Absolute URLs / data URIs → pass through unchanged.
//  2. /uploads/products/...  → rewrite to /products/... (served from public/ on Vercel).
//  3. Any other /uploads/... → prepend the backend base URL so the request
//     goes to the real server instead of the Vercel frontend.
//  4. Everything else → pass through unchanged.
export function resolveImageUrl(src: string | undefined | null): string {
  if (!src) return '';
  if (/^https?:\/\//i.test(src) || src.startsWith('data:')) return src;

  // Product images committed to public/products/ — rewrite to static path.
  if (src.startsWith('/uploads/products/')) {
    return src.replace('/uploads/products/', '/products/');
  }

  // Other /uploads/ paths live on the backend server, not the Vercel frontend.
  if (src.startsWith('/uploads/')) {
    // API_BASE is e.g. "https://ishara-backend.vercel.app/api"
    // We need just the origin: "https://ishara-backend.vercel.app"
    try {
      const backendOrigin = new URL(API_BASE).origin;
      return `${backendOrigin}${src}`;
    } catch {
      return src;
    }
  }

  return src;
}
