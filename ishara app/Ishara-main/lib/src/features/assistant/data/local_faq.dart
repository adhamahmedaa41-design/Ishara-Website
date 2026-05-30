/// Bilingual rule-based FAQ matcher — local fallback when the chatbot
/// backend is unreachable. The assistant tries `/api/chatbot/ask` first
/// and only falls back here on failure.
library;

class _FaqEntry {
  const _FaqEntry({required this.keys, required this.en, required this.ar});
  final List<String> keys;
  final String en;
  final String ar;
}

const List<_FaqEntry> _faq = [
  // ── Greetings ─────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: ['hello', 'hi', 'hey', 'howdy', 'greetings', 'good morning',
        'good evening', 'good afternoon', 'sup', 'yo',
        'مرحبا', 'أهلا', 'السلام', 'صباح', 'مساء', 'هلا', 'هاي'],
    en: 'Hello! 👋 I\'m the Ishara assistant. I can help you with:\n'
        '• Smart glasses features & pricing\n'
        '• Sign language translation\n'
        '• Emergency SOS setup\n'
        '• Vision & object detection\n'
        '• Learning hub & lessons\n'
        'What would you like to know?',
    ar: 'أهلًا! 👋 أنا مساعد إشارة. يمكنني مساعدتك في:\n'
        '• ميزات وأسعار النظارات الذكية\n'
        '• ترجمة لغة الإشارة\n'
        '• إعداد زر الاستغاثة\n'
        '• الرؤية واكتشاف الكائنات\n'
        '• مركز التعلم والدروس\n'
        'بماذا تريد أن تعرف؟',
  ),

  // ── Identity / About ───────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'who are you', 'what are you', 'what is ishara', 'about ishara',
      'about you', 'tell me about', 'introduce yourself', 'your name',
      'من أنت', 'ما هي إشارة', 'عن إشارة', 'ما اسمك', 'عرّف',
    ],
    en: 'I\'m the Ishara AI assistant. 🤖\n\n'
        'Ishara is an Egyptian assistive-technology ecosystem designed for:\n'
        '• Deaf & hard-of-hearing users — sign ↔ speech translation\n'
        '• Blind & low-vision users — obstacle detection, object ID, currency reading\n'
        '• Non-verbal users — text-to-speech & communication tools\n\n'
        'Products: Smart Assistive Glasses + free mobile app, working together.',
    ar: 'أنا مساعد إشارة الذكي. 🤖\n\n'
        'إشارة منظومة تقنيات مساعدة مصرية مصمَّمة لـ:\n'
        '• الصُّم وضعاف السمع — ترجمة الإشارة ↔ الكلام\n'
        '• المكفوفين وضعاف البصر — اكتشاف العوائق وتمييز الأشياء وقراءة العملات\n'
        '• غير الناطقين — تحويل النص إلى كلام وأدوات التواصل\n\n'
        'المنتجات: النظارات الذكية + تطبيق مجاني، يعملان معًا.',
  ),

  // ── Pricing ────────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'price', 'cost', 'how much', 'pricing', 'expensive', 'cheap', 'afford',
      'buy', 'purchase', 'order', 'payment', 'pay', 'fee', 'charge',
      'سعر', 'تكلفة', 'بكم', 'كام', 'اشتري', 'طلب', 'دفع', 'رسوم',
    ],
    en: '💰 Ishara Pricing:\n\n'
        '• Smart Assistive Glasses: **12,999 EGP**\n'
        '• Smart Bracelet: **2,499 EGP**\n'
        '• Ishara mobile app: **Free** (iOS & Android)\n'
        '• Shipping within Egypt: **50 EGP**\n\n'
        'Visit the Shop tab to place your order. [open:shop]',
    ar: '💰 أسعار إشارة:\n\n'
        '• النظارات الذكية: **١٢٬٩٩٩ جنيه**\n'
        '• السوار الذكي: **٢٬٤٩٩ جنيه**\n'
        '• تطبيق إشارة: **مجاني** (iOS وAndroid)\n'
        '• الشحن داخل مصر: **٥٠ جنيهًا**\n\n'
        'اذهب إلى تبويب المتجر لإتمام طلبك. [open:shop]',
  ),

  // ── Glasses / Hardware ─────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'glasses', 'smart glasses', 'hardware', 'specs', 'specification',
      'camera', 'processor', 'esp32', 'device', 'gadget', 'wearable',
      'نظارات', 'نظارة', 'جهاز', 'كاميرا', 'معالج', 'مواصفات',
    ],
    en: '🥽 Smart Assistive Glasses specs:\n\n'
        '• Camera: 12 MP\n'
        '• Processor: Qualcomm AR2\n'
        '• Battery: up to 8 hours active use\n'
        '• Features: sign language recognition, obstacle detection, '
        'currency ID, object naming, voice guidance\n'
        '• Connectivity: Bluetooth & Wi-Fi\n'
        '• Pair via the Hardware Pairing screen in settings.',
    ar: '🥽 مواصفات النظارات الذكية:\n\n'
        '• الكاميرا: ١٢ ميجابكسل\n'
        '• المعالج: Qualcomm AR2\n'
        '• البطارية: تصل إلى ٨ ساعات استخدام فعّال\n'
        '• الميزات: التعرف على الإشارة، اكتشاف العوائق، تمييز العملات، '
        'تسمية الأشياء، التوجيه الصوتي\n'
        '• الاتصال: بلوتوث وواي فاي\n'
        '• اربطها عبر شاشة إعداد الأجهزة في الإعدادات.',
  ),

  // ── Blind / Vision features ────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'blind', 'vision', 'obstacle', 'object', 'detect', 'identify',
      'currency', 'money', 'banknote', 'navigate', 'read text', 'ocr',
      'مكفوف', 'كفيف', 'بصر', 'عوائق', 'كائنات', 'عملة', 'فلوس', 'نقود',
      'نص', 'قراءة',
    ],
    en: '👁️ Vision features:\n\n'
        '• **Obstacle detection** — voice alert "obstacle ahead"\n'
        '• **Currency ID** — count Egyptian Pounds and piasters in real time\n'
        '• **Object naming** — identify everyday items with TTS\n'
        '• **OCR** — read printed text in Arabic and English\n\n'
        'All processed on-device for speed and privacy. [open:vision]',
    ar: '👁️ ميزات الرؤية:\n\n'
        '• **اكتشاف العوائق** — تنبيه صوتي «عائق أمامك»\n'
        '• **تمييز العملات** — عدّ الجنيه المصري والقروش لحظيًا\n'
        '• **تسمية الأشياء** — تحديد الأشياء اليومية بنطق صوتي\n'
        '• **OCR** — قراءة النص المطبوع بالعربية والإنجليزية\n\n'
        'كل المعالجة تتم محليًا للسرعة والخصوصية. [open:vision]',
  ),

  // ── Deaf / Sign language ───────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'deaf', 'sign', 'hearing', 'translate', 'sign language', 'asl', 'arsl',
      'arabic sign', 'speech to sign', 'sign to speech', 'interpretation',
      'إشارة', 'لغة الإشارة', 'ضعيف السمع', 'أصم', 'ترجمة', 'تفسير',
    ],
    en: '🤟 Sign Language features:\n\n'
        '• **Glasses camera** recognizes your signs and converts them to speech\n'
        '• **Mobile app** translates spoken Arabic/English back to sign clips\n'
        '• Supports Arabic Sign Language (ArSL)\n'
        '• Real-time translation with on-device AI\n\n'
        'Open the Translator tab to start. [open:translator]',
    ar: '🤟 ميزات لغة الإشارة:\n\n'
        '• **كاميرا النظارات** تتعرف على إشاراتك وتحولها إلى كلام\n'
        '• **التطبيق** يترجم الكلام المسموع (عربي/إنجليزي) إلى مقاطع إشارة\n'
        '• يدعم لغة الإشارة العربية (ArSL)\n'
        '• ترجمة فورية بالذكاء الاصطناعي على الجهاز\n\n'
        'افتح تبويب المترجم للبدء. [open:translator]',
  ),

  // ── SOS / Safety ──────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'sos', 'emergency', 'help', 'safety', 'alert', 'danger', 'accident',
      'urgent', 'distress', 'panic', 'send location', 'live location',
      'استغاثة', 'طوارئ', 'مساعدة', 'أمان', 'خطر', 'حادث', 'عاجل', 'موقع',
    ],
    en: '🆘 SOS & Safety:\n\n'
        '• Tap the big **red SOS button** in the Safety tab\n'
        '• A 5-second countdown starts — shake to cancel\n'
        '• Instantly sends your live location via email, WhatsApp, Telegram, or SMS to all emergency contacts\n'
        '• Add contacts in the Contacts screen\n\n'
        'Open Safety tab now → [open:safety]',
    ar: '🆘 الاستغاثة والأمان:\n\n'
        '• اضغط **زر الاستغاثة الأحمر الكبير** في تبويب الأمان\n'
        '• يبدأ عداد تنازلي ٥ ثوانٍ — هزّ الهاتف للإلغاء\n'
        '• يرسل فورًا موقعك المباشر عبر بريد إلكتروني وواتساب وتيليجرام ورسائل SMS لكل جهات الطوارئ\n'
        '• أضف جهات الاتصال في شاشة جهات الاتصال\n\n'
        'افتح تبويب الأمان الآن ← [open:safety]',
  ),

  // ── Emergency contacts ─────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'contact', 'add contact', 'emergency contact', 'remove contact',
      'edit contact', 'phone number',
      'جهة اتصال', 'إضافة', 'حذف جهة', 'رقم هاتف',
    ],
    en: '📞 Emergency Contacts:\n\n'
        '• Go to **Profile → Emergency Contacts** (or Safety → Contacts)\n'
        '• Add name, phone (with country code), relationship, and preferred channel\n'
        '• Channels: WhatsApp, Telegram, SMS, or All\n'
        '• Add multiple contacts for redundancy\n\n'
        'Open Contacts now → [open:profile/contacts]',
    ar: '📞 جهات الطوارئ:\n\n'
        '• اذهب إلى **الملف الشخصي ← جهات الطوارئ** (أو الأمان ← جهات الاتصال)\n'
        '• أضف الاسم والهاتف (مع رمز الدولة) والعلاقة والقناة المفضلة\n'
        '• القنوات: واتساب، تيليجرام، SMS، أو الكل\n'
        '• أضف عدة جهات اتصال للأمان\n\n'
        'افتح جهات الاتصال الآن ← [open:profile/contacts]',
  ),

  // ── Battery ────────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: ['battery', 'charge', 'charging', 'power', 'last', 'run out',
        'بطارية', 'شحن', 'طاقة'],
    en: '🔋 Battery life:\n\n'
        '• Smart Glasses: up to **8 hours** of active use per charge\n'
        '• Charging: via USB-C cable (included)\n'
        '• Tip: enable sleep mode when not actively using glasses to extend battery',
    ar: '🔋 عمر البطارية:\n\n'
        '• النظارات الذكية: حتى **٨ ساعات** استخدام فعّال بالشحنة الواحدة\n'
        '• الشحن: عبر كابل USB-C (مرفق)\n'
        '• نصيحة: فعّل وضع السكون عند عدم الاستخدام لإطالة عمر البطارية',
  ),

  // ── Shipping / Delivery ────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'shipping', 'delivery', 'ship', 'deliver', 'arrive', 'days',
      'outside egypt', 'international', 'courier',
      'توصيل', 'شحن', 'وصول', 'أيام', 'خارج مصر', 'دولي',
    ],
    en: '📦 Shipping:\n\n'
        '• Flat **50 EGP** anywhere in Egypt\n'
        '• Delivery in **2–4 business days**\n'
        '• International shipping: contact us at support@ishara.app\n'
        '• Track your order in the **Orders** section of the Shop tab [open:shop]',
    ar: '📦 الشحن:\n\n'
        '• **٥٠ جنيهًا** ثابتًا في أي مكان داخل مصر\n'
        '• التوصيل خلال **٢–٤ أيام عمل**\n'
        '• الشحن الدولي: تواصل معنا على support@ishara.app\n'
        '• تتبع طلبك في قسم **الطلبات** في تبويب المتجر [open:shop]',
  ),

  // ── Warranty / Return ──────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'warranty', 'return', 'refund', 'broken', 'defective', 'repair',
      'exchange', 'replace', 'guarantee',
      'ضمان', 'إرجاع', 'استرداد', 'تالف', 'إصلاح', 'استبدال',
    ],
    en: '🛡️ Warranty & Returns:\n\n'
        '• **2-year limited warranty** on all hardware\n'
        '• **14-day return policy** (unused, original packaging)\n'
        '• For repairs or replacements, email: support@ishara.app\n'
        '• The warranty covers manufacturing defects, not physical damage',
    ar: '🛡️ الضمان والإرجاع:\n\n'
        '• **ضمان محدود لسنتين** على جميع الأجهزة\n'
        '• **سياسة الإرجاع خلال ١٤ يومًا** (غير مستخدم، التغليف الأصلي)\n'
        '• للإصلاح أو الاستبدال: راسلنا على support@ishara.app\n'
        '• يشمل الضمان عيوب التصنيع، لا الأضرار المادية',
  ),

  // ── App / Mobile ───────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'app', 'mobile', 'download', 'install', 'ios', 'android', 'phone',
      'iphone', 'play store', 'app store', 'apk', 'update',
      'تطبيق', 'تحميل', 'هاتف', 'تثبيت', 'جوال', 'تحديث',
    ],
    en: '📱 Ishara Mobile App:\n\n'
        '• **Free** on iOS and Android\n'
        '• Features: sign ↔ speech, voice-to-text, currency detection, learning hub, SOS\n'
        '• Search "Ishara" on the App Store or Google Play\n'
        '• Keep the app updated for the latest AI models and features',
    ar: '📱 تطبيق إشارة:\n\n'
        '• **مجاني** على iOS وAndroid\n'
        '• الميزات: ترجمة الإشارة ↔ الكلام، صوت إلى نص، اكتشاف العملات، مركز التعلم، الاستغاثة\n'
        '• ابحث عن «إشارة» في App Store أو Google Play\n'
        '• احرص على تحديث التطبيق للحصول على أحدث نماذج الذكاء الاصطناعي',
  ),

  // ── Learning ───────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'learn', 'lesson', 'quiz', 'course', 'study', 'practice', 'beginner',
      'alphabet', 'dictionary', 'xp', 'progress', 'level',
      'تعلم', 'درس', 'اختبار', 'دورة', 'مبتدئ', 'أبجدية', 'قاموس', 'مستوى',
    ],
    en: '📚 Learning Hub:\n\n'
        '• Structured Arabic Sign Language lessons with video clips\n'
        '• Duolingo-style quizzes to earn XP\n'
        '• A full sign dictionary — tap any word to see its sign\n'
        '• Track your streak and progress\n\n'
        'Open the Learning tab → [open:learning]',
    ar: '📚 مركز التعلم:\n\n'
        '• دروس منظمة في لغة الإشارة العربية مع مقاطع فيديو\n'
        '• اختبارات بأسلوب Duolingo لكسب نقاط XP\n'
        '• قاموس إشارات كامل — اضغط على أي كلمة لتشاهد إشارتها\n'
        '• تتبع تسلسلك وتقدمك\n\n'
        'افتح تبويب التعلم ← [open:learning]',
  ),

  // ── Accessibility settings ─────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'accessibility', 'tts', 'text to speech', 'high contrast', 'font',
      'dyslexia', 'large text', 'color blind', 'motor', 'auto speak',
      'إمكانية الوصول', 'تحدث', 'نص إلى كلام', 'تباين', 'خط', 'عمى الألوان',
    ],
    en: '⚙️ Accessibility Settings:\n\n'
        '• **Auto-TTS** — reads all responses aloud automatically\n'
        '• **High contrast** mode for low-vision users\n'
        '• **Dyslexia font** (OpenDyslexic)\n'
        '• **Large text** scaling\n'
        '• **Color-blind palettes** (deuteranopia, protanopia, tritanopia)\n'
        '• **Motor mode** — larger tap targets\n\n'
        'Open Accessibility Settings → [open:profile/accessibility]',
    ar: '⚙️ إعدادات إمكانية الوصول:\n\n'
        '• **التحدث التلقائي** — يقرأ جميع الردود بصوت عالٍ\n'
        '• وضع **التباين العالي** لضعاف البصر\n'
        '• خط **عسر القراءة** (OpenDyslexic)\n'
        '• **تكبير النص**\n'
        '• **ألوان عمى الألوان** (دوتيرانوبيا، بروتانوبيا، تريتانوبيا)\n'
        '• **وضع الحركة** — أهداف ضغط أكبر\n\n'
        'افتح إعدادات إمكانية الوصول ← [open:profile/accessibility]',
  ),

  // ── Hardware pairing ───────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'pair', 'pairing', 'connect', 'bluetooth', 'wifi', 'setup',
      'configure', 'link', 'sync', 'connection',
      'إقران', 'توصيل', 'بلوتوث', 'واي فاي', 'إعداد', 'ربط',
    ],
    en: '🔗 Hardware Pairing:\n\n'
        '• Make sure the glasses are charged and powered on\n'
        '• Go to **Profile → Pair Hardware** (or press the Bluetooth icon)\n'
        '• Keep glasses within 1 metre during initial pairing\n'
        '• Once paired, the app syncs settings automatically\n\n'
        'Open Pairing screen → tap "Pair Hardware" in Profile',
    ar: '🔗 إقران الأجهزة:\n\n'
        '• تأكد من شحن النظارات وتشغيلها\n'
        '• اذهب إلى **الملف الشخصي ← إقران الأجهزة** (أو اضغط أيقونة البلوتوث)\n'
        '• احتفظ بالنظارات على بُعد متر واحد أثناء الإقران الأولي\n'
        '• بمجرد الإقران، يزامن التطبيق الإعدادات تلقائيًا',
  ),

  // ── Shop / Cart / Orders ───────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'shop', 'store', 'cart', 'order', 'checkout', 'add to cart',
      'wish list', 'browse', 'product',
      'متجر', 'سلة', 'طلب', 'منتج', 'تسوق', 'عربة',
    ],
    en: '🛒 Shop:\n\n'
        '• Browse Smart Glasses, Bracelets, and accessories\n'
        '• Add items to your cart and checkout securely\n'
        '• Track orders after purchase\n'
        '• Accepts credit/debit cards and cash on delivery\n\n'
        'Open Shop → [open:shop]',
    ar: '🛒 المتجر:\n\n'
        '• تصفح النظارات الذكية والأساور والإكسسوارات\n'
        '• أضف عناصر إلى سلتك وأتمم الشراء بأمان\n'
        '• تتبع طلباتك بعد الشراء\n'
        '• يقبل بطاقات الائتمان والدفع عند الاستلام\n\n'
        'افتح المتجر ← [open:shop]',
  ),

  // ── Profile / Account ──────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'profile', 'account', 'name', 'email', 'password', 'change', 'update',
      'photo', 'avatar', 'picture', 'login', 'logout', 'sign in', 'sign up',
      'ملف شخصي', 'حساب', 'اسم', 'بريد', 'كلمة مرور', 'صورة', 'تحديث',
    ],
    en: '👤 Profile & Account:\n\n'
        '• Tap the **Profile** tab to view/edit your info\n'
        '• Update your name, disability type, and profile picture\n'
        '• Change theme (light/dark/system) and language\n'
        '• Tap "Edit" on your profile card to make changes\n'
        '• Profile picture uploads require an internet connection',
    ar: '👤 الملف الشخصي والحساب:\n\n'
        '• اضغط تبويب **الملف الشخصي** لعرض معلوماتك أو تعديلها\n'
        '• حدّث اسمك ونوع الإعاقة وصورة الملف الشخصي\n'
        '• غيّر المظهر (فاتح/داكن/النظام) واللغة\n'
        '• اضغط «تعديل» على بطاقة ملفك الشخصي لإجراء التغييرات\n'
        '• رفع صورة الملف الشخصي يتطلب اتصالًا بالإنترنت',
  ),

  // ── Translator ─────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'translator', 'translation', 'convert', 'speak', 'voice', 'text',
      'مترجم', 'ترجمة', 'تحويل', 'كلام', 'نص',
    ],
    en: '🔄 Translator:\n\n'
        '• **Sign → Speech**: point the camera at someone signing — gets converted to spoken Arabic/English\n'
        '• **Speech → Sign**: speak or type text — plays the corresponding sign language clip\n'
        '• All processing is on-device for real-time results\n\n'
        'Open Translator → [open:translator]',
    ar: '🔄 المترجم:\n\n'
        '• **إشارة ← كلام**: صوّب الكاميرا على شخص يؤدي الإشارات — تُحوَّل إلى كلام عربي/إنجليزي\n'
        '• **كلام ← إشارة**: تحدث أو اكتب نصًا — يعرض مقطع لغة الإشارة المقابل\n'
        '• جميع المعالجة على الجهاز للحصول على نتائج فورية\n\n'
        'افتح المترجم ← [open:translator]',
  ),

  // ── Privacy / Data ─────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'privacy', 'data', 'security', 'safe', 'store', 'personal', 'gdpr',
      'خصوصية', 'بيانات', 'أمان', 'شخصي', 'تخزين',
    ],
    en: '🔒 Privacy & Data:\n\n'
        '• Vision and sign-language processing happens **on-device** — no video is sent to servers\n'
        '• Location is only shared when you trigger SOS\n'
        '• Account data is secured with JWT authentication\n'
        '• We never sell your personal data\n'
        '• Review our privacy policy at ishara.app/privacy',
    ar: '🔒 الخصوصية والبيانات:\n\n'
        '• تتم معالجة الرؤية ولغة الإشارة **على الجهاز** — لا تُرسَل أي مقاطع فيديو إلى الخوادم\n'
        '• يُشارَك الموقع فقط عند تفعيل الاستغاثة\n'
        '• بيانات الحساب مؤمَّنة بمصادقة JWT\n'
        '• لا نبيع بياناتك الشخصية إطلاقًا\n'
        '• راجع سياسة الخصوصية على ishara.app/privacy',
  ),

  // ── Troubleshooting ────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'not working', 'broken', 'error', 'problem', 'issue', 'bug', 'crash',
      'fix', 'help me', 'support', 'contact support', 'stuck', 'freeze',
      'لا يعمل', 'خطأ', 'مشكلة', 'عطل', 'إصلاح', 'دعم', 'مساعدة',
    ],
    en: '🛠️ Troubleshooting:\n\n'
        '• **App crash**: force-close and reopen, then update to latest version\n'
        '• **Glasses not pairing**: restart glasses, re-enter Bluetooth range, try re-pairing\n'
        '• **SOS not sending**: check internet/cellular connection and ensure contacts are saved\n'
        '• **Translation inaccurate**: ensure good lighting and clear signing\n'
        '• **Still stuck?** Email us: support@ishara.app',
    ar: '🛠️ استكشاف الأخطاء:\n\n'
        '• **التطبيق يتعطل**: أغلقه بالقوة وأعد فتحه، ثم حدّثه إلى أحدث إصدار\n'
        '• **النظارات لا تقترن**: أعد تشغيل النظارات، وادخل نطاق البلوتوث، وحاول الإقران مجددًا\n'
        '• **الاستغاثة لا ترسل**: تحقق من اتصال الإنترنت أو الشبكة المحمولة وتأكد من حفظ جهات الاتصال\n'
        '• **الترجمة غير دقيقة**: تأكد من الإضاءة الجيدة وإشارات واضحة\n'
        '• **لا تزال عالقًا؟** راسلنا: support@ishara.app',
  ),

  // ── Navigation guide ───────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'navigate', 'guide me', 'how to use', 'tutorial', 'where is', 'find',
      'screen', 'tab', 'menu', 'feature',
      'كيف', 'دليل', 'أين', 'ابحث', 'شاشة', 'تبويب', 'قائمة',
    ],
    en: '🗺️ App Navigation:\n\n'
        '• **🏠 Home** — Dashboard with quick actions\n'
        '• **🤟 Translator** — Sign ↔ Speech translation [open:translator]\n'
        '• **👁️ Vision** — Object detection, OCR, currency [open:vision]\n'
        '• **🆘 Safety** — SOS button & emergency contacts [open:safety]\n'
        '• **📚 Learning** — Lessons, quizzes, dictionary [open:learning]\n'
        '• **🛒 Shop** — Buy hardware [open:shop]\n'
        '• **👤 Profile** — Settings, accessibility, account',
    ar: '🗺️ التنقل في التطبيق:\n\n'
        '• **🏠 الرئيسية** — لوحة التحكم مع الإجراءات السريعة\n'
        '• **🤟 المترجم** — ترجمة الإشارة ↔ الكلام [open:translator]\n'
        '• **👁️ الرؤية** — اكتشاف الأشياء، OCR، العملات [open:vision]\n'
        '• **🆘 الأمان** — زر الاستغاثة وجهات الطوارئ [open:safety]\n'
        '• **📚 التعلم** — دروس، اختبارات، قاموس [open:learning]\n'
        '• **🛒 المتجر** — شراء الأجهزة [open:shop]\n'
        '• **👤 الملف الشخصي** — الإعدادات وإمكانية الوصول والحساب',
  ),

  // ── Contact / Support ──────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'contact us', 'email', 'support', 'reach', 'talk to', 'human', 'agent',
      'اتصل', 'بريد إلكتروني', 'دعم', 'تواصل',
    ],
    en: '📬 Contact & Support:\n\n'
        '• Email: **support@ishara.app**\n'
        '• Website: **ishara.app**\n'
        '• For order issues, include your order number\n'
        '• Response time: within 24 hours (business days)',
    ar: '📬 التواصل والدعم:\n\n'
        '• البريد: **support@ishara.app**\n'
        '• الموقع: **ishara.app**\n'
        '• لمشاكل الطلبات، أرفق رقم طلبك\n'
        '• وقت الرد: خلال ٢٤ ساعة (أيام العمل)',
  ),

  // ── Non-verbal / Speech ────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'non-verbal', 'nonverbal', 'mute', 'can\'t speak', 'speech', 'tts',
      'communicate', 'text to speech', 'speak for me',
      'غير ناطق', 'لا يستطيع الكلام', 'أخرس', 'تواصل',
    ],
    en: '🗣️ For non-verbal users:\n\n'
        '• Type text in the Translator → the app speaks it aloud for you\n'
        '• Use pre-saved phrases for quick communication\n'
        '• Enable Auto-TTS in Accessibility Settings for hands-free use\n'
        '• The glasses can also announce detected objects via voice [open:profile/accessibility]',
    ar: '🗣️ لغير الناطقين:\n\n'
        '• اكتب نصًا في المترجم ← ينطق التطبيق بصوت عالٍ نيابةً عنك\n'
        '• استخدم العبارات المحفوظة مسبقًا للتواصل السريع\n'
        '• فعّل التحدث التلقائي في إعدادات إمكانية الوصول للاستخدام الحر [open:profile/accessibility]',
  ),

  // ── Thank you / Positive ───────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'thank', 'thanks', 'great', 'awesome', 'perfect', 'good', 'nice',
      'helpful', 'love it', 'amazing', 'cool',
      'شكرا', 'ممتاز', 'رائع', 'جيد', 'مفيد',
    ],
    en: 'You\'re welcome! 😊 Is there anything else I can help you with? '
        'Feel free to ask about any Ishara feature.',
    ar: 'على الرحب والسعة! 😊 هل هناك شيء آخر يمكنني مساعدتك فيه؟ '
        'لا تتردد في السؤال عن أي ميزة من ميزات إشارة.',
  ),

  // ── Goodbye ────────────────────────────────────────────────────────────────
  _FaqEntry(
    keys: [
      'bye', 'goodbye', 'see you', 'later', 'exit', 'quit', 'close',
      'مع السلامة', 'وداعًا', 'إلى اللقاء', 'خروج',
    ],
    en: 'Goodbye! 👋 Stay safe and take care. Open the assistant anytime you need help.',
    ar: 'مع السلامة! 👋 اعتنِ بنفسك. افتح المساعد في أي وقت تحتاج مساعدة.',
  ),
];

