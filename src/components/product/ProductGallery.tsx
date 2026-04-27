import { useState } from 'react';
import { motion } from 'motion/react';
import type { ProductImage } from '../../api/productApi';
import { useApp } from '../AppProviders';

export function ProductGallery({ images }: { images: ProductImage[] }) {
  const { language } = useApp();
  const [idx, setIdx] = useState(0);
  const main = images[idx];

  if (!main) {
    return (
      <div className="aspect-square rounded-2xl bg-gradient-to-br from-[#14B8A6]/40 to-[#F97316]/40" />
    );
  }

  return (
    <div>
      <motion.div
        key={main.src}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="aspect-square rounded-2xl overflow-hidden bg-muted border border-border"
      >
        <img
          src={main.src}
          alt={main.alt[language] || main.alt.en}
          className="w-full h-full object-cover"
        />
      </motion.div>
      {images.length > 1 && (
        <div
          role="listbox"
          aria-label={language === 'ar' ? 'صور المنتج' : 'Product images'}
          className="flex gap-3 mt-4"
        >
          {images.map((img, i) => (
            <button
              key={img.src}
              role="option"
              aria-selected={i === idx}
              onClick={() => setIdx(i)}
              className={`w-20 h-20 rounded-lg overflow-hidden border-2 transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] ${
                i === idx ? 'border-[#14B8A6]' : 'border-transparent opacity-70 hover:opacity-100'
              }`}
            >
              <img
                src={img.src}
                alt=""
                aria-hidden="true"
                className="w-full h-full object-cover"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
