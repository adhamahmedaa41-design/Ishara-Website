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
        // TODO: Replace with professional product renders.
        images: [
            {
                src: "/uploads/products/glasses-hero.svg",
                alt: {
                    en: "Ishara Smart Assistive Glasses front view on gradient backdrop",
                    ar: "النظارات الذكية المساعدة من إشارة — منظور أمامي على خلفية متدرجة",
                },
            },
        ],
        priceEGP: 12999,
        compareAtEGP: 15999,
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
            {
                src: "/uploads/products/bracelet-hero.svg",
                alt: {
                    en: "Ishara Smart Bracelet — black silicone band with soft-glow SOS button",
                    ar: "السوار الذكي من إشارة — سوار سيليكون أسود بزر استغاثة مضيء",
                },
            },
        ],
        priceEGP: 2499,
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
            {
                src: "/uploads/products/app-hero.svg",
                alt: {
                    en: "Ishara mobile app UI mockup — translation screen",
                    ar: "واجهة تطبيق إشارة — شاشة الترجمة",
                },
            },
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
