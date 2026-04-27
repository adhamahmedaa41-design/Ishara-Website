// src/pages/ForgotPasswordPage.tsx
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Loader2, KeyRound, CheckCircle2, ArrowLeft } from 'lucide-react';
import * as authApi from '../api/authApi';
import { AuthPageShell } from '../components/auth/AuthPageShell';
import { authAlertError, authInputBase, authLinkText, authPrimaryBtn } from '../components/auth/authStyles';

export default function ForgotPasswordPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [email, setEmail] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await authApi.forgotPassword({ email });
      setSuccess(true);
    } catch (err: unknown) {
      const ex = err as { message?: string };
      setError(ex.message || 'Failed to send reset link. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthPageShell
      title={success ? 'Check Your Email' : 'Forgot Password?'}
      subtitle={
        success ? 'We sent a password reset link if an account exists.' : "Enter your email and we'll send a reset link."
      }
      footer={
        <div className="flex flex-col sm:flex-row justify-center gap-6 text-sm">
          <Link to="/login" className={authLinkText}>
            ← Back to Sign In
          </Link>
          <Link
            to="/"
            className="text-muted-foreground hover:text-foreground transition-colors flex items-center justify-center gap-1.5"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Home
          </Link>
        </div>
      }
    >
      {error ? (
        <div role="alert" aria-live="assertive" className={authAlertError}>{error}</div>
      ) : null}

      {!success ? (
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="email" className="block mb-2 text-sm font-medium text-foreground">
              Email
            </label>
            <input
              id="email"
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className={authInputBase}
              disabled={loading}
            />
          </div>

          <button type="submit" disabled={loading || !email} className={authPrimaryBtn}>
            {loading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Sending…
              </>
            ) : (
              <>
                <KeyRound className="w-5 h-5" />
                Send Reset Link
              </>
            )}
          </button>
        </form>
      ) : (
        <div className="text-center space-y-6">
          <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto" />
          <p className="text-sm text-muted-foreground">You can close this page now.</p>
        </div>
      )}
    </AuthPageShell>
  );
}