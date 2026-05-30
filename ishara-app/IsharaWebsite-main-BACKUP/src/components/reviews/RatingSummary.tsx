import { StarRating } from './StarRating';
import { useApp } from '../AppProviders';

export function RatingSummary({
  avg,
  count,
}: {
  avg: number;
  count: number;
}) {
  const { language } = useApp();
  return (
    <div className="flex items-center gap-4">
      <div className="text-5xl font-bold tabular-nums">{(avg || 0).toFixed(1)}</div>
      <div>
        <StarRating value={avg} readOnly label={`Average ${avg.toFixed(1)} out of 5`} />
        <div className="text-sm text-muted-foreground mt-1">
          {count} {language === 'ar' ? 'تقييم' : count === 1 ? 'review' : 'reviews'}
        </div>
      </div>
    </div>
  );
}
