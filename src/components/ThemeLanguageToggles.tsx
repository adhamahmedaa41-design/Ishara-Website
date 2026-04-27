import { motion } from 'motion/react';
import { Sun, Moon, Languages } from 'lucide-react';
import { useApp } from './AppProviders';

export function ThemeLanguageToggles() {
  const { theme, language, toggleTheme, toggleLanguage } = useApp();
  const isRTL = language === 'ar';

  return (
    <div className={`flex items-center gap-3 ${isRTL ? 'flex-row-reverse' : ''}`}>
      {/* Language Toggle */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={toggleLanguage}
        className="relative flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-teal-500/10 to-orange-500/10 border border-border hover:border-[var(--ishara-brand-teal)] transition-all group"
        aria-label="Toggle language"
      >
        <Languages className="w-4 h-4 text-foreground group-hover:text-[var(--ishara-brand-teal)] transition-colors" />
        <motion.span
          key={language}
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-sm font-medium text-foreground group-hover:text-[var(--ishara-brand-teal)] transition-colors"
        >
          {language.toUpperCase()}
        </motion.span>
      </motion.button>

      {/* Theme Toggle */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={toggleTheme}
        className="relative w-10 h-10 rounded-full bg-gradient-to-r from-teal-500/10 to-orange-500/10 border border-border hover:border-[var(--ishara-brand-orange)] flex items-center justify-center transition-all group overflow-hidden"
        aria-label="Toggle theme"
      >
        <motion.div
          initial={false}
          animate={{
            rotate: theme === 'dark' ? 180 : 0,
            scale: theme === 'dark' ? 0.8 : 1,
          }}
          transition={{ duration: 0.3, ease: 'easeInOut' }}
          className="relative"
        >
          {theme === 'light' ? (
            <Sun className="w-5 h-5 text-foreground group-hover:text-[var(--ishara-brand-orange)] transition-colors" />
          ) : (
            <Moon className="w-5 h-5 text-foreground group-hover:text-[var(--ishara-brand-orange)] transition-colors" />
          )}
        </motion.div>
      </motion.button>
    </div>
  );
}
