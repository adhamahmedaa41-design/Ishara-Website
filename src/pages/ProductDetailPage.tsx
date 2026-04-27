import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ChevronLeft, Star, Shield, Zap, Wifi, Battery, Eye, Hand } from 'lucide-react';
import { motion } from 'motion/react';
import { getProduct, type Product, type ProductFeature, type ProductSpec } from '../api/productApi';
import { useApp } from '../components/AppProviders';
import { useCart } from '../context/CartContext';
import { formatEGP } from '../lib/formatCurrency';

/* ── Fallback catalogue ── */
const FALLBACK_CATALOG: Record<string, Product> = {
  'smart-assistive-glasses': {
    _id: 'fb-glasses', slug: 'smart-assistive-glasses', category: 'hardware', isFeatured: true, isConcept: false,
    title: { en: 'Smart Assistive Glasses', ar: 'النظارات الذكية المساعدة' },
    tagline: { en: 'AI-powered vision, voice and awareness', ar: 'رؤية وصوت ووعي بالذكاء الاصطناعي' },
    description: {
      en: 'Our flagship smart glasses combine a built-in camera with edge AI to deliver real-time sign language recognition, obstacle detection, currency and object identification, and spoken voice guidance — all processed on-device for speed and privacy.\n\nDesigned for deaf, non-verbal and blind users, the glasses seamlessly bridge the gap between the hearing and deaf worlds while providing unparalleled environmental awareness for the visually impaired.',
      ar: 'نظاراتنا الذكية الرائدة تجمع بين كاميرا مدمجة وذكاء اصطناعي محلي لتقديم التعرف الفوري على لغة الإشارة، واكتشاف العوائق، وتمييز العملات والأشياء، والتوجيه الصوتي — كل ذلك يُعالج محليًا للسرعة والخصوصية.'
    },
    features: [
      { icon: 'Eye', title: { en: 'Sign Language Recognition', ar: 'التعرف على لغة الإشارة' }, desc: { en: 'Real-time translation of sign language to speech using on-device AI.', ar: 'ترجمة فورية للغة الإشارة إلى كلام.' } },
      { icon: 'Shield', title: { en: 'Obstacle Detection', ar: 'اكتشاف العوائق' }, desc: { en: 'Ultrasonic sensors detect obstacles and warn the user with audio cues.', ar: 'مستشعرات فوق صوتية تكتشف العوائق.' } },
      { icon: 'Zap', title: { en: 'Currency Recognition', ar: 'تمييز العملات' }, desc: { en: 'Instantly identifies Egyptian banknotes and coins via camera.', ar: 'تمييز فوري للعملات المصرية عبر الكاميرا.' } },
      { icon: 'Wifi', title: { en: 'Voice Guidance', ar: 'التوجيه الصوتي' }, desc: { en: 'Spoken cues like "obstacle ahead" processed on-device for privacy.', ar: 'إشارات صوتية مثل «عائق أمامك» تُعالج محليًا.' } },
    ],
    specs: [
      { label: { en: 'Battery Life', ar: 'عمر البطارية' }, value: { en: 'Up to 8 hours active use', ar: 'حتى ٨ ساعات استخدام' } },
      { label: { en: 'Weight', ar: 'الوزن' }, value: { en: '52 g', ar: '٥٢ جرام' } },
      { label: { en: 'Connectivity', ar: 'الاتصال' }, value: { en: 'Bluetooth 5.3 + Wi-Fi 6', ar: 'بلوتوث ٥.٣ + واي فاي ٦' } },
      { label: { en: 'Processor', ar: 'المعالج' }, value: { en: 'Qualcomm AR2 Gen 1', ar: 'كوالكوم AR2 الجيل الأول' } },
      { label: { en: 'Camera', ar: 'الكاميرا' }, value: { en: '12 MP wide-angle', ar: '١٢ ميجابكسل زاوية واسعة' } },
      { label: { en: 'Warranty', ar: 'الضمان' }, value: { en: '2-year limited warranty', ar: 'ضمان محدود لسنتين' } },
    ],
    images: [{ src: '', alt: { en: 'Smart Glasses', ar: 'النظارات الذكية' } }],
    priceEGP: 12999, compareAtEGP: 15999, stock: 25, ratingAvg: 4.8, ratingCount: 42,
  },
  'smart-bracelet': {
    _id: 'fb-bracelet', slug: 'smart-bracelet', category: 'hardware', isFeatured: false, isConcept: false,
    title: { en: 'Smart Bracelet', ar: 'السوار الذكي' },
    tagline: { en: 'Safety and connection, on your wrist', ar: 'الأمان والاتصال على معصمك' },
    description: {
      en: 'The Ishara Smart Bracelet is your always-on safety companion. With a dedicated SOS button, haptic vibration alerts for deaf users, and real-time GPS location sharing to emergency contacts, it ensures help is always one touch away.\n\nWater-resistant and built for everyday wear, the bracelet pairs seamlessly with the Ishara mobile app and smart glasses.',
      ar: 'سوار إشارة الذكي هو رفيق السلامة الدائم. بزر استغاثة مخصص وتنبيهات اهتزازية لضعاف السمع ومشاركة موقع GPS المباشر مع جهات الطوارئ.'
    },
    features: [
      { icon: 'Shield', title: { en: 'SOS Emergency Button', ar: 'زر الاستغاثة' }, desc: { en: 'Press and hold to alert emergency contacts with your live location.', ar: 'اضغط مطولًا لتنبيه جهات الطوارئ مع موقعك.' } },
      { icon: 'Zap', title: { en: 'Haptic Alerts', ar: 'تنبيهات اهتزازية' }, desc: { en: 'Vibration patterns notify deaf users of important events.', ar: 'أنماط اهتزاز تنبه ضعاف السمع.' } },
      { icon: 'Wifi', title: { en: 'Live GPS Sharing', ar: 'مشاركة الموقع' }, desc: { en: 'Share real-time location with family and caregivers.', ar: 'مشاركة الموقع مع العائلة.' } },
      { icon: 'Battery', title: { en: 'Long Battery', ar: 'بطارية طويلة' }, desc: { en: 'Up to 5 days standby on a single charge.', ar: 'حتى ٥ أيام في الاستعداد.' } },
    ],
    specs: [
      { label: { en: 'Battery Life', ar: 'عمر البطارية' }, value: { en: 'Up to 5 days standby', ar: 'حتى ٥ أيام استعداد' } },
      { label: { en: 'Water Resistance', ar: 'مقاومة الماء' }, value: { en: 'IP67', ar: 'IP67' } },
      { label: { en: 'Weight', ar: 'الوزن' }, value: { en: '28 g', ar: '٢٨ جرام' } },
      { label: { en: 'Connectivity', ar: 'الاتصال' }, value: { en: 'Bluetooth 5.2 + GPS', ar: 'بلوتوث ٥.٢ + GPS' } },
      { label: { en: 'Warranty', ar: 'الضمان' }, value: { en: '2-year limited warranty', ar: 'ضمان محدود لسنتين' } },
    ],
    images: [{ src: '', alt: { en: 'Smart Bracelet', ar: 'السوار الذكي' } }],
    priceEGP: 2499, stock: 60, ratingAvg: 4.6, ratingCount: 28,
  },
  'ishara-mobile-app': {
    _id: 'fb-app', slug: 'ishara-mobile-app', category: 'digital', isFeatured: false, isConcept: false,
    title: { en: 'Ishara Mobile App', ar: 'تطبيق إشارة' },
    tagline: { en: 'Your pocket interpreter and learning hub', ar: 'مترجمك الشخصي ومركز التعلم' },
    description: {
      en: 'The Ishara mobile app brings real-time sign language translation, voice-to-text conversion, and a structured learning hub right to your smartphone. Available on iOS and Android.\n\nPair it with the smart glasses and bracelet for a complete assistive technology ecosystem, or use it standalone as a powerful communication bridge.',
      ar: 'تطبيق إشارة يوفر ترجمة فورية للغة الإشارة وتحويل الصوت إلى نص ومركز تعلم منظم. متاح على iOS وAndroid.'
    },
    features: [
      { icon: 'Hand', title: { en: 'Sign ↔ Speech Translation', ar: 'ترجمة إشارة ↔ كلام' }, desc: { en: 'Bi-directional translation between sign language and spoken word.', ar: 'ترجمة ثنائية الاتجاه.' } },
      { icon: 'Eye', title: { en: 'Voice to Text', ar: 'صوت إلى نص' }, desc: { en: 'Real-time speech transcription for deaf users.', ar: 'نسخ فوري للكلام لضعاف السمع.' } },
      { icon: 'Zap', title: { en: 'Learning Hub', ar: 'مركز التعلم' }, desc: { en: 'Structured sign language courses with progress tracking.', ar: 'دورات منظمة بتتبع التقدم.' } },
      { icon: 'Wifi', title: { en: 'Device Sync', ar: 'مزامنة الأجهزة' }, desc: { en: 'Seamless pairing with glasses and bracelet.', ar: 'ربط سلس مع النظارات والسوار.' } },
    ],
    specs: [
      { label: { en: 'Platforms', ar: 'المنصات' }, value: { en: 'iOS 15+ / Android 10+', ar: 'iOS 15+ / Android 10+' } },
      { label: { en: 'Size', ar: 'الحجم' }, value: { en: '~85 MB', ar: '~٨٥ ميجابايت' } },
      { label: { en: 'Languages', ar: 'اللغات' }, value: { en: 'Arabic & English', ar: 'العربية والإنجليزية' } },
      { label: { en: 'Price', ar: 'السعر' }, value: { en: 'Free', ar: 'مجاني' } },
    ],
    images: [{ src: '', alt: { en: 'Ishara App', ar: 'تطبيق إشارة' } }],
    priceEGP: 0, stock: 9999, ratingAvg: 4.9, ratingCount: 156,
  },
};

