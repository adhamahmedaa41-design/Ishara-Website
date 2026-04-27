import { useForm } from 'react-hook-form';
import type { OrderAddress } from '../../api/orderApi';
import { useApp } from '../AppProviders';

export interface CheckoutFormValues extends OrderAddress {
  receiptEmail: string;
}

interface Props {
  defaultEmail?: string;
  defaultName?: string;
  onSubmit: (values: CheckoutFormValues) => void | Promise<void>;
  submitting?: boolean;
}

const EG_GOVS_EN = [
  'Cairo', 'Giza', 'Alexandria', 'Qalyubia', 'Sharqia', 'Dakahlia',
  'Gharbia', 'Monufia', 'Kafr El Sheikh', 'Beheira', 'Damietta',
  'Port Said', 'Ismailia', 'Suez', 'North Sinai', 'South Sinai',
  'Red Sea', 'Matrouh', 'Fayoum', 'Beni Suef', 'Minya', 'Asyut',
  'Sohag', 'Qena', 'Luxor', 'Aswan', 'New Valley',
];

export function CheckoutForm({ defaultEmail, defaultName, onSubmit, submitting }: Props) {
  const { language } = useApp();
  const { register, handleSubmit, formState: { errors } } = useForm<CheckoutFormValues>({
    defaultValues: {
      fullName: defaultName || '',
      receiptEmail: defaultEmail || '',
      country: 'EG',
      governorate: '',
      city: '',
      line1: '',
      phone: '',
    },
  });

  const L = {
    en: {
      contact: 'Contact',
      shipping: 'Shipping address',
      fullName: 'Full name',
      email: 'Email for order confirmation',
      phone: 'Phone',
      line1: 'Address line 1',
      line2: 'Address line 2 (optional)',
      city: 'City',
      gov: 'Governorate',
      postal: 'Postal code (optional)',
      required: 'This field is required',
      invalidEmail: 'Please enter a valid email',
      submit: 'Continue to payment',
      submitting: 'Processing…',
      selectGov: 'Select a governorate',
    },
    ar: {
      contact: 'بيانات الاتصال',
      shipping: 'عنوان الشحن',
      fullName: 'الاسم بالكامل',
      email: 'البريد الإلكتروني لتأكيد الطلب',
      phone: 'رقم الهاتف',
      line1: 'العنوان الأول',
      line2: 'العنوان الثاني (اختياري)',
      city: 'المدينة',
      gov: 'المحافظة',
      postal: 'الرمز البريدي (اختياري)',
      required: 'هذا الحقل مطلوب',
      invalidEmail: 'أدخل بريدًا إلكترونيًا صالحًا',
      submit: 'المتابعة للدفع',
      submitting: 'جاري المعالجة…',
      selectGov: 'اختر المحافظة',
    },
  }[language];

  const input =
    'w-full rounded-lg border border-input bg-background px-3 py-2.5 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6]';

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="space-y-8"
      aria-labelledby="checkout-heading"
      noValidate
    >
      <fieldset className="space-y-4">
        <legend className="text-lg font-semibold">{L.contact}</legend>
        <div>
          <label htmlFor="ck-email" className="block text-sm font-medium mb-1.5">
            {L.email}
          </label>
          <input
            id="ck-email"
            type="email"
            autoComplete="email"
            aria-invalid={!!errors.receiptEmail}
            aria-describedby={errors.receiptEmail ? 'ck-email-err' : undefined}
            {...register('receiptEmail', {
              required: L.required,
              pattern: { value: /^\S+@\S+\.\S+$/, message: L.invalidEmail },
            })}
            className={input}
          />
          {errors.receiptEmail && (
            <p id="ck-email-err" role="alert" className="text-xs text-destructive mt-1">
              {errors.receiptEmail.message}
            </p>
          )}
        </div>
      </fieldset>

      <fieldset className="space-y-4">
        <legend className="text-lg font-semibold">{L.shipping}</legend>

        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <label htmlFor="ck-name" className="block text-sm font-medium mb-1.5">{L.fullName}</label>
            <input id="ck-name" autoComplete="name" aria-invalid={!!errors.fullName}
              {...register('fullName', { required: L.required })} className={input} />
            {errors.fullName && <p role="alert" className="text-xs text-destructive mt-1">{errors.fullName.message}</p>}
          </div>
          <div>
            <label htmlFor="ck-phone" className="block text-sm font-medium mb-1.5">{L.phone}</label>
            <input id="ck-phone" autoComplete="tel" inputMode="tel" aria-invalid={!!errors.phone}
              {...register('phone', { required: L.required, minLength: { value: 6, message: L.required } })}
              className={input} />
            {errors.phone && <p role="alert" className="text-xs text-destructive mt-1">{errors.phone.message}</p>}
          </div>
        </div>

        <div>
          <label htmlFor="ck-line1" className="block text-sm font-medium mb-1.5">{L.line1}</label>
          <input id="ck-line1" autoComplete="address-line1" aria-invalid={!!errors.line1}
            {...register('line1', { required: L.required })} className={input} />
          {errors.line1 && <p role="alert" className="text-xs text-destructive mt-1">{errors.line1.message}</p>}
        </div>

        <div>
          <label htmlFor="ck-line2" className="block text-sm font-medium mb-1.5">{L.line2}</label>
          <input id="ck-line2" autoComplete="address-line2" {...register('line2')} className={input} />
        </div>

        <div className="grid sm:grid-cols-3 gap-4">
          <div>
            <label htmlFor="ck-city" className="block text-sm font-medium mb-1.5">{L.city}</label>
            <input id="ck-city" autoComplete="address-level2" aria-invalid={!!errors.city}
              {...register('city', { required: L.required })} className={input} />
            {errors.city && <p role="alert" className="text-xs text-destructive mt-1">{errors.city.message}</p>}
          </div>
          <div>
            <label htmlFor="ck-gov" className="block text-sm font-medium mb-1.5">{L.gov}</label>
            <select id="ck-gov" aria-invalid={!!errors.governorate}
              {...register('governorate', { required: L.required })} className={input}>
              <option value="">{L.selectGov}</option>
              {EG_GOVS_EN.map((g) => <option key={g} value={g}>{g}</option>)}
            </select>
            {errors.governorate && <p role="alert" className="text-xs text-destructive mt-1">{errors.governorate.message}</p>}
          </div>
          <div>
            <label htmlFor="ck-postal" className="block text-sm font-medium mb-1.5">{L.postal}</label>
            <input id="ck-postal" autoComplete="postal-code" {...register('postalCode')} className={input} />
          </div>
        </div>
      </fieldset>

      <button
        type="submit"
        disabled={submitting}
        className="w-full py-3 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white font-medium disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
      >
        {submitting ? L.submitting : L.submit}
      </button>
    </form>
  );
}
