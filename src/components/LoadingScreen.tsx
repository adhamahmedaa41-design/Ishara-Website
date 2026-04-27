import { motion, AnimatePresence } from 'motion/react';
import { useEffect, useState } from 'react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface LoadingScreenProps {
  onComplete: () => void;
}

export function LoadingScreen({ onComplete }: LoadingScreenProps) {
  const [progress, setProgress] = useState(0);
  const [isComplete, setIsComplete] = useState(false);

  useEffect(() => {
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            setIsComplete(true);
            setTimeout(onComplete, 600);
          }, 500);
          return 100;
        }
        return prev + 2;
      });
    }, 30);

    return () => clearInterval(interval);
  }, [onComplete]);

  return (
    <AnimatePresence>
      {!isComplete && (
        <motion.div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-background"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, scale: 1.05 }}
          transition={{ duration: 0.6, ease: 'easeInOut' }}
        >
          {/* Animated background morphing blobs */}
          <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden>
            <motion.div
              className="absolute w-[500px] h-[500px] rounded-full opacity-[0.06]"
              style={{
                background: 'radial-gradient(circle, #14B8A6 0%, transparent 70%)',
                top: '20%',
                left: '10%',
              }}
              animate={{
                scale: [1, 1.3, 1],
                x: [0, 60, 0],
                y: [0, -40, 0],
                borderRadius: ['42% 58% 70% 30% / 45% 45% 55% 55%', '70% 30% 46% 54% / 30% 29% 71% 70%', '42% 58% 70% 30% / 45% 45% 55% 55%'],
              }}
              transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
            />
            <motion.div
              className="absolute w-[400px] h-[400px] rounded-full opacity-[0.05]"
              style={{
                background: 'radial-gradient(circle, #F97316 0%, transparent 70%)',
                bottom: '15%',
                right: '10%',
              }}
              animate={{
                scale: [1, 1.2, 1],
                x: [0, -50, 0],
                y: [0, 30, 0],
                borderRadius: ['30% 70% 35% 65% / 58% 68% 32% 42%', '42% 58% 70% 30% / 45% 45% 55% 55%', '30% 70% 35% 65% / 58% 68% 32% 42%'],
              }}
              transition={{ duration: 10, repeat: Infinity, ease: 'easeInOut' }}
            />
          </div>

          <div className="relative flex flex-col items-center">
            {/* Logo container with morph animation */}
            <motion.div
              className="text-center mb-10"
              initial={{ scale: 0.3, opacity: 0, filter: 'blur(20px)' }}
              animate={{ scale: 1, opacity: 1, filter: 'blur(0px)' }}
              transition={{ duration: 0.8, ease: [0.25, 0.46, 0.45, 0.94] }}
            >
              {/* Glowing ring behind logo */}
              <motion.div
                className="absolute inset-0 m-auto w-48 h-48 rounded-full"
                style={{
                  background: 'conic-gradient(from 0deg, #14B8A6, #F97316, #14B8A6)',
                  filter: 'blur(30px)',
                  opacity: 0.15,
                }}
                animate={{ rotate: 360 }}
                transition={{ duration: 4, repeat: Infinity, ease: 'linear' }}
              />

              {/* Logo with morphing glow */}
              <motion.div
                className="relative inline-block mb-6"
                animate={{
                  scale: [1, 1.05, 1],
                  filter: [
                    'drop-shadow(0 0 8px rgba(20,184,166,0.3))',
                    'drop-shadow(0 0 20px rgba(20,184,166,0.5))',
                    'drop-shadow(0 0 8px rgba(20,184,166,0.3))',
                  ],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: 'easeInOut',
                }}
              >
                <ImageWithFallback 
                  src="https://i.ibb.co/vCVYft2v/eng.png"
                  alt="ISHARA Logo"
                  className="w-44 h-44 object-contain mx-auto"
                />
              </motion.div>
              
              {/* Title with gradient reveal */}
              <motion.h1
                className="text-6xl bg-gradient-to-r from-[#14B8A6] to-[#F97316] bg-clip-text text-transparent"
                style={{ fontWeight: 700 }}
                initial={{ opacity: 0, y: 20, letterSpacing: '0.3em' }}
                animate={{ opacity: 1, y: 0, letterSpacing: '0.15em' }}
                transition={{ delay: 0.3, duration: 0.6 }}
              >
                ISHARA
              </motion.h1>
              
              <motion.p
                className="text-muted-foreground mt-2 tracking-widest uppercase text-sm"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5, duration: 0.5 }}
              >
                Empowering Independence
              </motion.p>
            </motion.div>

            {/* Progress Bar with gradient glow */}
            <motion.div
              className="w-80 relative"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.6 }}
            >
              <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                <motion.div
                  className="h-full rounded-full"
                  style={{
                    background: 'linear-gradient(90deg, #14B8A6, #F97316)',
                  }}
                  initial={{ width: 0 }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.3 }}
                />
              </div>
              {/* Glow under progress bar */}
              <motion.div
                className="absolute top-0 h-1.5 rounded-full blur-md opacity-60"
                style={{
                  background: 'linear-gradient(90deg, #14B8A6, #F97316)',
                }}
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.3 }}
              />
            </motion.div>

            <motion.p
              className="text-center mt-4 text-sm text-muted-foreground font-mono tabular-nums"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.8 }}
            >
              {progress}%
            </motion.p>

            {/* Floating Particles */}
            {[...Array(16)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute rounded-full"
                style={{
                  width: `${2 + Math.random() * 4}px`,
                  height: `${2 + Math.random() * 4}px`,
                  background: i % 2 === 0
                    ? `rgba(20, 184, 166, ${0.3 + Math.random() * 0.4})`
                    : `rgba(249, 115, 22, ${0.3 + Math.random() * 0.4})`,
                  left: `${-120 + Math.random() * 340}px`,
                  top: `${-120 + Math.random() * 340}px`,
                }}
                animate={{
                  y: [0, -(20 + Math.random() * 40), 0],
                  x: [0, (Math.random() - 0.5) * 30, 0],
                  opacity: [0, 0.8, 0],
                  scale: [0, 1, 0],
                }}
                transition={{
                  duration: 2.5 + Math.random() * 2,
                  repeat: Infinity,
                  delay: i * 0.15,
                  ease: 'easeInOut',
                }}
              />
            ))}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}