bool _isArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

/// Returns a best-match answer for [question]. Always returns *something*;
/// language is auto-detected from the question itself.
String localFaqMatch(String question) {
  final q = question.toLowerCase().trim();
  if (q.isEmpty) {
    return 'Hello! 👋 Ask me anything about Ishara — features, pricing, '
        'how-to guides, or troubleshooting.';
  }
  final ar = _isArabic(question);

  // Score-based matching: prefer entries with more keyword hits
  _FaqEntry? bestEntry;
  int bestScore = 0;

  for (final item in _faq) {
    int score = 0;
    for (final k in item.keys) {
      if (q.contains(k.toLowerCase())) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      bestEntry = item;
    }
  }

  if (bestEntry != null) {
    return ar ? bestEntry.ar : bestEntry.en;
  }

  // Contextual fallback based on question length/type
  if (ar) {
    return 'يسعدني مساعدتك! يمكنني الإجابة عن أسئلة حول:\n'
        '• الأسعار والمنتجات\n'
        '• لغة الإشارة والترجمة\n'
        '• ميزات الأمان والاستغاثة\n'
        '• النظارات الذكية\n'
        '• التعلم والدروس\n'
        'ماذا تريد أن تعرف؟';
  }
  return 'I\'d love to help! I can answer questions about:\n'
      '• Pricing & products\n'
      '• Sign language translation\n'
      '• SOS & safety features\n'
      '• Smart glasses specs\n'
      '• Learning & lessons\n'
      'What would you like to know?';
}

