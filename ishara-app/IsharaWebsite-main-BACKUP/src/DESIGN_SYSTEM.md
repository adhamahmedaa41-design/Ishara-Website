# ISHARA Design System Documentation

## Overview
This document outlines the comprehensive design system for the ISHARA accessibility platform, featuring seamless dual-theme (Light/Dark) and bilingual (English LTR / Arabic RTL) support across both the cinematic website and mobile app.

---

## 🎨 Semantic Color Tokens

### Light Mode Tokens
```css
--ishara-brand-teal: #14B8A6;        /* Primary brand color */
--ishara-brand-orange: #F97316;      /* Secondary brand color */
--ishara-brand-teal-light: #5EEAD4;  /* Light teal accent */
--ishara-brand-orange-light: #FB923C; /* Light orange accent */

--background: #ffffff;                /* Main background */
--foreground: oklch(0.145 0 0);      /* Main text color */
--card: #ffffff;                      /* Card background */
--border: rgba(0, 0, 0, 0.1);        /* Border color */
--muted: #ececf0;                    /* Muted elements */
--accent: #e9ebef;                    /* Accent elements */
```

### Dark Mode Tokens
```css
--ishara-brand-teal: #2DD4BF;        /* Adjusted for dark mode */
--ishara-brand-orange: #FB923C;      /* Adjusted for dark mode */

--background: #0F172A;                /* Dark background */
--foreground: #F1F5F9;                /* Light text */
--card: #1E293B;                      /* Dark card background */
--border: #334155;                    /* Subtle borders */
--muted: #334155;                     /* Muted dark elements */
--accent: #334155;                    /* Dark accent elements */
```

### Usage in Components
```tsx
// Use semantic tokens instead of raw colors
className="bg-card text-foreground border-border"

// For brand colors
style={{ color: 'var(--ishara-brand-teal)' }}
```

---

## 🔤 Typography System

### Font Families
- **English (LTR)**: `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
- **Arabic (RTL)**: `'Almarai', 'Tahoma', 'Arabic Typesetting', sans-serif`

### Typography Scales
Automatically applied based on `lang` attribute:

```html
<!-- English -->
<html lang="en">
  <!-- Uses Inter font family -->
</html>

<!-- Arabic -->
<html lang="ar" dir="rtl">
  <!-- Uses Almarai font family -->
</html>
```

### Font Weights
- Normal: 400
- Medium: 500
- Semibold: 600
- Bold: 700
- Extrabold: 800

---

## 🌐 Language & Direction System

### Context Provider
The unified `AppProviders` component manages global theme and language state:

```tsx
import { AppProviders, useApp } from './components/AppProviders';

// Wrap your app
<AppProviders>
  <YourApp />
</AppProviders>

// Use in components
const { theme, language, toggleTheme, toggleLanguage, t } = useApp();
```

### Translation Function
```tsx
const { t } = useApp();

// Use translation keys
<h1>{t('hero.title')}</h1>
// English: "Navigate Safely with ISHARA"
// Arabic: "تنقل بأمان مع إشارة"
```

### RTL Layout Principles

#### 1. Flexbox Direction
```tsx
const isRTL = language === 'ar';

<div className={`flex ${isRTL ? 'flex-row-reverse' : ''}`}>
  {/* Content automatically mirrors */}
</div>
```

#### 2. Text Alignment
```tsx
<div className={isRTL ? 'text-right' : 'text-left'}>
  {/* Text aligns correctly */}
</div>
```

#### 3. Icon Mirroring
```tsx
import { ChevronRight, ChevronLeft } from 'lucide-react';

const ChevronIcon = isRTL ? ChevronLeft : ChevronRight;
<ChevronIcon className="w-5 h-5" />
```

#### 4. Directional Spacing
```tsx
// Instead of: pl-4 pr-8
// Use: ps-4 pe-8 (start/end logical properties)

// Or conditionally:
className={isRTL ? 'pr-4' : 'pl-4'}
```

---

## 🎯 Component Examples

### 1. Header with Theme & Language Toggles
```tsx
import { Header } from './components/Header';
import { useApp } from './components/AppProviders';

export function WebsiteApp() {
  const { theme, language } = useApp();
  
  return (
    <>
      <Header />
      {/* Header automatically uses global theme/language */}
    </>
  );
}
```

### 2. RTL-Aware Card Component
```tsx
const { language } = useApp();
const isRTL = language === 'ar';

<div className={`flex items-center gap-4 ${isRTL ? 'flex-row-reverse' : ''}`}>
  <Icon className="w-6 h-6" />
  <div className={isRTL ? 'text-right' : 'text-left'}>
    <h3>{title}</h3>
    <p>{description}</p>
  </div>
