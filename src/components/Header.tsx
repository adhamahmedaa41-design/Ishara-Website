import { Link, useLocation } from 'react-router-dom';
import { motion, useScroll, useTransform, AnimatePresence } from 'motion/react';
import { Moon, Sun, Languages, LogOut, Menu, X, ShoppingBag, Download, Smartphone, QrCode } from 'lucide-react';
import { useState, useEffect } from 'react';
import { useApp } from './AppProviders';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { useAuth } from '../hooks/useAuth';
import { UserAvatar } from './UserAvatar';
import { CartIconButton } from './cart/CartIconButton';

/* ── Download App Modal ─────────────────────────────────── */
function DownloadModal({ open, onClose, language }: { open: boolean; onClose: () => void; language: 'en' | 'ar' }) {
  if (!open) return null;
  const L = language === 'ar'
    ? { title: 'حمّل تطبيق إشارة', subtitle: 'امسح رمز QR أو اختر متجرك', ios: 'App Store', android: 'Google Play', close: 'إغلاق' }
    : { title: 'Download Ishara App', subtitle: 'Scan the QR code or choose your store', ios: 'App Store', android: 'Google Play', close: 'Close' };
  return (
    <>
      <motion.div
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm" onClick={onClose}
      />
      <motion.div
        initial={{ opacity: 0, scale: 0.92, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.92, y: 20 }}
        transition={{ type: 'spring', damping: 25, stiffness: 350 }}
        className="fixed z-[61] inset-x-4 top-[15vh] sm:inset-auto sm:left-1/2 sm:top-1/2 sm:-translate-x-1/2 sm:-translate-y-1/2 w-auto sm:w-[420px] bg-card border border-border rounded-3xl shadow-2xl overflow-hidden"
      >
        {/* Gradient header */}
        <div className="bg-gradient-to-r from-[#14B8A6] to-[#F97316] p-6 text-center text-white">
          <Smartphone className="w-10 h-10 mx-auto mb-3 drop-shadow-lg" />
          <h2 className="text-xl font-bold">{L.title}</h2>
          <p className="text-sm text-white/80 mt-1">{L.subtitle}</p>
        </div>
        <div className="p-6 space-y-5">
          {/* QR Code placeholder */}
          <div className="mx-auto w-40 h-40 rounded-2xl bg-muted border-2 border-dashed border-border flex flex-col items-center justify-center gap-2">
            <QrCode className="w-16 h-16 text-muted-foreground/40" />
            <span className="text-xs text-muted-foreground">QR Code</span>
          </div>
          {/* Store buttons */}
          <div className="grid grid-cols-2 gap-3">
            <a href="#" className="flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-black text-white text-sm font-medium hover:bg-gray-800 transition-colors">
              <svg viewBox="0 0 24 24" className="w-5 h-5 fill-current"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
              {L.ios}
            </a>
            <a href="#" className="flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-black text-white text-sm font-medium hover:bg-gray-800 transition-colors">
              <svg viewBox="0 0 24 24" className="w-5 h-5 fill-current"><path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.302 2.302-2.302 2.302-2.598-2.302 2.598-2.302zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.635z"/></svg>
              {L.android}
            </a>
          </div>
        </div>
        <div className="px-6 pb-5">
          <button onClick={onClose} className="w-full py-2.5 rounded-xl text-sm font-medium text-muted-foreground hover:bg-accent transition-colors">{L.close}</button>
        </div>
      </motion.div>
    </>
  );
}