/// Returns 3 contextual follow-up suggestion strings based on the last reply.
/// The assistant uses these as tappable chips after each answer so the
/// conversation feels dynamic instead of static.
List<String> suggestFollowUps(String lastReply) {
  final r = lastReply.toLowerCase();
  final isAr = _isArabic(lastReply);

  if (r.contains('sos') || r.contains('safety') || r.contains('استغاث')) {
    return isAr
        ? ['كيف أضيف جهة طوارئ؟', 'ماذا يرسل زر الاستغاثة؟', 'هل تعمل الاستغاثة بدون إنترنت؟']
        : ['How do I add an emergency contact?', 'What does SOS send exactly?', 'Can SOS work offline?'];
  }
  if (r.contains('vision') || r.contains('currency') || r.contains('عمل') || r.contains('عملة')) {
    return isAr
        ? ['كيف أقرأ الأوراق النقدية؟', 'هل يقرأ النص العربي؟', 'ما الأشياء التي يمكن اكتشافها؟']
        : ['How do I read banknotes?', 'Can it read Arabic text?', 'What objects can it detect?'];
  }
  if (r.contains('sign') || r.contains('translate') || r.contains('إشارة') || r.contains('ترجم')) {
    return isAr
        ? ['ما مدى دقة ترجمة الإشارة؟', 'هل تدعم لغة الإشارة العربية؟', 'أرني درسًا']
        : ['How accurate is sign translation?', 'Does it work in Arabic Sign Language?', 'Show me a lesson'];
  }
  if (r.contains('learn') || r.contains('lesson') || r.contains('تعلم') || r.contains('درس')) {
    return isAr
        ? ['ابدأ اختبارًا', 'افتح القاموس', 'كيف أفتح الدرس التالي؟']
        : ['Start a quiz', 'Open the dictionary', 'How do I unlock the next lesson?'];
  }
  if (r.contains('price') || r.contains('cost') || r.contains('سعر') || r.contains('تكلفة')) {
    return isAr
        ? ['أين أشتري النظارات؟', 'هل يوجد شحن خارج مصر؟', 'هل هناك ضمان؟']
        : ['Where can I buy the glasses?', 'Do you ship outside Egypt?', 'Is there a warranty?'];
  }
  if (r.contains('glasses') || r.contains('hardware') || r.contains('نظارات')) {
    return isAr
        ? ['كيف أشحن النظارات؟', 'كيف أقرن النظارات؟', 'ما مواصفات النظارات؟']
        : ['How do I charge the glasses?', 'How do I pair the glasses?', 'What are the glasses specs?'];
  }
  if (r.contains('account') || r.contains('profile') || r.contains('حساب') || r.contains('ملف')) {
    return isAr
        ? ['كيف أغير صورتي الشخصية؟', 'كيف أضيف جهة طوارئ؟', 'كيف أغير اللغة؟']
        : ['How do I change my profile picture?', 'How do I add an emergency contact?', 'How do I change the language?'];
  }
  // Default suggestions cover the main features
  return isAr
      ? ['كيف تعمل الاستغاثة؟', 'ماذا يفعل تبويب الرؤية؟', 'أخبرني عن النظارات الذكية']
      : ['How does SOS work?', 'What can the Vision tab do?', 'Tell me about the smart glasses'];
}
