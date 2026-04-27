import { useEffect, useMemo, useState } from 'react';
import { motion } from 'motion/react';
import { Link } from 'react-router-dom';
import { ShoppingCart, Star, Sparkles } from 'lucide-react';
import { listProducts, type Product } from '../api/productApi';
import { useApp } from '../components/AppProviders';
import { useCart } from '../context/CartContext';
import { formatEGP } from '../lib/formatCurrency';

type Tab = 'all' | 'hardware' | 'digital';

// Fallback products shown when the API is unreachable (DB down)
const FALLBACK_PRODUCTS: Product[] = [
  {
    _id: 'fb-glasses', slug: 'smart-assistive-glasses', category: 'hardware', isFeatured: true, isConcept: false,
    title: { en: 'Smart Assistive Glasses', ar: 'النظارات الذكية المساعدة' },
    tagline: { en: 'AI-powered vision, voice and awareness', ar: 'رؤية وصوت ووعي بالذكاء الاصطناعي' },
    description: { en: 'Flagship smart glasses with sign language recognition, obstacle detection and voice guidance.', ar: 'نظارات ذكية رائدة.' },
    features: [], specs: [],
    images: [{ src: '', alt: { en: 'Smart Glasses', ar: 'النظارات الذكية' } }],
    priceEGP: 12999, compareAtEGP: 15999, stock: 25, ratingAvg: 4.8, ratingCount: 42,
  },
  {
    _id: 'fb-bracelet', slug: 'smart-bracelet', category: 'hardware', isFeatured: false, isConcept: false,
    title: { en: 'Smart Bracelet', ar: 'السوار الذكي' },
    tagline: { en: 'Safety and connection, on your wrist', ar: 'الأمان والاتصال على معصمك' },
    description: { en: 'SOS emergency button, vibration alerts, live location sharing.', ar: 'زر استغاثة وتنبيهات.' },
    features: [], specs: [],
    images: [{ src: '', alt: { en: 'Smart Bracelet', ar: 'السوار الذكي' } }],
    priceEGP: 2499, stock: 60, ratingAvg: 4.6, ratingCount: 28,
  },
  {
    _id: 'fb-app', slug: 'ishara-mobile-app', category: 'digital', isFeatured: false, isConcept: false,
    title: { en: 'Ishara Mobile App', ar: 'تطبيق إشارة' },
    tagline: { en: 'Your pocket interpreter and learning hub', ar: 'مترجمك الشخصي ومركز التعلم' },
    description: { en: 'Sign translation, voice-to-text, learning hub.', ar: 'ترجمة الإشارة.' },
    features: [], specs: [],
    images: [{ src: '', alt: { en: 'Ishara App', ar: 'تطبيق إشارة' } }],
    priceEGP: 0, stock: 9999, ratingAvg: 4.9, ratingCount: 156,
  },
];

const PRODUCT_GRADIENTS = [
  'from-[#14B8A6]/20 via-[#0f766e]/10 to-[#14B8A6]/5',
  'from-[#F97316]/20 via-[#c2410c]/10 to-[#F97316]/5',
  'from-[#6366f1]/20 via-[#4338ca]/10 to-[#6366f1]/5',
];
const PRODUCT_ICONS = ['🕶️', '⌚', '📱'];

