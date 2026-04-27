import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { X, Loader2, Eye, EyeOff, LogIn, UserPlus, KeyRound, ShieldCheck } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import * as authApi from '../api/authApi';

type AuthView = 'login' | 'register' | 'verify-otp' | 'forgot-password';

interface AuthModalProps {
    isOpen: boolean;
    onClose: () => void;
}

export function AuthModal({ isOpen, onClose }: AuthModalProps) {
    const { login } = useAuth();
    const [view, setView] = useState<AuthView>('login');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [showPassword, setShowPassword] = useState(false);

    // Form states
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [name, setName] = useState('');
    const [otp, setOtp] = useState('');

    const resetForm = () => {
        setError('');
        setSuccess('');
        setPassword('');
        setOtp('');
        setShowPassword(false);
    };

    const switchView = (v: AuthView) => {
        resetForm();
        setView(v);
    };

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const data = await authApi.login({ email, password });
            login(data.token, data.user);
            onClose();
            resetForm();
        } catch (err: any) {
            if (err.isVerified === false) {
                setError('Please verify your email first.');
                setView('verify-otp');
            } else {
                setError(err.message || 'Login failed');
            }
        } finally {
            setLoading(false);
        }
    };

    const handleRegister = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await authApi.register({ email, password, name });
            setSuccess('Registration successful! Check your email for OTP.');
            setView('verify-otp');
        } catch (err: any) {
            setError(err.message || 'Registration failed');
        } finally {
            setLoading(false);
        }
    };

    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const data = await authApi.verifyOtp({ email, otp });
            login(data.token, data.user);
            onClose();
            resetForm();
        } catch (err: any) {
            setError(err.message || 'Invalid OTP');
        } finally {
            setLoading(false);
        }
    };

    const handleResendOtp = async () => {
        setLoading(true);
        setError('');
        try {
            await authApi.resendOtp({ email });
            setSuccess('New OTP sent to your email!');
        } catch (err: any) {
            setError(err.message || 'Failed to resend OTP');
        } finally {
            setLoading(false);
        }
    };

    const handleForgotPassword = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await authApi.forgotPassword({ email });
            setSuccess('Password reset link sent to your email!');
        } catch (err: any) {
            setError(err.message || 'Failed to send reset link');
        } finally {
            setLoading(false);
        }
    };

    /* ── shared Tailwind partials (no leading icons, spacious) ── */
    const inputBase =
        'w-full px-4 py-4 text-base rounded-xl bg-secondary border-2 border-transparent text-foreground placeholder-muted-foreground outline-none focus:border-[#14B8A6] focus:ring-2 focus:ring-[#14B8A6]/30 focus:ring-offset-2 focus:ring-offset-card transition-all';
    const inputWithToggle =
        'w-full pl-4 pr-12 py-4 text-base rounded-xl bg-secondary border-2 border-transparent text-foreground placeholder-muted-foreground outline-none focus:border-[#14B8A6] focus:ring-2 focus:ring-[#14B8A6]/30 focus:ring-offset-2 focus:ring-offset-card transition-all';
    const primaryBtn =
        'w-full py-4 rounded-xl font-semibold text-base text-white bg-gradient-to-r from-[#14B8A6] to-[#F97316] shadow-lg shadow-teal-500/25 hover:shadow-xl hover:shadow-teal-500/30 hover:brightness-110 disabled:opacity-60 disabled:cursor-not-allowed disabled:shadow-none flex items-center justify-center gap-2.5 transition-all';

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <motion.div
                className="fixed inset-0 z-[100] flex items-center justify-center"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
            >
                {/* Backdrop */}
                <motion.div
                    className="absolute inset-0 bg-black/50 backdrop-blur-md"
                    onClick={onClose}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                />

                {/* Modal card — wider + more padding, spacious layout */}
                <motion.div
                    className="relative bg-card rounded-3xl shadow-2xl w-full max-w-md sm:max-w-lg lg:max-w-xl mx-4 overflow-hidden border border-border"
                    initial={{ scale: 0.95, y: 24, opacity: 0 }}
                    animate={{ scale: 1, y: 0, opacity: 1 }}
                    exit={{ scale: 0.95, y: 24, opacity: 0 }}
                    transition={{ type: 'spring', damping: 28, stiffness: 300 }}
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Top gradient bar */}
                    <div className="h-1 w-full bg-gradient-to-r from-[#14B8A6] to-[#F97316]" />

                    <div className="px-8 py-10 sm:px-10 sm:py-12 lg:px-12 lg:py-14 pt-8">
                        {/* Close btn */}
                        <button
                            type="button"
                            onClick={onClose}
                            className="absolute top-5 right-5 p-2 rounded-full text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
                            aria-label="Close"
                        >
                            <X className="w-5 h-5" />
                        </button>

                        {/* Icon + Title block */}
                        <div className="text-center mb-12">
                            <div className="inline-flex mb-6 w-20 h-20 sm:w-24 sm:h-24 rounded-2xl bg-gradient-to-br from-[#14B8A6] to-[#F97316] items-center justify-center shadow-lg shadow-teal-500/25">
                                {view === 'login' && <LogIn className="w-7 h-7 text-white" />}
                                {view === 'register' && <UserPlus className="w-7 h-7 text-white" />}
                                {view === 'verify-otp' && <ShieldCheck className="w-7 h-7 text-white" />}
                                {view === 'forgot-password' && <KeyRound className="w-7 h-7 text-white" />}
                            </div>
                            <h3 className="text-2xl sm:text-3xl font-bold text-foreground">
                                {view === 'login' && 'Welcome Back'}
                                {view === 'register' && 'Create Account'}
                                {view === 'verify-otp' && 'Verify Email'}
                                {view === 'forgot-password' && 'Reset Password'}
                            </h3>
                            <p className="text-base text-muted-foreground mt-3">
                                {view === 'login' && 'Sign in to your ISHARA account'}
                                {view === 'register' && 'Join the ISHARA community'}
                                {view === 'verify-otp' && (email ? `Enter the OTP sent to ${email}` : 'Enter your 6-digit code')}
                                {view === 'forgot-password' && "We'll send you a reset link"}
                            </p>
                        </div>

                        {error && (
                            <motion.div
                                initial={{ opacity: 0, y: -8 }}
                                animate={{ opacity: 1, y: 0 }}
                                className="mb-8 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-600 dark:text-red-400 text-sm text-center"
                            >
                                {error}
                            </motion.div>
                        )}

                        {success && (
                            <motion.div
                                initial={{ opacity: 0, y: -8 }}
                                animate={{ opacity: 1, y: 0 }}
                                className="mb-8 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-700 dark:text-emerald-400 text-sm text-center"
                            >
                                {success}
                            </motion.div>
                        )}

                        {/* ─── LOGIN ─────────────────────────────── */}
                        {view === 'login' && (
                            <form onSubmit={handleLogin} className="space-y-0">
                                <div className="mb-7 sm:mb-8">
                                    <label htmlFor="auth-email" className="block mb-3 text-sm font-medium text-foreground">Email</label>
                                    <div className="relative">
                                        <input
                                            id="auth-email"
                                            type="email"
                                            placeholder="you@example.com"
                                            value={email}
                                            onChange={(e) => setEmail(e.target.value)}
                                            required
                                            autoComplete="email"
                                            className={inputBase}
                                        />
                                    </div>
                                </div>
                                <div className="mb-7 sm:mb-8">
                                    <label htmlFor="auth-password" className="block mb-3 text-sm font-medium text-foreground">Password</label>
                                    <div className="relative">
                                        <input
                                            id="auth-password"
                                            type={showPassword ? 'text' : 'password'}
                                            placeholder="••••••••"
                                            value={password}
                                            onChange={(e) => setPassword(e.target.value)}
                                            required
                                            autoComplete="current-password"
                                            className={inputWithToggle}
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setShowPassword(!showPassword)}
                                            className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-gray-300 hover:text-white hover:bg-white/10 transition-colors"
                                            aria-label={showPassword ? 'Hide password' : 'Show password'}
                                        >
                                            {showPassword ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
                                        </button>
                                    </div>
                                </div>

                                <div className="flex justify-end mb-8">
                                    <button type="button" onClick={() => switchView('forgot-password')} className="text-sm font-medium text-[#14B8A6] hover:underline">
                                        Forgot password?
                                    </button>
                                </div>

                                <button type="submit" disabled={loading} className={`${primaryBtn} mb-8`}>
                                    {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <LogIn className="w-5 h-5" />}
                                    {loading ? 'Signing in…' : 'Sign In'}
                                </button>

                                <p className="text-center text-sm text-muted-foreground pt-2">
                                    Don&apos;t have an account?{' '}
                                    <button type="button" onClick={() => switchView('register')} className="font-semibold text-[#14B8A6] hover:underline">
                                        Sign Up
                                    </button>
                                </p>
                            </form>
                        )}

                        {/* ─── REGISTER ──────────────────────────── */}
                        {view === 'register' && (
                            <form onSubmit={handleRegister} className="space-y-0">
                                <div className="mb-7 sm:mb-8">
                                    <label htmlFor="reg-name" className="block mb-3 text-sm font-medium text-foreground">Full Name</label>
                                    <div className="relative">
                                        <input id="reg-name" type="text" placeholder="Your name" value={name} onChange={(e) => setName(e.target.value)} required autoComplete="name" className={inputBase} />
                                    </div>
                                </div>
                                <div className="mb-7 sm:mb-8">
                                    <label htmlFor="reg-email" className="block mb-3 text-sm font-medium text-foreground">Email</label>
                                    <div className="relative">
                                        <input id="reg-email" type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" className={inputBase} />
                                    </div>
                                </div>
                                <div className="mb-8">
                                    <label htmlFor="reg-password" className="block mb-3 text-sm font-medium text-foreground">Password</label>
                                    <div className="relative">
                                        <input id="reg-password" type={showPassword ? 'text' : 'password'} placeholder="Min. 8 characters" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={8} autoComplete="new-password" className={inputWithToggle} />
                                        <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-gray-300 hover:text-white hover:bg-white/10 transition-colors" aria-label={showPassword ? 'Hide password' : 'Show password'}>
                                            {showPassword ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
                                        </button>
                                    </div>
                                </div>

                                <button type="submit" disabled={loading} className={`${primaryBtn} mb-8`}>
                                    {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <UserPlus className="w-5 h-5" />}
                                    {loading ? 'Creating…' : 'Create Account'}
                                </button>

                                <p className="text-center text-sm text-muted-foreground pt-2">
                                    Already have an account?{' '}
                                    <button type="button" onClick={() => switchView('login')} className="font-semibold text-[#14B8A6] hover:underline">Sign In</button>
                                </p>
                            </form>
                        )}

                        {/* ─── VERIFY OTP ─────────────────────────── */}
                        {view === 'verify-otp' && (
                            <form onSubmit={handleVerifyOtp} className="space-y-0">
                                <div className="mb-8">
                                    <label htmlFor="auth-otp" className="block mb-3 text-sm font-medium text-foreground">Verification code</label>
                                    <input id="auth-otp" type="text" inputMode="numeric" autoComplete="one-time-code" placeholder="000000" value={otp} onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} required maxLength={6} className="w-full px-4 py-5 rounded-xl bg-secondary border-2 border-transparent text-foreground text-center text-2xl tracking-[0.4em] placeholder-muted-foreground outline-none focus:border-[#14B8A6] focus:ring-2 focus:ring-[#14B8A6]/30 focus:ring-offset-2 focus:ring-offset-card transition-all" />
                                </div>

                                <button type="submit" disabled={loading || otp.length < 6} className={`${primaryBtn} mb-6`}>
                                    {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <ShieldCheck className="w-5 h-5" />}
                                    {loading ? 'Verifying…' : 'Verify Email'}
                                </button>

                                <div className="text-center pt-4 pb-2">
                                    <button type="button" onClick={handleResendOtp} disabled={loading} className="text-sm font-medium text-[#14B8A6] hover:underline disabled:opacity-50">
                                        Resend OTP
                                    </button>
                                </div>

                                <p className="text-center text-sm text-muted-foreground pt-4">
                                    <button type="button" onClick={() => switchView('login')} className="text-[#14B8A6] hover:underline font-semibold">← Back to Login</button>
                                </p>
                            </form>
                        )}

                        {/* ─── FORGOT PASSWORD ────────────────────── */}
                        {view === 'forgot-password' && (
                            <form onSubmit={handleForgotPassword} className="space-y-0">
                                <div className="mb-8">
                                    <label htmlFor="forgot-email" className="block mb-3 text-sm font-medium text-foreground">Email</label>
                                    <div className="relative">
                                        <input id="forgot-email" type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" className={inputBase} />
                                    </div>
                                </div>

                                <button type="submit" disabled={loading} className={`${primaryBtn} mb-8`}>
                                    {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <KeyRound className="w-5 h-5" />}
                                    {loading ? 'Sending…' : 'Send Reset Link'}
                                </button>

                                <p className="text-center text-sm text-muted-foreground pt-2">
                                    <button type="button" onClick={() => switchView('login')} className="text-[#14B8A6] hover:underline font-semibold">← Back to Login</button>
                                </p>
                            </form>
                        )}
                    </div>
                </motion.div>
            </motion.div>
        </AnimatePresence>
    );
}
