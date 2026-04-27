const API_BASE = `${import.meta.env.VITE_API_URL ?? ''}/api`;

type ApiFieldError = { field?: string; message?: string };
type ApiErrorBody = { message?: string; errors?: ApiFieldError[] | string[] };

async function readJsonSafe(res: Response) {
    const text = await res.text();
    if (!text) return null;
    try { return JSON.parse(text); } catch { return null; }
}

function normalizeApiError(body: unknown, fallback: string) {
    const raw = (body ?? {}) as Record<string, unknown>;
    const b = raw as ApiErrorBody;
    const message = typeof b.message === 'string' && b.message ? b.message : fallback;
    const errors = Array.isArray(b.errors) ? b.errors : [];
    const details = errors.map(e => typeof e === 'string' ? e : e?.message).filter((m): m is string => Boolean(m?.trim()));
    return { ...raw, message: details.length ? `${message}\n${details.join('\n')}` : message, errors };
}

async function postJson<T>(path: string, data: unknown, fallbackErrorMessage: string): Promise<T> {
    let res: Response;
    try {
        res = await fetch(`${API_BASE}${path}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        });
    } catch {
        throw { message: 'Cannot reach backend server. Please make sure the server is running.', errors: [] };
    }
    const json = await readJsonSafe(res);
    if (!res.ok) throw normalizeApiError(json, fallbackErrorMessage);
    return json as T;
}

/* ── Public API — all calls go to the real backend server ── */

export async function register(data: {
    email: string;
    password: string;
    confirmPassword?: string;
    name: string;
    disabilityType?: string;
}) {
    return postJson('/auth/register', data, 'Registration failed. Please try again.');
}

export async function verifyOtp(data: { email: string; otp: string }) {
    return postJson('/auth/verify-otp', data, 'OTP verification failed. Please try again.');
}

export async function login(data: { email: string; password: string }) {
    return postJson('/auth/login', data, 'Login failed. Please try again.');
}

export async function resendOtp(data: { email: string }) {
    return postJson('/auth/resend-otp', data, 'Failed to resend OTP. Please try again.');
}

export async function forgotPassword(data: { email: string }) {
    return postJson('/auth/forgot-password', data, 'Failed to send reset link. Please try again.');
}

export async function resetPassword(data: { token: string; newPassword: string }) {
    return postJson('/auth/reset-password', data, 'Password reset failed. Please try again.');
}

export async function getMe(token: string) {
    const res = await fetch(`${API_BASE}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` },
    });
    const json = await res.json();
    if (!res.ok) throw json;
    return json;
}