const ICON_MAP: Record<string, React.ElementType> = { Eye, Shield, Zap, Wifi, Battery, Hand };
const PRODUCT_EMOJI: Record<string, string> = {
  'smart-assistive-glasses': '🕶️',
  'smart-bracelet': '⌚',
  'ishara-mobile-app': '📱',
};

export default function ProductDetailPage() {
  const { slug = '' } = useParams();
  const { language } = useApp();
  const { add } = useCart();
  const [product, setProduct] = useState<Product | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [addedToCart, setAddedToCart] = useState(false);

  useEffect(() => {
    let cancelled = false;
    getProduct(slug)
      .then((p) => !cancelled && setProduct(p))
      .catch(() => {
        // Use fallback catalog
        const fb = FALLBACK_CATALOG[slug];
        if (fb && !cancelled) setProduct(fb);
        else if (!cancelled) setError('Product not found');
      });
    return () => { cancelled = true; };
  }, [slug]);

  const handleAdd = () => {
    if (!product) return;
    add(product, 1);
    setAddedToCart(true);
    setTimeout(() => setAddedToCart(false), 2000);
  };

  if (error) {
    return (
      <main className="min-h-screen pt-28 pb-20 container mx-auto px-6">
        <p role="alert" className="text-destructive text-lg">{error}</p>
        <Link to="/products" className="text-ishara-teal underline mt-4 inline-block">
          {language === 'ar' ? 'العودة إلى المنتجات' : '← Back to products'}
        </Link>
      </main>
    );
  }

  if (!product) {
    return (
      <main className="min-h-screen pt-28 pb-20 container mx-auto px-6">
        <div className="grid md:grid-cols-2 gap-10 animate-pulse">
          <div className="aspect-square rounded-2xl bg-muted" />
          <div className="space-y-4">
            <div className="h-8 w-2/3 bg-muted rounded" />
            <div className="h-4 w-full bg-muted rounded" />
            <div className="h-4 w-5/6 bg-muted rounded" />
            <div className="h-10 w-40 bg-muted rounded-full" />
          </div>
        </div>
      </main>
    );
  }

  const title = product.title[language] || product.title.en;
  const tagline = product.tagline[language] || product.tagline.en;
  const description = product.description[language] || product.description.en;
  const emoji = PRODUCT_EMOJI[product.slug] || '📦';

  return (
    <main id="main" className="min-h-screen pt-24 pb-20">
      <div className="container mx-auto px-6">
        <Link
          to="/products"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6"
        >
          <ChevronLeft className="w-4 h-4" />
          {language === 'ar' ? 'كل المنتجات' : 'All products'}
        </Link>

        {/* Hero grid */}
        <div className="grid md:grid-cols-2 gap-10 lg:gap-16">
          {/* Product visual */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="aspect-square rounded-3xl bg-gradient-to-br from-card to-muted flex items-center justify-center border border-border overflow-hidden"
          >
            <span className="text-[120px] md:text-[160px] select-none" role="img" aria-label={title}>
              {emoji}
            </span>
          </motion.div>

          {/* Product info */}
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="flex flex-col">
            {product.isFeatured && (
              <span className="self-start text-xs px-3 py-1 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white uppercase tracking-wider mb-4">
                {language === 'ar' ? 'المنتج الرئيسي' : 'Featured product'}
              </span>
            )}
            <h1 className="text-3xl md:text-5xl font-bold leading-tight">{title}</h1>
            <p className="text-lg text-muted-foreground mt-3">{tagline}</p>

            {product.ratingCount > 0 && (
              <div className="flex items-center gap-2 mt-4">
                <div className="flex">
                  {[1, 2, 3, 4, 5].map((s) => (
                    <Star key={s} className={`w-5 h-5 ${s <= Math.round(product.ratingAvg) ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'}`} />
                  ))}
                </div>
                <span className="font-medium">{product.ratingAvg.toFixed(1)}</span>
                <span className="text-sm text-muted-foreground">
                  ({product.ratingCount} {language === 'ar' ? 'تقييم' : 'reviews'})
                </span>
              </div>
            )}

            <p className="mt-6 leading-relaxed whitespace-pre-line">{description}</p>

            {/* Price & Add to Cart */}
            <div className="mt-8 p-6 rounded-2xl bg-card border border-border">
              <div className="flex items-baseline gap-3 mb-4">
                {product.priceEGP === 0 ? (
                  <span className="text-3xl font-bold text-ishara-teal">{language === 'ar' ? 'مجاني' : 'Free'}</span>
                ) : (
                  <>
                    <span className="text-3xl font-bold">{formatEGP(product.priceEGP)}</span>
                    {product.compareAtEGP && (
                      <span className="text-lg text-muted-foreground line-through">{formatEGP(product.compareAtEGP)}</span>
                    )}
                  </>
                )}
              </div>
              <motion.button
                onClick={handleAdd}
                disabled={addedToCart}
                className={`w-full py-3.5 rounded-xl font-semibold text-white transition-all ${
                  addedToCart
                    ? 'bg-emerald-500'
                    : 'bg-gradient-to-r from-[#14B8A6] to-[#F97316] hover:shadow-lg hover:shadow-teal-500/25'
                }`}
                whileHover={addedToCart ? {} : { scale: 1.02 }}
                whileTap={addedToCart ? {} : { scale: 0.98 }}
              >
                {addedToCart
                  ? (language === 'ar' ? 'تمت الإضافة ✓' : 'Added to Cart ✓')
                  : (language === 'ar' ? 'أضف للسلة' : 'Add to Cart')}
              </motion.button>
              {product.stock > 0 && product.stock < 50 && (
                <p className="text-xs text-muted-foreground mt-2 text-center">
                  {language === 'ar' ? `${product.stock} قطعة متبقية` : `Only ${product.stock} left in stock`}
                </p>
              )}
            </div>
          </motion.div>
        </div>

        {/* Features Grid */}
        {product.features.length > 0 && (
          <section className="mt-20">
            <h2 className="text-2xl font-bold mb-8">{language === 'ar' ? 'المميزات' : 'Key Features'}</h2>
            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {product.features.map((f: ProductFeature, i: number) => {
                const Icon = ICON_MAP[f.icon] || Zap;
                return (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.1 }}
                    className="p-6 rounded-2xl bg-card border border-border hover:border-ishara-teal/30 transition-colors"
                  >
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#14B8A6]/20 to-[#F97316]/10 flex items-center justify-center mb-4">
                      <Icon className="w-5 h-5 text-ishara-teal" />
                    </div>
                    <h3 className="font-semibold mb-2">{f.title[language] || f.title.en}</h3>
                    <p className="text-sm text-muted-foreground">{f.desc[language] || f.desc.en}</p>
                  </motion.div>
                );
              })}
            </div>
          </section>
        )}

        {/* Specs Table */}
        {product.specs.length > 0 && (
          <section className="mt-16">
            <h2 className="text-2xl font-bold mb-8">{language === 'ar' ? 'المواصفات' : 'Specifications'}</h2>
            <div className="rounded-2xl border border-border overflow-hidden">
              {product.specs.map((s: ProductSpec, i: number) => (
                <div key={i} className={`flex justify-between px-6 py-4 ${i % 2 === 0 ? 'bg-card' : 'bg-muted/30'}`}>
                  <span className="font-medium">{s.label[language] || s.label.en}</span>
                  <span className="text-muted-foreground">{s.value[language] || s.value.en}</span>
                </div>
              ))}
            </div>
          </section>
        )}
      </div>
    </main>
  );
}
