import { API_BASE } from './apiBase';

export type ChatRole = 'user' | 'assistant';
export interface ChatMessage {
  id: string;
  role: ChatRole;
  content: string;
  createdAt: number;
}

export interface StreamOptions {
  messages: { role: ChatRole; content: string }[];
  lang: 'en' | 'ar';
  onDelta: (chunk: string) => void;
  signal?: AbortSignal;
}

/* ── Rule-based FAQ (mirrors server/services/geminiService.js) ── */
const FAQ = [
  {
    keys: ['price', 'cost', 'how much', 'سعر', 'تكلفة', 'بكم', 'كام', 'buy', 'purchase', 'order', 'اشتري'],
    en: 'Smart Assistive Glasses: 12,999 EGP. Smart Bracelet: 2,499 EGP. Ishara mobile app: Free. Shipping in Egypt: 50 EGP.',
    ar: 'النظارات الذكية: ١٢٬٩٩٩ جنيه. السوار الذكي: ٢٬٤٩٩ جنيه. تطبيق إشارة: مجاني. الشحن داخل مصر: ٥٠ جنيهًا.',
  },
  {
    keys: ['blind', 'vision', 'see', 'obstacle', 'object', 'currency', 'مكفوف', 'كفيف', 'بصر', 'عوائق', 'عملة'],
    en: 'The glasses detect obstacles, read currency, identify objects, and speak voice cues like "obstacle ahead" — all processed on the device for speed and privacy.',
    ar: 'تكتشف النظارات العوائق وتقرأ العملات وتميز الأشياء، وتنطق إشارات صوتية مثل «عائق أمامك» — كل ذلك محليًا للسرعة والخصوصية.',
  },
  {
    keys: ['deaf', 'sign language', 'sign', 'hearing', 'translate', 'إشارة', 'لغة الإشارة', 'ضعيف السمع', 'أصم', 'ترجمة'],
    en: 'Ishara recognises sign language through the glasses\' camera and translates it to speech. The mobile app also translates spoken Arabic or English back into sign language.',
    ar: 'تتعرف إشارة على لغة الإشارة عبر كاميرا النظارات وتترجمها إلى كلام. ويقوم التطبيق بترجمة الكلام المسموع إلى لغة الإشارة العربية.',
  },
  {
    keys: ['sos', 'emergency', 'safety', 'alert', 'danger', 'استغاثة', 'طوارئ', 'مساعدة', 'أمان', 'خطر'],
    en: 'SOS & Safety: Tap the big red SOS button in the Safety section. A 5-second countdown starts — shake to cancel. It sends your live GPS location via WhatsApp, Telegram, SMS, and email to all your emergency contacts.',
    ar: 'اضغط زر الاستغاثة الكبير في قسم الأمان. يبدأ عداد ٥ ثوانٍ — هزّ الهاتف للإلغاء. يرسل موقعك المباشر عبر واتساب وتيليجرام ورسائل SMS وبريد إلكتروني.',
  },
  {
    keys: ['battery', 'charge', 'power', 'بطارية', 'شحن', 'طاقة'],
    en: 'Glasses: up to 8 hours of active use (USB-C charging). Bracelet: up to 5 days on standby.',
    ar: 'النظارات: حتى ٨ ساعات استخدام فعّال (شحن USB-C). السوار: حتى ٥ أيام في وضع الاستعداد.',
  },
  {
    keys: ['shipping', 'delivery', 'arrive', 'توصيل', 'وصول'],
    en: 'Flat 50 EGP shipping anywhere in Egypt. Typical delivery is 2–4 business days.',
    ar: 'الشحن ٥٠ جنيهًا ثابتًا داخل مصر. التوصيل خلال ٢–٤ أيام عمل.',
  },
  {
    keys: ['warranty', 'return', 'refund', 'repair', 'ضمان', 'إرجاع', 'استرداد'],
    en: 'Every hardware product ships with a 2-year limited warranty and a 14-day return policy. For repairs: support@ishara.app.',
    ar: 'كل منتج يأتي بضمان محدود لسنتين وسياسة إرجاع خلال ١٤ يومًا. للإصلاح: support@ishara.app.',
  },
  {
    keys: ['guide', 'navigate', 'how to use', 'tour', 'overview', 'walk me', 'show me', 'sections', 'website', 'explore', 'start', 'دليل', 'تصفح', 'كيف أستخدم', 'أقسام', 'نظرة'],
    en: `Here's a tour of the Ishara website:\n\n1. Hero — Welcome intro & mission overview\n2. About — Ishara's story and values\n3. Hardware — Smart Glasses & Bracelet specs\n4. Technology — How our AI & sensors work\n5. Safety — Interactive SOS emergency demo\n6. Learning — Sign language lessons & quizzes\n7. Shop — Buy glasses or bracelet\n8. Contact — Reach our team\n\nScroll down or click any section in the top navigation to jump there!`,
    ar: `إليك جولة في موقع إشارة:\n\n١. الرئيسية — مقدمة ورسالة إشارة\n٢. من نحن — قصة وقيم إشارة\n٣. الأجهزة — مواصفات النظارات والسوار\n٤. التقنية — كيف تعمل الذكاء الاصطناعي والمستشعرات\n٥. الأمان — محاكاة تفاعلية لنظام الاستغاثة\n٦. التعلم — دروس لغة الإشارة والاختبارات\n٧. المتجر — شراء النظارات أو السوار\n٨. اتصل بنا — تواصل مع الفريق\n\nمرر للأسفل أو انقر على أي قسم في شريط التنقل العلوي!`,
  },
  {
    keys: ['glasses', 'smart glasses', 'specs', 'specifications', 'processor', 'camera', 'نظارات', 'نظارة', 'كاميرا', 'مواصفات'],
    en: 'Smart Glasses specs:\n• 12 MP camera\n• Qualcomm AR2 processor\n• 8-hour battery (USB-C)\n• Sign language recognition\n• Obstacle detection (up to 2m)\n• Currency & object ID\n• Voice guidance\n• Price: 12,999 EGP',
    ar: 'مواصفات النظارات الذكية:\n• كاميرا ١٢ ميجابكسل\n• معالج Qualcomm AR2\n• بطارية ٨ ساعات (USB-C)\n• تعرف لغة الإشارة\n• اكتشاف عوائق (حتى مترين)\n• تمييز عملات وأشياء\n• توجيه صوتي\n• السعر: ١٢٬٩٩٩ جنيه',
  },
  {
    keys: ['bracelet', 'wrist', 'band', 'سوار', 'معصم'],
    en: 'Smart Bracelet:\n• SOS button with 5-second countdown\n• Haptic vibration alerts for deaf users\n• Live GPS location sharing\n• Water-resistant IP67\n• Up to 5 days battery\n• Price: 2,499 EGP',
    ar: 'السوار الذكي:\n• زر استغاثة مع عداد ٥ ثوانٍ\n• تنبيهات اهتزازية للصُّم\n• مشاركة GPS المباشر\n• مقاوم للماء IP67\n• بطارية تدوم حتى ٥ أيام\n• السعر: ٢٬٤٩٩ جنيه',
  },
  {
    keys: ['app', 'mobile', 'download', 'android', 'iphone', 'ios', 'تطبيق', 'تحميل', 'هاتف'],
    en: 'The Ishara app is FREE on iOS and Android. Features: sign-to-speech, speech-to-sign, vision assistance, SOS safety, learning hub, and accessibility settings. Search "Ishara" on App Store or Google Play.',
    ar: 'تطبيق إشارة مجاني على iOS وAndroid. يشمل: إشارة إلى كلام، كلام إلى إشارة، مساعدة بصرية، استغاثة، مركز تعلم، إعدادات وصولية. ابحث عن «إشارة» في App Store أو Google Play.',
  },
  {
    keys: ['learn', 'lesson', 'quiz', 'course', 'study', 'dictionary', 'تعلم', 'درس', 'اختبار', 'قاموس'],
    en: 'Learning Hub:\n• Arabic Sign Language (ArSL) lessons with video\n• Duolingo-style quizzes with XP rewards\n• Complete sign language dictionary\n• Progress tracking & daily streaks\n\nScroll to the Learning section on the website!',
    ar: 'مركز التعلم:\n• دروس لغة الإشارة العربية مع فيديو\n• اختبارات بأسلوب Duolingo مع مكافآت XP\n• قاموس إشارات كامل\n• تتبع التقدم وسلاسل يومية\n\nمرر إلى قسم التعلم في الموقع!',
  },
  {
    keys: ['shop', 'store', 'buy now', 'add to cart', 'متجر', 'شراء', 'اطلب'],
    en: 'Shop:\n• Smart Assistive Glasses — 12,999 EGP\n• Smart Safety Bracelet — 2,499 EGP\n• Shipping: 50 EGP, 2-4 business days in Egypt\n\nScroll to the Shop section or click "Shop" in the top navigation!',
    ar: 'المتجر:\n• النظارات الذكية — ١٢٬٩٩٩ جنيه\n• السوار الذكي — ٢٬٤٩٩ جنيه\n• الشحن: ٥٠ جنيهًا، ٢-٤ أيام عمل في مصر\n\nمرر إلى قسم المتجر أو انقر على «المتجر» في التنقل العلوي!',
  },
  {
    keys: ['contact', 'support', 'team', 'reach', 'email', 'اتصل', 'تواصل', 'دعم', 'فريق', 'بريد'],
    en: 'Contact our team:\n• Email: support@ishara.app\n• Or use the Contact form at the bottom of the website\n• Response time: within 24 hours',
    ar: 'تواصل مع الفريق:\n• البريد الإلكتروني: support@ishara.app\n• أو استخدم نموذج التواصل في أسفل الموقع\n• وقت الرد: خلال ٢٤ ساعة',
  },
  {
    keys: ['about', 'who', 'mission', 'story', 'company', 'what is ishara', 'من نحن', 'عن إشارة', 'رسالة'],
    en: 'Ishara is an Egyptian assistive-technology ecosystem for deaf, blind, and non-verbal users. Our name means "sign" or "gesture" in Arabic. We build smart hardware and software to empower independence and social inclusion.',
    ar: 'إشارة منظومة تقنيات مساعدة مصرية لضعاف السمع والمكفوفين وذوي النطق المحدود. اسمنا يعني الإشارة أو الإيماء. نبني أجهزة وبرامج ذكية لتمكين الاستقلالية والاندماج الاجتماعي.',
  },
  {
    keys: ['technology', 'how it works', 'ai', 'sensor', 'ultrasonic', 'tech', 'تقنية', 'كيف تعمل', 'ذكاء اصطناعي'],
    en: 'Ishara Technology:\n• Ultrasonic sensors detect obstacles up to 2 meters\n• On-device AI — works without internet\n• 12MP camera for real-time sign recognition\n• Dual haptic + audio feedback\n• All data processed locally for privacy',
    ar: 'تقنية إشارة:\n• مستشعرات فوق صوتية تكتشف العوائق حتى مترين\n• ذكاء اصطناعي محلي — يعمل بدون إنترنت\n• كاميرا ١٢ ميجابكسل للتعرف الفوري على الإشارة\n• تغذية راجعة مزدوجة: اهتزاز وصوت\n• جميع البيانات تُعالج محليًا للخصوصية',
  },
  {
    keys: ['accessibility', 'tts', 'contrast', 'dyslexia', 'large text', 'color blind', 'motor', 'إمكانية وصول', 'تباين', 'عسر قراءة'],
    en: 'Accessibility Settings:\n• Text-to-speech (TTS) narration\n• High contrast mode\n• Dyslexia-friendly font\n• Large text mode\n• Color-blind palettes\n• Motor accessibility support',
    ar: 'إعدادات إمكانية الوصول:\n• التحدث التلقائي (TTS)\n• وضع التباين العالي\n• خط صديق لعسر القراءة\n• وضع تكبير النص\n• ألوان مناسبة لعمى الألوان\n• دعم إمكانية الحركة',
  },
  {
    keys: ['hello', 'hi', 'hey', 'howdy', 'good morning', 'good evening', 'مرحب', 'أهلا', 'السلام', 'صباح', 'مساء', 'هلا'],
    en: 'Hello! 👋 I\'m the Ishara assistant. I can help you with:\n• Product info & pricing\n• Website navigation guide\n• Sign language & technology features\n• SOS & safety features\n• Ordering & support\n\nWhat would you like to know?',
    ar: 'أهلًا! 👋 أنا مساعد إشارة. يمكنني مساعدتك في:\n• معلومات المنتجات والأسعار\n• دليل تصفح الموقع\n• ميزات لغة الإشارة والتقنية\n• ميزات الأمان والاستغاثة\n• الطلب والدعم\n\nبماذا يمكنني مساعدتك؟',
  },
  {
    keys: ['thank', 'thanks', 'great', 'awesome', 'perfect', 'helpful', 'شكرا', 'ممتاز', 'رائع', 'مشكور'],
    en: 'You\'re welcome! 😊 Is there anything else I can help you with?',
    ar: 'على الرحب والسعة! 😊 هل هناك شيء آخر يمكنني مساعدتك فيه؟',
  },
];

