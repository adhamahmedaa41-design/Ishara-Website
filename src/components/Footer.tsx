import { motion } from 'motion/react';
import { Heart } from 'lucide-react';
import { FaInstagram, FaFacebookF, FaTiktok } from 'react-icons/fa';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface FooterProps {
  language: 'en' | 'ar';
}

export function Footer({ language }: FooterProps) {
  const content = {
    en: {
      tagline: 'Empowering independence through innovation',
      madeWith: 'Made with',
      by: 'by the ISHARA Team',
      quickLinks: {
        title: 'Quick Links',
        links: ['Home', 'Technology', 'Safety', 'Learning', 'Hardware', 'Contact']
      },
      company: {
        title: 'Company',
        links: ['About Us', 'Careers', 'Press', 'Blog']
      },
      legal: {
        title: 'Legal',
        links: ['Privacy Policy', 'Terms of Service', 'Cookie Policy']
      },
      rights: '© 2025 ISHARA. All rights reserved.'
    },
    ar: {
      tagline: 'تمكين الاستقلالية من خلال الابتكار',
      madeWith: 'صنع بـ',
      by: 'بواسطة فريق إشارة',
      quickLinks: {
        title: 'روابط سريعة',
        links: ['الرئيسية', 'التكنولوجيا', 'السلامة', 'التعلم', 'الأجهزة', 'اتصل بنا']
      },
      company: {
        title: 'الشركة',
        links: ['من نحن', 'الوظائف', 'الصحافة', 'المدونة']
      },
      legal: {
        title: 'قانوني',
        links: ['سياسة الخصوصية', 'شروط الخدمة', 'سياسة ملفات تعريف الارتباط']
      },
      rights: '© 2025 إشارة. جميع الحقوق محفوظة.'
    }
  };

  const t = content[language];

  // Real Ishara social handles — open in new tab with rel=noopener,noreferrer.
  const socialLinks: {
    icon: React.ComponentType<{ className?: string }>;
    label: string;
    href: string;
    hoverGradient: string;
  }[] = [
    {
      icon: FaInstagram,
      label: 'Instagram — @ishara.aast',
      href: 'https://www.instagram.com/ishara.aast?igsh=MTduNWowbGVjcGlibA==',
      hoverGradient: 'from-[#f09433] via-[#e6683c] to-[#bc1888]',
    },
    {
      icon: FaFacebookF,
      label: 'Facebook — Ishara',
      href: 'https://www.facebook.com/share/1bZkhGQtH6/?mibextid=wwXIfr',
      hoverGradient: 'from-[#1877F2] to-[#0a5fd1]',
    },
    {
      icon: FaTiktok,
      label: 'TikTok — @ishara_aast',
      href: 'https://www.tiktok.com/@ishara_aast?_r=1&_t=ZS-95nlfXGklTW',
      hoverGradient: 'from-[#25F4EE] via-black to-[#FE2C55]',
    },
  ];

  return (
    <footer className="relative py-20 overflow-hidden border-t border-border">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-t from-[#14B8A6]/5 via-background to-background" />

      <div className="container mx-auto px-6 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          {/* Brand Column */}
          <div className="lg:col-span-1">
            <motion.div
              className="flex items-center gap-3 mb-6"
              whileHover={{ scale: 1.05 }}
            >
              <motion.div
                className="w-12 h-12 bg-gradient-to-br from-[#14B8A6] to-[#F97316] rounded-xl flex items-center justify-center"
                animate={{
                  rotate: [0, 5, -5, 0],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: 'easeInOut'
                }}
              >
                <ImageWithFallback 
                  src="https://i.ibb.co/vCVYft2v/eng.png"
                  alt="ISHARA Logo"
                  className="w-8 h-8 object-contain"
                />
              </motion.div>
              <span className="text-2xl">ISHARA</span>
            </motion.div>
            <p className="text-muted-foreground mb-6">
              {t.tagline}
            </p>
            
            {/* Social Links */}
            <nav
              aria-label={language === 'ar' ? 'روابط التواصل الاجتماعي' : 'Social media links'}
              className="flex gap-3"
            >
              {socialLinks.map((social, index) => (
                <motion.a
                  key={social.label}
                  href={social.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={social.label}
                  title={social.label}
                  className={`w-11 h-11 rounded-xl bg-secondary hover:bg-gradient-to-br ${social.hoverGradient} flex items-center justify-center transition-all duration-300 group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]`}
                  whileHover={{ scale: 1.12, rotate: -4, y: -2 }}
                  whileTap={{ scale: 0.92 }}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <social.icon className="w-5 h-5 text-muted-foreground group-hover:text-white transition-colors" />
                </motion.a>
              ))}
            </nav>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="mb-6">{t.quickLinks.title}</h4>
            <ul className="space-y-3">
              {t.quickLinks.links.map((link, index) => (
                <motion.li
                  key={link}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                >
                  <motion.a
                    href="#"
                    className="text-muted-foreground hover:text-foreground transition-colors inline-block"
                    whileHover={{ x: 5 }}
                  >
                    {link}
                  </motion.a>
                </motion.li>
              ))}
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="mb-6">{t.company.title}</h4>
            <ul className="space-y-3">
              {t.company.links.map((link, index) => (
                <motion.li
                  key={link}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                >
                  <motion.a
                    href="#"
                    className="text-muted-foreground hover:text-foreground transition-colors inline-block"
                    whileHover={{ x: 5 }}
                  >
                    {link}
                  </motion.a>
                </motion.li>
              ))}
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="mb-6">{t.legal.title}</h4>
            <ul className="space-y-3">
              {t.legal.links.map((link, index) => (
                <motion.li
                  key={link}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                >
                  <motion.a
                    href="#"
                    className="text-muted-foreground hover:text-foreground transition-colors inline-block"
                    whileHover={{ x: 5 }}
                  >
                    {link}
                  </motion.a>
                </motion.li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-8 border-t border-border">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <motion.p
              className="text-muted-foreground text-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
            >
              {t.rights}
            </motion.p>
            
            <motion.div
              className="flex items-center gap-2 text-muted-foreground text-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.6 }}
            >
              <span>{t.madeWith}</span>
              <motion.div
                animate={{
                  scale: [1, 1.2, 1],
                }}
                transition={{
                  duration: 1,
                  repeat: Infinity,
                }}
              >
                <Heart className="w-4 h-4 text-red-500 fill-red-500" />
              </motion.div>
              <span>{t.by}</span>
            </motion.div>
          </div>
        </div>

        {/* Decorative elements */}
        <motion.div
          className="absolute -bottom-10 -right-10 w-40 h-40 bg-gradient-to-br from-[#14B8A6] to-[#F97316] rounded-full blur-3xl opacity-20"
          animate={{
            scale: [1, 1.2, 1],
            rotate: [0, 90, 0],
          }}
          transition={{
            duration: 10,
            repeat: Infinity,
          }}
        />
        <motion.div
          className="absolute -top-10 -left-10 w-40 h-40 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full blur-3xl opacity-20"
          animate={{
            scale: [1, 1.3, 1],
            rotate: [0, -90, 0],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
          }}
        />
      </div>
    </footer>
  );
}