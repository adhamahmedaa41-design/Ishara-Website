import { useState, useEffect, useRef } from 'react';
import { Navigate, Link } from 'react-router-dom';
import {
  User, Pencil, Camera, Save, X, Plus, Trash2, Loader2, AlertCircle,
  Moon, Sun, ChevronRight, Shield, Settings, UserCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useAuth } from '../hooks/useAuth';
import { UserAvatar } from '../components/UserAvatar';
import { useApp } from '../components/AppProviders';
import * as userApi from '../api/userApi';
import { getMe } from '../api/authApi';

const disabilityLabels: Record<string, string> = {
  deaf: '🤟 Deaf', 'non-verbal': '🤐 Non-Verbal', blind: '👁️ Blind', hearing: '👂 Hearing',
};

type TabId = 'personal' | 'emergency' | 'settings';

export default function ProfilePage() {
  const { user, token, updateUser, login } = useAuth();
  const { theme, toggleTheme } = useApp();

  const [activeTab, setActiveTab] = useState<TabId>('personal');
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [fetchLoading, setFetchLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const [formName, setFormName] = useState(user?.name ?? '');
  const [formBio, setFormBio] = useState(user?.bio ?? '');
  const [emergencyContacts, setEmergencyContacts] = useState<{ name: string; phone: string; relationship: string }[]>(user?.emergencyContacts ?? []);
  const [newContact, setNewContact] = useState({ name: '', phone: '', relationship: '' });
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (user) { setFetchLoading(false); setFormName(user.name ?? ''); setFormBio(user.bio ?? ''); setEmergencyContacts(user.emergencyContacts ?? []); return; }
    if (!token) { setFetchLoading(false); return; }
    getMe(token)
      .then((data) => { const u = data.user; login(token, { ...u, name: u.name ?? '', emergencyContacts: u.emergencyContacts ?? [] }); setFormName(u.name ?? ''); setFormBio(u.bio ?? ''); setEmergencyContacts(u.emergencyContacts ?? []); })
      .catch(() => setFetchError('Failed to load profile'))
      .finally(() => setFetchLoading(false));
  }, [token, login]);

  useEffect(() => { if (user) { setFormName(user.name ?? ''); setFormBio(user.bio ?? ''); setEmergencyContacts(user.emergencyContacts ?? []); } }, [user]);

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]; if (!file) return;
    setAvatarFile(file);
    const reader = new FileReader();
    reader.onload = () => setAvatarPreview(reader.result as string);
    reader.readAsDataURL(file);
  };

  const addContact = () => {
    if (!newContact.name.trim() || !newContact.phone.trim()) return;
    setEmergencyContacts([...emergencyContacts, { name: newContact.name.trim(), phone: newContact.phone.trim(), relationship: newContact.relationship.trim() }]);
    setNewContact({ name: '', phone: '', relationship: '' });
  };

  const removeContact = (index: number) => setEmergencyContacts(emergencyContacts.filter((_, i) => i !== index));

  const handleSave = async () => {
    if (!token) return;
    setIsLoading(true);
    try {
      if (avatarFile) { const fd = new FormData(); fd.append('avatar', avatarFile); const avatarRes = await userApi.updateAvatar(token, fd); updateUser({ profilePic: avatarRes.avatar ?? (avatarRes as any).profilePic }); }
      const profileRes = await userApi.updateProfile(token, { name: formName, bio: formBio || '', emergencyContacts });
      updateUser(profileRes.user ?? { name: formName, bio: formBio, emergencyContacts });
      setIsEditing(false); setAvatarFile(null); setAvatarPreview(null);
      setSaveSuccess(true); setTimeout(() => setSaveSuccess(false), 3000);
    } finally { setIsLoading(false); }
  };

  const cancelEdit = () => { setIsEditing(false); setAvatarPreview(null); setAvatarFile(null); setFormName(user?.name ?? ''); setFormBio(user?.bio ?? ''); setEmergencyContacts(user?.emergencyContacts ?? []); };

  if (!token && !user) return <Navigate to="/" replace />;

  if (fetchLoading) return (
    <div className="flex min-h-screen items-center justify-center">
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-col items-center gap-3">
        <Loader2 className="h-8 w-8 animate-spin text-[var(--ishara-brand-teal)]" />
        <p className="text-sm text-muted-foreground">Loading profile…</p>
      </motion.div>
    </div>
  );

  if (fetchError && !user) return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="flex flex-col items-center gap-3 text-center">
        <AlertCircle className="h-10 w-10 text-destructive" />
        <p className="text-lg font-medium">Failed to load profile</p>
        <Link to="/" className="mt-2 px-6 py-2.5 bg-gradient-ishara text-white rounded-xl font-medium shadow-lg">Go to Home</Link>
      </div>
    </div>
  );

  if (!user) return <div className="flex min-h-screen items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-[var(--ishara-brand-teal)]" /></div>;

  const tabs: { id: TabId; label: string; icon: React.ElementType }[] = [
    { id: 'personal', label: 'Personal', icon: UserCircle },
    { id: 'emergency', label: 'Emergency', icon: Shield },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  const cardCls = 'p-5 rounded-2xl bg-secondary border border-border hover:border-[var(--ishara-brand-teal)]/20 transition-colors';
  const inputCls = 'w-full px-4 py-2.5 rounded-xl bg-background border border-border text-foreground outline-none focus:border-[var(--ishara-brand-teal)] transition-all';

  return (
    <div className="min-h-screen pt-24 pb-16 px-4 relative z-10">
      <div aria-hidden className="fixed inset-0 pointer-events-none -z-10">
        <div className="absolute top-[10%] left-[5%] w-[400px] h-[400px] rounded-full bg-[var(--ishara-brand-teal)]/[0.04] blur-3xl" />
        <div className="absolute bottom-[10%] right-[5%] w-[300px] h-[300px] rounded-full bg-[var(--ishara-brand-orange)]/[0.04] blur-3xl" />
      </div>

      <div className="relative z-10 w-full max-w-3xl mx-auto space-y-6">
        {/* Success toast */}
        <AnimatePresence>
          {saveSuccess && (
            <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }} className="fixed top-24 left-1/2 -translate-x-1/2 z-50 px-6 py-3 rounded-2xl bg-[var(--ishara-brand-teal)] text-white font-medium shadow-xl">
              ✓ Profile saved successfully
            </motion.div>
          )}
        </AnimatePresence>

        {/* Profile Header Card */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="relative p-8 rounded-3xl overflow-hidden bg-gradient-to-br from-[#14B8A6] to-[#F97316]">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_50%,rgba(255,255,255,0.15)_0%,transparent_60%)]" />
          <div className="relative z-10 flex items-center gap-5">
            <div className="relative">
              {avatarPreview ? (
                <img src={avatarPreview} alt="Preview" className="w-20 h-20 rounded-2xl object-cover ring-2 ring-white/30 shadow-xl" />
              ) : (
                <UserAvatar user={user} size={80} ringClassName="ring-2 ring-white/30" />
              )}
              {isEditing && (
                <button type="button" onClick={() => fileInputRef.current?.click()} className="absolute -bottom-2 -right-2 w-8 h-8 rounded-xl bg-white text-teal-600 flex items-center justify-center shadow-lg hover:bg-gray-100 transition" aria-label="Change avatar">
                  <Camera className="w-4 h-4" />
                </button>
              )}
              <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleAvatarChange} />
            </div>
            <div className="min-w-0 flex-1">
              <h1 className="text-2xl font-bold text-white truncate">{user.name}</h1>
              <p className="text-sm text-white/80 truncate">{user.email}</p>
              <span className="inline-block mt-2 px-3 py-1 rounded-full bg-white/20 backdrop-blur-sm text-xs font-medium text-white">
                {disabilityLabels[user.disabilityType || ''] || user.disabilityType || 'User'}
              </span>
            </div>
            <div className="shrink-0">
              {!isEditing ? (
                <motion.button type="button" onClick={() => setIsEditing(true)} className="px-5 py-2.5 rounded-2xl bg-white/20 backdrop-blur-sm text-sm font-medium text-white hover:bg-white/30 transition flex items-center gap-2" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                  <Pencil className="w-4 h-4" /> Edit
                </motion.button>
              ) : (
                <motion.button type="button" onClick={cancelEdit} className="px-5 py-2.5 rounded-2xl bg-white/20 backdrop-blur-sm text-sm font-medium text-white hover:bg-white/30 transition flex items-center gap-2" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                  <X className="w-4 h-4" /> Cancel
                </motion.button>
              )}
            </div>
          </div>
        </motion.div>

        {/* Tab Switcher */}
        <div className="flex p-1 rounded-2xl bg-muted border border-border">
          {tabs.map((tab) => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)} className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-medium transition-all ${activeTab === tab.id ? 'bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white shadow-lg' : 'text-muted-foreground hover:text-foreground'}`}>
              <tab.icon className="w-4 h-4" />{tab.label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <form onSubmit={(e) => { e.preventDefault(); handleSave(); }} className="space-y-4">
          <AnimatePresence mode="wait">
            {activeTab === 'personal' && (
              <motion.div key="personal" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-3">
                <div className={cardCls}>
                  <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">Name</label>
                  {isEditing ? <input type="text" value={formName} onChange={(e) => setFormName(e.target.value)} className={inputCls} /> : <p className="text-foreground">{user.name}</p>}
                </div>
                <div className={cardCls}>
                  <label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">Bio</label>
                  {isEditing ? <textarea rows={3} value={formBio} onChange={(e) => setFormBio(e.target.value)} maxLength={300} className={inputCls + ' resize-none'} /> : <p className="text-muted-foreground">{user.bio || 'No bio yet'}</p>}
                </div>
                <div className={cardCls + ' flex items-center'}>
                  <div className="flex-1"><label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider">Email</label><p className="text-muted-foreground mt-1">{user.email}</p></div>
                  <ChevronRight className="w-5 h-5 text-muted-foreground" />
                </div>
                <div className={cardCls + ' flex items-center'}>
                  <div className="flex-1"><label className="block text-xs font-medium text-muted-foreground uppercase tracking-wider">User Type</label><p className="text-muted-foreground mt-1">{disabilityLabels[user.disabilityType || ''] || 'Not set'}</p></div>
                  <ChevronRight className="w-5 h-5 text-muted-foreground" />
                </div>
              </motion.div>
            )}

            {activeTab === 'emergency' && (
              <motion.div key="emergency" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-3">
                {emergencyContacts.map((contact, i) => (
                  <motion.div key={i} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.05 }} className={cardCls + ' flex items-center gap-3'}>
                    <div className="w-10 h-10 rounded-xl bg-[var(--ishara-brand-teal)]/10 flex items-center justify-center shrink-0">
                      <User className="w-5 h-5 text-[var(--ishara-brand-teal)]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <span className="text-sm font-medium">{contact.name}</span>
                      {contact.phone && <span className="ml-2 text-xs text-muted-foreground">{contact.phone}</span>}
                      {contact.relationship && <span className="ml-2 px-2 py-0.5 rounded-full bg-[var(--ishara-brand-teal)]/10 text-[10px] font-medium text-[var(--ishara-brand-teal)]">{contact.relationship}</span>}
                    </div>
                    {isEditing && <button type="button" onClick={() => removeContact(i)} className="text-destructive hover:text-destructive/80 transition p-1"><Trash2 className="w-4 h-4" /></button>}
                  </motion.div>
                ))}
                {emergencyContacts.length === 0 && (
                  <div className="p-8 rounded-2xl bg-secondary border border-border text-center">
                    <Shield className="w-10 h-10 text-muted-foreground/30 mx-auto mb-3" />
                    <p className="text-sm text-muted-foreground">No emergency contacts added yet</p>
                  </div>
                )}
                {isEditing && (
                  <div className={cardCls + ' space-y-3'}>
                    <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Add Contact</p>
                    <div className="flex gap-2">
                      <input type="text" value={newContact.name} onChange={(e) => setNewContact({ ...newContact, name: e.target.value })} placeholder="Name" className={inputCls + ' flex-1 text-sm'} />
                      <input type="text" value={newContact.phone} onChange={(e) => setNewContact({ ...newContact, phone: e.target.value })} placeholder="Phone" className={inputCls + ' flex-1 text-sm'} />
                    </div>
                    <div className="flex gap-2">
                      <input type="text" value={newContact.relationship} onChange={(e) => setNewContact({ ...newContact, relationship: e.target.value })} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addContact(); }}} placeholder="Relationship (e.g. Mother)" className={inputCls + ' flex-1 text-sm'} />
                      <motion.button type="button" onClick={addContact} className="px-4 py-2.5 rounded-xl bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white text-sm font-medium shadow-lg flex items-center gap-1" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                        <Plus className="w-4 h-4" /> Add
                      </motion.button>
                    </div>
                  </div>
                )}
              </motion.div>
            )}

            {activeTab === 'settings' && (
              <motion.div key="settings" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-3">
                <button type="button" onClick={toggleTheme} className={cardCls + ' w-full flex items-center gap-3'}>
                  <div className="w-10 h-10 rounded-xl bg-secondary flex items-center justify-center">
                    {theme === 'dark' ? <Moon className="w-5 h-5 text-muted-foreground" /> : <Sun className="w-5 h-5 text-muted-foreground" />}
                  </div>
                  <span className="flex-1 text-left text-sm font-medium">Dark Mode</span>
                  <div className={`w-12 h-7 rounded-full transition-all ${theme === 'dark' ? 'bg-gradient-to-r from-[#14B8A6] to-[#F97316]' : 'bg-gray-300 dark:bg-gray-600'}`}>
                    <div className={`w-6 h-6 bg-white rounded-full shadow-md mt-0.5 transition-transform ${theme === 'dark' ? 'translate-x-[22px]' : 'translate-x-[2px]'}`} />
                  </div>
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {isEditing && (
            <motion.button initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} type="submit" disabled={isLoading}
              className="w-full py-4 bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-2xl font-semibold shadow-xl shadow-teal-500/25 hover:shadow-2xl hover:brightness-[1.05] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 transition-all"
              whileHover={{ scale: isLoading ? 1 : 1.01 }} whileTap={{ scale: isLoading ? 1 : 0.98 }}
            >
              {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
              {isLoading ? 'Saving…' : 'Save Changes'}
            </motion.button>
          )}
        </form>
      </div>
    </div>
  );
}