export function Header() {
  const { theme, language, toggleTheme, toggleLanguage } = useApp();
  const { user, isAuthenticated, logout } = useAuth();
  const { scrollY } = useScroll();
  const location = useLocation();
  const [activeSection, setActiveSection] = useState('hero');
  const [mobileOpen, setMobileOpen] = useState(false);
  const [downloadOpen, setDownloadOpen] = useState(false);

  const headerBg = useTransform(scrollY, [0, 80], [0, 1]);
  const isRTL = language === 'ar';
  const isHome = location.pathname === '/';

  const sectionItems = [
    { id: 'hero', label: { en: 'Home', ar: 'الرئيسية' } },
    { id: 'technology', label: { en: 'Technology', ar: 'التكنولوجيا' } },
    { id: 'safety', label: { en: 'Safety', ar: 'السلامة' } },
    { id: 'learning', label: { en: 'Learning', ar: 'التعلم' } },
    { id: 'hardware', label: { en: 'Hardware', ar: 'الأجهزة' } },
    { id: 'about', label: { en: 'About', ar: 'عنا' } },
    { id: 'contact', label: { en: 'Contact', ar: 'اتصل بنا' } }
  ];

  useEffect(() => {
    if (!isHome) return;
    const handleScroll = () => {
      const sections = sectionItems.map(item => document.getElementById(item.id));
      const scrollPosition = window.scrollY + 200;
      for (let i = sections.length - 1; i >= 0; i--) {
        const section = sections[i];
        if (section && section.offsetTop <= scrollPosition) {
          setActiveSection(sectionItems[i].id);
          break;
        }
      }
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [isHome]);

  // Close mobile menu on route change
  useEffect(() => { setMobileOpen(false); }, [location.pathname]);

  const scrollToSection = (id: string) => {
    if (!isHome) {
      window.location.href = `/#${id}`;
      return;
    }
    const element = document.getElementById(id);
    if (element) element.scrollIntoView({ behavior: 'smooth' });
    setMobileOpen(false);
  };

  return (
    <>
      <motion.header
        className="fixed top-0 left-0 right-0 z-50"
        style={{
          backgroundColor: useTransform(headerBg, [0, 1], ['rgba(15,23,42,0)', 'rgba(15,23,42,0.85)']),
          backdropFilter: useTransform(headerBg, [0, 1], ['blur(0px)', 'blur(16px)']),
          borderBottom: useTransform(headerBg, [0, 1], ['1px solid transparent', '1px solid rgba(255,255,255,0.06)']),
        }}
      >
        <div className="container mx-auto px-6 py-3">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-3 cursor-pointer shrink-0">
              <motion.div
                className="flex items-center gap-3"
                whileHover={{ scale: 1.05 }}
              >
                <motion.div
                  className="h-14 flex items-center justify-center"
                  animate={{ rotate: [0, 5, -5, 0] }}
                  transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
                >
                  <ImageWithFallback
                    src="https://i.ibb.co/vCVYft2v/eng.png"
                    alt="ISHARA Logo"
                    className="h-14 w-auto object-contain drop-shadow-[0_0_12px_rgba(20,184,166,0.3)]"
                  />
                </motion.div>
              </motion.div>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden lg:flex items-center gap-1">
              {sectionItems.map((item) => (
                <motion.button
                  key={item.id}
                  onClick={() => scrollToSection(item.id)}
                  className="relative px-3 py-2 text-sm rounded-lg hover:bg-white/5 transition-colors"
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.96 }}
                >
                  <span className={activeSection === item.id ? 'text-white font-medium' : 'text-white/60'}>
                    {item.label[language]}
                  </span>
                  {activeSection === item.id && (
                    <motion.div
                      className="absolute bottom-0 left-2 right-2 h-0.5 rounded-full"
                      style={{ background: 'linear-gradient(90deg, #14B8A6, #F97316)' }}
                      layoutId="activeSection"
                      transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                    />
                  )}
                </motion.button>
              ))}

              {/* Products Link — always visible */}
              <Link to="/products">
                <motion.div
                  className={`flex items-center gap-1.5 px-4 py-2 rounded-full text-sm font-medium transition-all ${
                    location.pathname.startsWith('/products')
                      ? 'bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white shadow-lg shadow-teal-500/20'
                      : 'bg-white/5 text-white/80 hover:bg-white/10 hover:text-white border border-white/10'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <ShoppingBag className="w-4 h-4" />
                  {language === 'ar' ? 'المنتجات' : 'Products'}
                </motion.div>
              </Link>

            </nav>

            {/* Desktop Controls */}
            <div className="hidden lg:flex items-center gap-2">
              <motion.button
                onClick={toggleTheme}
                className="p-2.5 rounded-xl hover:bg-white/10 text-white/70 hover:text-white transition-colors"
                whileHover={{ scale: 1.1, rotate: 180 }}
                whileTap={{ scale: 0.9 }}
                transition={{ duration: 0.3 }}
                aria-label={theme === 'light' ? 'Switch to dark mode' : 'Switch to light mode'}
              >
                {theme === 'light' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
              </motion.button>

              <motion.button
                onClick={toggleLanguage}
                className="px-3 py-2 rounded-xl hover:bg-white/10 flex items-center gap-2 text-white/70 hover:text-white text-sm transition-colors"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Languages className="w-4 h-4" />
                <span>{language === 'en' ? 'عربي' : 'EN'}</span>
              </motion.button>

              {/* Download App icon (desktop controls) */}
              <motion.button
                onClick={() => setDownloadOpen(true)}
                className="p-2.5 rounded-xl hover:bg-white/10 text-white/70 hover:text-white transition-colors"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                aria-label={language === 'ar' ? 'حمّل التطبيق' : 'Download App'}
              >
                <Download className="w-5 h-5" />
              </motion.button>

              <CartIconButton />

              {isAuthenticated ? (
                <div className="flex items-center gap-2 ml-1">
                  <Link
                    to="/profile"
                    className="p-1 rounded-full hover:ring-2 hover:ring-[#14B8A6]/40 transition-all"
                    title="Profile"
                  >
                    <UserAvatar user={user ?? null} size={34} className="ring-0" ringClassName="" />
                  </Link>
                  <motion.button
                    onClick={logout}
                    className="p-2.5 rounded-xl hover:bg-red-500/10 text-white/60 hover:text-red-400 transition-colors"
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    title="Sign Out"
                  >
                    <LogOut className="w-4 h-4" />
                  </motion.button>
                </div>
              ) : (
                <Link to="/login">
                  <motion.div
                    className="ml-1 px-5 py-2.5 bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-full text-sm font-semibold shadow-lg shadow-teal-500/25 hover:shadow-xl hover:shadow-teal-500/35"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {language === 'ar' ? 'تسجيل الدخول' : 'Sign In'}
                  </motion.div>
                </Link>
              )}
            </div>

            {/* Mobile: cart + hamburger */}
            <div className="flex lg:hidden items-center gap-2">
              <CartIconButton />
              <motion.button
                onClick={() => setMobileOpen(!mobileOpen)}
                className="p-2.5 rounded-xl hover:bg-white/10 text-white transition-colors"
                whileTap={{ scale: 0.9 }}
                aria-label="Toggle menu"
              >
                {mobileOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </motion.button>
            </div>
          </div>
        </div>
      </motion.header>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
              onClick={() => setMobileOpen(false)}
            />
            <motion.nav
              initial={{ x: isRTL ? -320 : 320, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: isRTL ? -320 : 320, opacity: 0 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className={`fixed top-0 ${isRTL ? 'left-0' : 'right-0'} z-50 w-80 h-full bg-[#0f172a]/95 backdrop-blur-xl border-l border-white/5 shadow-2xl flex flex-col lg:hidden`}
            >
              <div className="p-6 border-b border-white/5">
                <div className="flex items-center justify-between">
                  <ImageWithFallback
                    src="https://i.ibb.co/vCVYft2v/eng.png"
                    alt="ISHARA"
                    className="h-10 w-auto"
                  />
                  <button onClick={() => setMobileOpen(false)} className="p-2 rounded-xl hover:bg-white/10 text-white/60">
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>

              <div className="flex-1 overflow-y-auto py-4 px-4 space-y-1">
                {sectionItems.map((item, i) => (
                  <motion.button
                    key={item.id}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.04 }}
                    onClick={() => scrollToSection(item.id)}
                    className={`w-full text-left px-4 py-3 rounded-xl text-sm transition-colors ${
                      activeSection === item.id
                        ? 'bg-gradient-to-r from-[#14B8A6]/15 to-transparent text-white font-medium border-l-2 border-[#14B8A6]'
                        : 'text-white/60 hover:text-white hover:bg-white/5'
                    }`}
                  >
                    {item.label[language]}
                  </motion.button>
                ))}

                <Link
                  to="/products"
                  className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-sm font-medium text-[#14B8A6] hover:bg-[#14B8A6]/10 transition-colors"
                  onClick={() => setMobileOpen(false)}
                >
                  <ShoppingBag className="w-4 h-4" />
                  {language === 'ar' ? 'المنتجات' : 'Products'}
                </Link>

                {/* Download App link in mobile */}
                <button
                  onClick={() => { setMobileOpen(false); setDownloadOpen(true); }}
                  className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-sm font-medium text-[#F97316] hover:bg-[#F97316]/10 transition-colors"
                >
                  <Download className="w-4 h-4" />
                  {language === 'ar' ? 'حمّل التطبيق' : 'Download App'}
                </button>
              </div>

              <div className="p-4 border-t border-white/5 space-y-3">
                <div className="flex gap-2">
                  <button
                    onClick={toggleTheme}
                    className="flex-1 py-2.5 rounded-xl bg-white/5 text-white/80 text-sm flex items-center justify-center gap-2 hover:bg-white/10 transition-colors"
                  >
                    {theme === 'light' ? <Moon className="w-4 h-4" /> : <Sun className="w-4 h-4" />}
                    {theme === 'light' ? 'Dark' : 'Light'}
                  </button>
                  <button
                    onClick={toggleLanguage}
                    className="flex-1 py-2.5 rounded-xl bg-white/5 text-white/80 text-sm flex items-center justify-center gap-2 hover:bg-white/10 transition-colors"
                  >
                    <Languages className="w-4 h-4" />
                    {language === 'en' ? 'عربي' : 'English'}
                  </button>
                </div>

                {isAuthenticated ? (
                  <div className="flex items-center gap-3 p-3 rounded-xl bg-white/5">
                    <UserAvatar user={user ?? null} size={36} className="ring-0" ringClassName="" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-white truncate">{user?.name}</p>
                      <Link
                        to="/profile"
                        className="text-xs text-[#14B8A6] hover:underline"
                        onClick={() => setMobileOpen(false)}
                      >
                        {language === 'ar' ? 'الملف الشخصي' : 'View Profile'}
                      </Link>
                    </div>
                    <button
                      onClick={() => { logout(); setMobileOpen(false); }}
                      className="p-2 rounded-lg hover:bg-red-500/10 text-white/60 hover:text-red-400"
                    >
                      <LogOut className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  <Link
                    to="/login"
                    className="block w-full py-3 text-center bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-xl font-semibold shadow-lg"
                    onClick={() => setMobileOpen(false)}
                  >
                    {language === 'ar' ? 'تسجيل الدخول' : 'Sign In'}
                  </Link>
                )}
              </div>
            </motion.nav>
          </>
        )}
      </AnimatePresence>

      {/* Download App Modal */}
      <AnimatePresence>
        <DownloadModal open={downloadOpen} onClose={() => setDownloadOpen(false)} language={language} />
      </AnimatePresence>
    </>
  );
}