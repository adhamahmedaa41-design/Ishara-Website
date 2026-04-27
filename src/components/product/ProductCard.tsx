import { Link } from 'react-router-dom';
import { motion } from 'motion/react';
import { Star } from 'lucide-react';
import type { Product } from '../../api/productApi';
import { useApp } from '../AppProviders';
import { formatEGP } from '../../lib/formatCurrency';

export function ProductCard({ product }: { product: Product }) {
  const { language } = useApp();
  const title = product.title[language] || product.title.en;
  const tagline = product.tagline[language] || product.tagline.en;
  const altText = product.images[0]?.alt[language] || title;
  const hasDiscount =
    product.compareAtEGP && product.compareAtEGP > product.priceEGP;

  return (
    <motion.article
      whileHover={{ y: -4 }}
      className="group bg-card border border-border rounded-2xl overflow-hidden flex flex-col focus-within:ring-2 focus-within:ring-[#14B8A6]"
    >
      <Link
        to={`/products/${product.slug}`}
        className="block aspect-[4/3] bg-muted overflow-hidden focus-visible:outline-none"
        aria-label={title}
      >
        {product.images[0]?.src ? (
          <img
            src={product.images[0].src}
            alt={altText}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-[#14B8A6]/40 to-[#F97316]/40" />
        )}
      </Link>
      <div className="p-5 flex flex-col flex-1">
        <div className="flex items-start justify-between gap-2">
          <h3 className="font-semibold leading-tight">
            <Link
              to={`/products/${product.slug}`}
              className="hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] rounded"
            >
              {title}
            </Link>
          </h3>
          {product.isFeatured && (
            <span className="shrink-0 text-[10px] px-2 py-0.5 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white uppercase tracking-wide">
              {language === 'ar' ? 'مميز' : 'Featured'}
            </span>
          )}
        </div>
        <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{tagline}</p>

        {product.ratingCount > 0 && (
          <div className="flex items-center gap-1 mt-3 text-sm">
            <Star className="w-4 h-4 fill-amber-400 text-amber-400" aria-hidden="true" />
            <span className="font-medium">{product.ratingAvg.toFixed(1)}</span>
            <span className="text-muted-foreground">({product.ratingCount})</span>
          </div>
        )}

        <div className="flex items-end justify-between mt-auto pt-4">
          {product.isConcept ? (
            <span className="text-sm font-medium text-[#14B8A6]">
              {language === 'ar' ? 'قريبًا' : 'Coming soon'}
            </span>
          ) : product.priceEGP === 0 ? (
            <span className="text-sm font-semibold">
              {language === 'ar' ? 'مجاني' : 'Free'}
            </span>
          ) : (
            <div className="flex items-baseline gap-2">
              <span className="font-semibold">
                {formatEGP(product.priceEGP, language)}
              </span>
              {hasDiscount && (
                <span className="text-xs text-muted-foreground line-through">
                  {formatEGP(product.compareAtEGP!, language)}
                </span>
              )}
            </div>
          )}
          <Link
            to={`/products/${product.slug}`}
            className="text-sm font-medium text-[#14B8A6] hover:text-[#F97316] transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] rounded px-2 py-1"
          >
            {language === 'ar' ? 'عرض →' : 'View →'}
          </Link>
        </div>
      </div>
    </motion.article>
  );
}
