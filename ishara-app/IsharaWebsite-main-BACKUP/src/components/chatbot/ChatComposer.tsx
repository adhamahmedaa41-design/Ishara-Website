import { useState, KeyboardEvent } from 'react';
import { Send } from 'lucide-react';
import { motion } from 'motion/react';

interface Props {
  onSend: (text: string) => void;
  placeholder: string;
  sendLabel: string;
  disabled?: boolean;
}

export function ChatComposer({ onSend, placeholder, sendLabel, disabled }: Props) {
  const [text, setText] = useState('');
  const [focused, setFocused] = useState(false);

  const submit = () => {
    const trimmed = text.trim();
    if (!trimmed || disabled) return;
    onSend(trimmed);
    setText('');
  };

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  };

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        submit();
      }}
      className="relative flex items-end gap-2 p-3 border-t border-white/5"
      style={{ background: 'rgba(15,23,42,0.8)' }}
    >
      <label htmlFor="chat-input" className="sr-only">
        {placeholder}
      </label>
      <div className={`flex-1 relative rounded-2xl transition-all duration-300 ${focused ? 'shadow-[0_0_0_2px_rgba(20,184,166,0.4)]' : ''}`}>
        <textarea
          id="chat-input"
          rows={1}
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={onKey}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          placeholder={placeholder}
          disabled={disabled}
          className="w-full resize-none rounded-2xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder:text-white/30 max-h-32 focus:outline-none focus:border-[#14B8A6]/50 disabled:opacity-40 transition-all"
        />
      </div>
      <motion.button
        type="submit"
        aria-label={sendLabel}
        disabled={disabled || !text.trim()}
        className="p-3 rounded-2xl bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white disabled:opacity-30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6] shadow-lg shadow-teal-500/20"
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.9 }}
      >
        <Send className="w-4 h-4" aria-hidden="true" />
      </motion.button>
    </form>
  );
}
