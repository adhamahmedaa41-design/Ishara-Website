import { motion } from 'motion/react';
import { ChevronDown, Sparkles } from 'lucide-react';
import { MagneticButton } from './MagneticButton';
import { useEffect, useState } from 'react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface HeroSectionProps {
  language: 'en' | 'ar';
}

export function HeroSection({ language }: HeroSectionProps) {
  const [typedText, setTypedText] = useState('');
  const fullText = language === 'en'
    ? 'Empowering Independence Through Innovation'
    : 'تمكين الاستقلالية من خلال الابتكار';

  useEffect(() => {
    let index = 0;
    setTypedText('');
    const timer = setInterval(() => {
      if (index < fullText.length) {
        setTypedText((prev) => prev + fullText.charAt(index));
        index++;
      } else {
        clearInterval(timer);
      }
    }, 50);

    return () => clearInterval(timer);
  }, [fullText]);

  const content = {
    en: {
      title: 'ISHARA',
      subtitle: 'Smart Glasses for the Visually Impaired',
      description: 'Revolutionary wearable technology that combines ultrasonic sensors with AI-powered safety systems to provide independence and confidence.',
      cta: 'Explore Technology'
    },
    ar: {
      title: 'إشارة',
      subtitle: 'نظارات ذكية لضعاف البصر',
      description: 'تقنية يمكن ارتداؤها ثورية تجمع بين أجهزة الاستشعار بالموجات فوق الصوتية وأنظمة السلامة المدعومة بالذكاء الاصطناعي لتوفير الاستقلالية والثقة.',
      cta: 'استكشف التكنولوجيا'
    }
  };

  const t = content[language];

  return (
    <section id="hero" className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Animated Background - using CSS variable for theme-aware gradient */}
      <div className="absolute inset-0 animate-gradient" style={{
        background: `linear-gradient(135deg, var(--ishara-brand-teal)/0.2 0%, var(--background) 50%, var(--ishara-brand-orange)/0.2 100%)`,
        backgroundSize: '200% 200%'
      }} />

      {/* Floating Shapes - theme-aware */}
      <motion.div
        className="absolute top-20 left-10 w-72 h-72 rounded-full blur-3xl"
        style={{ backgroundColor: 'var(--ishara-brand-teal)', opacity: 0.1 }}
        animate={{
          scale: [1, 1.2, 1],
          x: [0, 50, 0],
          y: [0, 30, 0],
        }}
        transition={{
          duration: 8,
          repeat: Infinity,
          ease: 'easeInOut'
        }}
      />
      <motion.div
        className="absolute bottom-20 right-10 w-96 h-96 rounded-full blur-3xl"
        style={{ backgroundColor: 'var(--ishara-brand-orange)', opacity: 0.1 }}
        animate={{
          scale: [1, 1.3, 1],
          x: [0, -50, 0],
          y: [0, -30, 0],
        }}
        transition={{
          duration: 10,
          repeat: Infinity,
          ease: 'easeInOut'
        }}
      />

      {/* Content */}
      <div className="relative z-10 container mx-auto px-6 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="mb-6"
        >
          <motion.div
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass mb-8"
            animate={{
              boxShadow: [
                '0 0 20px var(--ishara-brand-teal)33',
                '0 0 40px var(--ishara-brand-orange)88',
                '0 0 20px var(--ishara-brand-teal)33',
              ]
            }}
            transition={{ duration: 3, repeat: Infinity }}
          >
            <Sparkles className="w-4 h-4" style={{ color: 'var(--ishara-brand-teal)' }} />
            <span className="text-sm">Innovation in Accessibility</span>
          </motion.div>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="text-8xl md:text-9xl mb-4 text-gradient"
          style={{ fontWeight: 700, lineHeight: 1.1 }}
        >
          {t.title}
        </motion.h1>

        <motion.h2
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="text-3xl md:text-4xl mb-6 text-muted-foreground"
        >
          {t.subtitle}
        </motion.h2>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="h-16 mb-8"
        >
          <p className="text-xl text-muted-foreground">
            {typedText}
            <motion.span
              animate={{ opacity: [1, 0, 1] }}
              transition={{ duration: 0.8, repeat: Infinity }}
            >
              |
            </motion.span>
          </p>
        </motion.div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="text-lg text-muted-foreground max-w-2xl mx-auto mb-12"
        >
          {t.description}
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 1 }}
          className="flex flex-wrap items-center justify-center gap-6"
        >
          <MagneticButton
            className="px-8 py-4 bg-gradient-ishara text-white rounded-full shadow-2xl"
            onClick={() => document.getElementById('technology')?.scrollIntoView({ behavior: 'smooth' })}
          >
            <span className="flex items-center gap-2">
              {t.cta}
              <motion.div
                animate={{ x: [0, 5, 0] }}
                transition={{ duration: 1.5, repeat: Infinity }}
              >
                →
              </motion.div>
            </span>
          </MagneticButton>
        </motion.div>

        {/* 3D Glasses Visualization */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 1.2 }}
          className="mt-20 relative"
        >
          <motion.div
            className="inline-block relative"
            animate={{
              y: [0, -20, 0],
              rotateY: [0, 10, -10, 0],
            }}
            transition={{
              duration: 6,
              repeat: Infinity,
              ease: 'easeInOut'
            }}
          >
            <div className="text-9xl opacity-80">
              <ImageWithFallback
                src="https://i.ibb.co/vCVYft2v/eng.png"
                alt="ISHARA Logo"
                className="w-48 h-48 object-contain"
              />
            </div>
            <motion.div
              className="absolute inset-0 blur-2xl opacity-50"
              style={{ background: 'var(--ishara-gradient)' }}
              animate={{
                scale: [1, 1.2, 1],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
              }}
            />
          </motion.div>
        </motion.div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.5 }}
          className="absolute bottom-10 left-1/2 -translate-x-1/2"
        >
          <motion.div
            animate={{ y: [0, 10, 0] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="flex flex-col items-center gap-2 text-muted-foreground"
          >
            <span className="text-sm">Scroll to Explore</span>
            <ChevronDown className="w-6 h-6" />
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}