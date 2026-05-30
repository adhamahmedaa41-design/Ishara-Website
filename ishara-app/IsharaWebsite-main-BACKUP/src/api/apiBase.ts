// Centralised API base URL. Reads VITE_API_BASE at build time so both dev
// (`npm run dev`) and production builds talk to the same backend the Flutter
// app uses. Falls back to a relative '/api' for the legacy same-origin setup.
//
// Set in your Vercel project (Settings → Environment Variables):
//   VITE_API_BASE=https://ishara-backend.vercel.app/api
//
// Or in a local `.env` at the project root for dev:
//   VITE_API_BASE=https://ishara-backend.vercel.app/api
const DEFAULT_API_BASE =
  typeof window !== 'undefined' && window.location.hostname === 'localhost'
    ? '/api'
    : 'https://ishara-backend.vercel.app/api';

export const API_BASE: string =
  (import.meta.env?.VITE_API_BASE as string | undefined)?.replace(/\/$/, '') ||
  DEFAULT_API_BASE;
