import { Minus, Plus, Trash2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useCart, type CartLine } from '../../context/CartContext';
import { useApp } from '../AppProviders';
import { formatEGP } from '../../lib/formatCurrency';

export function CartLineItem({ line }: { line: CartLine }) {
  const { language } = useApp();
  const { setQty, remove } = useCart();
  const title = language === 'ar' ? line.titleAr || line.titleEn : line.titleEn;

  return (
    <div className="flex items-center gap-4 py-4 border-b border-border">
      <Link
        to={`/products/${line.slug}`}
        className="shrink-0 w-20 h-20 rounded-lg overflow-hidden bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
      >
        {line.image ? (
          <img src={line.image} alt={title} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-[#14B8A6]/30 to-[#F97316]/30" />
        )}
      </Link>

      <div className="flex-1 min-w-0">
        <Link
          to={`/products/${line.slug}`}
          className="font-medium truncate hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] rounded"
        >
          {title}
        </Link>
        <div className="text-sm text-muted-foreground mt-1">
          {formatEGP(line.priceEGP, language)}
        </div>
      </div>

      <div
        className="flex items-center gap-1 border border-border rounded-lg p-1"
        role="group"
        aria-label={language === 'ar' ? 'تعديل الكمية' : 'Update quantity'}
      >
        <button
          onClick={() => setQty(line.product, line.qty - 1)}
          disabled={line.qty <= 1}
          aria-label={language === 'ar' ? 'تقليل' : 'Decrease'}
          className="p-1.5 rounded hover:bg-accent disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
        >
          <Minus className="w-4 h-4" />
        </button>
        <span className="w-8 text-center tabular-nums" aria-live="polite">
          {line.qty}
        </span>
        <button
          onClick={() => setQty(line.product, line.qty + 1)}
          disabled={line.stock > 0 && line.qty >= line.stock}
          aria-label={language === 'ar' ? 'زيادة' : 'Increase'}
          className="p-1.5 rounded hover:bg-accent disabled:opacity-40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
        >
          <Plus className="w-4 h-4" />
        </button>
      </div>

      <div className="w-24 text-right font-semibold tabular-nums hidden sm:block">
        {formatEGP(line.priceEGP * line.qty, language)}
      </div>

      <button
        onClick={() => remove(line.product)}
        aria-label={language === 'ar' ? 'إزالة من السلة' : 'Remove from cart'}
        className="p-2 text-muted-foreground hover:text-destructive focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive rounded"
      >
        <Trash2 className="w-4 h-4" />
      </button>
    </div>
  );
}