function localFaqMatch(question: string, lang: string): string {
  const q = question.toLowerCase();
  for (const item of FAQ) {
    if (item.keys.some((k) => q.includes(k))) {
      return lang === 'ar' ? item.ar : item.en;
    }
  }
  return lang === 'ar'
    ? 'يسعدني مساعدتك! جرّب سؤالًا عن الأسعار، النظارات الذكية، السوار، لغة الإشارة، أو كيف تعمل تقنياتنا. يمكنك أيضًا التواصل معنا عبر قسم "اتصل بنا".'
    : 'I\'d love to help! Try asking about pricing, the smart glasses, bracelet, sign language translation, or how our technology works. You can also reach our team through the Contact section.';
}

/** Simulates streaming by yielding words with a delay */
async function localStreamFallback(text: string, onDelta: (chunk: string) => void, signal?: AbortSignal) {
  const words = text.split(' ');
  for (let i = 0; i < words.length; i++) {
    if (signal?.aborted) return;
    await new Promise((r) => setTimeout(r, 25 + Math.random() * 35));
    onDelta((i === 0 ? '' : ' ') + words[i]);
  }
}

// Streams chat — tries server first, falls back to local FAQ.
export async function streamChat({ messages, lang, onDelta, signal }: StreamOptions) {
  const lastMsg = messages[messages.length - 1]?.content || '';

  // Try server first
  try {
    const res = await fetch(`${API_BASE}/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages, lang }),
      signal,
    });

    if (res.ok && res.body) {
      const reader = res.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';

      for (;;) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const parts = buffer.split('\n\n');
        buffer = parts.pop() || '';
        for (const part of parts) {
          const line = part.trim();
          if (!line.startsWith('data:')) continue;
          const payload = line.slice(5).trim();
          if (payload === '[DONE]') return;
          try {
            const obj = JSON.parse(payload);
            if (obj.delta) onDelta(obj.delta as string);
          } catch { /* ignore */ }
        }
      }
      return; // Server stream completed
    }
  } catch {
    // Server unreachable — fall through to local
  }

  // Local FAQ fallback
  const answer = localFaqMatch(lastMsg, lang);
  await localStreamFallback(answer, onDelta, signal);
}
