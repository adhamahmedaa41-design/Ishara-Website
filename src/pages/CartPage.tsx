import { Link } from 'react-router-dom';
import { ShoppingBag } from 'lucide-react';
import { useCart } from '../context/CartContext';
import { useApp } from '../components/AppProviders';
import { CartLineItem } from '../components/cart/CartLineItem';
import { CartSummary } from '../components/cart/CartSummary';

export default function CartPage() {
  const { lines, isSyncing } = useCart();
  const { language } = useApp();

  const L = {
    en: {
      title: 'Your cart',
      empty: 'Your cart is empty.',
      browse: 'Browse products',
      syncing: 'Syncing with your account…',
    },
    ar: {
      title: 'سلتك',
      empty: 'سلتك فارغة.',
      browse: 'تصفح المنتجات',
      syncing: 'جاري المزامنة مع حسابك…',
    },
  }[language];

  return (
    <main id="main" className="min-h-screen pt-28 pb-20">
      <div className="container mx-auto px-6">
        <h1 className="text-3xl md:text-5xl font-bold mb-8">{L.title}</h1>
        {isSyncing && (
          <div role="status" className="text-sm text-muted-foreground mb-4">
            {L.syncing}
          </div>
        )}

        {lines.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-12 text-center">
            <ShoppingBag
              className="w-12 h-12 mx-auto text-muted-foreground"
              aria-hidden="true"
            />
            <p className="mt-4 text-lg">{L.empty}</p>
            <Link
              to="/products"
              className="inline-block mt-6 px-6 py-3 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
            >
              {L.browse}
            </Link>
          </div>
        ) : (
          <div className="grid lg:grid-cols-[1fr_380px] gap-10">
            <div>
              {lines.map((line) => (
                <CartLineItem key={line.product} line={line} />
              ))}
            </div>
            <CartSummary />
          </div>
        )}
      </div>
    </main>
  );
}
