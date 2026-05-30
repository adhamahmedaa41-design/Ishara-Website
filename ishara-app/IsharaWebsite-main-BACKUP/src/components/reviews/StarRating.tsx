import { useState, KeyboardEvent } from 'react';
import { Star } from 'lucide-react';

interface Props {
  value: number; // 0..5
  onChange?: (v: number) => void;
  size?: number;
  readOnly?: boolean;
  label?: string;
}

// Accessible 1..5 star rating. Keyboard: arrow keys adjust when interactive.
export function StarRating({ value, onChange, size = 20, readOnly, label }: Props) {
  const [hover, setHover] = useState<number | null>(null);
  const current = hover ?? value;

  const commit = (v: number) => onChange?.(Math.max(1, Math.min(5, v)));

  const handleKey = (e: KeyboardEvent<HTMLDivElement>) => {
    if (readOnly) return;
    if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
      e.preventDefault();
      commit((value || 0) + 1);
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
      e.preventDefault();
      commit((value || 0) - 1);
    } else if (e.key >= '1' && e.key <= '5') {
      commit(Number(e.key));
    }
  };

  return (
    <div
      role={readOnly ? 'img' : 'radiogroup'}
      aria-label={label || (readOnly ? `Rating: ${value} out of 5` : 'Choose a rating from 1 to 5')}
      aria-valuenow={readOnly ? value : undefined}
      tabIndex={readOnly ? -1 : 0}
      onKeyDown={handleKey}
      className={`inline-flex items-center gap-0.5 ${readOnly ? '' : 'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] rounded'}`}
      onMouseLeave={() => setHover(null)}
    >
      {[1, 2, 3, 4, 5].map((n) => {
        const filled = n <= Math.round(current);
        const common = {
          width: size,
          height: size,
        };
        const star = (
          <Star
            style={common}
            className={filled ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/40'}
            aria-hidden="true"
          />
        );
        return readOnly ? (
          <span key={n}>{star}</span>
        ) : (
          <button
            key={n}
            type="button"
            role="radio"
            aria-checked={value === n}
            aria-label={`${n} star${n > 1 ? 's' : ''}`}
            onMouseEnter={() => setHover(n)}
            onClick={() => commit(n)}
            className="p-0.5 rounded focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
          >
            {star}
          </button>
        );
      })}
    </div>
  );
}
