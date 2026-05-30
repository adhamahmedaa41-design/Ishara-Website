import { useState, useEffect } from 'react';
import { User } from 'lucide-react';
import { resolveImageUrl } from '../lib/imageUrl';

interface UserAvatarProps {
  user: { name?: string; profilePic?: string } | null;
  size?: number;
  className?: string;
  ringClassName?: string;
}

/** Default avatar for users without a profile picture - shows gradient circle with user icon or initials */
export function UserAvatar({ user, size = 40, className = '', ringClassName = 'ring-2 ring-white/30' }: UserAvatarProps) {
  const [imgError, setImgError] = useState(false);

  // Reset error state whenever the profile picture URL changes so a freshly
  // uploaded picture is always attempted (avoids the stale-error bug).
  useEffect(() => {
    setImgError(false);
  }, [user?.profilePic]);

  const initials = user?.name
    ? user.name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase()
    : '?';

  // Resolve the URL — converts /uploads/ paths to backend origin on Vercel
  const resolvedSrc = resolveImageUrl(user?.profilePic);

  // Use profilePic only if it exists, is not a default placeholder, and hasn't errored
  const hasRealAvatar =
    resolvedSrc &&
    !resolvedSrc.includes('default') &&
    !imgError;

  if (hasRealAvatar) {
    return (
      <img
        src={resolvedSrc}
        alt={user?.name ? `${user.name}'s avatar` : 'Avatar'}
        width={size}
        height={size}
        onError={() => setImgError(true)}
        className={`rounded-full object-cover ${ringClassName} ${className}`}
        style={{ width: size, height: size }}
      />
    );
  }

  // Fallback: gradient circle with user icon or initials (default avatar for new users)
  return (
    <div
      style={{ width: size, height: size, fontSize: size * 0.38 }}
      className={`flex items-center justify-center rounded-full bg-gradient-to-br from-[#14B8A6] to-[#F97316] text-white font-semibold ${ringClassName} ${className}`}
      role="img"
      aria-label={user?.name ? `${user.name}'s avatar` : 'Default user avatar'}
    >
      {size >= 32 ? initials : <User style={{ width: size * 0.45, height: size * 0.45 }} />}
    </div>
  );
}

