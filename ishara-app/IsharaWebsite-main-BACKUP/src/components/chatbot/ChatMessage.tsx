import { Volume2, VolumeX } from 'lucide-react';
import { motion } from 'motion/react';
import type { ChatMessage } from '../../api/chatApi';

interface Props {
  msg: ChatMessage;
  onSpeak?: (text: string) => void;
  speakingMsgId?: string | null;
  narrateLabel: { speak: string; stop: string };
}

export function ChatMessageBubble({
  msg,
  onSpeak,
  speakingMsgId,
  narrateLabel,
}: Props) {
  const isUser = msg.role === 'user';
  const isSpeaking = speakingMsgId === msg.id;

  return (
    <motion.div
      initial={{ opacity: 0, y: 8, scale: 0.95 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ duration: 0.2 }}
      className={`flex ${isUser ? 'justify-end' : 'justify-start'} group`}
    >
      <div
        className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap ${
          isUser
            ? 'bg-gradient-to-br from-[#14B8A6] to-[#0d9488] text-white rounded-br-lg shadow-lg shadow-teal-500/10'
            : 'bg-white/5 border border-white/5 text-white/90 rounded-bl-lg'
        }`}
      >
        {!isUser && (
          <div className="w-6 h-0.5 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] mb-2 opacity-60" />
        )}
        {msg.content || (
          <span className="opacity-40 italic">…</span>
        )}
        {!isUser && onSpeak && msg.content && (
          <button
            onClick={() => onSpeak(msg.content)}
            aria-label={isSpeaking ? narrateLabel.stop : narrateLabel.speak}
            aria-pressed={isSpeaking}
            className="ml-2 -mb-0.5 inline-flex items-center justify-center w-7 h-7 rounded-lg text-white/40 hover:text-white hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] transition-colors"
          >
            {isSpeaking ? (
              <VolumeX className="w-3.5 h-3.5" />
            ) : (
              <Volume2 className="w-3.5 h-3.5" />
            )}
          </button>
        )}
      </div>
    </motion.div>
  );
}
