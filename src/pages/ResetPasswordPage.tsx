// src/pages/ResetPasswordPage.tsx
import { useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { Loader2, Lock, CheckCircle2, ArrowLeft, Eye, EyeOff } from 'lucide-react';
import * as authApi from '../api/authApi';
import { AuthPageShell } from '../components/auth/AuthPageShell';
import { authAlertError, authAlertSuccess, authInputBase, authInputWithToggle, authPrimaryBtn } from '../components/auth/authStyles';

export default function ResetPasswordPage() {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();

  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const effectiveToken = token ?? '';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!effectiveToken) {
      setError('This reset link is missing a token. Please request a new password reset email.');
      return;
    }

    if (!newPassword || !confirmPassword) {
      setError('Please fill in both password fields.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    if (newPassword.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    setLoading(true);

    try {
      const res = await authApi.resetPassword({ token: effectiveToken, newPassword });
      setSuccess((res as { message?: string })?.message || 'Your password has been reset. Redirecting to login…');

      setTimeout(() => {
        navigate('/login', { replace: true });
      }, 2500);
    } catch (err: unknown) {
      const ex = err as { message?: string };
      setError(
        ex.message || 'Failed to reset password. The link may be invalid or expired. Please request a new email.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthPageShell
      title="Reset Your Password"
      subtitle={
        effectiveToken
          ? 'Choose a new password for your ISHARA account.'
          : 'This reset link is invalid or missing a token.'
      }
      footer={
        <div className="flex flex-col sm:flex-row justify-center gap-6 text-sm">
          <Link to="/login" className="text-muted-foreground hover:text-foreground transition-colors flex items-center justify-center gap-1.5">
            <ArrowLeft className="w-4 h-4" />
            Back to Sign In
          </Link>
          <Link
            to="/forgot-password"
            className="text-muted-foreground hover:text-foreground transition-colors flex items-center justify-center gap-1.5"
          >
            <Lock className="w-4 h-4" />
            Request New Link
          </Link>
        </div>
      }
    >
      {error ? (
        <div role="alert" aria-live="assertive" className={authAlertError}>{error}</div>
      ) : null}
      {success ? (
        <div role="status" aria-live="polite" className={authAlertSuccess}>{success}</div>
      ) : null}

      {!success && (
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="newPassword" className="block mb-2 text-sm font-medium text-foreground">
              New Password
            </label>
            <div className="relative">
              <input
                id="newPassword"
                type={showPassword ? 'text' : 'password'}
                placeholder="••••••••"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
                minLength={8}
                autoComplete="new-password"
                className={authInputWithToggle}
                disabled={loading || !effectiveToken}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted/50 transition-colors"
                disabled={loading}
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? <Eye className="w-5 h-5" /> : <EyeOff className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <div>
            <label htmlFor="confirmPassword" className="block mb-2 text-sm font-medium text-foreground">
              Confirm New Password
            </label>
            <input
              id="confirmPassword"
              type={showPassword ? 'text' : 'password'}
              placeholder="••••••••"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              minLength={8}
              autoComplete="new-password"
              className={authInputBase}
              disabled={loading || !effectiveToken}
            />
          </div>

          <button type="submit" disabled={loading || !effectiveToken} className={authPrimaryBtn}>
            {loading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Resetting…
              </>
            ) : (
              <>
                <Lock className="w-5 h-5" />
                Reset Password
              </>
            )}
          </button>
        </form>
      )}
    </AuthPageShell>
  );
}

