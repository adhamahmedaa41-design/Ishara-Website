import { Trash2 } from 'lucide-react';
import { StarRating } from './StarRating';
import type { Review } from '../../api/reviewApi';
import { useAuth } from '../../hooks/useAuth';
import { useApp } from '../AppProviders';

interface Props {
  review: Review;
  onDelete?: (id: string) => void;
}

export function ReviewItem({ review, onDelete }: Props) {
  const { user } = useAuth();
  const { language } = useApp();
  const isOwner = user?.id === review.user;
  const when = new Date(review.createdAt).toLocaleDateString(
    language === 'ar' ? 'ar-EG' : 'en-GB',
    { year: 'numeric', month: 'short', day: 'numeric' }
  );

  return (
    <article className="py-4 border-b border-border last:border-0">
      <header className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          {review.userAvatar ? (
            <img
              src={review.userAvatar}
              alt=""
              aria-hidden="true"
              className="w-9 h-9 rounded-full object-cover"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#14B8A6] to-[#F97316] text-white flex items-center justify-center font-semibold">
              {review.userName.charAt(0).toUpperCase()}
            </div>
          )}
          <div>
            <div className="font-medium leading-tight">{review.userName}</div>
            <div className="text-xs text-muted-foreground">{when}</div>
          </div>
        </div>
        {isOwner && onDelete && (
          <button
            onClick={() => onDelete(review._id)}
            aria-label={language === 'ar' ? 'حذف تقييمي' : 'Delete my review'}
            className="p-2 text-muted-foreground hover:text-destructive rounded focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        )}
      </header>
      <div className="mt-2">
        <StarRating value={review.rating} readOnly />
      </div>
      {review.text && (
        <p className="text-sm mt-2 leading-relaxed whitespace-pre-wrap">
          {review.text}
        </p>
      )}
    </article>
  );
}
