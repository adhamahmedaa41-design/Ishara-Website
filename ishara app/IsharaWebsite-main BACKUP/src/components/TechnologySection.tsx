import { motion } from 'motion/react';
import { Waves, Zap, Shield, Smartphone } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';
import { SensorSimulator } from './SensorSimulator';

interface TechnologySectionProps {
  language: 'en' | 'ar';
}

export function TechnologySection({ language }: TechnologySectionProps) {
  const content = {
    en: {
      title: 'Revolutionary Technology',
      subtitle: 'Advanced ultrasonic sensors combined with AI-powered safety systems',
      features: [
        {
          icon: Waves,
          title: 'Ultrasonic Sensors',
          description: 'Detect obstacles up to 2 meters away with precision accuracy'
        },
        {
          icon: Zap,
          title: 'Real-time Alerts',
          description: 'Instant haptic and audio feedback for immediate awareness'
        },
        {
          icon: Shield,
          title: 'AI Safety System',
          description: 'Smart algorithms predict and prevent potential hazards'
        },
        {
          icon: Smartphone,
          title: 'App Integration',
          description: 'Seamless connection to mobile app for enhanced control'
        }
      ],
      howItWorks: 'How It Works',
      steps: [
        { title: 'Detect', description: 'Sensors scan the environment continuously' },
        { title: 'Process', description: 'AI analyzes distance and obstacle type' },
        { title: 'Alert', description: 'User receives immediate feedback' },
        { title: 'Navigate', description: 'Confidently move through any space' }
      ]
    },
    ar: {
      title: 'تكنولوجيا ثورية',
      subtitle: 'أجهزة استشعار بالموجات فوق الصوتية المتقدمة مع أنظمة السلامة المدعومة بالذكاء الاصطناعي',
      features: [
        {
          icon: Waves,
          title: 'أجهزة استشعار بالموجات فوق الصوتية',
          description: 'اكتشاف العوائق حتى مسافة 2 متر بدقة عالية'
        },
        {
          icon: Zap,
          title: 'تنبيهات في الوقت الفعلي',
          description: 'ردود فعل لمسية وصوتية فورية للوعي الفوري'
        },
        {
          icon: Shield,
          title: 'نظام سلامة بالذكاء الاصطناعي',
          description: 'خوارزميات ذكية تتنبأ وتمنع المخاطر المحتملة'
        },
        {
          icon: Smartphone,
          title: 'التكامل مع التطبيق',
          description: 'اتصال سلس بتطبيق الهاتف المحمول لتحكم محسّن'
        }
      ],
      howItWorks: 'كيف يعمل',
      steps: [
        { title: 'الكشف', description: 'أجهزة الاستشعار تفحص البيئة باستمرار' },
        { title: 'المعالجة', description: 'الذكاء الاصطناعي يحلل المسافة ونوع العائق' },
        { title: 'التنبيه', description: 'يتلقى المستخدم ردود فعل فورية' },
        { title: 'التنقل', description: 'التحرك بثقة في أي مساحة' }
      ]
    }
  };

  const t = content[language];

  return (
    <section id="technology" className="min-h-screen py-32 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-b from-background via-[#14B8A6]/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        {/* Section Header */}
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                rotate: [0, 360],
              }}
              transition={{
                duration: 20,
                repeat: Infinity,
                ease: 'linear',
              }}
            >
              <Waves className="w-16 h-16 text-[#14B8A6]" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-20">
          {t.features.map((feature, index) => (
            <ScrollReveal key={index} delay={index * 0.1} direction="up">
              <motion.div
                className="bg-card p-8 rounded-2xl border-2 border-transparent hover:border-[#14B8A6] transition-all group"
                whileHover={{ y: -10 }}
              >
                <motion.div
                  className="w-16 h-16 mb-6 bg-gradient-to-br from-[#14B8A6] to-[#F97316] rounded-xl flex items-center justify-center"
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.5 }}
                >
                  <feature.icon className="w-8 h-8 text-white" />
                </motion.div>
                <h3 className="mb-3">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </motion.div>
            </ScrollReveal>
          ))}
        </div>

        {/* Interactive Sensor Demo */}
        <ScrollReveal direction="scale">
          <div className="mb-20">
            <SensorSimulator language={language} />
          </div>
        </ScrollReveal>

        {/* How It Works */}
        <ScrollReveal>
          <div className="text-center mb-12">
            <h2 className="mb-4">{t.howItWorks}</h2>
          </div>
        </ScrollReveal>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {t.steps.map((step, index) => (
            <ScrollReveal key={index} delay={index * 0.15} direction="up">
              <motion.div
                className="relative"
                initial={{ opacity: 0 }}
                whileInView={{ opacity: 1 }}
                viewport={{ once: true }}
              >
                {/* Connection Line */}
                {index < t.steps.length - 1 && (
                  <motion.div
                    className="hidden md:block absolute top-12 left-full w-full h-1 bg-gradient-to-r from-[#14B8A6] to-[#F97316]"
                    initial={{ scaleX: 0 }}
                    whileInView={{ scaleX: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: index * 0.15 + 0.5, duration: 0.5 }}
                  />
                )}

                <div className="bg-card p-8 rounded-2xl text-center relative">
                  <motion.div
                    className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-[#14B8A6] to-[#F97316] rounded-full flex items-center justify-center text-white text-3xl"
                    whileHover={{ scale: 1.1, rotate: 360 }}
                    transition={{ duration: 0.5 }}
                  >
                    {index + 1}
                  </motion.div>
                  <h3 className="mb-3">{step.title}</h3>
                  <p className="text-muted-foreground">{step.description}</p>
                </div>
              </motion.div>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}
