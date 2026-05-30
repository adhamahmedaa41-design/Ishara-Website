import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { AuthProvider } from '../hooks/useAuth';
import { CartProvider } from '../context/CartContext';

type Theme = 'light' | 'dark';
type Language = 'en' | 'ar';

interface AppContextType {
  theme: Theme;
  language: Language;
  toggleTheme: () => void;
  toggleLanguage: () => void;
  setTheme: (theme: Theme) => void;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
}

const translations = {
  en: {
    // Navigation
    'nav.home': 'Home',
    'nav.features': 'Features',
    'nav.technology': 'Technology',
    'nav.about': 'About',
    'nav.contact': 'Contact',

    // Hero
    'hero.title': 'Navigate Safely with ISHARA',
    'hero.subtitle': 'Revolutionary smart glasses for the visually impaired',
    'hero.cta': 'Explore Technology',

    // Common
    'common.loading': 'Loading...',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.next': 'Next',
    'common.back': 'Back',
  },
  ar: {
    // Navigation
    'nav.home': 'الرئيسية',
    'nav.features': 'المميزات',
    'nav.technology': 'التكنولوجيا',
    'nav.about': 'من نحن',
    'nav.contact': 'اتصل بنا',

    // Hero
    'hero.title': 'تنقل بأمان مع إشارة',
    'hero.subtitle': 'نظارات ذكية ثورية لضعاف البصر',
    'hero.cta': 'استكشف التكنولوجيا',

    // Common
    'common.loading': 'جاري التحميل...',
    'common.save': 'حفظ',
    'common.cancel': 'إلغاء',
    'common.next': 'التالي',
    'common.back': 'رجوع',
  }
};

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProviders({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window === 'undefined') return 'light';
    const saved = localStorage.getItem('ishara-theme');
    if (saved === 'light' || saved === 'dark') return saved;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  });

  const [language, setLanguageState] = useState<Language>(() => {
    if (typeof window === 'undefined') return 'en';
    const saved = localStorage.getItem('ishara-language');
    if (saved === 'en' || saved === 'ar') return saved;
    return 'en';
  });

  useEffect(() => {
    // Apply theme
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('ishara-theme', theme);
  }, [theme]);

  useEffect(() => {
    // Apply language and direction
    document.documentElement.setAttribute('dir', language === 'ar' ? 'rtl' : 'ltr');
    document.documentElement.setAttribute('lang', language);
    localStorage.setItem('ishara-language', language);
  }, [language]);

  const toggleTheme = () => {
    setThemeState(prev => prev === 'light' ? 'dark' : 'light');
  };

  const toggleLanguage = () => {
    setLanguageState(prev => prev === 'en' ? 'ar' : 'en');
  };

  const setTheme = (newTheme: Theme) => {
    setThemeState(newTheme);
  };

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
  };

  const t = (key: string): string => {
    return translations[language][key as keyof typeof translations['en']] || key;
  };

  return (
    <AppContext.Provider value={{ theme, language, toggleTheme, toggleLanguage, setTheme, setLanguage, t }}>
      <AuthProvider>
        <CartProvider>
          {children}
        </CartProvider>
      </AuthProvider>
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProviders');
  }
  return context;
}
