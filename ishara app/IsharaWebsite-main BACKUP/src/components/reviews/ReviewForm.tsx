import { useState } from 'react';
import { Link } from 'react-router-dom';
import { toast } from 'sonner';
import { StarRating } from './StarRating';
import { createReview } from '../../api/reviewApi';
import type { Review } from '../../api/reviewApi';
import { useAuth } from '../../hooks/useAuth';
import { useApp } from '../AppProviders';

interface Props {
  slug: string;
  hasExisting: boolean;
  onCreated: (r: Review) => void;
}

export function ReviewForm({ slug, hasExisting, onCreated }: Props) {
  const { isAuthenticated } = useAuth();
  const { language } = useApp();
  const [rating, setRating] = useState(0);
  const [text, setText] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const L = {
    en: {
      title: 'Write a review',
      ratingLabel: 'Your rating',
      textLabel: 'Your review (optional)',
      placeholder: 'Share how Ishara helped you or someone you know…',
      submit: 'Post review',
      submitting: 'Posting…',
      loginCta: 'Sign in to leave a review',
      already: 'You have already reviewed this product.',
      ratingRequired: 'Please pick a rating from 1 to 5.',
    },
    ar: {
      title: 'اكتب تقييمًا',
      ratingLabel: 'تقييمك',
      textLabel: 'تقييمك (اختياري)',
      placeholder: 'شاركنا كيف ساعدتك إشارة أو شخصًا تعرفه…',
      submit: 'نشر التقييم',
      submitting: 'جاري النشر…',
      loginCta: 'سجّل الدخول لكتابة تقييم',
      already: 'لقد قيّمت هذا المنتج من قبل.',
      ratingRequired: 'اختر تقييمًا من ١ إلى ٥.',
    },
  }[language];

  if (!isAuthenticated) {
    return (
      <div className="rounded-2xl border border-border bg-card p-6 text-center">
        <Link
          to="/login"
          className="inline-block px-5 py-2 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
        >
          {L.loginCta}
        </Link>
      </div>
    );
  }

  if (hasExisting) {
    return (
      <div className="rounded-2xl border border-border bg-muted/30 p-6 text-sm text-muted-foreground">
        {L.already}
      </div>
    );
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (rating < 1) {
      setError(L.ratingRequired);
      return;
    }
    setSubmitting(true);
    try {
      const { review } = await createReview(slug, { rating, text: text.trim() });
      toast.success(
        language === 'ar' ? 'تم نشر تقييمك. شكرًا!' : 'Review posted. Thank you!'
      );
      onCreated(review);
      setRating(0);
      setText('');
    } catch (err: unknown) {
      const msg =
        (err as { message?: string })?.message ||
        (language === 'ar' ? 'تعذّر نشر التقييم.' : 'Could not post review.');
      setError(msg);
      toast.error(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form
      onSubmit={submit}
      className="rounded-2xl border border-border bg-card p-6 space-y-4"
      aria-labelledby="review-form-heading"
    >
      <h3 id="review-form-heading" className="font-semibold">
        {L.title}
      </h3>

      <div>
        <label className="block text-sm font-medium mb-2">{L.ratingLabel}</label>
        <StarRating value={rating} onChange={setRating} size={28} />
      </div>

      <div>
        <label htmlFor="review-text" className="block text-sm font-medium mb-2">
          {L.textLabel}
        </label>
        <textarea
          id="review-text"
          rows={4}
          maxLength={2000}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={L.placeholder}
          className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
        />
      </div>

      {error && (
        <div role="alert" className="text-sm text-destructive">
          {error}
        </div>
      )}

      <button
        type="submit"
        disabled={submitting}
        className="px-5 py-2 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
      >
        {submitting ? L.submitting : L.submit}
      </button>
    </form>
  );
}
