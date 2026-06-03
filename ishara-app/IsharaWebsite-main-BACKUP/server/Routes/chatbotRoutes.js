const express = require("express");
const router = express.Router();
const { authMiddleware } = require("../middleware/authMiddleware");

const SYSTEM_PROMPT = `You are the Ishara Assistant — a helpful, friendly, and knowledgeable guide for the Ishara accessibility app.
Ishara helps deaf, blind, and non-verbal users in Egypt with:
- Sign language translation (camera → Arabic text + speech), and Arabic text → sign clips
- Vision: Egyptian currency totaling, fine-grained object naming with TTS, OCR (English + Arabic)
- Multi-contact emergency SOS with silent SMS + WhatsApp + Telegram and live location
- Learning Hub with Arabic Sign Language clips and a Duolingo-style quiz
- Hardware glasses pairing for obstacle detection and SOS button
- Shop for accessibility products (Smart Glasses: 1,500 EGP, Smart Bracelet: 800 EGP, App: Free)
- Accessibility settings: auto-TTS, high contrast, color-blind palettes, dyslexia font, large text, motor mode
- Warranty: 2-year limited; Returns: 14-day policy; Shipping: 50 EGP within Egypt
You answer in the user's language (Arabic or English). Be warm, informative, and thorough.
For navigation hints, append a tag like [open:translator] [open:vision] [open:safety] [open:learning] [open:shop] [open:profile/accessibility] [open:profile/contacts] [open:assistant].`;

router.post("/ask", authMiddleware, async (req, res) => {
    try {
        const { messages = [] } = req.body;
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            const last = (messages[messages.length - 1]?.content || "").toLowerCase();
            const reply = ruleBased(last);
            return res.json({ reply, source: "local" });
        }
        const contents = messages.map((m) => ({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{ text: m.content }],
        }));
        const body = {
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            contents,
            generationConfig: { temperature: 0.5, maxOutputTokens: 1024 },
        };
        const r = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
            { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }
        );
        const data = await r.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
        if (!text) {
            const last = (messages[messages.length - 1]?.content || "").toLowerCase();
            return res.json({ reply: ruleBased(last), source: "local-fallback" });
        }
        res.json({ reply: text, source: "gemini" });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});

// Public endpoint — no auth required — for the website chat widget
router.post("/public-ask", async (req, res) => {
    try {
        const { messages = [] } = req.body;
        const last = (messages[messages.length - 1]?.content || "").toLowerCase();
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey) {
            return res.json({ reply: ruleBased(last), source: "local" });
        }

        const contents = messages.map((m) => ({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{ text: m.content }],
        }));
        const body = {
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            contents,
            generationConfig: { temperature: 0.5, maxOutputTokens: 1024 },
        };
        const r = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
            { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }
        );
        const data = await r.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
        if (!text) {
            return res.json({ reply: ruleBased(last), source: "local-fallback" });
        }
        res.json({ reply: text, source: "gemini" });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
});


function isArabic(q) {
    return /[\u0600-\u06FF]/.test(q);
}

