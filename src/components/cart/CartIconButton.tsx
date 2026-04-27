import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'motion/react';
import { ShoppingCart } from 'lucide-react';
import { useCart } from '../../context/CartContext';

export function CartIconButton() {
  const { count } = useCart();
  return (
    <Link
      to="/cart"
      aria-label={`Cart, ${count} ${count === 1 ? 'item' : 'items'}`}
      className="relative p-2 rounded-lg hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] focus-visible:ring-offset-2 transition"
    >
      <ShoppingCart className="w-5 h-5" aria-hidden="true" />
      <AnimatePresence>
        {count > 0 && (
          <motion.span
            key={count}
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 500, damping: 25 }}
            className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white text-[10px] font-semibold flex items-center justify-center shadow ring-2 ring-background"
            aria-hidden="true"
          >
            {count > 99 ? '99+' : count}
          </motion.span>
        )}
      </AnimatePresence>
    </Link>
  );
}
