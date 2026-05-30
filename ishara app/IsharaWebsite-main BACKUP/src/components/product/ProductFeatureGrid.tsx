import * as Icons from 'lucide-react';
import { motion } from 'motion/react';
import type { ProductFeature } from '../../api/productApi';
import { useApp } from '../AppProviders';

// Resolve a lucide icon name defensively — unknown names fall back to Sparkles.
function Icon({ name, className }: { name: string; className?: string }) {
  const Cmp =
    (Icons as unknown as Record<string, React.ComponentType<{ className?: string; 'aria-hidden'?: boolean }>>)[name] ||
    Icons.Sparkles;
  return <Cmp className={className} aria-hidden={true} />;
}

export function ProductFeatureGrid({ features }: { features: ProductFeature[] }) {
  const { language } = useApp();
  if (!features.length) return null;

  return (
    <section aria-labelledby="features-heading" className="py-12">
      <h2 id="features-heading" className="text-2xl md:text-3xl font-bold mb-8">
        {language === 'ar' ? 'المكونات الأساسية' : 'Core components'}
      </h2>
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {features.map((f, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ delay: i * 0.05 }}
            className="p-6 rounded-2xl border border-border bg-card hover:border-[#14B8A6] transition-colors"
          >
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#14B8A6]/20 to-[#F97316]/20 flex items-center justify-center mb-4">
              <Icon name={f.icon} className="w-6 h-6 text-[#14B8A6]" />
            </div>
            <h3 className="font-semibold text-lg mb-1">
              {f.title[language] || f.title.en}
            </h3>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {f.desc[language] || f.desc.en}
            </p>
          </motion.div>
        ))}
      </div>
    </section>
  );
}
