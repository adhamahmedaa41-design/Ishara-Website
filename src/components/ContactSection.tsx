import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { Send, MapPin, Mail, Check, Loader2 } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';
import { MagneticButton } from './MagneticButton';

interface ContactSectionProps {
  language: 'en' | 'ar';
}

export function ContactSection({ language }: ContactSectionProps) {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [error, setError] = useState('');

  const content = {
    en: {
      title: 'Get in Touch',
      subtitle: 'Have questions? We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
      name: 'Your Name',
      email: 'Email Address',
      subject: 'Subject',
      message: 'Your Message',
      send: 'Send Message',
      sending: 'Sending...',
      sent: 'Message Sent!',
      sentDesc: 'We\'ll get back to you soon.',
      sendAnother: 'Send Another Message',
      info: {
        title: 'Contact Information',
        email: 'contact@ishara.com',
        location: 'Cairo, Egypt',
      },
      errorGeneric: 'Something went wrong. Please try again.',
    },
    ar: {
      title: 'تواصل معنا',
      subtitle: 'لديك أسئلة؟ نحب أن نسمع منك. أرسل لنا رسالة وسنرد في أقرب وقت ممكن.',
      name: 'اسمك',
      email: 'البريد الإلكتروني',
      subject: 'الموضوع',
      message: 'رسالتك',
      send: 'إرسال الرسالة',
      sending: 'جاري الإرسال...',
      sent: 'تم إرسال الرسالة!',
      sentDesc: 'سنعود إليك قريبًا.',
      sendAnother: 'إرسال رسالة أخرى',
      info: {
        title: 'معلومات الاتصال',
        email: 'contact@ishara.com',
        location: 'القاهرة، مصر',
      },
      errorGeneric: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
    }
  };

  const t = content[language];

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
    setError('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || t.errorGeneric);
      }

      setIsSubmitted(true);
      setFormData({ name: '', email: '', subject: '', message: '' });
    } catch (err: any) {
      setError(err.message || t.errorGeneric);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section id="contact" className="py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-emerald-500/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                y: [0, -10, 0],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
              }}
            >
              <Send className="w-16 h-16 text-emerald-500" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        <div className="grid grid-cols-1 lg:grid-cols-5 gap-12 max-w-6xl mx-auto">
          {/* Contact Info */}
          <ScrollReveal direction="left" className="lg:col-span-2">
            <div className="bg-card p-8 rounded-3xl shadow-2xl h-full">
              <h3 className="mb-8">{t.info.title}</h3>
              <div className="space-y-6">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-[#14B8A6] rounded-xl flex items-center justify-center">
                    <Mail className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <p className="font-medium">Email</p>
                    <a
                      href={`mailto:${t.info.email}`}
                      className="text-muted-foreground hover:text-[#14B8A6] transition-colors"
                    >
                      {t.info.email}
                    </a>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-[#F97316] to-amber-500 rounded-xl flex items-center justify-center">
                    <MapPin className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <p className="font-medium">Location</p>
                    <p className="text-muted-foreground">{t.info.location}</p>
                  </div>
                </div>
              </div>
            </div>
          </ScrollReveal>

          {/* Form */}
          <ScrollReveal direction="right" className="lg:col-span-3">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <AnimatePresence mode="wait">
                {isSubmitted ? (
                  <motion.div
                    key="success"
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    className="text-center py-20"
                  >
                    <motion.div
                      className="w-20 h-20 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-6"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: 'spring', delay: 0.2 }}
                    >
                      <Check className="w-10 h-10 text-green-500" />
                    </motion.div>
                    <h3 className="mb-2">{t.sent}</h3>
                    <p className="text-muted-foreground mb-6">{t.sentDesc}</p>
                    <button
                      onClick={() => setIsSubmitted(false)}
                      className="px-6 py-3 bg-gradient-to-r from-[#14B8A6] to-emerald-500 text-white rounded-xl"
                    >
                      {t.sendAnother}
                    </button>
                  </motion.div>
                ) : (
                  <motion.form
                    key="form"
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    onSubmit={handleSubmit}
                    className="space-y-6"
                  >
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div>
                        <label htmlFor="name" className="block text-sm mb-2">{t.name}</label>
                        <input
                          id="name"
                          name="name"
                          type="text"
                          required
                          value={formData.name}
                          onChange={handleChange}
                          className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-emerald-500 outline-none transition-colors"
                        />
                      </div>
                      <div>
                        <label htmlFor="email" className="block text-sm mb-2">{t.email}</label>
                        <input
                          id="email"
                          name="email"
                          type="email"
                          required
                          value={formData.email}
                          onChange={handleChange}
                          className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-emerald-500 outline-none transition-colors"
                        />
                      </div>
                    </div>
                    <div>
                      <label htmlFor="subject" className="block text-sm mb-2">{t.subject}</label>
                      <input
                        id="subject"
                        name="subject"
                        type="text"
                        required
                        value={formData.subject}
                        onChange={handleChange}
                        className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-emerald-500 outline-none transition-colors"
                      />
                    </div>
                    <div>
                      <label htmlFor="message" className="block text-sm mb-2">{t.message}</label>
                      <textarea
                        id="message"
                        name="message"
                        rows={5}
                        required
                        value={formData.message}
                        onChange={handleChange}
                        className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-emerald-500 outline-none transition-colors resize-none"
                      />
                    </div>

                    {error && (
                      <motion.p
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-red-500 text-sm"
                      >
                        {error}
                      </motion.p>
                    )}

                    <MagneticButton
                      type="submit"
                      disabled={isSubmitting}
                      className="w-full py-4 bg-gradient-to-r from-[#14B8A6] to-emerald-500 text-white rounded-xl disabled:opacity-50"
                    >
                      <span className="flex items-center justify-center gap-3 w-full">
                        {isSubmitting ? (
                          <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            {t.sending}
                          </>
                        ) : (
                          <>
                            <Send className="w-5 h-5" />
                            {t.send}
                          </>
                        )}
                      </span>
                    </MagneticButton>
                  </motion.form>
                )}
              </AnimatePresence>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}