export default function ProductsPage() {
  const { language } = useApp();
  const { add } = useCart();
  const [products, setProducts] = useState<Product[] | null>(null);
  const [tab, setTab] = useState<Tab>('all');
  const [addedId, setAddedId] = useState<string | null>(null);

  useEffect(() => {
    listProducts()
      .then((data) => setProducts(data && data.length > 0 ? data : FALLBACK_PRODUCTS))
      .catch(() => setProducts(FALLBACK_PRODUCTS));
  }, []);

  const L = {
    en: {
      title: 'Shop the Ishara Ecosystem',
      subtitle: 'Connected assistive technology for deaf, non-verbal and blind users.',
      tabs: { all: 'All Products', hardware: 'Hardware', digital: 'Apps & Digital' },
      addToCart: 'Add to Cart',
      added: 'Added ✓',
      free: 'Free',
    },
    ar: {
      title: 'تسوّق منظومة إشارة',
      subtitle: 'تقنيات مساعدة متصلة لضعاف السمع والمكفوفين.',
      tabs: { all: 'كل المنتجات', hardware: 'الأجهزة', digital: 'تطبيقات' },
      addToCart: 'أضف للسلة',
      added: 'تمت ✓',
      free: 'مجاني',
    },
  }[language];

  const shop = useMemo(() => (products || []).filter((p) => !p.isConcept), [products]);
  const filtered = useMemo(() => (tab === 'all' ? shop : shop.filter((p) => p.category === tab)), [shop, tab]);

  const handleAddToCart = (product: Product) => {
    add(product, 1);
    setAddedId(product._id);
    setTimeout(() => setAddedId(null), 1500);
  };

  return (
    <main id="main" className="min-h-screen pt-28 pb-20 relative">
      {/* Background orbs */}
      <div aria-hidden className="fixed inset-0 pointer-events-none -z-10">
        <div className="absolute top-[5%] right-[10%] w-[500px] h-[500px] rounded-full bg-[var(--ishara-brand-teal)]/[0.04] blur-3xl" />
        <div className="absolute bottom-[10%] left-[5%] w-[400px] h-[400px] rounded-full bg-[var(--ishara-brand-orange)]/[0.04] blur-3xl" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <header className="max-w-3xl mb-12">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--ishara-brand-teal)]/10 border border-[var(--ishara-brand-teal)]/20 mb-4"
          >
            <Sparkles className="w-4 h-4 text-[var(--ishara-brand-teal)]" />
            <span className="text-xs font-medium text-[var(--ishara-brand-teal)]">{language === 'ar' ? 'متجر إشارة' : 'ISHARA STORE'}</span>
          </motion.div>
          <motion.h1
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold text-gradient"
          >
            {L.title}
          </motion.h1>
          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }} className="text-muted-foreground mt-3 md:text-lg">
            {L.subtitle}
          </motion.p>
        </header>

        {/* Tabs */}
        <div role="tablist" aria-label="Product categories" className="inline-flex p-1 rounded-2xl bg-muted border border-border mb-10">
          {(['all', 'hardware', 'digital'] as Tab[]).map((t) => (
            <button
              key={t}
              role="tab"
              aria-selected={tab === t}
              onClick={() => setTab(t)}
              className={`px-5 py-2.5 rounded-xl text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] ${
                tab === t
                  ? 'bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white shadow-lg'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {L.tabs[t]}
            </button>
          ))}
        </div>

        {/* Product Grid */}
        {!products ? (
          <ProductGridSkeleton />
        ) : filtered.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-muted-foreground text-lg">{language === 'ar' ? 'لا توجد منتجات.' : 'No products found.'}</p>
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8">
            {filtered.map((p, i) => (
              <motion.article
                key={p._id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                whileHover={{ y: -6 }}
                className="group bg-card border border-border rounded-3xl overflow-hidden flex flex-col shadow-sm hover:shadow-xl transition-shadow duration-300"
              >
                {/* Image / Gradient placeholder */}
                <Link to={`/products/${p.slug}`} className="block aspect-[4/3] overflow-hidden relative">
                  {p.images[0]?.src ? (
                    <img
                      src={p.images[0].src}
                      alt={p.images[0].alt[language] || p.title[language]}
                      className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                      loading="lazy"
                    />
                  ) : (
                    <div className={`w-full h-full bg-gradient-to-br ${PRODUCT_GRADIENTS[i % PRODUCT_GRADIENTS.length]} flex items-center justify-center`}>
                      <motion.span
                        className="text-7xl select-none"
                        animate={{ y: [0, -8, 0], rotate: [0, 5, -5, 0] }}
                        transition={{ duration: 4, repeat: Infinity }}
                      >
                        {PRODUCT_ICONS[i % PRODUCT_ICONS.length]}
                      </motion.span>
                    </div>
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  {p.isFeatured && (
                    <span className="absolute top-4 left-4 px-3 py-1 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white text-[10px] font-bold uppercase tracking-wider shadow-lg">
                      {language === 'ar' ? 'مميز' : 'Featured'}
                    </span>
                  )}
                </Link>

                <div className="p-6 flex flex-col flex-1">
                  <h3 className="font-bold text-lg leading-tight">
                    <Link to={`/products/${p.slug}`} className="hover:text-[var(--ishara-brand-teal)] transition-colors">
                      {p.title[language] || p.title.en}
                    </Link>
                  </h3>
                  <p className="text-sm text-muted-foreground mt-1.5 line-clamp-2">{p.tagline[language] || p.tagline.en}</p>

                  {/* Rating */}
                  {p.ratingCount > 0 && (
                    <div className="flex items-center gap-1.5 mt-3">
                      <div className="flex gap-0.5">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star
                            key={star}
                            className={`w-3.5 h-3.5 ${star <= Math.round(p.ratingAvg) ? 'fill-amber-400 text-amber-400' : 'fill-muted text-muted'}`}
                          />
                        ))}
                      </div>
                      <span className="text-xs text-muted-foreground">{p.ratingAvg.toFixed(1)} ({p.ratingCount})</span>
                    </div>
                  )}

                  <div className="flex items-end justify-between mt-auto pt-5">
                    {p.priceEGP === 0 ? (
                      <span className="text-lg font-bold text-[var(--ishara-brand-teal)]">{L.free}</span>
                    ) : (
                      <div>
                        <span className="text-xl font-bold">{formatEGP(p.priceEGP, language)}</span>
                        {p.compareAtEGP && p.compareAtEGP > p.priceEGP && (
                          <span className="ml-2 text-sm text-muted-foreground line-through">{formatEGP(p.compareAtEGP, language)}</span>
                        )}
                      </div>
                    )}
                    <motion.button
                      onClick={() => handleAddToCart(p)}
                      disabled={p.stock <= 0}
                      className={`px-4 py-2.5 rounded-xl text-sm font-medium flex items-center gap-2 transition-all ${
                        addedId === p._id
                          ? 'bg-[var(--ishara-brand-teal)] text-white shadow-lg'
                          : 'bg-secondary border border-border text-foreground hover:bg-gradient-to-r hover:from-[#14B8A6] hover:to-[#F97316] hover:text-white hover:border-transparent hover:shadow-lg'
                      }`}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <ShoppingCart className="w-4 h-4" />
                      {addedId === p._id ? L.added : L.addToCart}
                    </motion.button>
                  </div>
                </div>
              </motion.article>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

function ProductGridSkeleton() {
  return (
    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8" aria-hidden="true">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="rounded-3xl bg-card border border-border overflow-hidden">
          <div className="aspect-[4/3] bg-muted animate-pulse" />
          <div className="p-6 space-y-3">
            <div className="h-5 bg-muted rounded-lg w-2/3 animate-pulse" />
            <div className="h-3 bg-muted rounded w-full animate-pulse" />
            <div className="h-3 bg-muted rounded w-1/2 animate-pulse" />
          </div>
        </div>
      ))}
    </div>
  );
}
