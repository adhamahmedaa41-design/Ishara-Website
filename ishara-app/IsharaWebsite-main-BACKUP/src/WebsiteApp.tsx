import { useState, useEffect } from 'react';
import { HeroSection } from './components/HeroSection';
import { TechnologySection } from './components/TechnologySection';
import { SafetySection } from './components/SafetySection';
import { LearningSection } from './components/LearningSection';
import { HardwareSection } from './components/HardwareSection';
import { AboutSection } from './components/AboutSection';
import { ContactSection } from './components/ContactSection';
import { Footer } from './components/Footer';
import { ParticleField } from './components/ParticleField';
import { LoadingScreen } from './components/LoadingScreen';
import { ScrollProgress } from './components/ScrollProgress';
import { BackToTop } from './components/BackToTop';
import { ToastProvider } from './components/ToastProvider';
import { useApp } from './components/AppProviders';

export default function WebsiteApp() {
  const { theme, language } = useApp();
  const [isLoading, setIsLoading] = useState(true);

  // Loading screen timer
  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 1200);
    return () => clearTimeout(timer);
  }, []);

  return (
    <>
      <ToastProvider theme={theme} />
      {isLoading && <LoadingScreen onComplete={() => setIsLoading(false)} />}

      <div className="relative min-h-screen">
        <ScrollProgress />
        <ParticleField />

        <main id="main" className="relative" tabIndex={-1}>
          <HeroSection language={language} />
          <TechnologySection language={language} />
          <SafetySection language={language} />
          <LearningSection language={language} />
          <HardwareSection language={language} />
          <AboutSection language={language} />
          <ContactSection language={language} />
        </main>

        <Footer language={language} />
        <BackToTop />
      </div>
    </>
  );
}