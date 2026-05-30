// services/geminiService.js
// Google Gemini proxy with graceful fallback to a rule-based FAQ responder
// when GEMINI_API_KEY is not configured. Streams tokens over SSE when possible.

let clientInstance = null;
function getClient() {
    if (clientInstance) return clientInstance;
    const key = process.env.GEMINI_API_KEY;
    if (!key) return null;
    try {
        // eslint-disable-next-line global-require
        const { GoogleGenerativeAI } = require("@google/generative-ai");
        clientInstance = new GoogleGenerativeAI(key);
        return clientInstance;
    } catch (err) {
        console.warn(
            "Gemini SDK not installed — run `npm i @google/generative-ai` in server/."
        );
        return null;
    }
}

const SYSTEM_PROMPT_EN = `You are Ishara's assistant — a warm, concise helper for an assistive-technology ecosystem for deaf, non-verbal, and blind users.
Core products:
• Smart Assistive Glasses — camera + edge AI for sign language recognition, obstacle detection, currency & object recognition, spoken voice guidance.
• Smart Bracelet — SOS emergency button, haptic alerts for deaf users, live location sharing.
• Ishara Mobile App — sign ↔ speech translation, voice-to-text, text-to-sign, structured learning hub.
• Concept products — Smart Cane, Home Hub.

Rules:
1. Use simple sentences. Avoid jargon. Default to under 80 words unless asked for detail.
2. If the user writes in Arabic, answer in Modern Standard Arabic.
3. Be empathetic toward disability. Never use pitying language.
4. If asked about prices: Glasses 12,999 EGP, Bracelet 2,499 EGP, App Free. Shipping inside Egypt 50 EGP.
5. If asked something you don't know, say so clearly and suggest contacting the team via the Contact section.
6. Never invent medical, legal, or safety claims. If emergency: advise the SOS button or calling 122 (Egypt police) / 123 (ambulance).`;

const SYSTEM_PROMPT_AR = `أنت مساعد إشارة — مساعد ودود وموجز لمنظومة تقنيات مساعدة لضعاف السمع والمكفوفين وذوي النطق المحدود.
المنتجات الأساسية:
• النظارات الذكية — كاميرا وذكاء اصطناعي محلي للتعرف على لغة الإشارة، واكتشاف العوائق، وتمييز العملات والأشياء، وتوجيه صوتي.
• السوار الذكي — زر استغاثة، تنبيهات اهتزازية، ومشاركة فورية للموقع.
• تطبيق إشارة — ترجمة إشارة↔كلام، صوت إلى نص، نص إلى إشارة، ومركز تعلم منظم.
• منتجات قيد التطوير — العصا الذكية، المركز المنزلي.

القواعد:
١. استخدم جملًا بسيطة وتجنب المصطلحات. اختصر الرد تحت ٨٠ كلمة ما لم يُطلب غير ذلك.
٢. إذا كتب المستخدم بالإنجليزية فأجب بالإنجليزية.
٣. كن متعاطفًا دون لغة شفقة.
٤. الأسعار: النظارات ١٢٬٩٩٩ ج.م، السوار ٢٬٤٩٩ ج.م، التطبيق مجاني. الشحن داخل مصر ٥٠ ج.م.
٥. إن لم تعرف، فقل ذلك وانصح بالتواصل عبر قسم "اتصل بنا".
٦. لا تختلق ادعاءات طبية أو قانونية. في حالة الطوارئ انصح باستخدام زر الاستغاثة أو الاتصال بـ ١٢٢ (الشرطة) / ١٢٣ (الإسعاف).`;

