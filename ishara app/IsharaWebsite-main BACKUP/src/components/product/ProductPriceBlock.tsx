import { useState } from 'react';
import { motion } from 'motion/react';
import { Minus, Plus, ShoppingCart, Check } from 'lucide-react';
import { toast } from 'sonner';
import type { Product } from '../../api/productApi';
import { useApp } from '../AppProviders';
import { useCart } from '../../context/CartContext';
import { formatEGP } from '../../lib/formatCurrency';

export function ProductPriceBlock({ product }: { product: Product }) {
  const { language } = useApp();
  const { add } = useCart();
  const [qty, setQty] = useState(1);
  const [justAdded, setJustAdded] = useState(false);

  const hasDiscount =
    product.compareAtEGP && product.compareAtEGP > product.priceEGP;
  const inStock = product.stock > 0 && !product.isConcept;
  const isFree = product.priceEGP === 0 && !product.isConcept;

  const onAdd = () => {
    add(product, qty);
    setJustAdded(true);
    toast.success(
      language === 'ar'
        ? `تمت إضافة ${product.title.ar || product.title.en} إلى السلة`
        : `${product.title.en} added to cart`
    );
    window.setTimeout(() => setJustAdded(false), 1500);
  };

  const L = {
    en: {
      inStock: 'In stock',
      outOfStock: 'Out of stock',
      concept: 'Concept — not for sale',
      free: 'Free',
      quantity: 'Quantity',
      add: 'Add to cart',
      added: 'Added!',
      notify: 'Notify me when available',
    },
    ar: {
      inStock: 'متوفر',
      outOfStock: 'غير متوفر',
      concept: 'مفهوم — غير متاح للبيع',
      free: 'مجاني',
      quantity: 'الكمية',
      add: 'إضافة إلى السلة',
      added: 'تمت الإضافة!',
      notify: 'نبّهني عند التوفر',
    },
  }[language];

  return (
    <div className="space-y-6">
      {/* Price */}
      <div className="flex items-baseline gap-3 flex-wrap">
        {product.isConcept ? (
          <span className="text-2xl font-bold text-[#14B8A6]">{L.concept}</span>
        ) : isFree ? (
          <span className="text-3xl font-bold">{L.free}</span>
        ) : (
          <>
            <span className="text-3xl md:text-4xl font-bold">
              {formatEGP(product.priceEGP, language)}
            </span>
            {hasDiscount && (
              <span className="text-lg text-muted-foreground line-through">
                {formatEGP(product.compareAtEGP!, language)}
              </span>
            )}
          </>
        )}
      </div>

      {/* Stock badge */}
      {!product.isConcept && (
        <div
          className={`inline-flex items-center gap-2 text-sm px-3 py-1 rounded-full ${
            inStock
              ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
              : 'bg-red-500/10 text-red-600 dark:text-red-400'
          }`}
          role="status"
        >
          <span className="w-2 h-2 rounded-full bg-current" aria-hidden="true" />
          {inStock ? L.inStock : L.outOfStock}
        </div>
      )}

      {/* Qty + Add */}
      {!product.isConcept && inStock && !isFree && (
        <div className="flex items-center gap-4 flex-wrap">
          <div
            role="group"
            aria-label={L.quantity}
            className="flex items-center border border-border rounded-full"
          >
            <button
              onClick={() => setQty((q) => Math.max(1, q - 1))}
              aria-label={language === 'ar' ? 'تقليل' : 'Decrease'}
              className="p-3 hover:bg-accent rounded-l-full disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
              disabled={qty <= 1}
            >
              <Minus className="w-4 h-4" />
            </button>
            <span className="w-10 text-center font-medium tabular-nums" aria-live="polite">
              {qty}
            </span>
            <button
              onClick={() =>
                setQty((q) => Math.min(product.stock, q + 1, 99))
              }
              aria-label={language === 'ar' ? 'زيادة' : 'Increase'}
              className="p-3 hover:bg-accent rounded-r-full disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
              disabled={qty >= product.stock}
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>

          <motion.button
            onClick={onAdd}
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            className="flex-1 min-w-[160px] px-6 py-3 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium flex items-center justify-center gap-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
          >
            {justAdded ? (
              <>
                <Check className="w-5 h-5" /> {L.added}
              </>
            ) : (
              <>
                <ShoppingCart className="w-5 h-5" /> {L.add}
              </>
            )}
          </motion.button>
        </div>
      )}

      {/* Free digital product */}
      {!product.isConcept && isFree && (
        <button
          onClick={onAdd}
          className="w-full py-3 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
        >
          {language === 'ar' ? 'احصل عليه مجانًا' : 'Get it free'}
        </button>
      )}

      {/* Concept CTA */}
      {product.isConcept && (
        <button
          disabled
          className="w-full py-3 rounded-full border-2 border-dashed border-[#14B8A6] text-[#14B8A6] font-medium"
        >
          {L.notify}
        </button>
      )}
    </div>
  );
}
