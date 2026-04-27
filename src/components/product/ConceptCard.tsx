import { motion } from 'motion/react';
import { Sparkles } from 'lucide-react';
import type { Product } from '../../api/productApi';
import { useApp } from '../AppProviders';

export function ConceptCard({ product }: { product: Product }) {
  const { language } = useApp();
  return (
    <motion.article
      whileHover={{ y: -3 }}
      className="relative rounded-2xl overflow-hidden border-2 border-dashed border-[#14B8A6]/50 bg-gradient-to-br from-[#14B8A6]/5 to-[#F97316]/5 p-6"
    >
      <div className="absolute top-3 end-3 inline-flex items-center gap-1 text-[10px] uppercase tracking-wide px-2 py-0.5 rounded-full bg-[#14B8A6] text-white">
        <Sparkles className="w-3 h-3" aria-hidden="true" />
        {language === 'ar' ? 'قريبًا' : 'Concept'}
      </div>
      <div className="aspect-video rounded-lg bg-muted mb-4 overflow-hidden">
        {product.images[0]?.src ? (
          <img
            src={product.images[0].src}
            alt={product.images[0].alt[language] || product.title[language] || product.title.en}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : null}
      </div>
      <h3 className="text-lg font-semibold">
        {product.title[language] || product.title.en}
      </h3>
      <p className="text-sm text-muted-foreground mt-1">
        {product.tagline[language] || product.tagline.en}
      </p>
    </motion.article>
  );
}
