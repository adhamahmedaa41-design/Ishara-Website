import type { ReactNode } from 'react';
import { motion } from 'motion/react';
import { Link } from 'react-router-dom';
import { ImageWithFallback } from '../figma/ImageWithFallback';

export function AuthPageShell({
  title,
  subtitle,
  footer,
  children,
}: {
  title: ReactNode;
  subtitle?: ReactNode;
  footer?: ReactNode;
  children: ReactNode;
}) {
  return (
    <main
      id="main"
      className="min-h-screen relative flex items-stretch overflow-hidden pt-20"
    >
      {/* Animated background orbs */}
      <div aria-hidden className="absolute inset-0 pointer-events-none">
        <motion.div
          className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(20,184,166,0.08) 0%, transparent 70%)' }}
          animate={{ x: [0, 40, 0], y: [0, 30, 0], scale: [1, 1.1, 1] }}
          transition={{ duration: 12, repeat: Infinity, ease: 'easeInOut' }}
        />
        <motion.div
          className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(249,115,22,0.06) 0%, transparent 70%)' }}
          animate={{ x: [0, -30, 0], y: [0, -40, 0], scale: [1, 1.15, 1] }}
          transition={{ duration: 14, repeat: Infinity, ease: 'easeInOut' }}
        />
      </div>

      <div className="relative z-10 w-full grid lg:grid-cols-[1fr_1fr]">
        {/* Form panel */}
        <section
          className="flex items-center justify-center px-5 sm:px-8 py-12"
          aria-labelledby="auth-title"
        >
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="w-full max-w-md space-y-7"
          >
            <div className="flex justify-center lg:hidden">
              <Link to="/" aria-label="Ishara home" className="inline-flex">
                <ImageWithFallback
                  src="https://i.ibb.co/vCVYft2v/eng.png"
                  alt="Ishara"
                  className="h-12 w-auto object-contain"
                />
              </Link>
            </div>

            <header className="text-center lg:text-start">
              <motion.h1
                id="auth-title"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="text-4xl sm:text-5xl font-bold tracking-tight text-gradient"
              >
                {title}
              </motion.h1>
              {subtitle ? (
                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.2 }}
                  className="mt-2 text-muted-foreground"
                >
                  {subtitle}
                </motion.p>
              ) : null}
            </header>

            <motion.div
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.25 }}
              className="relative bg-card/80 backdrop-blur-sm rounded-3xl border border-border shadow-xl shadow-black/5 p-6 sm:p-8 space-y-6 overflow-hidden"
            >
              {/* Animated gradient top border */}
              <div className="absolute top-0 left-6 right-6 h-[2px] rounded-full overflow-hidden">
                <motion.div
                  className="h-full w-[200%]"
                  style={{ background: 'linear-gradient(90deg, transparent, #14B8A6, #F97316, transparent)' }}
                  animate={{ x: ['-50%', '0%'] }}
                  transition={{ duration: 3, repeat: Infinity, ease: 'linear' }}
                />
              </div>
              {children}
            </motion.div>

            {footer ? (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.4 }}
                className="text-center"
              >
                {footer}
              </motion.div>
            ) : null}
          </motion.div>
        </section>

        {/* Brand panel */}
        <aside
          aria-hidden="true"
          className="hidden lg:flex relative overflow-hidden items-center justify-center"
          style={{
            background: 'linear-gradient(135deg, #0f172a 0%, rgba(20,184,166,0.3) 50%, rgba(249,115,22,0.4) 100%)',
          }}
        >
          {/* Animated shapes */}
          <motion.div
            className="absolute w-64 h-64 rounded-full border border-white/10"
            style={{ top: '15%', right: '10%' }}
            animate={{ rotate: 360, scale: [1, 1.1, 1] }}
            transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
          />
          <motion.div
            className="absolute w-40 h-40 rounded-full border border-white/5"
            style={{ bottom: '20%', left: '10%' }}
            animate={{ rotate: -360 }}
            transition={{ duration: 25, repeat: Infinity, ease: 'linear' }}
          />
          <motion.div
            className="absolute w-3 h-3 rounded-full bg-[#14B8A6]/60"
            animate={{ y: [0, -100, 0], x: [0, 30, 0] }}
            transition={{ duration: 6, repeat: Infinity }}
            style={{ top: '40%', left: '30%' }}
          />
          <motion.div
            className="absolute w-2 h-2 rounded-full bg-[#F97316]/60"
            animate={{ y: [0, 80, 0], x: [0, -20, 0] }}
            transition={{ duration: 8, repeat: Infinity }}
            style={{ top: '60%', right: '25%' }}
          />

          <div className="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_30%_30%,white_0%,transparent_50%)]" />
          <div className="relative z-10 max-w-md px-10 space-y-8">
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3, type: 'spring' }}
            >
              <ImageWithFallback
                src="https://i.ibb.co/vCVYft2v/eng.png"
                alt=""
                className="h-16 w-auto drop-shadow-[0_0_20px_rgba(20,184,166,0.4)]"
              />
            </motion.div>
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="text-4xl font-bold leading-tight text-white"
            >
              Technology that
              <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#14B8A6] to-[#F97316]">
                speaks, sees &amp; protects.
              </span>
            </motion.h2>
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
              className="text-white/70 leading-relaxed"
            >
              Ishara is a connected ecosystem of smart glasses, a safety bracelet
              and a companion app — built for deaf, non-verbal and blind users.
            </motion.p>
            <motion.ul initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.6 }} className="space-y-3 text-sm">
              {[
                'Sign language ↔ speech translation',
                'Real-time obstacle & currency recognition',
                'SOS emergency & live location sharing',
              ].map((line, i) => (
                <motion.li
                  key={line}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.7 + i * 0.1 }}
                  className="flex items-start gap-3 text-white/80"
                >
                  <span className="mt-1.5 w-2 h-2 rounded-full bg-gradient-to-r from-[#14B8A6] to-[#F97316] shrink-0" />
                  <span>{line}</span>
                </motion.li>
              ))}
            </motion.ul>
          </div>
        </aside>
      </div>
    </main>
  );
}
