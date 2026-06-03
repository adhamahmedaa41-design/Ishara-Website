// seed/seedProducts.js
// Run: `node server/seed/seedProducts.js`
//
// Populates the 4 core Ishara products + 2 concept cards. Safe to re-run:
// existing products are updated (by slug) rather than duplicated.
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

const connectDB = require("../config/dbConfig");
const Product = require("../models/Product");

const PRODUCTS = [
    {
        slug: "smart-assistive-glasses",
        category: "hardware",
        isFeatured: true,
        title: { en: "Smart Assistive Glasses", ar: "النظارات الذكية المساعدة" },
        tagline: {
            en: "See the world differently — AI-powered vision, voice and awareness.",
            ar: "شاهد العالم بطريقة مختلفة — رؤية بالذكاء الاصطناعي وصوت ووعي محيطي.",
        },
        description: {
            en: "Ishara's flagship wearable. Onboard AI recognises sign language, reads text, identifies currency, detects obstacles, and speaks natural voice feedback — all processed locally on device for privacy and speed.",
            ar: "منتجنا الرائد القابل للارتداء. يتعرف الذكاء الاصطناعي المدمج على لغة الإشارة، ويقرأ النصوص، ويميز العملات، ويكتشف العوائق، ويقدم ملاحظات صوتية طبيعية — كل ذلك محليًا للخصوصية والسرعة.",
        },
        features: [
            {
                icon: "Camera",
                title: { en: "Camera", ar: "الكاميرا" },
                desc: {
                    en: "Real-time video capture, sign language recognition, object and currency detection.",
                    ar: "تصوير فيديو لحظي، والتعرف على لغة الإشارة، والأشياء، والعملات.",
                },
            },
            {
                icon: "Radar",
                title: { en: "Sensors", ar: "المستشعرات" },
                desc: {
                    en: "Obstacle detection, collision avoidance and 360° environment awareness.",
                    ar: "اكتشاف العوائق وتجنب التصادم والوعي بالمحيط 360°.",
                },
            },
            {
                icon: "Cpu",
                title: { en: "Microcontroller", ar: "المعالج" },
                desc: {
                    en: "Edge AI processes inputs on-device — no cloud dependency.",
                    ar: "ذكاء اصطناعي حافّي يعالج المدخلات محليًا دون الحاجة للسحابة.",
                },
            },
            {
                icon: "Volume2",
                title: { en: "Audio Output", ar: "الصوت" },
                desc: {
                    en: "Natural voice guidance: “Obstacle ahead”, “This is 50 EGP”, “Door detected”.",
                    ar: "توجيه صوتي طبيعي: «عائق أمامك»، «هذه ٥٠ جنيه»، «باب أمامك».",
                },
            },
            {
                icon: "Wifi",
                title: { en: "Connectivity", ar: "الاتصال" },
                desc: {
                    en: "Wi-Fi and Bluetooth pairing with the Ishara mobile app for updates and history.",
                    ar: "اتصال Wi-Fi وBluetooth مع تطبيق إشارة للتحديثات والسجل.",
                },
            },
        ],
        specs: [
            { label: { en: "Battery", ar: "البطارية" }, value: { en: "8 hours", ar: "٨ ساعات" } },
            { label: { en: "Weight", ar: "الوزن" }, value: { en: "62 g", ar: "٦٢ جم" } },
            { label: { en: "Camera", ar: "الكاميرا" }, value: { en: "8 MP + ToF", ar: "٨ ميجابكسل + ToF" } },
            { label: { en: "Processor", ar: "المعالج" }, value: { en: "Edge NPU 4 TOPS", ar: "NPU ٤ TOPS" } },
            { label: { en: "Warranty", ar: "الضمان" }, value: { en: "2 years", ar: "سنتان" } },
        ],
        images: [
            { src: "/uploads/products/glasses-1.jpg", alt: { en: "Smart Assistive Glasses — front hero view", ar: "النظارات الذكية المساعدة — منظور أمامي" } },
            { src: "/uploads/products/glasses-2.jpg", alt: { en: "Smart Assistive Glasses — 3/4 angle", ar: "النظارات الذكية المساعدة — منظور ثلاثة أرباع" } },
            { src: "/uploads/products/glasses-3.jpg", alt: { en: "Smart Assistive Glasses — side profile", ar: "النظارات الذكية المساعدة — منظور جانبي" } },
            { src: "/uploads/products/glasses-4.jpg", alt: { en: "Smart Assistive Glasses — top folded view", ar: "النظارات الذكية المساعدة — منظور علوي مطوي" } },
            { src: "/uploads/products/glasses-5.jpg", alt: { en: "Smart Assistive Glasses — camera macro close-up", ar: "النظارات الذكية المساعدة — لقطة مقربة للكاميرا" } },
            { src: "/uploads/products/glasses-6.jpg", alt: { en: "Smart Assistive Glasses — lifestyle, worn in a cafe", ar: "النظارات الذكية المساعدة — استخدام يومي في مقهى" } },
        ],
        priceEGP: 1500,
        compareAtEGP: 2000,
        stock: 25,
    },
    {
        slug: "smart-bracelet",
        category: "hardware",
        title: { en: "Smart Bracelet", ar: "السوار الذكي" },
        tagline: {
            en: "Safety and connection, on your wrist.",
            ar: "الأمان والاتصال — على معصمك.",
        },
        description: {
            en: "A discreet wearable with an SOS emergency button, vibration alerts for deaf users, and real-time location sharing with trusted contacts.",
            ar: "جهاز قابل للارتداء يحتوي زر استغاثة، وتنبيهات اهتزازية لضعاف السمع، ومشاركة فورية للموقع مع جهات اتصال موثوقة.",
        },
        features: [
            {
                icon: "Siren",
                title: { en: "SOS Button", ar: "زر الاستغاثة" },
                desc: {
                    en: "One long press alerts emergency contacts with your live location.",
                    ar: "ضغطة مطولة واحدة تنبّه جهات الاتصال مع موقعك المباشر.",
                },
            },
            {
                icon: "Vibrate",
                title: { en: "Haptic Alerts", ar: "تنبيهات اهتزازية" },
                desc: {
                    en: "Distinct vibration patterns signal calls, messages and hazards.",
                    ar: "أنماط اهتزاز مميزة تشير للمكالمات والرسائل والمخاطر.",
                },
            },
            {
                icon: "MapPin",
                title: { en: "Location Sharing", ar: "مشاركة الموقع" },
                desc: {
                    en: "Family members can track your route live during emergencies.",
                    ar: "يمكن لأفراد العائلة تتبع مسارك مباشرة في حالات الطوارئ.",
                },
            },
        ],
        specs: [
            { label: { en: "Battery", ar: "البطارية" }, value: { en: "5 days", ar: "٥ أيام" } },
            { label: { en: "Water rating", ar: "مقاومة الماء" }, value: { en: "IP68", ar: "IP68" } },
        ],
        images: [
            { src: "/uploads/products/bracelet-1.jpg", alt: { en: "Smart Bracelet — front hero with glowing SOS button", ar: "السوار الذكي — منظور أمامي وزر استغاثة مضيء" } },
            { src: "/uploads/products/bracelet-2.jpg", alt: { en: "Smart Bracelet — 3/4 angle on flat surface", ar: "السوار الذكي — منظور ثلاثة أرباع" } },
            { src: "/uploads/products/bracelet-3.jpg", alt: { en: "Smart Bracelet — side profile", ar: "السوار الذكي — منظور جانبي" } },
            { src: "/uploads/products/bracelet-4.jpg", alt: { en: "Smart Bracelet — top circular view", ar: "السوار الذكي — منظور علوي دائري" } },
            { src: "/uploads/products/bracelet-5.jpg", alt: { en: "Smart Bracelet — macro of the SOS button", ar: "السوار الذكي — لقطة مقربة لزر الاستغاثة" } },
            { src: "/uploads/products/bracelet-6.jpg", alt: { en: "Smart Bracelet — lifestyle, worn on a wrist", ar: "السوار الذكي — على المعصم" } },
        ],
        priceEGP: 800,
        stock: 60,
    },
    {
        slug: "ishara-mobile-app",
        category: "digital",
        title: { en: "Ishara Mobile App", ar: "تطبيق إشارة" },
        tagline: {
            en: "Your pocket interpreter and learning hub.",
            ar: "مترجمك الشخصي ومركز التعلم في جيبك.",
        },
        description: {
            en: "A free companion app: sign-language translation, voice-to-text, text-to-sign, and a structured learning hub for Arabic and international sign language.",
            ar: "تطبيق مرافق مجاني: ترجمة لغة الإشارة، وتحويل الصوت إلى نص، والنص إلى إشارة، ومركز تعلم منظم للعربية ولغة الإشارة الدولية.",
        },
        features: [
            {
                icon: "Languages",
                title: { en: "Sign ↔ Speech Translation", ar: "ترجمة الإشارة ↔ الكلام" },
                desc: {
                    en: "Real-time two-way translation between sign and spoken Arabic or English.",
                    ar: "ترجمة فورية ثنائية الاتجاه بين الإشارة والعربية أو الإنجليزية.",
                },
            },
            {
                icon: "GraduationCap",
                title: { en: "Learning Hub", ar: "مركز التعلم" },
                desc: {
                    en: "Guided lessons, practice mode, and progress tracking.",
                    ar: "دروس موجهة، ووضع تدريب، وتتبع التقدم.",
                },
            },
            {
                icon: "Mic",
                title: { en: "Voice-to-Text", ar: "الصوت إلى نص" },
                desc: {
                    en: "Instant captions during conversations and phone calls.",
                    ar: "ترجمة نصية فورية أثناء المحادثات والمكالمات.",
                },
            },
        ],
        specs: [
            { label: { en: "Platforms", ar: "المنصات" }, value: { en: "iOS, Android", ar: "iOS و Android" } },
            { label: { en: "Price", ar: "السعر" }, value: { en: "Free", ar: "مجاني" } },
        ],
        images: [
            { src: "/uploads/products/app-1.jpg", alt: { en: "Ishara app — translation screen", ar: "تطبيق إشارة — شاشة الترجمة" } },
            { src: "/uploads/products/app-2.jpg", alt: { en: "Ishara app — live voice-to-text captions", ar: "تطبيق إشارة — ترجمة فورية صوت إلى نص" } },
            { src: "/uploads/products/app-3.jpg", alt: { en: "Ishara app — learning hub grid", ar: "تطبيق إشارة — شبكة مركز التعلم" } },
            { src: "/uploads/products/app-4.jpg", alt: { en: "Ishara app — emergency signs lesson", ar: "تطبيق إشارة — درس إشارات الطوارئ" } },
            { src: "/uploads/products/app-5.jpg", alt: { en: "Ishara app — sign-to-speech and speech-to-sign", ar: "تطبيق إشارة — إشارة إلى كلام والعكس" } },
            { src: "/uploads/products/app-6.jpg", alt: { en: "Ishara app — lifestyle, used in a conversation", ar: "تطبيق إشارة — استخدام أثناء المحادثة" } },
        ],
        priceEGP: 0,
        stock: 9999,
    },
    {
        slug: "ishara-smart-cane",
        category: "concept",
        isConcept: true,
        title: { en: "Smart Cane (Concept)", ar: "العصا الذكية (مفهوم)" },
        tagline: {
            en: "Upcoming — haptic navigation for the blind.",
            ar: "قريبًا — ملاحة اهتزازية للمكفوفين.",
        },
        description: {
            en: "Concept project: a smart cane with ultrasonic ranging and GPS-linked vibration cues, pairing with the Ishara glasses for richer spatial awareness.",
            ar: "مشروع مفهومي: عصا ذكية مزودة بقياس الموجات فوق الصوتية وإشارات اهتزازية مرتبطة بـ GPS، تتزامن مع نظارات إشارة لإدراك مكاني أوسع.",
        },
        features: [],
        specs: [],
        images: [
            {
                src: "/uploads/products/concept-cane.svg",
                alt: {
                    en: "Ishara concept smart cane illustration",
                    ar: "توضيح مفهومي للعصا الذكية من إشارة",
                },
            },
        ],
        priceEGP: 0,
        stock: 0,
    },
    {
        slug: "ishara-home-hub",
        category: "concept",
        isConcept: true,
        title: { en: "Home Hub (Concept)", ar: "المركز المنزلي (مفهوم)" },
        tagline: {
            en: "Upcoming — a central safety + comms hub for the home.",
            ar: "قريبًا — مركز أمان واتصال للمنزل.",
        },
        description: {
            en: "Concept: a tabletop device that synchronises Ishara wearables, detects home hazards (smoke, doorbell, crying baby) and signals them visually for deaf users.",
            ar: "مفهوم: جهاز مكتبي يوحّد أجهزة إشارة القابلة للارتداء، ويكتشف مخاطر المنزل (الدخان، الجرس، بكاء الطفل) ويعرضها بصريًا لضعاف السمع.",
        },
        features: [],
        specs: [],
        images: [
            {
                src: "/uploads/products/concept-hub.svg",
                alt: {
                    en: "Ishara concept home hub rendering",
                    ar: "تصور مفهومي للمركز المنزلي من إشارة",
                },
            },
        ],
        priceEGP: 0,
        stock: 0,
    },
];

(async function run() {
    try {
        await connectDB();
        for (const p of PRODUCTS) {
            await Product.findOneAndUpdate({ slug: p.slug }, p, {
                upsert: true,
                new: true,
                setDefaultsOnInsert: true,
            });
            console.log(`  ✓ ${p.slug}`);
        }
        console.log("Seed complete.");
        process.exit(0);
    } catch (err) {
        console.error("Seed failed:", err);
        process.exit(1);
    }
})();
