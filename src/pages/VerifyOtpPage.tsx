// src/pages/VerifyOtpPage.tsx
import { useState } from 'react';
import { Link, useNavigate, useLocation, Navigate } from 'react-router-dom';
import { ShieldCheck, Loader2, ArrowLeft } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import * as authApi from '../api/authApi';
import { AuthPageShell } from '../components/auth/AuthPageShell';
import { authAlertError, authAlertSuccess, authInputOtp, authLinkText, authPrimaryBtn } from '../components/auth/authStyles';

export default function VerifyOtpPage() {
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const { state } = useLocation() as { state?: { email?: string } };
  const [email] = useState(state?.email ?? '');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  if (!email) {
    navigate('/login', { replace: true });
    return null;
  }

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.length !== 6) return;
    setLoading(true);
    setError('');
    try {
      const data = await authApi.verifyOtp({ email, otp });
      login(data.token, data.user);
      navigate('/', { replace: true });
    } catch (err: unknown) {
      const ex = err as { message?: string };
      setError(ex.message || 'Invalid OTP. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleResendOtp = async () => {
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      await authApi.resendOtp({ email });
      setSuccess('New OTP sent to your email!');
    } catch (err: unknown) {
      const ex = err as { message?: string };
      setError(ex.message || 'Failed to resend OTP.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthPageShell
      title="Verify Email"
      subtitle={
        <>
          Enter the code sent to <strong>{email}</strong>
        </>
      }
      footer={
        <Link
          to="/"
          className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center justify-center gap-1.5"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Home
        </Link>
      }
    >
      {error ? (
        <div role="alert" aria-live="assertive" className={authAlertError}>{error}</div>
      ) : null}
      {success ? (
        <div role="status" aria-live="polite" className={authAlertSuccess}>{success}</div>
      ) : null}

      <form onSubmit={handleVerifyOtp} className="space-y-6">
        <div>
          <label htmlFor="otp" className="block mb-2 text-sm font-medium text-foreground">
            Verification Code
          </label>
          <input
            id="otp"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            placeholder="000000"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
            required
            maxLength={6}
            className={authInputOtp}
            disabled={loading}
          />
        </div>

        <button type="submit" disabled={loading || otp.length !== 6} className={authPrimaryBtn}>
          {loading ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              Verifying…
            </>
          ) : (
            <>
              <ShieldCheck className="w-5 h-5" />
              Verify
            </>
          )}
        </button>
      </form>

      <div className="flex flex-col sm:flex-row sm:justify-between gap-4 text-sm pt-2">
        <button type="button" onClick={handleResendOtp} disabled={loading} className={authLinkText}>
          Resend code
        </button>
        <Link to="/login" className={authLinkText}>
          Back to Sign In
        </Link>
      </div>
    </AuthPageShell>
  );
}