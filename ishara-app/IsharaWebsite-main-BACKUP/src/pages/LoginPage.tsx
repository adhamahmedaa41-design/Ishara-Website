// src/pages/LoginPage.tsx
import { useState } from 'react';
import { Link, useNavigate, Navigate } from 'react-router-dom';
import { LogIn, Loader2, Eye, EyeOff, Mail, Lock } from 'lucide-react';
import { motion } from 'motion/react';
import { useAuth } from '../hooks/useAuth';
import * as authApi from '../api/authApi';
import { AuthPageShell } from '../components/auth/AuthPageShell';

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const data = await authApi.login({ email, password });
      login(data.token, data.user);
      navigate('/', { replace: true });
    } catch (err: unknown) {
      const ex = err as { isVerified?: boolean; message?: string };
      if (ex.isVerified === false) {
        setError('Please verify your email first.');
        navigate('/verify-otp', { state: { email }, replace: true });
      } else {
        setError(ex.message || 'Login failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const inputCls = 'w-full py-3.5 rounded-2xl bg-secondary border border-border text-foreground placeholder:text-muted-foreground/60 outline-none transition-all focus:border-[var(--ishara-brand-teal)] focus:shadow-[0_0_0_3px_rgba(20,184,166,0.15)] hover:border-[var(--ishara-brand-teal)]/40 disabled:opacity-40';

  return (
    <AuthPageShell
      title="Welcome Back"
      subtitle="Sign in to your Ishara account"
      footer={
        <Link to="/" className="text-sm text-muted-foreground hover:text-foreground transition-colors inline-flex items-center gap-1.5">
          ← Back to Home
        </Link>
      }
    >
      {error ? (
        <motion.div
          initial={{ opacity: 0, y: -8, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          role="alert"
          aria-live="assertive"
          className="flex items-start gap-2.5 p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-red-700 dark:text-red-400 text-sm"
        >
          {error}
        </motion.div>
      ) : null}

      <form onSubmit={handleLogin} className="space-y-5">
        <motion.div
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1 }}
        >
          <label htmlFor="email" className="block mb-2 text-sm font-medium text-foreground">
            Email Address
          </label>
          <div className="relative group">
            <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
            <input
              id="email"
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className={inputCls + ' pl-11 pr-4'}
              disabled={loading}
            />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.15 }}
        >
          <label htmlFor="password" className="block mb-2 text-sm font-medium text-foreground">
            Password
          </label>
          <div className="relative group">
            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 group-focus-within:text-[var(--ishara-brand-teal)] transition-colors" />
            <input
              id="password"
              type={showPassword ? 'text' : 'password'}
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              className={inputCls + ' pl-11 pr-14'}
              disabled={loading}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-muted-foreground/40 hover:text-foreground transition-colors"
              disabled={loading}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
            </button>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="flex flex-col sm:flex-row sm:justify-between gap-2 text-sm"
        >
          <Link to="/forgot-password" className="text-[var(--ishara-brand-teal)] hover:underline underline-offset-4 transition-colors">
            Forgot password?
          </Link>
          <Link to="/register" className="text-[var(--ishara-brand-teal)] hover:underline underline-offset-4 transition-colors">
            Create an account
          </Link>
        </motion.div>

        <motion.button
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25 }}
          type="submit"
          disabled={loading}
          className="w-full py-4 rounded-2xl font-semibold text-white bg-gradient-to-r from-[#14B8A6] to-[#F97316] shadow-lg shadow-teal-500/25 hover:shadow-xl hover:shadow-teal-500/35 hover:brightness-[1.05] active:scale-[0.99] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2.5 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6]"
          whileHover={{ scale: loading ? 1 : 1.01 }}
          whileTap={{ scale: loading ? 1 : 0.98 }}
        >
          {loading ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              Signing in…
            </>
          ) : (
            <>
              <LogIn className="w-5 h-5" />
              Sign In
            </>
          )}
        </motion.button>
      </form>
    </AuthPageShell>
  );
}