import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { CheckCircle2, Printer } from 'lucide-react';
import { motion } from 'motion/react';
import { getOrder, type Order } from '../api/orderApi';
import { useApp } from '../components/AppProviders';
import { formatEGP } from '../lib/formatCurrency';

export default function OrderConfirmationPage() {
  const { id = '' } = useParams();
  const { language } = useApp();
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getOrder(id)
      .then(({ order }) => setOrder(order))
      .catch((e) => setError((e as { message?: string })?.message || 'Not found'));
  }, [id]);

  const L = {
    en: {
      thanks: 'Thank you for your order!',
      subtitle: (num: string) =>
        `Order #${num} is confirmed. A receipt has been emailed to you.`,
      pending: 'Payment pending. Please complete the payment step.',
      items: 'Items',
      shipping: 'Shipping to',
      total: 'Total',
      print: 'Print receipt',
      continue: 'Continue shopping',
      orders: 'View my orders',
    },
    ar: {
      thanks: 'شكرًا لطلبك!',
      subtitle: (num: string) =>
        `تم تأكيد الطلب رقم ${num}. تم إرسال الإيصال إلى بريدك الإلكتروني.`,
      pending: 'الدفع معلّق. يُرجى إكمال عملية الدفع.',
      items: 'العناصر',
      shipping: 'الشحن إلى',
      total: 'الإجمالي',
      print: 'طباعة الإيصال',
      continue: 'متابعة التسوق',
      orders: 'عرض طلباتي',
    },
  }[language];

  if (error)
    return (
      <main className="min-h-screen pt-28 pb-20 container mx-auto px-6">
        <p role="alert" className="text-destructive">{error}</p>
      </main>
    );

  if (!order)
    return (
      <main className="min-h-screen pt-28 pb-20 container mx-auto px-6">
        <div className="h-12 bg-muted animate-pulse rounded w-1/2" />
      </main>
    );

  const isPaid = order.status === 'paid' || order.status === 'fulfilled';

  return (
    <main id="main" className="min-h-screen pt-28 pb-20 print:pt-8">
      <div className="container mx-auto px-6 max-w-3xl">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <CheckCircle2
            className={`w-16 h-16 mx-auto ${
              isPaid ? 'text-emerald-500' : 'text-amber-500'
            }`}
            aria-hidden="true"
          />
          <h1 className="text-3xl md:text-4xl font-bold mt-4">{L.thanks}</h1>
          <p className="text-muted-foreground mt-2">
            {isPaid ? L.subtitle(order._id.slice(-6).toUpperCase()) : L.pending}
          </p>
        </motion.div>

        <section className="mt-10 rounded-2xl border border-border bg-card p-6">
          <h2 className="font-semibold mb-4">{L.items}</h2>
          <ul className="divide-y divide-border">
            {order.items.map((i) => (
              <li key={i.product} className="flex items-center gap-4 py-3">
                {i.image && (
                  <img
                    src={i.image}
                    alt=""
                    aria-hidden="true"
                    className="w-14 h-14 rounded-lg object-cover bg-muted"
                  />
                )}
                <div className="flex-1">
                  <div className="font-medium">
                    {language === 'ar' ? i.titleAr || i.titleEn : i.titleEn}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    × {i.qty}
                  </div>
                </div>
                <div className="tabular-nums">
                  {formatEGP(i.unitPriceEGP * i.qty, language)}
                </div>
              </li>
            ))}
          </ul>

          <div className="mt-6 text-right">
            <div className="text-sm text-muted-foreground">
              {language === 'ar' ? 'الشحن' : 'Shipping'}:{' '}
              {formatEGP(order.shippingEGP, language)}
            </div>
            <div className="text-xl font-semibold mt-1">
              {L.total}: {formatEGP(order.totalEGP, language)}
            </div>
          </div>
        </section>

        <section className="mt-6 rounded-2xl border border-border bg-card p-6">
          <h2 className="font-semibold mb-3">{L.shipping}</h2>
          <address className="not-italic text-sm text-muted-foreground leading-relaxed">
            {order.address.fullName}<br />
            {order.address.line1}{order.address.line2 ? `, ${order.address.line2}` : ''}<br />
            {order.address.city}, {order.address.governorate} {order.address.postalCode}<br />
            {order.address.phone}
          </address>
        </section>

        <div className="flex flex-wrap gap-3 mt-8 print:hidden">
          <button
            onClick={() => window.print()}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full border border-border hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
          >
            <Printer className="w-4 h-4" aria-hidden="true" /> {L.print}
          </button>
          <Link
            to="/orders"
            className="inline-flex items-center px-5 py-2.5 rounded-full border border-border hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
          >
            {L.orders}
          </Link>
          <Link
            to="/products"
            className="inline-flex items-center px-5 py-2.5 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
          >
            {L.continue}
          </Link>
        </div>
      </div>
    </main>
  );
}
