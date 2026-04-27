import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { toast } from 'sonner';
import { AlertTriangle, ShieldCheck, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { useCart } from '../context/CartContext';
import { useAuth } from '../hooks/useAuth';
import { useApp } from '../components/AppProviders';
import { createOrder } from '../api/orderApi';
import { CheckoutForm, type CheckoutFormValues } from '../components/checkout/CheckoutForm';
import { StripePaymentElement } from '../components/checkout/StripePaymentElement';
import { formatEGP } from '../lib/formatCurrency';

const SHIPPING_EGP = 50;

export default function CheckoutPage() {
  const { lines, subtotalEGP, clear } = useCart();
  const { user, isAuthenticated } = useAuth();
  const { language } = useApp();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [submitting, setSubmitting] = useState(false);
  const [paymentError, setPaymentError] = useState<string | null>(null);
  const [order, setOrder] = useState<
    | { id: string; clientSecret: string | null; provider: 'stripe' | 'mock' }
    | null
  >(null);

  // Redirect gating
  useEffect(() => {
    if (!isAuthenticated) navigate('/login?redirect=/checkout');
  }, [isAuthenticated, navigate]);
  useEffect(() => {
    if (lines.length === 0 && !order) navigate('/cart');
  }, [lines.length, order, navigate]);

  // Handle Stripe return — when user comes back from Stripe redirect
  useEffect(() => {
    const paymentIntent = searchParams.get('payment_intent');
    const redirectStatus = searchParams.get('redirect_status');
    if (paymentIntent && redirectStatus === 'succeeded') {
      // Payment succeeded via Stripe redirect — clear cart
      clear();
      toast.success(
        language === 'ar'
          ? 'تم الدفع بنجاح!'
          : 'Payment successful!'
      );
    } else if (paymentIntent && redirectStatus === 'failed') {
      setPaymentError(
        language === 'ar'
          ? 'فشلت عملية الدفع. يرجى المحاولة مرة أخرى.'
          : 'Payment failed. Please try again.'
      );
    }
  }, [searchParams]); // eslint-disable-line react-hooks/exhaustive-deps

  const L = {
    en: {
      title: 'Checkout',
      review: 'Your items',
      payment: 'Payment',
      mockBanner:
        'Demo mode — Stripe not configured. Orders complete instantly and are recorded, but no money is charged.',
      subtotal: 'Subtotal',
      shipping: 'Shipping',
      total: 'Total',
      secure: 'Secure checkout powered by Stripe',
      paymentFailed: 'Payment failed',
      tryAgain: 'Try again',
      orderFailed: 'Order creation failed. Please try again.',
    },
    ar: {
      title: 'إتمام الشراء',
      review: 'عناصر طلبك',
      payment: 'الدفع',
      mockBanner:
        'وضع العرض التجريبي — لم يُهيّأ Stripe. يتم إنشاء الطلبات فعليًا لكن دون خصم مبلغ.',
      subtotal: 'المجموع الفرعي',
      shipping: 'الشحن',
      total: 'الإجمالي',
      secure: 'دفع آمن عبر Stripe',
      paymentFailed: 'فشل الدفع',
      tryAgain: 'حاول مرة أخرى',
      orderFailed: 'فشل في إنشاء الطلب. يرجى المحاولة مرة أخرى.',
    },
  }[language];

  const onSubmit = async (values: CheckoutFormValues) => {
    setSubmitting(true);
    setPaymentError(null);
    try {
      const { receiptEmail, ...address } = values;
      const res = await createOrder({
        items: lines.map((l) => ({ product: l.product, qty: l.qty })),
        address,
        receiptEmail,
      });
      setOrder({
        id: res.orderId,
        clientSecret: res.clientSecret,
        provider: res.provider,
      });
      if (res.provider === 'mock') {
        toast.success(
          language === 'ar'
            ? 'تم إنشاء طلبك (وضع تجريبي)'
            : 'Order placed (demo mode)'
        );
        // Cart is cleared ONLY after confirmed payment (mock = instant)
        clear();
        navigate(`/orders/${res.orderId}`);
      }
      // For Stripe: cart is NOT cleared here — it's cleared after
      // the webhook confirms payment or after redirect_status=succeeded
    } catch (err: unknown) {
      const msg = (err as { message?: string })?.message || L.orderFailed;
      setPaymentError(msg);
      toast.error(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const total = subtotalEGP + (lines.length ? SHIPPING_EGP : 0);

  return (
    <main id="main" className="min-h-screen pt-28 pb-20">
      <div className="container mx-auto px-6 max-w-5xl">
        <motion.h1
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-3xl md:text-5xl font-bold mb-8"
        >
          {L.title}
        </motion.h1>

        {/* Payment error banner */}
        {paymentError && (
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            role="alert"
            className="mb-6 flex items-start gap-3 p-4 rounded-2xl bg-red-500/10 border border-red-500/20 text-red-700 dark:text-red-400"
          >
            <AlertTriangle className="w-5 h-5 mt-0.5 shrink-0" />
            <div className="flex-1">
              <p className="font-medium">{L.paymentFailed}</p>
              <p className="text-sm mt-1">{paymentError}</p>
            </div>
            <button
              onClick={() => { setPaymentError(null); setOrder(null); }}
              className="text-sm font-medium underline underline-offset-4 hover:no-underline shrink-0"
            >
              {L.tryAgain}
            </button>
          </motion.div>
        )}

        <div className="grid lg:grid-cols-[1fr_360px] gap-10">
          <section>
            {!order ? (
              <CheckoutForm
                defaultEmail={user?.email}
                defaultName={user?.name}
                onSubmit={onSubmit}
                submitting={submitting}
              />
            ) : order.clientSecret ? (
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                className="space-y-6"
              >
                <h2 className="text-xl font-semibold">{L.payment}</h2>
                <StripePaymentElement
                  clientSecret={order.clientSecret}
                  orderId={order.id}
                  returnPath={`/orders/${order.id}`}
                />
                <p className="text-xs text-muted-foreground flex items-center gap-1.5">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  {L.secure}
                </p>
              </motion.div>
            ) : (
              <div
                role="status"
                className="flex items-start gap-3 p-4 rounded-lg bg-amber-500/10 text-amber-700 dark:text-amber-300"
              >
                <AlertTriangle className="w-5 h-5 mt-0.5" aria-hidden="true" />
                <p className="text-sm">{L.mockBanner}</p>
              </div>
            )}
          </section>

          <aside className="bg-card border border-border rounded-2xl p-6 h-fit sticky top-28">
            <h2 className="font-semibold mb-4">{L.review}</h2>
            <ul className="space-y-3 mb-4">
              {lines.map((l) => (
                <li key={l.product} className="flex justify-between text-sm">
                  <span>
                    {(language === 'ar' ? l.titleAr || l.titleEn : l.titleEn)}{' '}
                    <span className="text-muted-foreground">× {l.qty}</span>
                  </span>
                  <span className="tabular-nums">
                    {formatEGP(l.priceEGP * l.qty, language)}
                  </span>
                </li>
              ))}
            </ul>
            <div className="text-sm space-y-1 border-t border-border pt-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">{L.subtotal}</span>
                <span>{formatEGP(subtotalEGP, language)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">{L.shipping}</span>
                <span>{formatEGP(lines.length ? SHIPPING_EGP : 0, language)}</span>
              </div>
              <div className="flex justify-between font-semibold text-base pt-2">
                <span>{L.total}</span>
                <span className="tabular-nums">{formatEGP(total, language)}</span>
              </div>
            </div>

            {/* Processing indicator */}
            {submitting && (
              <div className="flex items-center justify-center gap-2 mt-4 py-3 rounded-xl bg-[#14B8A6]/10 text-[#14B8A6] text-sm font-medium">
                <Loader2 className="w-4 h-4 animate-spin" />
                {language === 'ar' ? 'جاري المعالجة…' : 'Processing…'}
              </div>
            )}
          </aside>
        </div>
      </div>
    </main>
  );
}
