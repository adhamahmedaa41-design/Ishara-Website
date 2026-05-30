import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { useCart } from '../../context/CartContext';
import { useApp } from '../AppProviders';
import { useAuth } from '../../hooks/useAuth';
import { formatEGP } from '../../lib/formatCurrency';

const SHIPPING_EGP = 50;

export function CartSummary() {
  const { subtotalEGP, count } = useCart();
  const { language } = useApp();
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();

  const shipping = count > 0 ? SHIPPING_EGP : 0;
  const total = subtotalEGP + shipping;

  const L = {
    en: {
      summary: 'Order Summary',
      subtotal: 'Subtotal',
      shipping: 'Shipping',
      total: 'Total',
      checkout: 'Proceed to checkout',
      empty: 'Your cart is empty',
      signInFirst: 'Sign in to checkout',
    },
    ar: {
      summary: 'ملخص الطلب',
      subtotal: 'المجموع الفرعي',
      shipping: 'الشحن',
      total: 'الإجمالي',
      checkout: 'المتابعة للدفع',
      empty: 'سلتك فارغة',
      signInFirst: 'سجّل الدخول للمتابعة',
    },
  }[language];

  const onCheckout = () => {
    if (!isAuthenticated) {
      navigate('/login?redirect=/checkout');
      return;
    }
    navigate('/checkout');
  };

  return (
    <aside
      aria-labelledby="cart-summary-heading"
      className="bg-card border border-border rounded-2xl p-6 sticky top-24"
    >
      <h2 id="cart-summary-heading" className="text-lg font-semibold mb-4">
        {L.summary}
      </h2>
      <dl className="space-y-2 text-sm">
        <div className="flex justify-between">
          <dt className="text-muted-foreground">{L.subtotal}</dt>
          <dd className="tabular-nums">{formatEGP(subtotalEGP, language)}</dd>
        </div>
        <div className="flex justify-between">
          <dt className="text-muted-foreground">{L.shipping}</dt>
          <dd className="tabular-nums">{formatEGP(shipping, language)}</dd>
        </div>
        <div className="h-px bg-border my-2" />
        <div className="flex justify-between text-base font-semibold">
          <dt>{L.total}</dt>
          <dd className="tabular-nums">{formatEGP(total, language)}</dd>
        </div>
      </dl>
      <motion.button
        onClick={onCheckout}
        disabled={count === 0}
        whileHover={{ scale: count === 0 ? 1 : 1.02 }}
        whileTap={{ scale: count === 0 ? 1 : 0.98 }}
        className="w-full mt-6 py-3 px-4 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium disabled:opacity-50 disabled:cursor-not-allowed focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
      >
        {count === 0 ? L.empty : isAuthenticated ? L.checkout : L.signInFirst}
      </motion.button>
    </aside>
  );
}
