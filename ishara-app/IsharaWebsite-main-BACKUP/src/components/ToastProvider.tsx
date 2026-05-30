import { Toaster } from 'sonner@2.0.3';

interface ToastProviderProps {
  theme: 'light' | 'dark';
}

export function ToastProvider({ theme }: ToastProviderProps) {
  return (
    <Toaster
      theme={theme}
      position="top-right"
      toastOptions={{
        style: {
          background: theme === 'dark' ? '#1E293B' : '#ffffff',
          color: theme === 'dark' ? '#F1F5F9' : '#0F172A',
          border: `1px solid ${theme === 'dark' ? '#334155' : 'rgba(0, 0, 0, 0.1)'}`,
        },
        className: 'toast',
      }}
      richColors
    />
  );
}
