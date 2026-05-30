// EGP currency formatter with locale-aware output.
//   en -> "EGP 12,999"
//   ar -> "١٢٬٩٩٩ ج.م"
// Falls back to plain number + "EGP" if Intl is unavailable.
export function formatEGP(amount: number, lang: 'en' | 'ar' = 'en'): string {
  const safe = Number.isFinite(amount) ? amount : 0;
  try {
    return new Intl.NumberFormat(lang === 'ar' ? 'ar-EG' : 'en-EG', {
      style: 'currency',
      currency: 'EGP',
      maximumFractionDigits: 0,
    }).format(safe);
  } catch {
    return `${safe.toLocaleString()} EGP`;
  }
}
