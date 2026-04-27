import { http } from './httpClient';

export type Bilingual = { en: string; ar: string };

export interface ProductFeature {
  icon: string;
  title: Bilingual;
  desc: Bilingual;
}
export interface ProductSpec {
  label: Bilingual;
  value: Bilingual;
}
export interface ProductImage {
  src: string;
  alt: Bilingual;
}

export interface Product {
  _id: string;
  slug: string;
  category: 'hardware' | 'digital' | 'concept';
  title: Bilingual;
  tagline: Bilingual;
  description: Bilingual;
  features: ProductFeature[];
  specs: ProductSpec[];
  images: ProductImage[];
  priceEGP: number;
  compareAtEGP?: number;
  stock: number;
  isConcept: boolean;
  isFeatured: boolean;
  ratingAvg: number;
  ratingCount: number;
}

export async function listProducts(params?: {
  category?: string;
  q?: string;
  featured?: boolean;
}): Promise<Product[]> {
  const res = await http<{ products: Product[] }>('/products', {
    query: {
      category: params?.category,
      q: params?.q,
      featured: params?.featured ? 'true' : undefined,
    },
  });
  return res.products;
}

export async function getProduct(slug: string): Promise<Product> {
  const res = await http<{ product: Product }>(`/products/${encodeURIComponent(slug)}`);
  return res.product;
}
