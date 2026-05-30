import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import type { ProductImage } from '../../api/productApi';
import { useApp } from '../AppProviders';

export function ProductGallery({ images }: { images: ProductImage[] }) {
  const { language } = useApp();
  const [idx, setIdx] = useState(0);
  const [dir, setDir] = useState(0);
  const thumbsRef = useRef<HTMLDivElement | null>(null);
  const touchStartX = useRef<number | null>(null);

  const count = images.length;

  const goTo = useCallback(
    (next: number, direction = 1) => {
      if (count === 0) return;
      const wrapped = ((next % count) + count) % count;
      setDir(direction);
      setIdx(wrapped);
    },
    [count]
  );

  const prev = useCallback(() => goTo(idx - 1, -1), [goTo, idx]);
  const next = useCallback(() => goTo(idx + 1, 1), [goTo, idx]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') prev();
      else if (e.key === 'ArrowRight') next();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [prev, next]);

  useEffect(() => {
    const el = thumbsRef.current?.querySelector<HTMLElement>(`[data-idx="${idx}"]`);
    el?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
  }, [idx]);

  if (count === 0) {
    return (
      <div className="aspect-square rounded-2xl bg-gradient-to-br from-[#14B8A6]/40 to-[#F97316]/40" />
    );
  }

  const main = images[idx];

  const onTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };
  const onTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX.current == null) return;
    const dx = e.changedTouches[0].clientX - touchStartX.current;
    if (Math.abs(dx) > 40) (dx < 0 ? next : prev)();
    touchStartX.current = null;
  };

  const variants = {
    enter: (d: number) => ({ x: d > 0 ? 60 : -60, opacity: 0 }),
    center: { x: 0, opacity: 1 },
    exit: (d: number) => ({ x: d > 0 ? -60 : 60, opacity: 0 }),
  };

  return (
    <div className="select-none">
      <div
        className="relative aspect-square rounded-2xl overflow-hidden bg-muted border border-border group"
        onTouchStart={onTouchStart}
        onTouchEnd={onTouchEnd}
        role="region"
        aria-roledescription="carousel"
        aria-label={language === 'ar' ? 'صور المنتج' : 'Product images'}
      >
        <AnimatePresence initial={false} custom={dir} mode="popLayout">
          <motion.img
            key={main.src}
            src={main.src}
            alt={main.alt[language] || main.alt.en}
            className="absolute inset-0 w-full h-full object-cover"
            custom={dir}
            variants={variants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ x: { type: 'spring', stiffness: 260, damping: 30 }, opacity: { duration: 0.2 } }}
            draggable={false}
          />
        </AnimatePresence>

        {count > 1 && (
          <>
            <button
              type="button"
              onClick={prev}
              aria-label={language === 'ar' ? 'السابق' : 'Previous image'}
              className="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/45 backdrop-blur-sm text-white flex items-center justify-center opacity-0 group-hover:opacity-100 focus-visible:opacity-100 transition hover:bg-black/65 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <button
              type="button"
              onClick={next}
              aria-label={language === 'ar' ? 'التالي' : 'Next image'}
              className="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/45 backdrop-blur-sm text-white flex items-center justify-center opacity-0 group-hover:opacity-100 focus-visible:opacity-100 transition hover:bg-black/65 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
            >
              <ChevronRight className="w-5 h-5" />
            </button>

            <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5">
              {images.map((_, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => goTo(i, i > idx ? 1 : -1)}
                  aria-label={`${language === 'ar' ? 'صورة' : 'Image'} ${i + 1}`}
                  className={`h-1.5 rounded-full transition-all ${
                    i === idx ? 'w-6 bg-white' : 'w-1.5 bg-white/50 hover:bg-white/80'
                  }`}
                />
              ))}
            </div>
          </>
        )}
      </div>

      {count > 1 && (
        <div
          ref={thumbsRef}
          role="listbox"
          aria-label={language === 'ar' ? 'مصغرات الصور' : 'Image thumbnails'}
          className="flex gap-3 mt-4 overflow-x-auto scroll-smooth snap-x snap-mandatory pb-2 [&::-webkit-scrollbar]:hidden [scrollbar-width:none]"
        >
          {images.map((img, i) => (
            <button
              key={img.src}
              data-idx={i}
              role="option"
              aria-selected={i === idx}
              onClick={() => goTo(i, i > idx ? 1 : -1)}
              className={`shrink-0 snap-center w-20 h-20 rounded-lg overflow-hidden border-2 transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] ${
                i === idx ? 'border-[#14B8A6]' : 'border-transparent opacity-60 hover:opacity-100'
              }`}
            >
              <img
                src={img.src}
                alt=""
                aria-hidden="true"
                className="w-full h-full object-cover"
                draggable={false}
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
