// Shared Tailwind class bundles for every auth screen. Keeping these
// centralised means any visual tweak to the auth surface (e.g. ring colour,
// padding scale, focus treatment) is a one-file change.
const base =
  'w-full px-4 sm:px-5 py-3.5 text-base rounded-xl border text-foreground ' +
  'placeholder:text-muted-foreground/80 outline-none transition-all duration-200 ' +
  'bg-background/80 border-border hover:border-[#14B8A6]/60 ' +
  'focus:border-[#14B8A6] focus:ring-4 focus:ring-[#14B8A6]/20 ' +
  'aria-[invalid=true]:border-red-500 aria-[invalid=true]:ring-4 aria-[invalid=true]:ring-red-500/20 ' +
  'disabled:opacity-60 disabled:cursor-not-allowed';

export const authInputBase = base;

export const authInputWithToggle =
  base.replace('px-4 sm:px-5', 'pl-4 sm:pl-5 pr-12');

export const authInputOtp =
  base.replace(
    'px-4 sm:px-5 py-3.5 text-base',
    'px-5 py-5 text-2xl text-center tracking-[0.5em] font-mono'
  );

export const authSelect =
  base + ' bg-background text-foreground appearance-none';

export const authPrimaryBtn =
  'w-full py-3.5 px-6 rounded-xl font-semibold text-base text-white ' +
  'bg-gradient-to-r from-[#14B8A6] to-[#F97316] ' +
  'shadow-lg shadow-teal-500/25 ' +
  'hover:shadow-xl hover:shadow-teal-500/35 hover:brightness-[1.03] ' +
  'active:scale-[0.99] ' +
  'disabled:opacity-60 disabled:cursor-not-allowed disabled:shadow-none ' +
  'flex items-center justify-center gap-2.5 ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6] ' +
  'transition-all duration-200';

export const authSecondaryBtn =
  'w-full py-3 px-6 rounded-xl font-medium text-base ' +
  'border border-border hover:bg-accent text-foreground ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#14B8A6] ' +
  'transition-colors';

export const authLinkText =
  'text-[#14B8A6] hover:text-[#0ea698] hover:underline underline-offset-4 transition-colors ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#14B8A6] rounded';

export const authAlertError =
  'flex items-start gap-2.5 p-4 rounded-xl bg-red-500/10 border border-red-500/30 ' +
  'text-red-700 dark:text-red-400 text-sm whitespace-pre-line';

export const authAlertSuccess =
  'flex items-start gap-2.5 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 ' +
  'text-emerald-700 dark:text-emerald-400 text-sm whitespace-pre-line';

export const authFieldHint = 'mt-2 text-xs text-muted-foreground';
export const authLabel = 'block mb-2 text-sm font-medium text-foreground';
