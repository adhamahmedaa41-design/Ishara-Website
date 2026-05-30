import { motion, useScroll, AnimatePresence } from 'motion/react';
import { ArrowUp } from 'lucide-react';
import { useState, useEffect } from 'react';

export function BackToTop() {
  const [isVisible, setIsVisible] = useState(false);
  const { scrollY } = useScroll();

  useEffect(() => {
    return scrollY.on('change', (latest) => {
      setIsVisible(latest > 300);
    });
  }, [scrollY]);

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.button
          initial={{ opacity: 0, scale: 0.5, y: 100 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.5, y: 100 }}
          onClick={scrollToTop}
          className="fixed bottom-8 right-8 z-50 w-14 h-14 bg-gradient-to-r from-[#14B8A6] to-[#F97316] rounded-full flex items-center justify-center text-white shadow-2xl hover:shadow-3xl group"
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
        >
          <motion.div
            animate={{ y: [0, -3, 0] }}
            transition={{ duration: 1.5, repeat: Infinity }}
          >
            <ArrowUp className="w-6 h-6" />
          </motion.div>
          
          {/* Ripple effect */}
          <motion.div
            className="absolute inset-0 rounded-full border-2 border-white/50"
            initial={{ scale: 1, opacity: 0 }}
            animate={{
              scale: [1, 1.5, 1],
              opacity: [0.5, 0, 0.5],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
            }}
          />
        </motion.button>
      )}
    </AnimatePresence>
  );
}
