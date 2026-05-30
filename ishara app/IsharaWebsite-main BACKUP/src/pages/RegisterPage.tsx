// src/pages/RegisterPage.tsx
import { useState } from 'react';
import { Link, useNavigate, Navigate } from 'react-router-dom';
import { UserPlus, Loader2, Eye, EyeOff, Mail, Lock, User, ArrowLeft } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useAuth } from '../hooks/useAuth';
import * as authApi from '../api/authApi';
import { AuthPageShell } from '../components/auth/AuthPageShell';

const DISABILITY_OPTIONS = [
  { value: 'deaf', emoji: '🤟', label: 'Deaf', desc: 'Hard of hearing' },
  { value: 'non-verbal', emoji: '🤐', label: 'Non-Verbal', desc: 'Speech impaired' },
  { value: 'blind', emoji: '👁️', label: 'Blind', desc: 'Visually impaired' },
] as const;

export default function RegisterPage() {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [step, setStep] = useState(1);

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [disabilityType, setDisabilityType] = useState<'deaf' | 'non-verbal' | 'blind'>('deaf');

  if (isAuthenticated) return <Navigate to="/" replace />;

  const inputCls = 'w-full py-3.5 rounded-2xl bg-secondary border border-border text-foreground placeholder:text-muted-foreground/60 outline-none transition-all focus:border-[var(--ishara-brand-teal)] focus:shadow-[0_0_0_3px_rgba(20,184,166,0.15)] hover:border-[var(--ishara-brand-teal)]/40';

  const handleRegister = async () => {
    setLoading(true);
    setError('');
    try {
      if (password !== confirmPassword) {
        setError('Passwords do not match.');
        setStep(2);
        return;
      }
      await authApi.register({ name, email, password, confirmPassword, disabilityType });
      navigate('/verify-otp', { state: { email }, replace: true });
    } catch (err: unknown) {
      const ex = err as { message?: string };
      setError(ex.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const nextStep = () => {
    if (step === 1 && (!name.trim() || !email.trim())) { setError('Please fill in all fields.'); return; }
    if (step === 2 && (!password || !confirmPassword)) { setError('Please fill in all fields.'); return; }
    if (step === 2 && password !== confirmPassword) { setError('Passwords do not match.'); return; }
    setError('');
    setStep(step + 1);
  };

  return (
    <AuthPageShell
      title="Join Ishara"
      subtitle="Create your account in 3 simple steps"
      footer={
        <Link to="/" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center justify-center gap-1.5">
          <ArrowLeft className="w-4 h-4" />
          Back to Home
        </Link>
      }
    >
      {/* Step indicator */}
      <div className="flex items-center justify-center gap-2 mb-2">
        {[1, 2, 3].map((s) => (
          <div key={s} className="flex items-center gap-2">
            <motion.div
              className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all ${
                step >= s
                  ? 'bg-gradient-to-br from-[#14B8A6] to-[#F97316] text-white shadow-lg shadow-teal-500/20'
                  : 'bg-secondary text-muted-foreground border border-border'
              }`}
              animate={step === s ? { scale: [1, 1.1, 1] } : {}}
              transition={{ duration: 0.3 }}
            >
              {s}
            </motion.div>
            {s < 3 && <div className={`w-8 h-0.5 rounded-full transition-colors ${step > s ? 'bg-[var(--ishara-brand-teal)]' : 'bg-border'}`} />}
          </div>
        ))}
      </div>

      {error && (
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          role="alert"
          className="p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-red-700 dark:text-red-400 text-sm"
        >
          {error}
        </motion.div>
      )}

      <AnimatePresence mode="wait">
        {step === 1 && (
          <motion.div key="step1" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-4">
            <div>
              <label htmlFor="name" className="block mb-2 text-sm font-medium text-foreground">Full Name</label>
              <div className="relative group">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
                <input id="name" type="text" placeholder="Your name" value={name} onChange={(e) => setName(e.target.value)} required autoComplete="name" className={inputCls + ' pl-11 pr-4'} />
              </div>
            </div>
            <div>
              <label htmlFor="reg-email" className="block mb-2 text-sm font-medium text-foreground">Email Address</label>
              <div className="relative group">
                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
                <input id="reg-email" type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" className={inputCls + ' pl-11 pr-4'} />
              </div>
            </div>
            <motion.button type="button" onClick={nextStep} className="w-full py-4 rounded-2xl font-semibold text-white bg-gradient-to-r from-[#14B8A6] to-[#F97316] shadow-lg shadow-teal-500/25 hover:shadow-xl hover:brightness-[1.05] active:scale-[0.99] flex items-center justify-center gap-2 transition-all" whileHover={{ scale: 1.01 }} whileTap={{ scale: 0.98 }}>
              Continue →
            </motion.button>
          </motion.div>
        )}

        {step === 2 && (
          <motion.div key="step2" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-4">
            <div>
              <label htmlFor="reg-pass" className="block mb-2 text-sm font-medium text-foreground">Password</label>
              <div className="relative group">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
                <input id="reg-pass" type={showPassword ? 'text' : 'password'} placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={8} autoComplete="new-password" className={inputCls + ' pl-11 pr-14'} />
                <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-muted-foreground/40 hover:text-foreground transition-colors" aria-label={showPassword ? 'Hide' : 'Show'}>
                  {showPassword ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
                </button>
              </div>
              <p className="mt-2 text-xs text-muted-foreground">Min 8 characters with a letter and number.</p>
            </div>
            <div>
              <label htmlFor="reg-confirm" className="block mb-2 text-sm font-medium text-foreground">Confirm Password</label>
              <div className="relative group">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
                <input id="reg-confirm" type={showPassword ? 'text' : 'password'} placeholder="••••••••" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} required minLength={8} autoComplete="new-password" className={inputCls + ' pl-11 pr-4'} />
              </div>
            </div>
            <div className="flex gap-3">
              <button type="button" onClick={() => { setStep(1); setError(''); }} className="flex-1 py-3.5 rounded-2xl font-medium text-muted-foreground bg-secondary border border-border hover:bg-accent transition-all">← Back</button>
              <motion.button type="button" onClick={nextStep} className="flex-[2] py-3.5 rounded-2xl font-semibold text-white bg-gradient-to-r from-[#14B8A6] to-[#F97316] shadow-lg shadow-teal-500/25 hover:shadow-xl hover:brightness-[1.05] transition-all" whileHover={{ scale: 1.01 }} whileTap={{ scale: 0.98 }}>Continue →</motion.button>
            </div>
          </motion.div>
        )}

        {step === 3 && (
          <motion.div key="step3" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-4">
            <p className="text-sm text-muted-foreground text-center">Select your user type</p>
            <div className="grid grid-cols-3 gap-3">
              {DISABILITY_OPTIONS.map((opt) => (
                <motion.button
                  key={opt.value}
                  type="button"
                  onClick={() => setDisabilityType(opt.value)}
                  className={`relative p-4 rounded-2xl border-2 text-center transition-all ${
                    disabilityType === opt.value
                      ? 'border-[var(--ishara-brand-teal)] bg-[var(--ishara-brand-teal)]/10 shadow-lg shadow-teal-500/10'
                      : 'border-border bg-secondary hover:border-[var(--ishara-brand-teal)]/30 hover:bg-accent'
                  }`}
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                >
                  <span className="text-2xl block mb-2">{opt.emoji}</span>
                  <span className="text-sm font-medium text-foreground block">{opt.label}</span>
                  <span className="text-[10px] text-muted-foreground block mt-0.5">{opt.desc}</span>
                  {disabilityType === opt.value && (
                    <motion.div layoutId="selectedType" className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-[var(--ishara-brand-teal)] flex items-center justify-center" transition={{ type: 'spring', stiffness: 500, damping: 30 }}>
                      <span className="text-white text-xs">✓</span>
                    </motion.div>
                  )}
                </motion.button>
              ))}
            </div>
            <div className="flex gap-3">
              <button type="button" onClick={() => { setStep(2); setError(''); }} className="flex-1 py-3.5 rounded-2xl font-medium text-muted-foreground bg-secondary border border-border hover:bg-accent transition-all">← Back</button>
              <motion.button type="button" onClick={handleRegister} disabled={loading} className="flex-[2] py-3.5 rounded-2xl font-semibold text-white bg-gradient-to-r from-[#14B8A6] to-[#F97316] shadow-lg shadow-teal-500/25 hover:shadow-xl hover:brightness-[1.05] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 transition-all" whileHover={{ scale: loading ? 1 : 1.01 }} whileTap={{ scale: loading ? 1 : 0.98 }}>
                {loading ? (<><Loader2 className="w-5 h-5 animate-spin" />Creating…</>) : (<><UserPlus className="w-5 h-5" />Create Account</>)}
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <p className="text-center text-sm text-muted-foreground">
        Already have an account?{' '}
        <Link to="/login" className="text-[var(--ishara-brand-teal)] hover:underline underline-offset-4 transition-colors font-medium">Sign In</Link>
      </p>
    </AuthPageShell>
  );
}