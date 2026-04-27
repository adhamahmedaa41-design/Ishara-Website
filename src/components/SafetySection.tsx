import { motion, AnimatePresence } from 'motion/react';
import { useState, useEffect } from 'react';
import { Shield, Mail, AlertCircle, Check, Plus, Trash2, Loader2 } from 'lucide-react';
import { ScrollReveal } from './ScrollReveal';
import { MagneticButton } from './MagneticButton';
import { useAuth } from '../hooks/useAuth';
import { http } from '../api/httpClient';

interface Contact {
  id: string;
  name: string;
  email: string;
  phone: string;
}

interface SafetySectionProps {
  language: 'en' | 'ar';
}

export function SafetySection({ language }: SafetySectionProps) {
  const { user, isAuthenticated, updateUser } = useAuth();
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [sosActive, setSosActive] = useState(false);
  const [sosStatus, setSosStatus] = useState<{ sent: number; failed: number } | null>(null);
  const [saving, setSaving] = useState(false);
  const [newContact, setNewContact] = useState({
    name: '',
    email: '',
    phone: '',
  });

  // Load contacts from user profile on mount / auth change
  useEffect(() => {
    if (user?.emergencyContacts) {
      setContacts(
        user.emergencyContacts.map((c, i) => ({
          id: c._id ?? String(i),
          name: c.name,
          email: c.email ?? '',
          phone: c.phone ?? '',
        }))
      );
    } else {
      setContacts([]);
    }
  }, [user]);

  const content = {
    en: {
      title: 'Safety System',
      subtitle: 'Emergency contacts and instant SOS alerts',
      addContact: 'Add Emergency Contact',
      name: 'Name',
      email: 'Email Address',
      phone: 'Phone Number (optional)',
      save: 'Save Contact',
      cancel: 'Cancel',
      testSOS: 'Send SOS Alert',
      sosActive: 'SOS ACTIVATED',
      sending: 'Sending email alerts to all contacts...',
      noContacts: 'No emergency contacts added yet',
      addFirst: 'Add your first emergency contact',
      messagesSent: (sent: number) => `SOS email sent to ${sent} contact${sent === 1 ? '' : 's'} successfully!`,
      sendFailed: 'Failed to send SOS emails. Please try again.',
      features: [
        {
          title: 'Instant Email Alerts',
          description: 'Send SOS emails to all contacts simultaneously'
        },
        {
          title: 'Bilingual Message',
          description: 'Emergency alert sent in English and Arabic'
        },
        {
          title: 'Location Sharing',
          description: 'GPS coordinates sent automatically'
        }
      ]
    },
    ar: {
      title: 'نظام السلامة',
      subtitle: 'جهات اتصال الطوارئ وتنبيهات SOS الفورية',
      addContact: 'إضافة جهة اتصال طوارئ',
      name: 'الاسم',
      email: 'البريد الإلكتروني',
      phone: 'رقم الهاتف (اختياري)',
      save: 'حفظ جهة الاتصال',
      cancel: 'إلغاء',
      testSOS: 'إرسال تنبيه SOS',
      sosActive: 'تم تفعيل SOS',
      sending: 'إرسال تنبيهات البريد الإلكتروني إلى جميع جهات الاتصال...',
      noContacts: 'لم تتم إضافة جهات اتصال طوارئ بعد',
      addFirst: 'أضف جهة الاتصال الأولى للطوارئ',
      messagesSent: (sent: number) => `تم إرسال بريد SOS إلى ${sent} جهة اتصال بنجاح!`,
      sendFailed: 'فشل إرسال رسائل SOS. يرجى المحاولة مرة أخرى.',
      features: [
        {
          title: 'تنبيهات بريد إلكتروني فورية',
          description: 'إرسال SOS بالبريد الإلكتروني لجميع جهات الاتصال في وقت واحد'
        },
        {
          title: 'رسالة ثنائية اللغة',
          description: 'تنبيه الطوارئ يُرسل بالإنجليزية والعربية'
        },
        {
          title: 'مشاركة الموقع',
          description: 'إحداثيات GPS ترسل تلقائيا'
        }
      ]
    }
  };

  const t = content[language];

  const saveContacts = async (updated: Contact[]) => {
    if (!isAuthenticated) return;
    setSaving(true);
    try {
      const payload = updated.map(({ name, email, phone }) => ({ name, email, phone, relationship: '' }));
      const data = await http<{ user: { emergencyContacts: { _id?: string; name: string; email: string; phone: string; relationship: string }[] } }>(
        '/users/update-profile',
        { method: 'PUT', body: { emergencyContacts: payload }, auth: true }
      );
      if (data.user?.emergencyContacts) {
        const saved = data.user.emergencyContacts.map((c, i) => ({
          id: c._id ?? String(i),
          name: c.name,
          email: c.email ?? '',
          phone: c.phone ?? '',
        }));
        setContacts(saved);
        updateUser({ emergencyContacts: data.user.emergencyContacts });
      }
    } catch {
      // revert on failure — contacts already reflect old state if we revert
    } finally {
      setSaving(false);
    }
  };

  const addContact = async () => {
    if (!newContact.name || !newContact.email) return;
    const updated = [...contacts, { id: Date.now().toString(), ...newContact }];
    setContacts(updated);
    setNewContact({ name: '', email: '', phone: '' });
    setShowForm(false);
    await saveContacts(updated);
  };

  const removeContact = async (id: string) => {
    const updated = contacts.filter(c => c.id !== id);
    setContacts(updated);
    await saveContacts(updated);
  };

  const triggerSOS = async () => {
    const emailContacts = contacts.filter(c => c.email.trim() && c.email.includes('@'));
    if (emailContacts.length === 0) return;

    setSosActive(true);
    setSosStatus(null);

    try {
      let location: { lat: number; lng: number } | undefined;
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
          navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 })
        );
        location = { lat: pos.coords.latitude, lng: pos.coords.longitude };
      } catch {
        // location unavailable — send without it
      }

      const response = await fetch('/api/sos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          to: emailContacts.map(c => c.email.trim()),
          senderName: 'Ishara Website User',
          senderPhone: emailContacts[0]?.phone || '',
          ...(location ? { location } : {}),
        }),
      });

      const data = await response.json();
      setSosStatus({ sent: data.sent ?? 0, failed: data.failed ?? 0 });
    } catch {
      setSosStatus({ sent: 0, failed: emailContacts.length });
    }

    setTimeout(() => {
      setSosActive(false);
      setSosStatus(null);
    }, 5000);
  };

  return (
    <section id="safety" className="min-h-screen py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-[#F97316]/5 to-background" />

      <div className="container mx-auto px-6 relative z-10">
        <ScrollReveal>
          <div className="text-center mb-20">
            <motion.div
              className="inline-block mb-4"
              animate={{
                scale: [1, 1.2, 1],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
              }}
            >
              <Shield className="w-16 h-16 text-[#F97316]" />
            </motion.div>
            <h2 className="mb-4">{t.title}</h2>
            <p className="text-muted-foreground text-xl max-w-3xl mx-auto">
              {t.subtitle}
            </p>
          </div>
        </ScrollReveal>

        {/* Features */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {t.features.map((feature, index) => (
            <ScrollReveal key={index} delay={index * 0.1}>
              <div className="bg-card p-6 rounded-2xl text-center">
                <h3 className="mb-2">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </div>
            </ScrollReveal>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Contact Manager */}
          <ScrollReveal direction="left">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <div className="flex items-center justify-between mb-6">
                <h3>Emergency Contacts</h3>
                <div className="flex items-center gap-2">
                  {saving && <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />}
                  {isAuthenticated && (
                    <MagneticButton
                      onClick={() => setShowForm(!showForm)}
                      className="p-3 bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-xl"
                    >
                      <Plus className="w-5 h-5" />
                    </MagneticButton>
                  )}
                </div>
              </div>

              {!isAuthenticated && (
                <div className="text-center py-8 text-muted-foreground">
                  <AlertCircle className="w-10 h-10 mx-auto mb-3 opacity-50" />
                  <p className="font-medium">Sign in to save emergency contacts</p>
                  <p className="text-sm mt-1">Your contacts will be stored securely in your account.</p>
                </div>
              )}

              {/* Add Contact Form */}
              <AnimatePresence>
                {showForm && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    className="mb-6 overflow-hidden"
                  >
                    <div className="bg-secondary/50 p-6 rounded-2xl space-y-4">
                      <input
                        type="text"
                        placeholder={t.name}
                        value={newContact.name}
                        onChange={(e) => setNewContact({ ...newContact, name: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-[#14B8A6] outline-none transition-colors"
                      />
                      <input
                        type="email"
                        placeholder={t.email}
                        value={newContact.email}
                        onChange={(e) => setNewContact({ ...newContact, email: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-[#14B8A6] outline-none transition-colors"
                      />
                      <input
                        type="tel"
                        placeholder={t.phone}
                        value={newContact.phone}
                        onChange={(e) => setNewContact({ ...newContact, phone: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl bg-background border border-border focus:border-[#14B8A6] outline-none transition-colors"
                      />
                      <div className="flex gap-3">
                        <button
                          onClick={addContact}
                          className="flex-1 py-3 bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-xl"
                        >
                          {t.save}
                        </button>
                        <button
                          onClick={() => setShowForm(false)}
                          className="px-6 py-3 bg-secondary rounded-xl"
                        >
                          {t.cancel}
                        </button>
                      </div>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Contact List */}
              <div className="space-y-3">
                <AnimatePresence>
                  {contacts.map((contact, index) => (
                      <motion.div
                        key={contact.id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 20 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex items-center justify-between p-4 bg-secondary/50 rounded-xl group hover:bg-secondary transition-colors"
                      >
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-gradient-to-br from-[#14B8A6] to-[#F97316] rounded-full flex items-center justify-center">
                            <Mail className="w-6 h-6 text-white" />
                          </div>
                          <div>
                            <p>{contact.name}</p>
                            <p className="text-sm text-muted-foreground">{contact.email}</p>
                          </div>
                        </div>
                        <motion.button
                          onClick={() => removeContact(contact.id)}
                          className="opacity-0 group-hover:opacity-100 p-2 hover:bg-destructive/20 rounded-lg transition-all"
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                        >
                          <Trash2 className="w-5 h-5 text-destructive" />
                        </motion.button>
                      </motion.div>
                  ))}
                </AnimatePresence>

                {contacts.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
                    <p>{t.noContacts}</p>
                    <p className="text-sm">{t.addFirst}</p>
                  </div>
                )}
              </div>
            </div>
          </ScrollReveal>

          {/* SOS Demo */}
          <ScrollReveal direction="right">
            <div className="bg-card p-8 rounded-3xl shadow-2xl">
              <h3 className="mb-6">SOS Alert System</h3>

              {/* SOS Button */}
              <motion.button
                onClick={triggerSOS}
                disabled={contacts.filter(c => c.email.includes('@')).length === 0 || sosActive}
                className={`relative w-full aspect-square rounded-full mb-8 ${contacts.filter(c => c.email.includes('@')).length === 0 ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'
                  }`}
                whileHover={contacts.filter(c => c.email.includes('@')).length > 0 ? { scale: 1.05 } : {}}
                whileTap={contacts.filter(c => c.email.includes('@')).length > 0 ? { scale: 0.95 } : {}}
              >
                <motion.div
                  className="absolute inset-0 rounded-full bg-gradient-to-br from-red-500 to-orange-500"
                  animate={sosActive ? {
                    scale: [1, 1.2, 1],
                    boxShadow: [
                      '0 0 0 0 rgba(239, 68, 68, 0.7)',
                      '0 0 0 40px rgba(239, 68, 68, 0)',
                      '0 0 0 0 rgba(239, 68, 68, 0)'
                    ]
                  } : {}}
                  transition={{ duration: 1, repeat: sosActive ? Infinity : 0 }}
                />
                <div className="relative z-10 flex flex-col items-center justify-center h-full text-white">
                  {sosActive ? (
                    <>
                      <AlertCircle className="w-20 h-20 mb-4" />
                      <span className="text-3xl">{t.sosActive}</span>
                    </>
                  ) : (
                    <>
                      <Shield className="w-20 h-20 mb-4" />
                      <span className="text-2xl">SOS</span>
                      <span className="text-sm mt-2">{t.testSOS}</span>
                    </>
                  )}
                </div>
              </motion.button>

              {/* Message Flow Visualization */}
              <AnimatePresence>
                {sosActive && (
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    className="space-y-4"
                  >
                    {!sosStatus ? (
                      <>
                        <p className="text-center text-muted-foreground mb-4">{t.sending}</p>
                        {contacts.filter(c => c.email.includes('@')).map((contact, index) => (
                          <motion.div
                            key={contact.id}
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: index * 0.3 }}
                            className="flex items-center gap-3 p-4 bg-secondary/50 border border-border rounded-xl"
                          >
                            <Mail className="w-5 h-5 text-[#14B8A6]" />
                            <span>Email → {contact.name} ({contact.email})</span>
                          </motion.div>
                        ))}
                      </>
                    ) : sosStatus.sent > 0 ? (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="p-6 bg-green-500/20 border border-green-500 rounded-xl text-center"
                      >
                        <Check className="w-12 h-12 text-green-500 mx-auto mb-2" />
                        <p>{t.messagesSent(sosStatus.sent)}</p>
                      </motion.div>
                    ) : (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="p-6 bg-red-500/20 border border-red-500 rounded-xl text-center"
                      >
                        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-2" />
                        <p>{t.sendFailed}</p>
                      </motion.div>
                    )}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}
