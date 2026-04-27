import { http } from './httpClient';

export interface OrderAddress {
  fullName: string;
  phone: string;
  line1: string;
  line2?: string;
  city: string;
  governorate: string;
  postalCode?: string;
  country?: string;
}

export interface OrderItem {
  product: string;
  slug: string;
  titleEn: string;
  titleAr: string;
  image: string;
  unitPriceEGP: number;
  qty: number;
}

export interface Order {
  _id: string;
  user: string;
  items: OrderItem[];
  subtotalEGP: number;
  shippingEGP: number;
  totalEGP: number;
  currency: string;
  address: OrderAddress;
  receiptEmail: string;
  status:
    | 'pending_payment'
    | 'paid'
    | 'fulfilled'
    | 'cancelled'
    | 'refunded';
  paymentProvider: 'stripe' | 'mock';
  paidAt?: string;
  createdAt: string;
}

export interface CreateOrderResponse {
  orderId: string;
  clientSecret: string | null;
  provider: 'stripe' | 'mock';
}

export function createOrder(body: {
  items: { product: string; qty: number }[];
  address: OrderAddress;
  receiptEmail: string;
}) {
  return http<CreateOrderResponse>('/orders', { method: 'POST', auth: true, body });
}

export function listMyOrders() {
  return http<{ orders: Order[] }>('/orders', { auth: true });
}

export function getOrder(id: string) {
  return http<{ order: Order }>(`/orders/${id}`, { auth: true });
}
