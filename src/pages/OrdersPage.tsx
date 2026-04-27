import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { listMyOrders, type Order } from '../api/orderApi';
import { useAuth } from '../hooks/useAuth';
import { useApp } from '../components/AppProviders';
import { formatEGP } from '../lib/formatCurrency';

const STATUS_COLOR: Record<Order['status'], string> = {
  pending_payment: 'bg-amber-500/10 text-amber-600 dark:text-amber-400',
  paid: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
  fulfilled: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
  cancelled: 'bg-red-500/10 text-red-600 dark:text-red-400',
  refunded: 'bg-slate-500/10 text-slate-600 dark:text-slate-400',
};

export default function OrdersPage() {
  const { isAuthenticated } = useAuth();
  const { language } = useApp();
  const navigate = useNavigate();
  const [orders, setOrders] = useState<Order[] | null>(null);

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login?redirect=/orders');
      return;
    }
    listMyOrders()
      .then(({ orders }) => setOrders(orders))
      .catch(() => setOrders([]));
  }, [isAuthenticated, navigate]);

  const L = {
    en: { title: 'My orders', empty: 'You have no orders yet.', view: 'View →', items: 'items' },
    ar: { title: 'طلباتي', empty: 'ليس لديك طلبات بعد.', view: 'عرض ←', items: 'عناصر' },
  }[language];

  return (
    <main id="main" className="min-h-screen pt-28 pb-20">
      <div className="container mx-auto px-6 max-w-4xl">
        <h1 className="text-3xl md:text-4xl font-bold mb-8">{L.title}</h1>
        {orders === null ? (
          <div className="h-24 bg-muted rounded-xl animate-pulse" />
        ) : orders.length === 0 ? (
          <p className="text-muted-foreground">{L.empty}</p>
        ) : (
          <ul className="space-y-3">
            {orders.map((o) => (
              <li key={o._id}>
                <Link
                  to={`/orders/${o._id}`}
                  className="flex flex-wrap items-center gap-4 p-5 rounded-2xl border border-border bg-card hover:border-[#14B8A6] transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
                >
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold">#{o._id.slice(-6).toUpperCase()}</div>
                    <div className="text-sm text-muted-foreground">
                      {new Date(o.createdAt).toLocaleDateString(
                        language === 'ar' ? 'ar-EG' : 'en-GB'
                      )}{' '}
                      · {o.items.length} {L.items}
                    </div>
                  </div>
                  <span
                    className={`text-xs px-2.5 py-1 rounded-full font-medium uppercase tracking-wide ${STATUS_COLOR[o.status]}`}
                  >
                    {o.status.replace('_', ' ')}
                  </span>
                  <div className="font-semibold tabular-nums">
                    {formatEGP(o.totalEGP, language)}
                  </div>
                  <span className="text-[#14B8A6] text-sm" aria-hidden="true">
                    {L.view}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </main>
  );
}
