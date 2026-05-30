import { useCallback, useEffect, useRef, useState } from 'react';

// Thin wrapper around the browser SpeechSynthesis API.
// Exposes: supported flag, speaking flag, speak(), cancel(), and auto voice
// selection based on requested language (ar-EG preferred for Arabic, en-US / en-GB
// for English, with fallbacks).
export function useSpeechSynthesis(lang: 'en' | 'ar') {
  const supported =
    typeof window !== 'undefined' && 'speechSynthesis' in window;

  const [speaking, setSpeaking] = useState(false);
  const voicesRef = useRef<SpeechSynthesisVoice[]>([]);

  useEffect(() => {
    if (!supported) return;
    const refresh = () => {
      voicesRef.current = window.speechSynthesis.getVoices();
    };
    refresh();
    window.speechSynthesis.onvoiceschanged = refresh;
    return () => {
      if ('speechSynthesis' in window) {
        window.speechSynthesis.onvoiceschanged = null;
      }
    };
  }, [supported]);

  const pickVoice = useCallback(() => {
    const voices = voicesRef.current;
    if (!voices.length) return null;
    const prefix = lang === 'ar' ? 'ar' : 'en';
    // Prefer a high-quality voice if available.
    return (
      voices.find((v) => v.lang?.toLowerCase().startsWith(prefix)) ||
      voices.find((v) => v.default) ||
      voices[0] ||
      null
    );
  }, [lang]);

  const speak = useCallback(
    (text: string) => {
      if (!supported || !text) return;
      try {
        window.speechSynthesis.cancel();
        const u = new SpeechSynthesisUtterance(text);
        const voice = pickVoice();
        if (voice) u.voice = voice;
        u.lang = lang === 'ar' ? 'ar-EG' : 'en-US';
        u.rate = 1;
        u.pitch = 1;
        u.onstart = () => setSpeaking(true);
        u.onend = () => setSpeaking(false);
        u.onerror = () => setSpeaking(false);
        window.speechSynthesis.speak(u);
      } catch {
        setSpeaking(false);
      }
    },
    [supported, pickVoice, lang]
  );

  const cancel = useCallback(() => {
    if (!supported) return;
    window.speechSynthesis.cancel();
    setSpeaking(false);
  }, [supported]);

  return { supported, speaking, speak, cancel };
}