// Rule-based fallback. Uses keyword matching — enough to make the widget
// useful in local dev without an API key.
const FAQ = [
    {
        keys: ["price", "cost", "kam", "kam sa3r", "سعر", "تكلفة", "بكم"],
        en: "Smart Assistive Glasses: 12,999 EGP. Smart Bracelet: 2,499 EGP. Ishara mobile app: Free. Shipping in Egypt: 50 EGP.",
        ar: "النظارات الذكية: ١٢٬٩٩٩ جنيه. السوار الذكي: ٢٬٤٩٩ جنيه. تطبيق إشارة: مجاني. الشحن داخل مصر: ٥٠ جنيهًا.",
    },
    {
        keys: ["blind", "vision", "see", "مكفوف", "كفيف", "بصر"],
        en: "The glasses detect obstacles, read currency, identify objects, and speak voice cues like \"obstacle ahead\" — all processed on the device for speed and privacy.",
        ar: "تكتشف النظارات العوائق وتقرأ العملات وتميز الأشياء، وتنطق إشارات صوتية مثل «عائق أمامك» — كل ذلك محليًا للسرعة والخصوصية.",
    },
    {
        keys: ["deaf", "sign", "hearing", "إشارة", "لغة الإشارة", "ضعيف السمع", "أصم"],
        en: "Ishara recognises sign language through the glasses' camera and translates it to speech. The mobile app also translates spoken Arabic or English back into sign language.",
        ar: "تتعرف إشارة على لغة الإشارة عبر كاميرا النظارات وتترجمها إلى كلام. ويقوم التطبيق بترجمة الكلام المسموع عربيًا أو إنجليزيًا إلى لغة الإشارة.",
    },
    {
        keys: ["sos", "emergency", "help", "استغاثة", "طوارئ"],
        en: "Press and hold the bracelet's SOS button to alert your emergency contacts with your live location. The glasses can also trigger an SOS by voice command.",
        ar: "اضغط مطولًا على زر الاستغاثة بالسوار لتنبيه جهات الاتصال مع موقعك المباشر. كما يمكن تفعيل الاستغاثة بالنظارات بأمر صوتي.",
    },
    {
        keys: ["battery", "بطارية"],
        en: "Glasses: up to 8 hours of active use. Bracelet: up to 5 days on standby.",
        ar: "النظارات: حتى ٨ ساعات استخدام فعّال. السوار: حتى ٥ أيام في وضع الاستعداد.",
    },
    {
        keys: ["shipping", "delivery", "شحن", "توصيل"],
        en: "Flat 50 EGP shipping anywhere in Egypt. Typical delivery is 2–4 business days.",
        ar: "الشحن ٥٠ جنيهًا داخل مصر. عادةً يصل خلال ٢–٤ أيام عمل.",
    },
    {
        keys: ["warranty", "ضمان"],
        en: "Every hardware product ships with a 2-year limited warranty.",
        ar: "كل منتج يأتي بضمان محدود لمدة سنتين.",
    },
];

function ruleMatch(question, lang) {
    const q = String(question || "").toLowerCase();
    for (const item of FAQ) {
        if (item.keys.some((k) => q.includes(k))) {
            return lang === "ar" ? item.ar : item.en;
        }
    }
    return lang === "ar"
        ? "أنا مساعد إشارة التجريبي (بدون مفتاح Gemini الآن). جرّب سؤالًا عن الأسعار، لغة الإشارة، أو كيف تساعد النظارات المكفوفين."
        : "I'm the demo Ishara assistant (no Gemini API key configured). Try asking about pricing, sign language, or how the glasses help blind users.";
}

function buildHistory(messages, lang) {
    const sys = lang === "ar" ? SYSTEM_PROMPT_AR : SYSTEM_PROMPT_EN;
    // Gemini v1 chat expects role: 'user' | 'model', with a leading system-style turn.
    const history = [
        { role: "user", parts: [{ text: sys }] },
        {
            role: "model",
            parts: [
                {
                    text:
                        lang === "ar"
                            ? "فهمت. أنا مساعد إشارة، جاهز للمساعدة."
                            : "Understood. I'm the Ishara assistant, ready to help.",
                },
            ],
        },
    ];
    const past = messages.slice(0, -1);
    for (const m of past) {
        history.push({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{ text: String(m.content || "") }],
        });
    }
    return history;
}

async function streamReply(res, { messages, lang }) {
    const client = getClient();
    const last = messages[messages.length - 1]?.content || "";

    // SSE headers
    res.set({
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no",
    });
    res.flushHeaders?.();

    const send = (data) => {
        res.write(`data: ${JSON.stringify(data)}\n\n`);
    };
    const done = () => {
        res.write("data: [DONE]\n\n");
        res.end();
    };

    // Fallback path — no key / no SDK
    if (!client) {
        send({ delta: ruleMatch(last, lang) });
        return done();
    }

    try {
        const model = client.getGenerativeModel({
            model: process.env.GEMINI_MODEL || "gemini-2.5-flash",
        });
        const chat = model.startChat({ history: buildHistory(messages, lang) });
        const stream = await chat.sendMessageStream(last);
        for await (const chunk of stream.stream) {
            const text = chunk.text();
            if (text) send({ delta: text });
        }
        done();
    } catch (err) {
        console.error("Gemini stream error:", err?.message || err);
        send({
            delta:
                lang === "ar"
                    ? "عذرًا، واجهت مشكلة في الاتصال بالذكاء. حاول مجددًا أو تواصل مع الفريق."
                    : "Sorry, I hit a connection issue. Please try again or contact our team.",
        });
        done();
    }
}

module.exports = { streamReply };
