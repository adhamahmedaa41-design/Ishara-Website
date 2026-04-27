// Shared fetch wrapper. Mirrors the error normalization used by authApi
// so every page gets consistent { message, errors } shapes.
const API_BASE = `${import.meta.env.VITE_API_URL ?? ''}/api`;

type ApiFieldError = { field?: string; message?: string };
type ApiErrorBody = { message?: string; errors?: ApiFieldError[] | string[] };

function getToken(): string | null {
  try {
    return localStorage.getItem('token');
  } catch {
    return null;
  }
}

async function readJsonSafe(res: Response) {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function normalizeError(body: unknown, fallback: string) {
  const raw = (body ?? {}) as Record<string, unknown>;
  const b = raw as ApiErrorBody;
  const message = typeof b.message === 'string' && b.message ? b.message : fallback;
  const errors = Array.isArray(b.errors) ? b.errors : [];
  const details = errors
    .map((e) => (typeof e === 'string' ? e : e?.message))
    .filter((m): m is string => Boolean(m && m.trim()));
  return {
    ...raw,
    message: details.length ? `${message}\n${details.join('\n')}` : message,
    errors,
  };
}

type HttpOptions = {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  body?: unknown;
  auth?: boolean;
  query?: Record<string, string | number | boolean | undefined>;
};

export async function http<T = unknown>(
  path: string,
  opts: HttpOptions = {},
  fallbackError = 'Something went wrong. Please try again.'
): Promise<T> {
  const { method = 'GET', body, auth = false, query } = opts;

  const qs = query
    ? '?' +
      Object.entries(query)
        .filter(([, v]) => v !== undefined && v !== '')
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
        .join('&')
    : '';

  const headers: Record<string, string> = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth) {
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  let res: Response;
  try {
    res = await fetch(`${API_BASE}${path}${qs}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    throw {
      message: 'Cannot reach the server. Check your connection and try again.',
      errors: [],
    };
  }

  const json = await readJsonSafe(res);
  if (!res.ok) throw normalizeError(json, fallbackError);
  return json as T;
}
