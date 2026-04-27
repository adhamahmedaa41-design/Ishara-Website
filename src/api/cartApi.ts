import { http } from './httpClient';
import type { Bilingual } from './productApi';

export interface ServerCartItem {
  product: string;
  slug: string;
  title: Bilingual;
  image: string;
  priceEGP: number;
  stock: number;
  qty: number;
}

export interface ServerCart {
  items: ServerCartItem[];
  subtotalEGP: number;
}

export function getServerCart() {
  return http<ServerCart>('/cart', { auth: true });
}

export function replaceServerCart(items: { product: string; qty: number }[]) {
  return http<ServerCart>('/cart', { method: 'PUT', auth: true, body: { items } });
}

export function clearServerCart() {
  return http<ServerCart>('/cart', { method: 'DELETE', auth: true });
}
