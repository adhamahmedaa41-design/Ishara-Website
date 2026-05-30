import { motion } from 'motion/react';

interface Props {
  questions: string[];
  onSelect: (q: string) => void;
}

export function SuggestedQuestions({ questions, onSelect }: Props) {
  if (!questions.length) return null;
  return (
    <div className="flex flex-wrap gap-2" role="list">
      {questions.map((q, i) => (
        <motion.button
          key={q}
          role="listitem"
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: i * 0.08 }}
          onClick={() => onSelect(q)}
          className="text-xs px-3.5 py-2 rounded-full bg-[#14B8A6]/10 border border-[#14B8A6]/20 text-[#14B8A6] hover:bg-[#14B8A6]/20 hover:border-[#14B8A6]/40 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]"
          whileHover={{ scale: 1.03 }}
          whileTap={{ scale: 0.97 }}
        >
          {q}
        </motion.button>
      ))}
    </div>
  );
}
