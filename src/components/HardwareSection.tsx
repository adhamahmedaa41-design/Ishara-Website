import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { Cpu, Battery, Wifi, Zap, Eye, Volume2, X } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';
import '@google/model-viewer';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'model-viewer': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & {
        src?: string;
        alt?: string;
        'auto-rotate'?: boolean | string;
        'camera-controls'?: boolean | string;
        'shadow-intensity'?: string;
        exposure?: string;
        style?: React.CSSProperties;
        class?: string;
      }, HTMLElement>;
    }
  }
}

interface HardwareSectionProps {
  language: 'en' | 'ar';
}

export function HardwareSection({ language }: HardwareSectionProps) {
  const [selectedFeature, setSelectedFeature] = useState<number | null>(null);
  const [explodedView, setExplodedView] = useState(false);

  const content = {
    en: {
      title: 'Hardware Innovation',
      subtitle: 'Cutting-edge technology in a sleek, wearable design',
      viewProduct: '3D Product View',
      explodedView: 'Exploded View',
      normalView: 'Normal View',
      features: [
        {
          icon: Cpu,
          title: 'AI Processor',
          description: 'Advanced neural processing unit for real-time analysis',
          position: { x: -30, y: -20 }
        },
        {
          icon: Battery,
          title: '24h Battery',
          description: 'All-day battery life with fast charging',
          position: { x: 30, y: -20 }
        },
        {
          icon: Wifi,
          title: 'Bluetooth 5.2',
          description: 'Seamless connectivity to mobile devices',
          position: { x: -30, y: 20 }
        },
        {
          icon: Zap,
          title: 'Ultrasonic Sensors',
          description: 'Dual sensors for 180° coverage',
          position: { x: 30, y: 20 }
        }
      ],
      specs: {
        title: 'Technical Specifications',
        items: [
          { label: 'Weight', value: '45g' },
          { label: 'Battery Life', value: '24 hours' },
          { label: 'Detection Range', value: 'Up to 2 meters' },
          { label: 'Charging Time', value: '2 hours' },
          { label: 'Water Resistance', value: 'IP54' },
          { label: 'Connectivity', value: 'Bluetooth 5.2' }
        ]
      }
    },
    ar: {
      title: 'ابتكار الأجهزة',
      subtitle: 'تقنية متطورة في تصميم أنيق يمكن ارتداؤه',
      viewProduct: 'عرض المنتج ثلاثي الأبعاد',
      explodedView: 'عرض منفجر',
      normalView: 'العرض العادي',
      features: [
        {
          icon: Cpu,
          title: 'معالج الذكاء الاصطناعي',
          description: 'وحدة معالجة عصبية متقدمة للتحليل في الوقت الفعلي',
          position: { x: -30, y: -20 }
        },
        {
          icon: Battery,
          title: 'بطارية 24 ساعة',
          description: 'عمر بطارية طوال اليوم مع شحن سريع',
          position: { x: 30, y: -20 }
        },
        {
          icon: Wifi,
          title: 'بلوتوث 5.2',
          description: 'اتصال سلس بالأجهزة المحمولة',
          position: { x: -30, y: 20 }
        },
        {
          icon: Zap,
          title: 'أجهزة استشعار بالموجات فوق الصوتية',
          description: 'مستشعران مزدوجان لتغطية 180 درجة',
          position: { x: 30, y: 20 }
        }
      ],
      specs: {
        title: 'المواصفات الفنية',
        items: [
          { label: 'الوزن', value: '45 جم' },
          { label: 'عمر البطارية', value: '24 ساعة' },
          { label: 'نطاق الكشف', value: 'حتى 2 متر' },
          { label: 'وقت الشحن', value: 'ساعتان' },
          { label: 'مقاومة الماء', value: 'IP54' },
          { label: 'الاتصال', value: 'بلوتوث 5.2' }
        ]
      }
    }
  };

  const t = content[language];


  return (
    <section id="hardware" className="min-h-screen py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-blue-500/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                rotateY: [0, 360],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: 'linear',
              }}
            >
              <Eye className="w-16 h-16 text-blue-500" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-20">
          {/* 3D Product Viewer */}
          <ScrollReveal direction="left">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <div className="flex justify-between items-center mb-6">
                <h3>{t.viewProduct}</h3>
                <motion.button
                  onClick={() => setExplodedView(!explodedView)}
                  className="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl text-sm"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {explodedView ? t.normalView : t.explodedView}
                </motion.button>
              </div>

              <div className="relative aspect-square rounded-2xl bg-gradient-to-br from-blue-500/20 to-purple-500/20 overflow-hidden">
                {/* Real 3D GLB Model */}
                <model-viewer
                  src="/glasses.glb"
                  alt="Ishara Smart Glasses"
                  auto-rotate={!explodedView ? "true" : undefined}
                  camera-controls="true"
                  shadow-intensity="1"
                  exposure="1"
                  style={{ width: '100%', height: '100%', background: 'transparent' }}
                />

                {/* Component Hotspots */}
                {!explodedView && t.features.map((feature, index) => (
                  <motion.div
                    key={index}
                    className="absolute w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 cursor-pointer"
                    style={{
                      left: `calc(50% + ${feature.position.x}px)`,
                      top: `calc(50% + ${feature.position.y}px)`,
                    }}
                    whileHover={{ scale: 1.5 }}
                    onClick={() => setSelectedFeature(index)}
                    animate={{
                      boxShadow: [
                        '0 0 0 0 rgba(59, 130, 246, 0.7)',
                        '0 0 0 10px rgba(59, 130, 246, 0)',
                      ],
                    }}
                    transition={{ duration: 2, repeat: Infinity, delay: index * 0.3 }}
                  >
                    <motion.div
                      className="w-full h-full rounded-full flex items-center justify-center text-white text-xs"
                      whileHover={{ rotate: 360 }}
                    >
                      {index + 1}
                    </motion.div>
                  </motion.div>
                ))}

                {/* Exploded View Components */}
                {explodedView && (
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                    <motion.div initial={{ y: 0, opacity: 1 }} animate={{ y: -200, opacity: 0.9 }} className="absolute">
                      <Cpu className="w-16 h-16 text-blue-500" />
                    </motion.div>
                    <motion.div initial={{ y: 0, opacity: 1 }} animate={{ y: 200, opacity: 0.9 }} className="absolute">
                      <Battery className="w-16 h-16 text-green-500" />
                    </motion.div>
                    <motion.div initial={{ x: 0, opacity: 1 }} animate={{ x: -200, opacity: 0.9 }} className="absolute">
                      <Zap className="w-16 h-16 text-yellow-500" />
                    </motion.div>
                    <motion.div initial={{ x: 0, opacity: 1 }} animate={{ x: 200, opacity: 0.9 }} className="absolute">
                      <Wifi className="w-16 h-16 text-purple-500" />
                    </motion.div>
                  </div>
                )}

                {/* Ambient particles */}
                {[...Array(10)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute w-2 h-2 bg-blue-500 rounded-full"
                    style={{
                      left: `${Math.random() * 100}%`,
                      top: `${Math.random() * 100}%`,
                    }}
                    animate={{
                      y: [0, -30, 0],
                      opacity: [0, 1, 0],
                    }}
                    transition={{
                      duration: 3,
                      repeat: Infinity,
                      delay: i * 0.3,
                    }}
                  />
                ))}
              </div>

              <p className="text-center text-muted-foreground text-sm mt-4">
                Drag to rotate • Click hotspots to explore
              </p>
            </div>
          </ScrollReveal>

          {/* Features & Specs */}
          <ScrollReveal direction="right">
            <div className="space-y-6">
              {/* Features */}
              <div className="bg-card p-6 rounded-2xl">
                <h3 className="mb-6">Key Features</h3>
                <div className="space-y-4">
                  {t.features.map((feature, index) => (
                    <motion.div
                      key={index}
                      className={`p-4 rounded-xl transition-all cursor-pointer ${
                        selectedFeature === index
                          ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white'
                          : 'bg-secondary hover:bg-secondary/70'
                      }`}
                      onClick={() => setSelectedFeature(selectedFeature === index ? null : index)}
                      whileHover={{ x: 10 }}
                    >
                      <div className="flex items-start gap-4">
                        <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                          selectedFeature === index ? 'bg-white/20' : 'bg-gradient-to-br from-blue-500 to-purple-500'
                        }`}>
                          <feature.icon className={`w-6 h-6 ${selectedFeature === index ? 'text-white' : 'text-white'}`} />
                        </div>
                        <div className="flex-1">
                          <h4 className="mb-1">{feature.title}</h4>
                          <p className={`text-sm ${selectedFeature === index ? 'text-white/90' : 'text-muted-foreground'}`}>
                            {feature.description}
                          </p>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>

              {/* Specifications */}
              <div className="bg-card p-6 rounded-2xl">
                <h3 className="mb-6">{t.specs.title}</h3>
                <div className="grid grid-cols-2 gap-4">
                  {t.specs.items.map((spec, index) => (
                    <ScrollReveal key={index} delay={index * 0.1}>
                      <motion.div
                        className="p-4 bg-secondary rounded-xl text-center"
                        whileHover={{ scale: 1.05, y: -5 }}
                      >
                        <p className="text-sm text-muted-foreground mb-1">{spec.label}</p>
                        <p className="text-xl bg-gradient-to-r from-blue-500 to-purple-500 bg-clip-text text-transparent">
                          {spec.value}
                        </p>
                      </motion.div>
                    </ScrollReveal>
                  ))}
                </div>
              </div>
            </div>
          </ScrollReveal>
        </div>

        {/* Feature Detail Modal */}
        <AnimatePresence>
          {selectedFeature !== null && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-6"
              onClick={() => setSelectedFeature(null)}
            >
              <motion.div
                initial={{ scale: 0.8, y: 50 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.8, y: 50 }}
                className="bg-card p-8 rounded-3xl max-w-lg w-full shadow-2xl"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="flex justify-between items-start mb-6">
                  <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-500 rounded-2xl flex items-center justify-center">
                    {(() => {
                      const Icon = t.features[selectedFeature].icon;
                      return <Icon className="w-8 h-8 text-white" />;
                    })()}
                  </div>
                  <button
                    onClick={() => setSelectedFeature(null)}
                    className="p-2 hover:bg-secondary rounded-lg"
                  >
                    <X className="w-6 h-6" />
                  </button>
                </div>
                <h3 className="mb-3">{t.features[selectedFeature].title}</h3>
                <p className="text-muted-foreground mb-6">
                  {t.features[selectedFeature].description}
                </p>
                <motion.div
                  className="p-6 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-2xl"
                  animate={{
                    boxShadow: [
                      '0 0 20px rgba(59, 130, 246, 0.3)',
                      '0 0 40px rgba(168, 85, 247, 0.5)',
                      '0 0 20px rgba(59, 130, 246, 0.3)',
                    ],
                  }}
                  transition={{ duration: 2, repeat: Infinity }}
                >
                  <p className="text-sm text-muted-foreground">
                    This component is crucial for delivering the optimal ISHARA experience,
                    ensuring precision, reliability, and seamless integration with the overall system.
                  </p>
                </motion.div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  );
}