function ruleBased(q) {
    if (!q || q.trim().length === 0) {
        return "Hello! 👋 I'm the Ishara assistant. Ask me anything about the app, smart glasses, sign language, SOS, or any feature!";
    }

    const ar = isArabic(q);

    // Greetings
    if (/hello|hi |hey|howdy|good morning|good evening|مرحب|أهلا|السلام|صباح|مساء|هلا/.test(q)) {
        return ar
            ? "أهلًا! 👋 أنا مساعد إشارة. اسألني عن النظارات الذكية، الأسعار، لغة الإشارة، الاستغاثة، أو كيفية استخدام أي ميزة!"
            : "Hello! 👋 I'm the Ishara assistant. Ask me about the smart glasses, pricing, sign language, SOS, or how to use any feature!";
    }

    // Identity / About
    if (/who are you|what are you|what is ishara|about ishara|introduce|your name|من أنت|ما هي إشارة|عن إشارة/.test(q)) {
        return ar
            ? "أنا مساعد إشارة الذكي. 🤖\n\nإشارة منظومة تقنيات مساعدة مصرية مصمَّمة لـ:\n• الصُّم وضعاف السمع — ترجمة الإشارة ↔ الكلام\n• المكفوفين وضعاف البصر — اكتشاف العوائق وتمييز الأشياء وقراءة العملات\n• غير الناطقين — تحويل النص إلى كلام\n\nالمنتجات: النظارات الذكية (١٬٥٠٠ جنيه) + تطبيق مجاني."
            : "I'm the Ishara AI assistant. 🤖\n\nIshara is an Egyptian assistive-technology ecosystem for:\n• Deaf/hard-of-hearing — sign ↔ speech translation\n• Blind/low-vision — obstacle detection, object ID, currency reading\n• Non-verbal — text-to-speech & communication tools\n\nProducts: Smart Glasses (1,500 EGP) + free mobile app.";
    }

    // Navigation / Guide
    if (/guide|navigate|how to use|tutorial|where is|website|overview|دليل|كيف|أين|نظرة عامة/.test(q)) {
        return ar
            ? "🗺️ دليل التطبيق:\n\n• 🤟 المترجم — إشارة ↔ كلام [open:translator]\n• 👁️ الرؤية — اكتشاف الأشياء، OCR، العملات [open:vision]\n• 🆘 الأمان — زر الاستغاثة وجهات الطوارئ [open:safety]\n• 📚 التعلم — دروس، اختبارات، قاموس [open:learning]\n• 🛒 المتجر — شراء الأجهزة [open:shop]\n• 👤 الملف الشخصي — الإعدادات وإمكانية الوصول"
            : "🗺️ App Navigation:\n\n• 🤟 Translator — Sign ↔ Speech [open:translator]\n• 👁️ Vision — Object detection, OCR, currency [open:vision]\n• 🆘 Safety — SOS & emergency contacts [open:safety]\n• 📚 Learning — Lessons, quizzes, dictionary [open:learning]\n• 🛒 Shop — Buy hardware [open:shop]\n• 👤 Profile — Settings & accessibility";
    }

    // Pricing
    if (/price|cost|how much|pricing|buy|purchase|order|pay|سعر|تكلفة|بكم|كام|اشتري|طلب/.test(q)) {
        return ar
            ? "💰 أسعار إشارة:\n\n• النظارات الذكية: **١٬٥٠٠ جنيه**\n• السوار الذكي: **٨٠٠ جنيه**\n• التطبيق: **مجاني** (iOS وAndroid)\n• الشحن داخل مصر: **٥٠ جنيهًا**\n\nافتح المتجر للطلب. [open:shop]"
            : "💰 Ishara Pricing:\n\n• Smart Assistive Glasses: **1,500 EGP**\n• Smart Bracelet: **800 EGP**\n• Mobile app: **Free** (iOS & Android)\n• Shipping in Egypt: **50 EGP**\n\nOpen Shop to order. [open:shop]";
    }

    // Glasses / Hardware
    if (/glasses|smart glasses|hardware|specs|camera|processor|device|wearable|نظارات|نظارة|كاميرا|جهاز/.test(q)) {
        return ar
            ? "🥽 مواصفات النظارات الذكية:\n\n• الكاميرا: ١٢ ميجابكسل\n• المعالج: Qualcomm AR2\n• البطارية: ٨ ساعات استخدام فعّال\n• الميزات: التعرف على الإشارة، اكتشاف العوائق، تمييز العملات، التوجيه الصوتي\n• الاتصال: بلوتوث وواي فاي"
            : "🥽 Smart Glasses specs:\n\n• Camera: 12 MP\n• Processor: Qualcomm AR2\n• Battery: 8 hours active use\n• Features: sign recognition, obstacle detection, currency ID, voice guidance\n• Connectivity: Bluetooth & Wi-Fi";
    }

    // Vision / Blind
    if (/blind|vision|obstacle|object|detect|currency|money|ocr|read text|مكفوف|بصر|عوائق|عملة|فلوس|نص/.test(q)) {
        return ar
            ? "👁️ ميزات الرؤية:\n\n• اكتشاف العوائق مع تنبيه صوتي\n• تمييز العملات المصرية لحظيًا\n• تسمية الأشياء بنطق صوتي\n• قراءة النص المطبوع (عربي + إنجليزي)\n\nكل المعالجة تتم محليًا. [open:vision]"
            : "👁️ Vision features:\n\n• Obstacle detection with voice alert\n• Real-time Egyptian currency counting\n• Object naming with text-to-speech\n• OCR for printed text (Arabic + English)\n\nAll on-device for privacy. [open:vision]";
    }

    // Sign language / Deaf
    if (/deaf|sign|hearing|translate|arsl|arabic sign|إشارة|لغة الإشارة|ضعيف السمع|أصم|ترجمة/.test(q)) {
        return ar
            ? "🤟 ميزات لغة الإشارة:\n\n• كاميرا النظارات تتعرف على إشاراتك وتحولها إلى كلام\n• التطبيق يترجم الكلام المسموع إلى مقاطع إشارة\n• يدعم لغة الإشارة العربية (ArSL)\n\nافتح المترجم للبدء. [open:translator]"
            : "🤟 Sign language features:\n\n• Glasses camera recognizes signs → converts to speech\n• App translates spoken Arabic/English → sign clips\n• Supports Arabic Sign Language (ArSL)\n\nOpen Translator to start. [open:translator]";
    }

    // SOS / Emergency
    if (/sos|emergency|safety|alert|danger|urgent|live location|استغاثة|طوارئ|مساعدة عاجلة|أمان|خطر/.test(q)) {
        return ar
            ? "🆘 الاستغاثة والأمان:\n\n• اضغط زر الاستغاثة الأحمر الكبير في تبويب الأمان\n• يبدأ عداد تنازلي ٥ ثوانٍ — هزّ الهاتف للإلغاء\n• يرسل موقعك المباشر عبر بريد وواتساب وتيليجرام ورسائل SMS\n• أضف جهات الاتصال أولًا. [open:safety]"
            : "🆘 SOS & Safety:\n\n• Tap the big red SOS button in the Safety tab\n• 5-second countdown — shake to cancel\n• Sends live location via email, WhatsApp, Telegram, SMS\n• Add contacts first. [open:safety]";
    }

    // Contacts
    if (/contact|add contact|emergency contact|phone number|جهة اتصال|إضافة|رقم هاتف/.test(q)) {
        return ar
            ? "📞 جهات الطوارئ:\n\n• اذهب إلى الملف الشخصي ← جهات الطوارئ\n• أضف الاسم والهاتف (مع رمز الدولة) والعلاقة والقناة المفضلة\n• القنوات: واتساب، تيليجرام، SMS، أو الكل\n• يمكنك إضافة عدة جهات اتصال. [open:profile/contacts]"
            : "📞 Emergency Contacts:\n\n• Go to Profile → Emergency Contacts\n• Add name, phone (with country code), relationship, preferred channel\n• Channels: WhatsApp, Telegram, SMS, or All\n• Add multiple contacts for redundancy. [open:profile/contacts]";
    }

    // Battery
    if (/battery|charge|power|بطارية|شحن|طاقة/.test(q)) {
        return ar
            ? "🔋 البطارية:\n\n• النظارات الذكية: حتى ٨ ساعات استخدام فعّال\n• الشحن عبر كابل USB-C (مرفق)\n• فعّل وضع السكون لإطالة عمر البطارية"
            : "🔋 Battery:\n\n• Smart Glasses: up to 8 hours active use\n• Charge via included USB-C cable\n• Enable sleep mode to extend battery life";
    }

    // Shipping
    if (/shipping|delivery|ship|deliver|arrive|توصيل|شحن|وصول/.test(q)) {
        return ar
            ? "📦 الشحن:\n\n• ٥٠ جنيهًا ثابتًا داخل مصر\n• التوصيل خلال ٢–٤ أيام عمل\n• الشحن الدولي: support@ishara.app"
            : "📦 Shipping:\n\n• Flat 50 EGP anywhere in Egypt\n• Delivery in 2–4 business days\n• International shipping: support@ishara.app";
    }

    // Warranty / Return
    if (/warranty|return|refund|repair|replace|ضمان|إرجاع|استرداد/.test(q)) {
        return ar
            ? "🛡️ الضمان والإرجاع:\n\n• ضمان محدود لسنتين\n• سياسة الإرجاع خلال ١٤ يومًا (غير مستخدم)\n• للإصلاح: support@ishara.app"
            : "🛡️ Warranty & Returns:\n\n• 2-year limited warranty\n• 14-day return policy (unused, original packaging)\n• For repairs: support@ishara.app";
    }

    // App / Mobile
    if (/app|mobile|download|install|android|iphone|ios|تطبيق|تحميل|هاتف/.test(q)) {
        return ar
            ? "📱 تطبيق إشارة:\n\n• مجاني على iOS وAndroid\n• الميزات: ترجمة الإشارة ↔ الكلام، رؤية، تعلم، استغاثة\n• ابحث عن «إشارة» في App Store أو Google Play"
            : "📱 Ishara App:\n\n• Free on iOS and Android\n• Features: sign translation, vision, learning, SOS\n• Search 'Ishara' on App Store or Google Play";
    }

    // Learning
    if (/learn|lesson|quiz|course|study|dictionary|xp|level|تعلم|درس|اختبار|قاموس/.test(q)) {
        return ar
            ? "📚 مركز التعلم:\n\n• دروس لغة الإشارة العربية مع مقاطع فيديو\n• اختبارات بأسلوب Duolingo لكسب XP\n• قاموس إشارات كامل\n\nافتح تبويب التعلم. [open:learning]"
            : "📚 Learning Hub:\n\n• Arabic Sign Language lessons with video\n• Duolingo-style quizzes for XP\n• Full sign dictionary\n\nOpen Learning tab. [open:learning]";
    }

    // Accessibility
    if (/accessibility|tts|high contrast|dyslexia|large text|color blind|motor|إمكانية|تحدث|تباين/.test(q)) {
        return ar
            ? "⚙️ إعدادات إمكانية الوصول:\n\n• التحدث التلقائي (TTS)\n• التباين العالي\n• خط عسر القراءة\n• تكبير النص\n• ألوان عمى الألوان\n• وضع الحركة\n\n [open:profile/accessibility]"
            : "⚙️ Accessibility Settings:\n\n• Auto-TTS\n• High contrast mode\n• Dyslexia font\n• Large text\n• Color-blind palettes\n• Motor mode\n\n [open:profile/accessibility]";
    }

    // Troubleshooting
    if (/not working|broken|error|problem|bug|crash|fix|stuck|freeze|لا يعمل|خطأ|مشكلة|عطل/.test(q)) {
        return ar
            ? "🛠️ استكشاف الأخطاء:\n\n• التطبيق يتعطل: أغلقه وأعد فتحه وحدّثه\n• النظارات لا تقترن: أعد التشغيل وحاول الإقران\n• الاستغاثة لا ترسل: تحقق من الإنترنت وجهات الاتصال\n• الترجمة غير دقيقة: تأكد من الإضاءة الجيدة\n• الدعم: support@ishara.app"
            : "🛠️ Troubleshooting:\n\n• App crash: force-close, reopen, update\n• Glasses not pairing: restart and re-pair\n• SOS not sending: check internet + contacts\n• Translation inaccurate: ensure good lighting\n• Support: support@ishara.app";
    }

    // Thank you
    if (/thank|thanks|great|awesome|perfect|helpful|amazing|شكرا|ممتاز|رائع/.test(q)) {
        return ar
            ? "على الرحب والسعة! 😊 هل هناك شيء آخر يمكنني مساعدتك فيه؟"
            : "You're welcome! 😊 Is there anything else I can help you with?";
    }

    // Goodbye
    if (/bye|goodbye|see you|later|مع السلامة|وداع/.test(q)) {
        return ar
            ? "مع السلامة! 👋 افتح المساعد في أي وقت تحتاج مساعدة."
            : "Goodbye! 👋 Open the assistant anytime you need help.";
    }

    // Default
    return ar
        ? "يسعدني مساعدتك! يمكنني الإجابة عن أسئلة حول:\n• الأسعار والمنتجات\n• لغة الإشارة والترجمة\n• ميزات الأمان والاستغاثة\n• النظارات الذكية\n• التعلم والدروس\nماذا تريد أن تعرف؟"
        : "I'd love to help! I can answer questions about:\n• Pricing & products\n• Sign language translation\n• SOS & safety features\n• Smart glasses specs\n• Learning & lessons\nWhat would you like to know?";
}

module.exports = router;
