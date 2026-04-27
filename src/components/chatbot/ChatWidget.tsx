import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { MessageCircle, X, Trash2, Volume2, VolumeX, Sparkles } from 'lucide-react';
import { streamChat, type ChatMessage } from '../../api/chatApi';
import { ChatMessageBubble } from './ChatMessage';
import { ChatComposer } from './ChatComposer';
import { SuggestedQuestions } from './SuggestedQuestions';
import { TypingIndicator } from './TypingIndicator';
import { useSpeechSynthesis } from './useSpeechSynthesis';
import { useApp } from '../AppProviders';

const STORAGE_KEY = 'ishara-chat-history-v1';
const NARRATED_KEY = 'ishara-chat-narrated';

const SUGGESTIONS = {
  en: [
    'How do the glasses help blind users?',
    'How does sign language translation work?',
    'How much do the glasses cost?',
    'What can the bracelet do in an emergency?',
  ],
  ar: [
    'كيف تساعد النظارات المكفوفين؟',
    'كيف تعمل ترجمة لغة الإشارة؟',
    'كم سعر النظارات؟',
    'ما الذي يفعله السوار في الطوارئ؟',
  ],
};

function loadHistory(): ChatMessage[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v : [];
  } catch {
    return [];
  }
}

function uid() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function ChatWidget() {
  const { language } = useApp();
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>(() => loadHistory());
  const [narrated, setNarrated] = useState<boolean>(() => {
    try {
      return localStorage.getItem(NARRATED_KEY) === '1';
    } catch {
      return false;
    }
  });
  const [pending, setPending] = useState(false);
  const [speakingMsgId, setSpeakingMsgId] = useState<string | null>(null);

  const scrollRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);
  const tts = useSpeechSynthesis(language);

  // Persist history (cap to last 50 messages).
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(messages.slice(-50)));
    } catch {
      /* quota */
    }
  }, [messages]);

  useEffect(() => {
    try {
      localStorage.setItem(NARRATED_KEY, narrated ? '1' : '0');
    } catch {
      /* ignore */
    }
  }, [narrated]);

  // Auto-scroll to bottom on new message.
  useEffect(() => {
    if (!open) return;
    const el = scrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [messages, open, pending]);

  // Stop TTS when widget closes.
  useEffect(() => {
    if (!open) {
      tts.cancel();
      setSpeakingMsgId(null);
    }
  }, [open, tts]);

  const L = {
    en: {
      open: 'Open Ishara assistant',
      close: 'Close assistant',
      title: 'Ishara Assistant',
      subtitle: 'Ask me anything about Ishara',
      greeting: 'Hi! 👋 I\'m your Ishara assistant. Ask me anything about our smart glasses, bracelet, app, or accessibility features.',
      placeholder: 'Type your question…',
      send: 'Send message',
      clear: 'Clear conversation',
      narrateOn: 'Turn narration on',
      narrateOff: 'Turn narration off',
      thinking: 'Assistant is typing',
      speak: 'Read aloud',
      stop: 'Stop reading',
    },
    ar: {
      open: 'افتح مساعد إشارة',
      close: 'أغلق المساعد',
      title: 'مساعد إشارة',
      subtitle: 'اسألني عن أي شيء يخص إشارة',
      greeting: 'أهلًا! 👋 أنا مساعد إشارة. اسألني عن النظارات الذكية أو السوار أو التطبيق أو ميزات الوصولية.',
      placeholder: 'اكتب سؤالك…',
      send: 'إرسال',
      clear: 'مسح المحادثة',
      narrateOn: 'تشغيل القراءة الصوتية',
      narrateOff: 'إيقاف القراءة الصوتية',
      thinking: 'المساعد يكتب',
      speak: 'قراءة بصوت عالٍ',
      stop: 'إيقاف القراءة',
    },
  }[language];

  const speakMessage = useCallback(
    (id: string, text: string) => {
      if (speakingMsgId === id) {
        tts.cancel();
        setSpeakingMsgId(null);
        return;
      }
      tts.speak(text);
      setSpeakingMsgId(id);
    },
    [tts, speakingMsgId]
  );

  useEffect(() => {
    if (!tts.speaking) setSpeakingMsgId(null);
  }, [tts.speaking]);

  const send = useCallback(
    async (text: string) => {
      if (pending) return;
      const userMsg: ChatMessage = {
        id: uid(),
        role: 'user',
        content: text,
        createdAt: Date.now(),
      };
      const assistantMsg: ChatMessage = {
        id: uid(),
        role: 'assistant',
        content: '',
        createdAt: Date.now(),
      };
      const next = [...messages, userMsg, assistantMsg];
      setMessages(next);
      setPending(true);

      const controller = new AbortController();
      abortRef.current = controller;

      let finalText = '';
      try {
        await streamChat({
          lang: language,
          messages: next
            .filter((m) => m.id !== assistantMsg.id)
            .map((m) => ({ role: m.role, content: m.content })),
          onDelta: (delta) => {
            finalText += delta;
            setMessages((prev) =>
              prev.map((m) =>
                m.id === assistantMsg.id ? { ...m, content: m.content + delta } : m
              )
            );
          },
          signal: controller.signal,
        });
      } catch (err: unknown) {
        const msg =
          (err as { message?: string })?.message ||
          (language === 'ar'
            ? 'تعذر الاتصال بالمساعد.'
            : 'Could not reach assistant.');
        setMessages((prev) =>
          prev.map((m) =>
            m.id === assistantMsg.id ? { ...m, content: msg } : m
          )
        );
        finalText = msg;
      } finally {
        setPending(false);
        abortRef.current = null;
        if (narrated && finalText.trim()) {
          tts.speak(finalText);
          setSpeakingMsgId(assistantMsg.id);
        }
      }
    },
    [language, messages, pending, narrated, tts]
  );

  const clear = () => {
    abortRef.current?.abort();
    tts.cancel();
    setMessages([]);
    setSpeakingMsgId(null);
  };

  const isRTL = language === 'ar';

  return (
    <>
      {/* Floating FAB with pulse ring */}
      <div className={`fixed bottom-6 ${isRTL ? 'left-6' : 'right-6'} z-[9998]`}>
        {/* Pulse rings */}
        {!open && (
          <>
            <motion.div
              className="absolute inset-0 rounded-full bg-gradient-to-br from-[#14B8A6] to-[#F97316]"
              animate={{ scale: [1, 1.6], opacity: [0.4, 0] }}
              transition={{ duration: 2, repeat: Infinity, ease: 'easeOut' }}
            />
            <motion.div
              className="absolute inset-0 rounded-full bg-gradient-to-br from-[#14B8A6] to-[#F97316]"
              animate={{ scale: [1, 1.4], opacity: [0.3, 0] }}
              transition={{ duration: 2, repeat: Infinity, ease: 'easeOut', delay: 0.5 }}
            />
          </>
        )}
        <motion.button
          onClick={() => setOpen((v) => !v)}
          aria-label={open ? L.close : L.open}
          aria-expanded={open}
          className="relative w-16 h-16 rounded-full bg-gradient-to-br from-[#14B8A6] to-[#F97316] text-white shadow-2xl shadow-teal-500/30 flex items-center justify-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          animate={open ? { rotate: 0 } : { rotate: [0, -10, 10, 0] }}
          transition={open ? { duration: 0.2 } : { duration: 2, repeat: Infinity, repeatDelay: 3 }}
        >
          <AnimatePresence mode="wait">
            {open ? (
              <motion.div key="close" initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }} transition={{ duration: 0.15 }}>
                <X className="w-7 h-7" aria-hidden="true" />
              </motion.div>
            ) : (
              <motion.div key="open" initial={{ rotate: 90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: -90, opacity: 0 }} transition={{ duration: 0.15 }}>
                <MessageCircle className="w-7 h-7" aria-hidden="true" />
              </motion.div>
            )}
          </AnimatePresence>
        </motion.button>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 24, scale: 0.92 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 24, scale: 0.92 }}
            transition={{ type: 'spring', damping: 22, stiffness: 300 }}
            role="dialog"
            aria-modal="false"
            aria-labelledby="chat-title"
            className={`fixed bottom-28 ${isRTL ? 'left-6' : 'right-6'} z-[9999] w-[min(400px,calc(100vw-2rem))] h-[min(600px,calc(100vh-8rem))] rounded-3xl shadow-2xl shadow-black/30 flex flex-col overflow-hidden`}
            style={{
              background: 'linear-gradient(145deg, rgba(15,23,42,0.97) 0%, rgba(15,23,42,0.95) 100%)',
              border: '1px solid rgba(255,255,255,0.08)',
              backdropFilter: 'blur(20px)',
            }}
          >
            {/* Header */}
            <div className="relative px-5 py-4 overflow-hidden">
              {/* Gradient bg */}
              <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6] to-[#F97316] opacity-90" />
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_50%,white/20_0%,transparent_60%)]" />
              <div className="relative z-10 flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center shadow-inner">
                  <Sparkles className="w-5 h-5 text-white" aria-hidden="true" />
                </div>
                <div className="flex-1 min-w-0">
                  <h2 id="chat-title" className="font-bold text-white leading-tight">
                    {L.title}
                  </h2>
                  <p className="text-[11px] text-white/80 truncate">{L.subtitle}</p>
                </div>
                {tts.supported && (
                  <button
                    onClick={() => {
                      if (narrated) tts.cancel();
                      setNarrated((v) => !v);
                    }}
                    aria-label={narrated ? L.narrateOff : L.narrateOn}
                    aria-pressed={narrated}
                    title={narrated ? L.narrateOff : L.narrateOn}
                    className="p-2 rounded-xl hover:bg-white/15 text-white/90 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white"
                  >
                    {narrated ? (
                      <Volume2 className="w-4 h-4" aria-hidden="true" />
                    ) : (
                      <VolumeX className="w-4 h-4" aria-hidden="true" />
                    )}
                  </button>
                )}
                <button
                  onClick={clear}
                  aria-label={L.clear}
                  title={L.clear}
                  className="p-2 rounded-xl hover:bg-white/15 text-white/90 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white"
                >
                  <Trash2 className="w-4 h-4" aria-hidden="true" />
                </button>
              </div>
            </div>

            {/* Messages */}
            <div
              ref={scrollRef}
              className="flex-1 overflow-y-auto px-4 py-4 space-y-3"
              role="log"
              aria-live="polite"
              aria-label={L.title}
              style={{
                scrollbarWidth: 'thin',
                scrollbarColor: 'rgba(255,255,255,0.1) transparent',
              }}
            >
              {messages.length === 0 && (
                <div className="space-y-4">
                  <motion.div
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="rounded-2xl bg-white/5 border border-white/5 px-4 py-3 text-sm text-white/80"
                  >
                    {L.greeting}
                  </motion.div>
                  <SuggestedQuestions
                    questions={SUGGESTIONS[language]}
                    onSelect={send}
                  />
                </div>
              )}
              {messages.map((m) => (
                <ChatMessageBubble
                  key={m.id}
                  msg={m}
                  onSpeak={tts.supported ? (text) => speakMessage(m.id, text) : undefined}
                  speakingMsgId={speakingMsgId}
                  narrateLabel={{ speak: L.speak, stop: L.stop }}
                />
              ))}
              {pending && messages[messages.length - 1]?.content === '' && (
                <TypingIndicator label={L.thinking} />
              )}
            </div>

            <ChatComposer
              onSend={send}
              placeholder={L.placeholder}
              sendLabel={L.send}
              disabled={pending}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
