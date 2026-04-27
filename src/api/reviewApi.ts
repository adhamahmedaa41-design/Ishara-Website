import { http } from './httpClient';

export interface Review {
  _id: string;
  user: string;
  product: string;
  userName: string;
  userAvatar?: string;
  rating: number;
  text: string;
  createdAt: string;
  updatedAt: string;
}

export interface ReviewListResponse {
  reviews: Review[];
  total: number;
  page: number;
  pageCount: number;
  summary: { ratingAvg: number; ratingCount: number };
}

export function listReviews(slug: string, page = 1, limit = 10) {
  return http<ReviewListResponse>(`/products/${encodeURIComponent(slug)}/reviews`, {
    query: { page, limit },
  });
}

export function createReview(slug: string, body: { rating: number; text: string }) {
  return http<{ review: Review }>(`/products/${encodeURIComponent(slug)}/reviews`, {
    method: 'POST',
    body,
    auth: true,
  });
}

export function updateReview(id: string, body: { rating?: number; text?: string }) {
  return http<{ review: Review }>(`/reviews/${id}`, {
    method: 'PUT',
    body,
    auth: true,
  });
}

export function deleteReview(id: string) {
  return http<{ message: string }>(`/reviews/${id}`, { method: 'DELETE', auth: true });
}
