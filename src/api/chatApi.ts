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
    keys: ['price', 'cost', 'how much', 'سعر', 'تكلفة', 'بكم', 'كام'],
    en: 'Smart Assistive Glasses: 12,999 EGP. Smart Bracelet: 2,499 EGP. Ishara mobile app: Free. Shipping in Egypt: 50 EGP.',
    ar: 'النظارات الذكية: ١٢٬٩٩٩ جنيه. السوار الذكي: ٢٬٤٩٩ جنيه. تطبيق إشارة: مجاني. الشحن داخل مصر: ٥٠ جنيهًا.',
  },
  {
    keys: ['blind', 'vision', 'see', 'obstacle', 'مكفوف', 'كفيف', 'بصر', 'عوائق'],
    en: 'The glasses detect obstacles, read currency, identify objects, and speak voice cues like "obstacle ahead" — all processed on the device for speed and privacy.',
    ar: 'تكتشف النظارات العوائق وتقرأ العملات وتميز الأشياء، وتنطق إشارات صوتية مثل «عائق أمامك» — كل ذلك محليًا للسرعة والخصوصية.',
  },
  {
    keys: ['deaf', 'sign', 'hearing', 'translate', 'إشارة', 'لغة الإشارة', 'ضعيف السمع', 'أصم', 'ترجمة'],
    en: 'Ishara recognises sign language through the glasses\' camera and translates it to speech. The mobile app also translates spoken Arabic or English back into sign language.',
    ar: 'تتعرف إشارة على لغة الإشارة عبر كاميرا النظارات وتترجمها إلى كلام. ويقوم التطبيق بترجمة الكلام المسموع إلى لغة الإشارة.',
  },
  {
    keys: ['sos', 'emergency', 'help', 'safety', 'استغاثة', 'طوارئ', 'مساعدة'],
    en: 'Press and hold the bracelet\'s SOS button to alert your emergency contacts with your live location. The glasses can also trigger an SOS by voice command.',
    ar: 'اضغط مطولًا على زر الاستغاثة بالسوار لتنبيه جهات الاتصال مع موقعك المباشر. كما يمكن تفعيل الاستغاثة بالنظارات بأمر صوتي.',
  },
  {
    keys: ['battery', 'charge', 'بطارية', 'شحن'],
    en: 'Glasses: up to 8 hours of active use. Bracelet: up to 5 days on standby.',
    ar: 'النظارات: حتى ٨ ساعات استخدام فعّال. السوار: حتى ٥ أيام في وضع الاستعداد.',
  },
  {
    keys: ['shipping', 'delivery', 'شحن', 'توصيل'],
    en: 'Flat 50 EGP shipping anywhere in Egypt. Typical delivery is 2–4 business days.',
    ar: 'الشحن ٥٠ جنيهًا داخل مصر. عادةً يصل خلال ٢–٤ أيام عمل.',
  },
  {
    keys: ['warranty', 'return', 'ضمان', 'إرجاع'],
    en: 'Every hardware product ships with a 2-year limited warranty and a 14-day return policy.',
    ar: 'كل منتج يأتي بضمان محدود لمدة سنتين وسياسة إرجاع خلال ١٤ يومًا.',
  },
  {
    keys: ['app', 'mobile', 'download', 'تطبيق', 'تحميل', 'هاتف'],
    en: 'The Ishara mobile app is free on iOS and Android. It includes sign ↔ speech translation, voice-to-text, and a structured learning hub.',
    ar: 'تطبيق إشارة مجاني على iOS وAndroid. يشمل ترجمة إشارة ↔ كلام، صوت إلى نص، ومركز تعلم منظم.',
  },
  {
    keys: ['bracelet', 'wrist', 'سوار', 'معصم'],
    en: 'The Smart Bracelet features an SOS button, haptic vibration alerts for deaf users, and real-time GPS sharing with emergency contacts. It\'s water-resistant (IP67) and lasts up to 5 days.',
    ar: 'السوار الذكي يتميز بزر استغاثة وتنبيهات اهتزازية ومشاركة موقع GPS. مقاوم للماء (IP67) ويدوم حتى ٥ أيام.',
  },
  {
    keys: ['glasses', 'camera', 'نظارات', 'كاميرا'],
    en: 'The Smart Assistive Glasses have a 12MP camera, Qualcomm AR2 processor, and 8-hour battery. They provide sign language recognition, obstacle detection, currency ID, and voice guidance.',
    ar: 'النظارات الذكية بكاميرا ١٢ ميجابكسل ومعالج Qualcomm AR2 وبطارية ٨ ساعات. تقدم التعرف على الإشارة واكتشاف العوائق وتمييز العملات.',
  },
  {
    keys: ['hello', 'hi', 'hey', 'مرحبا', 'أهلا', 'السلام'],
    en: 'Hello! 👋 I\'m the Ishara assistant. I can help you with information about our smart glasses, bracelet, mobile app, pricing, and accessibility features. What would you like to know?',
    ar: 'أهلًا! 👋 أنا مساعد إشارة. يمكنني مساعدتك بمعلومات عن النظارات الذكية والسوار والتطبيق والأسعار. ماذا تريد أن تعرف؟',
  },
  {
    keys: ['who', 'what is ishara', 'about', 'ما هي', 'من أنت', 'عن إشارة'],
    en: 'Ishara is an assistive technology ecosystem designed for deaf, non-verbal, and blind users. Our products include Smart Assistive Glasses, a Smart Safety Bracelet, and a free mobile app — all working together to empower independence.',
    ar: 'إشارة هي منظومة تقنيات مساعدة لضعاف السمع والمكفوفين. منتجاتنا تشمل النظارات الذكية والسوار الذكي وتطبيق مجاني — جميعها تعمل معًا لتمكين الاستقلالية.',
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
    const res = await fetch('/api/chat', {
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
