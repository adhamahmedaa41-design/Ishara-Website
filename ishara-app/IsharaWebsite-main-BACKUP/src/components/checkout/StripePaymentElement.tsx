import { useEffect, useMemo, useState } from 'react';
import { loadStripe, type Stripe } from '@stripe/stripe-js';
import {
  Elements,
  PaymentElement,
  useElements,
  useStripe,
} from '@stripe/react-stripe-js';
import { useApp } from '../AppProviders';

interface Props {
  clientSecret: string;
  orderId: string;
  returnPath: string; // where Stripe redirects after payment, e.g. "/orders/abc"
}

// Lazy-loads Stripe.js only when a clientSecret is actually available.
export function StripePaymentElement({ clientSecret, returnPath }: Props) {
  const publishable = (import.meta as unknown as {
    env: { VITE_STRIPE_PUBLISHABLE_KEY?: string };
  }).env.VITE_STRIPE_PUBLISHABLE_KEY;

  const stripePromise = useMemo<Promise<Stripe | null> | null>(
    () => (publishable ? loadStripe(publishable) : null),
    [publishable]
  );

  if (!publishable || !stripePromise) {
    return (
      <div role="alert" className="text-sm text-destructive">
        Stripe is not configured. Set VITE_STRIPE_PUBLISHABLE_KEY in your .env.
      </div>
    );
  }

  return (
    <Elements
      stripe={stripePromise}
      options={{ clientSecret, appearance: { theme: 'stripe' } }}
    >
      <InnerForm returnPath={returnPath} />
    </Elements>
  );
}

function InnerForm({ returnPath }: { returnPath: string }) {
  const stripe = useStripe();
  const elements = useElements();
  const { language } = useApp();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => setError(null), []);

  const L = {
    en: { pay: 'Pay now', processing: 'Processing payment…' },
    ar: { pay: 'ادفع الآن', processing: 'جاري المعالجة…' },
  }[language];

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe || !elements) return;
    setSubmitting(true);
    setError(null);

    const { error: err } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}${returnPath}`,
      },
    });
    if (err) setError(err.message || 'Payment failed.');
    setSubmitting(false);
  };

  return (
    <form onSubmit={onSubmit} className="space-y-4" aria-label="Card payment form">
      <PaymentElement options={{ layout: 'tabs' }} />
      {error && (
        <div role="alert" className="text-sm text-destructive">
          {error}
        </div>
      )}
      <button
        type="submit"
        disabled={!stripe || submitting}
        className="w-full py-3 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
      >
        {submitting ? L.processing : L.pay}
      </button>
    </form>
  );
}
