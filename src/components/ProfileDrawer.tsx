import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import {
    X, Pencil, Camera, Save, Plus, Trash2, Loader2,
    Moon, Sun, Bell, Shield, User, ChevronRight
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useApp } from './AppProviders';
import * as userApi from '../api/userApi';

interface ProfileDrawerProps {
    isOpen: boolean;
    onClose: () => void;
}

const disabilityLabels: Record<string, string> = {
    deaf: '🤟 Deaf',
    'non-verbal': '🤐 Non-Verbal',
    blind: '👁️ Blind',
    hearing: '👂 Hearing',
};

export function ProfileDrawer({ isOpen, onClose }: ProfileDrawerProps) {
    const { user, token, updateUser } = useAuth();
    const { theme, toggleTheme } = useApp();

    const [isEditing, setIsEditing] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
    const [avatarFile, setAvatarFile] = useState<File | null>(null);
    const [toastMsg, setToastMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Form state
    const [formName, setFormName] = useState(user?.name ?? '');
    const [formBio, setFormBio] = useState(user?.bio ?? '');
    const [emergencyContacts, setEmergencyContacts] = useState(user?.emergencyContacts ?? []);
    const [newContact, setNewContact] = useState({ name: '', phone: '', relationship: '' });

    // Sync form state when user changes or drawer opens
    useEffect(() => {
        if (user && isOpen) {
            setFormName(user.name);
            setFormBio(user.bio ?? '');
            setEmergencyContacts(user.emergencyContacts ?? []);
        }
    }, [user, isOpen]);

    // Auto-dismiss toast
    useEffect(() => {
        if (toastMsg) {
            const t = setTimeout(() => setToastMsg(null), 3000);
            return () => clearTimeout(t);
        }
    }, [toastMsg]);

    // Close on Escape
    useEffect(() => {
        const handler = (e: KeyboardEvent) => {
            if (e.key === 'Escape' && isOpen) onClose();
        };
        window.addEventListener('keydown', handler);
        return () => window.removeEventListener('keydown', handler);
    }, [isOpen, onClose]);

    const showToast = (type: 'success' | 'error', text: string) => setToastMsg({ type, text });

    const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        setAvatarFile(file);
        const reader = new FileReader();
        reader.onload = () => setAvatarPreview(reader.result as string);
        reader.readAsDataURL(file);
    };

    const addContact = () => {
        const { name, phone, relationship } = newContact;
        if (!name.trim() || !phone.trim()) {
            showToast('error', 'Name and phone are required');
            return;
        }
        setEmergencyContacts([...emergencyContacts, {
            name: name.trim(), phone: phone.trim(), relationship: relationship.trim()
        }]);
        setNewContact({ name: '', phone: '', relationship: '' });
    };

    const removeContact = (index: number) => {
        setEmergencyContacts(emergencyContacts.filter((_: any, i: number) => i !== index));
    };

    const handleSave = async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            // Upload avatar if changed
            if (avatarFile) {
                const fd = new FormData();
                fd.append('avatar', avatarFile);
                const avatarRes = await userApi.updateAvatar(token, fd);
                updateUser({ profilePic: avatarRes.avatar ?? avatarRes.profilePic });
            }
            // Save profile
            const profileRes = await userApi.updateProfile(token, {
                name: formName,
                bio: formBio || '',
                emergencyContacts,
            });
            updateUser(profileRes.user ?? { name: formName, bio: formBio, emergencyContacts });
            showToast('success', 'Profile updated!');
            setIsEditing(false);
            setAvatarFile(null);
            setAvatarPreview(null);
        } catch (err: any) {
            showToast('error', err.message || 'Failed to update profile');
        } finally {
            setIsLoading(false);
        }
    };

    const cancelEdit = () => {
        setIsEditing(false);
        setAvatarPreview(null);
        setAvatarFile(null);
        setFormName(user?.name ?? '');
        setFormBio(user?.bio ?? '');
        setEmergencyContacts(user?.emergencyContacts ?? []);
    };

    // Initials avatar
    const initials = user?.name
        ? user.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
        : '?';

    if (!user) return null;

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        className="fixed inset-0 z-[90] bg-black/50 backdrop-blur-sm"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                    />

                    {/* Drawer */}
                    <motion.div
                        className="fixed top-0 right-0 z-[91] h-full w-full max-w-md bg-card border-l border-border shadow-2xl overflow-y-auto"
                        initial={{ x: '100%' }}
                        animate={{ x: 0 }}
                        exit={{ x: '100%' }}
                        transition={{ type: 'spring', damping: 30, stiffness: 300 }}
                    >
                        {/* Toast */}
                        <AnimatePresence>
                            {toastMsg && (
                                <motion.div
                                    initial={{ opacity: 0, y: -20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    exit={{ opacity: 0, y: -20 }}
                                    className={`absolute top-4 left-4 right-4 z-10 p-3 rounded-xl text-sm text-center font-medium ${toastMsg.type === 'success'
                                            ? 'bg-green-500/20 border border-green-500/50 text-green-400'
                                            : 'bg-red-500/20 border border-red-500/50 text-red-400'
                                        }`}
                                >
                                    {toastMsg.text}
                                </motion.div>
                            )}
                        </AnimatePresence>

                        <div className="p-6">
                            {/* Header */}
                            <div className="flex items-center justify-between mb-6">
                                <div>
                                    <h2 className="text-xl font-semibold">Profile</h2>
                                    <p className="text-sm text-muted-foreground">Manage your account</p>
                                </div>
                                <motion.button
                                    onClick={onClose}
                                    className="p-2 rounded-lg hover:bg-secondary transition-colors"
                                    whileHover={{ scale: 1.1 }}
                                    whileTap={{ scale: 0.9 }}
                                >
                                    <X className="w-5 h-5" />
                                </motion.button>
                            </div>

                            {/* Profile Card */}
                            <div className="p-5 rounded-2xl bg-gradient-to-br from-[#14B8A6] to-[#F97316] text-white mb-6">
                                <div className="flex items-center gap-4">
                                    <div className="relative">
                                        {avatarPreview ? (
                                            <img
                                                src={avatarPreview}
                                                alt="Preview"
                                                className="w-16 h-16 rounded-full object-cover ring-2 ring-white/30"
                                            />
                                        ) : user.profilePic ? (
                                            <img
                                                src={user.profilePic}
                                                alt={user.name}
                                                className="w-16 h-16 rounded-full object-cover ring-2 ring-white/30"
                                            />
                                        ) : (
                                            <div className="w-16 h-16 rounded-full bg-white/20 flex items-center justify-center text-xl font-bold">
                                                {initials}
                                            </div>
                                        )}
                                        {isEditing && (
                                            <button
                                                type="button"
                                                onClick={() => fileInputRef.current?.click()}
                                                className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full bg-white text-[#14B8A6] flex items-center justify-center shadow-lg hover:bg-gray-100 transition"
                                                aria-label="Change avatar"
                                            >
                                                <Camera className="w-3.5 h-3.5" />
                                            </button>
                                        )}
                                        <input
                                            ref={fileInputRef}
                                            type="file"
                                            accept="image/*"
                                            className="hidden"
                                            onChange={handleAvatarChange}
                                        />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <p className="text-lg font-semibold truncate">{user.name}</p>
                                        <p className="text-sm opacity-90 truncate">{user.email}</p>
                                    </div>
                                    <div className="shrink-0">
                                        {!isEditing ? (
                                            <button
                                                onClick={() => setIsEditing(true)}
                                                className="px-3 py-1.5 rounded-xl bg-white/20 text-sm font-medium backdrop-blur-sm hover:bg-white/30 transition flex items-center gap-1.5"
                                            >
                                                <Pencil className="w-3.5 h-3.5" /> Edit
                                            </button>
                                        ) : (
                                            <button
                                                onClick={cancelEdit}
                                                className="px-3 py-1.5 rounded-xl bg-white/20 text-sm font-medium backdrop-blur-sm hover:bg-white/30 transition flex items-center gap-1.5"
                                            >
                                                <X className="w-3.5 h-3.5" /> Cancel
                                            </button>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Personal Info */}
                            <div className="mb-6">
                                <h3 className="text-xs font-medium text-muted-foreground mb-3 px-1 uppercase tracking-wider">Personal Info</h3>
                                <div className="space-y-2">
                                    {/* Name */}
                                    <div className="p-4 rounded-xl bg-secondary border border-border">
                                        <label className="block text-sm font-medium mb-1.5">Name</label>
                                        {isEditing ? (
                                            <input
                                                type="text"
                                                value={formName}
                                                onChange={e => setFormName(e.target.value)}
                                                className="w-full px-3 py-2 rounded-lg bg-background border border-border text-foreground outline-none focus:border-[#14B8A6] transition-colors text-sm"
                                            />
                                        ) : (
                                            <p className="text-sm text-muted-foreground">{user.name}</p>
                                        )}
                                    </div>

                                    {/* Bio */}
                                    <div className="p-4 rounded-xl bg-secondary border border-border">
                                        <label className="block text-sm font-medium mb-1.5">Bio</label>
                                        {isEditing ? (
                                            <textarea
                                                rows={3}
                                                value={formBio}
                                                onChange={e => setFormBio(e.target.value)}
                                                className="w-full px-3 py-2 rounded-lg bg-background border border-border text-foreground outline-none focus:border-[#14B8A6] transition-colors text-sm resize-none"
                                                maxLength={300}
                                            />
                                        ) : (
                                            <p className="text-sm text-muted-foreground">{user.bio || 'No bio yet'}</p>
                                        )}
                                    </div>

                                    {/* Email (read-only) */}
                                    <div className="p-4 rounded-xl bg-secondary border border-border flex items-center gap-3">
                                        <div className="flex-1">
                                            <label className="block text-sm font-medium">Email</label>
                                            <p className="text-sm text-muted-foreground">{user.email}</p>
                                        </div>
                                        <ChevronRight className="w-4 h-4 text-muted-foreground" />
                                    </div>

                                    {/* Disability Type (read-only) */}
                                    <div className="p-4 rounded-xl bg-secondary border border-border flex items-center gap-3">
                                        <div className="flex-1">
                                            <label className="block text-sm font-medium">User Type</label>
                                            <p className="text-sm text-muted-foreground">
                                                {disabilityLabels[user.disabilityType || ''] || user.disabilityType || 'Not set'}
                                            </p>
                                        </div>
                                        <ChevronRight className="w-4 h-4 text-muted-foreground" />
                                    </div>
                                </div>
                            </div>

                            {/* General Settings */}
                            <div className="mb-6">
                                <h3 className="text-xs font-medium text-muted-foreground mb-3 px-1 uppercase tracking-wider">General</h3>
                                <div className="space-y-2">
                                    {/* Dark Mode Toggle */}
                                    <button
                                        type="button"
                                        onClick={toggleTheme}
                                        className="w-full p-4 rounded-xl bg-secondary border border-border flex items-center gap-3 hover:bg-accent transition-colors"
                                    >
                                        {theme === 'dark' ? <Moon className="w-5 h-5 text-muted-foreground" /> : <Sun className="w-5 h-5 text-muted-foreground" />}
                                        <span className="flex-1 text-left text-sm font-medium">Dark Mode</span>
                                        <div className={`w-11 h-6 rounded-full transition-all ${theme === 'dark' ? 'bg-gradient-to-r from-[#14B8A6] to-[#F97316]' : 'bg-gray-300 dark:bg-gray-600'}`}>
                                            <div className={`w-5 h-5 bg-white rounded-full shadow-md mt-0.5 transition-transform ${theme === 'dark' ? 'translate-x-[22px]' : 'translate-x-[2px]'}`} />
                                        </div>
                                    </button>

                                    {/* Notifications */}
                                    <div className="p-4 rounded-xl bg-secondary border border-border flex items-center gap-3">
                                        <Bell className="w-5 h-5 text-muted-foreground" />
                                        <span className="flex-1 text-sm font-medium">Notifications</span>
                                        <span className="text-sm text-muted-foreground">On</span>
                                        <ChevronRight className="w-4 h-4 text-muted-foreground" />
                                    </div>
                                </div>
                            </div>

                            {/* Privacy & Security */}
                            <div className="mb-6">
                                <h3 className="text-xs font-medium text-muted-foreground mb-3 px-1 uppercase tracking-wider">Privacy & Security</h3>
                                <div className="space-y-2">
                                    {[
                                        { icon: Shield, label: 'Privacy Settings' },
                                        { icon: User, label: 'Account Security' },
                                    ].map((item) => (
                                        <div key={item.label} className="p-4 rounded-xl bg-secondary border border-border flex items-center gap-3 hover:bg-accent transition-colors cursor-pointer">
                                            <item.icon className="w-5 h-5 text-muted-foreground" />
                                            <span className="flex-1 text-sm font-medium">{item.label}</span>
                                            <ChevronRight className="w-4 h-4 text-muted-foreground" />
                                        </div>
                                    ))}
                                </div>
                            </div>

                            {/* Emergency Contacts */}
                            <div className="mb-6">
                                <h3 className="text-xs font-medium text-muted-foreground mb-3 px-1 uppercase tracking-wider">Emergency Contacts</h3>
                                <div className="space-y-2">
                                    {emergencyContacts.map((contact: any, i: number) => (
                                        <div key={i} className="p-4 rounded-xl bg-secondary border border-border flex items-center gap-3">
                                            <User className="w-5 h-5 text-muted-foreground shrink-0" />
                                            <div className="flex-1 min-w-0">
                                                <span className="text-sm font-medium">
                                                    {typeof contact === 'string' ? contact : contact.name}
                                                </span>
                                                {typeof contact === 'object' && contact.phone && (
                                                    <span className="ml-2 text-xs text-muted-foreground">{contact.phone}</span>
                                                )}
                                                {typeof contact === 'object' && contact.relationship && (
                                                    <span className="ml-2 px-2 py-0.5 rounded-full bg-[#14B8A6]/10 text-xs font-medium text-[#14B8A6]">
                                                        {contact.relationship}
                                                    </span>
                                                )}
                                            </div>
                                            {isEditing && (
                                                <button
                                                    type="button"
                                                    onClick={() => removeContact(i)}
                                                    className="text-red-400 hover:text-red-300 transition"
                                                    aria-label={`Remove ${typeof contact === 'string' ? contact : contact.name}`}
                                                >
                                                    <Trash2 className="w-4 h-4" />
                                                </button>
                                            )}
                                        </div>
                                    ))}
                                    {emergencyContacts.length === 0 && (
                                        <p className="px-4 py-3 text-sm text-muted-foreground">No emergency contacts</p>
                                    )}
                                </div>

                                {/* Add contact form */}
                                {isEditing && (
                                    <div className="mt-3 space-y-2">
                                        <div className="flex gap-2">
                                            <input
                                                type="text"
                                                value={newContact.name}
                                                onChange={e => setNewContact({ ...newContact, name: e.target.value })}
                                                placeholder="Name"
                                                className="flex-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground placeholder-muted-foreground outline-none focus:border-[#14B8A6] transition-colors"
                                            />
                                            <input
                                                type="text"
                                                value={newContact.phone}
                                                onChange={e => setNewContact({ ...newContact, phone: e.target.value })}
                                                placeholder="Phone"
                                                className="flex-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground placeholder-muted-foreground outline-none focus:border-[#14B8A6] transition-colors"
                                            />
                                        </div>
                                        <div className="flex gap-2">
                                            <input
                                                type="text"
                                                value={newContact.relationship}
                                                onChange={e => setNewContact({ ...newContact, relationship: e.target.value })}
                                                onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); addContact(); } }}
                                                placeholder="Relationship (e.g. Mother)"
                                                className="flex-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground placeholder-muted-foreground outline-none focus:border-[#14B8A6] transition-colors"
                                            />
                                            <button
                                                type="button"
                                                onClick={addContact}
                                                className="px-4 py-2 rounded-lg bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white text-sm font-medium hover:shadow-lg transition-shadow flex items-center gap-1"
                                            >
                                                <Plus className="w-4 h-4" /> Add
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Save button */}
                            {isEditing && (
                                <motion.button
                                    onClick={handleSave}
                                    disabled={isLoading}
                                    className="w-full py-3 bg-gradient-to-r from-[#14B8A6] to-[#F97316] text-white rounded-xl font-medium hover:shadow-lg transition-shadow disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                                    whileHover={{ scale: 1.02 }}
                                    whileTap={{ scale: 0.98 }}
                                >
                                    {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
                                    {isLoading ? 'Saving…' : 'Save Changes'}
                                </motion.button>
                            )}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
