import { useCallback, useEffect, useState } from 'react';
import { toast } from 'sonner';
import {
  deleteReview,
  listReviews,
  type Review,
} from '../../api/reviewApi';
import { useAuth } from '../../hooks/useAuth';
import { useApp } from '../AppProviders';
import { RatingSummary } from './RatingSummary';
import { ReviewForm } from './ReviewForm';
import { ReviewItem } from './ReviewItem';

interface Props {
  slug: string;
  initialAvg: number;
  initialCount: number;
}

export function ReviewList({ slug, initialAvg, initialCount }: Props) {
  const { user } = useAuth();
  const { language } = useApp();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState({
    ratingAvg: initialAvg,
    ratingCount: initialCount,
  });

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const r = await listReviews(slug, 1, 20);
      setReviews(r.reviews);
      setSummary(r.summary);
    } catch {
      /* handled silently — empty list */
    } finally {
      setLoading(false);
    }
  }, [slug]);

  useEffect(() => {
    load();
  }, [load]);

  const myExisting = user ? reviews.find((r) => r.user === user.id) : undefined;

  const onCreated = (review: Review) => {
    setReviews((prev) => [review, ...prev]);
    setSummary((s) => {
      const newCount = s.ratingCount + 1;
      const newAvg = (s.ratingAvg * s.ratingCount + review.rating) / newCount;
      return {
        ratingCount: newCount,
        ratingAvg: Math.round(newAvg * 10) / 10,
      };
    });
  };

  const onDelete = async (id: string) => {
    if (!confirm(language === 'ar' ? 'هل أنت متأكد من الحذف؟' : 'Delete this review?'))
      return;
    try {
      await deleteReview(id);
      toast.success(language === 'ar' ? 'تم الحذف' : 'Review deleted');
      await load();
    } catch (err: unknown) {
      toast.error((err as { message?: string })?.message || 'Delete failed');
    }
  };

  return (
    <section aria-labelledby="reviews-heading" className="py-12">
      <h2 id="reviews-heading" className="text-2xl md:text-3xl font-bold mb-6">
        {language === 'ar' ? 'تقييمات العملاء' : 'Customer reviews'}
      </h2>

      <div className="grid md:grid-cols-[1fr_2fr] gap-8">
        <div className="space-y-6">
          <RatingSummary avg={summary.ratingAvg} count={summary.ratingCount} />
          <ReviewForm
            slug={slug}
            hasExisting={Boolean(myExisting)}
            onCreated={onCreated}
          />
        </div>
        <div>
          {loading ? (
            <div className="text-sm text-muted-foreground">
              {language === 'ar' ? 'جاري التحميل...' : 'Loading reviews…'}
            </div>
          ) : reviews.length === 0 ? (
            <div className="text-sm text-muted-foreground">
              {language === 'ar'
                ? 'لا توجد تقييمات بعد — كن أول من يكتب تقييمًا.'
                : 'No reviews yet — be the first to write one.'}
            </div>
          ) : (
            <div className="rounded-2xl border border-border bg-card px-6">
              {reviews.map((r) => (
                <ReviewItem key={r._id} review={r} onDelete={onDelete} />
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