</div>
```

### 3. Theme-Aware Button
```tsx
<button className="bg-card text-foreground border-border hover:bg-accent transition-colors">
  {/* Automatically adapts to current theme */}
</button>
```

---

## 📱 Mobile App Integration

### Tab Navigation
All tabs automatically respect the global theme and language:

```tsx
// MobileApp.tsx
const { theme, language } = useApp();

<div className={`${theme === 'dark' ? 'dark' : ''}`}>
  {/* All child components inherit theme */}
</div>
```

### Profile Tab Toggles
The Profile tab provides UI controls for theme and language switching:

```tsx
// ProfileTab.tsx
const { theme, language, toggleTheme, toggleLanguage } = useApp();

<button onClick={toggleTheme}>
  {theme === 'dark' ? <Moon /> : <Sun />}
</button>

<button onClick={toggleLanguage}>
  {language === 'en' ? 'عربي' : 'English'}
</button>
```

---

## 🎬 Cinematic Elements Theme Support

### Particle Field
The particle field automatically adapts colors based on theme:

```tsx
// Light mode: Dark particles on light background
// Dark mode: Light particles with glow on dark background
```

### Scroll Animations
All scroll-triggered animations maintain WCAG AA contrast ratios in both themes.

---

## ✅ Implementation Checklist

### Website
- [x] Semantic color tokens in `globals.css`
- [x] Arabic font family (Almarai)
- [x] Unified AppProviders context
- [x] Header with theme/language toggles
- [x] All sections respect theme/language
- [x] RTL layout mirroring
- [x] Particle field theme adaptation
- [x] Magnetic cursor theme colors

### Mobile App
- [x] Global theme context integration
- [x] Profile tab theme/language toggles
- [x] All tabs respect theme changes
- [x] RTL support in all components
- [x] Tab bar RTL mirroring
- [x] Form elements RTL alignment
- [x] Emergency contact platform cards RTL

---

## 🔧 Customization Guide

### Adding New Color Tokens
```css
/* In globals.css */
:root {
  --ishara-custom-color: #YOUR_COLOR;
}

.dark {
  --ishara-custom-color: #YOUR_DARK_COLOR;
}
```

### Adding New Translations
```tsx
// In AppProviders.tsx
const translations = {
  en: {
    'your.key': 'Your English Text',
  },
  ar: {
    'your.key': 'النص العربي',
  }
};
```

### Creating RTL-Aware Components
```tsx
export function MyComponent() {
  const { language } = useApp();
  const isRTL = language === 'ar';
  
  return (
    <div dir={isRTL ? 'rtl' : 'ltr'}>
      {/* Your component */}
    </div>
  );
}
```

---

## 📊 Four States Demonstrated

The entire application seamlessly switches between:

1. **Light / English (LTR)** - Default state with light theme and English
2. **Dark / English (LTR)** - Dark theme with English maintained
3. **Light / Arabic (RTL)** - Light theme with Arabic and RTL layout
4. **Dark / Arabic (RTL)** - Dark theme with Arabic and RTL layout

All combinations are fully tested and production-ready.

---

## 🎨 Design Tokens Quick Reference

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--ishara-brand-teal` | #14B8A6 | #2DD4BF | Primary brand |
| `--ishara-brand-orange` | #F97316 | #FB923C | Secondary brand |
| `--background` | #ffffff | #0F172A | Page background |
| `--foreground` | ~#030213 | #F1F5F9 | Text color |
| `--card` | #ffffff | #1E293B | Card background |
| `--border` | rgba(0,0,0,0.1) | #334155 | Borders |
| `--muted` | #ececf0 | #334155 | Muted elements |

---

## 🌟 Best Practices

1. **Always use semantic tokens** - Never hardcode colors
2. **Test all four states** - Light/Dark × English/Arabic
3. **Use `isRTL` helper** - For conditional RTL logic
4. **Logical properties** - Prefer `ps/pe` over `pl/pr` when possible
5. **Icon direction** - Mirror directional icons for RTL
6. **Text alignment** - Always set based on language direction
7. **Transitions** - Ensure smooth theme/language transitions
8. **Accessibility** - Maintain WCAG AA contrast in all states

---

## 📞 Support

For questions about the design system, refer to:
- Color tokens: `/styles/globals.css`
- Context provider: `/components/AppProviders.tsx`
- Example components: `/components/Header.tsx`, `/components/mobile/ProfileTab.tsx`

---

**Last Updated**: November 2024
**Version**: 1.0.0
**Status**: Production Ready ✅
