import type { ProductSpec } from '../../api/productApi';
import { useApp } from '../AppProviders';

export function SpecsTable({ specs }: { specs: ProductSpec[] }) {
  const { language } = useApp();
  if (!specs.length) return null;
  return (
    <section aria-labelledby="specs-heading" className="py-12">
      <h2 id="specs-heading" className="text-2xl md:text-3xl font-bold mb-6">
        {language === 'ar' ? 'المواصفات' : 'Specifications'}
      </h2>
      <div className="rounded-2xl border border-border bg-card overflow-hidden">
        <table className="w-full">
          <tbody>
            {specs.map((s, i) => (
              <tr
                key={i}
                className="border-b border-border last:border-0"
              >
                <th
                  scope="row"
                  className="text-start py-3 px-5 bg-muted/40 font-medium w-1/3"
                >
                  {s.label[language] || s.label.en}
                </th>
                <td className="py-3 px-5">{s.value[language] || s.value.en}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
