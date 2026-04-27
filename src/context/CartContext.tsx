import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  ReactNode,
} from 'react';
import { getServerCart, replaceServerCart, clearServerCart } from '../api/cartApi';
import type { Product } from '../api/productApi';
import { useAuth } from '../hooks/useAuth';

// Local cart line — lightweight snapshot kept even when logged out.
export interface CartLine {
  product: string;
  slug: string;
  titleEn: string;
  titleAr: string;
  image: string;
  priceEGP: number;
  stock: number;
  qty: number;
}

interface CartContextType {
  lines: CartLine[];
  subtotalEGP: number;
  count: number;
  isSyncing: boolean;
  add: (p: Product, qty?: number) => void;
  remove: (productId: string) => void;
  setQty: (productId: string, qty: number) => void;
  clear: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);
const STORAGE_KEY = 'ishara-cart-v1';

function loadLocal(): CartLine[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveLocal(lines: CartLine[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
  } catch {
    /* quota / private mode — ignore */
  }
}

function productToLine(p: Product, qty: number): CartLine {
  return {
    product: p._id,
    slug: p.slug,
    titleEn: p.title.en,
    titleAr: p.title.ar,
    image: p.images?.[0]?.src || '',
    priceEGP: p.priceEGP,
    stock: p.stock,
    qty,
  };
}

export function CartProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated, token } = useAuth();
  const [lines, setLines] = useState<CartLine[]>(() => loadLocal());
  const [isSyncing, setIsSyncing] = useState(false);
  const mergedOnceRef = useRef(false);

  // Persist locally every change.
  useEffect(() => {
    saveLocal(lines);
  }, [lines]);

  // On login: merge localStorage into server cart, then trust server as truth.
  useEffect(() => {
    async function merge() {
      if (!isAuthenticated || !token || mergedOnceRef.current) return;
      mergedOnceRef.current = true;
      setIsSyncing(true);
      try {
        const server = await getServerCart();

        // Combine: sum qty where both exist; clamp to 99.
        const combined = new Map<string, number>();
        server.items.forEach((i) => combined.set(i.product, i.qty));
        lines.forEach((l) =>
          combined.set(l.product, Math.min((combined.get(l.product) || 0) + l.qty, 99))
        );

        const merged = [...combined.entries()].map(([product, qty]) => ({ product, qty }));
        const updated = merged.length ? await replaceServerCart(merged) : server;

        setLines(
          updated.items.map((i) => ({
            product: i.product,
            slug: i.slug,
            titleEn: i.title.en,
            titleAr: i.title.ar,
            image: i.image,
            priceEGP: i.priceEGP,
            stock: i.stock,
            qty: i.qty,
          }))
        );
      } catch {
        // Keep local lines if server unreachable.
      } finally {
        setIsSyncing(false);
      }
    }
    merge();
    if (!isAuthenticated) mergedOnceRef.current = false;
  }, [isAuthenticated, token]); // eslint-disable-line react-hooks/exhaustive-deps

  // Push the authoritative items to the server (debounced).
  const pushTimer = useRef<number | null>(null);
  const schedulePush = useCallback(
    (next: CartLine[]) => {
      if (!isAuthenticated) return;
      if (pushTimer.current) window.clearTimeout(pushTimer.current);
      pushTimer.current = window.setTimeout(async () => {
        try {
          await replaceServerCart(next.map((l) => ({ product: l.product, qty: l.qty })));
        } catch {
          /* swallow — localStorage still has it */
        }
      }, 400);
    },
    [isAuthenticated]
  );

  const add = useCallback(
    (p: Product, qty = 1) => {
      setLines((prev) => {
        const idx = prev.findIndex((l) => l.product === p._id);
        let next: CartLine[];
        if (idx >= 0) {
          next = [...prev];
          next[idx] = {
            ...next[idx],
            qty: Math.min(next[idx].qty + qty, Math.max(1, p.stock || 99), 99),
          };
        } else {
          next = [...prev, productToLine(p, Math.max(1, qty))];
        }
        schedulePush(next);
        return next;
      });
    },
    [schedulePush]
  );

  const remove = useCallback(
    (productId: string) => {
      setLines((prev) => {
        const next = prev.filter((l) => l.product !== productId);
        schedulePush(next);
        return next;
      });
    },
    [schedulePush]
  );

  const setQty = useCallback(
    (productId: string, qty: number) => {
      setLines((prev) => {
        const next = prev
          .map((l) =>
            l.product === productId
              ? { ...l, qty: Math.max(1, Math.min(qty, 99)) }
              : l
          )
          .filter((l) => l.qty > 0);
        schedulePush(next);
        return next;
      });
    },
    [schedulePush]
  );

  const clear = useCallback(() => {
    setLines([]);
    if (isAuthenticated) clearServerCart().catch(() => {});
  }, [isAuthenticated]);

  const subtotalEGP = useMemo(
    () => lines.reduce((s, l) => s + l.priceEGP * l.qty, 0),
    [lines]
  );
  const count = useMemo(() => lines.reduce((s, l) => s + l.qty, 0), [lines]);

  return (
    <CartContext.Provider
      value={{ lines, subtotalEGP, count, isSyncing, add, remove, setQty, clear }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used within CartProvider');
  return ctx;
}
