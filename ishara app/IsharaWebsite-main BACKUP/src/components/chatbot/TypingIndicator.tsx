export function TypingIndicator({ label }: { label: string }) {
  return (
    <div
      className="inline-flex items-center gap-1.5 text-xs text-muted-foreground"
      role="status"
      aria-live="polite"
    >
      <span className="sr-only">{label}</span>
      <span className="w-2 h-2 rounded-full bg-[#14B8A6] animate-bounce" style={{ animationDelay: '0ms' }} aria-hidden="true" />
      <span className="w-2 h-2 rounded-full bg-[#14B8A6] animate-bounce" style={{ animationDelay: '150ms' }} aria-hidden="true" />
      <span className="w-2 h-2 rounded-full bg-[#14B8A6] animate-bounce" style={{ animationDelay: '300ms' }} aria-hidden="true" />
    </div>
  );
}
