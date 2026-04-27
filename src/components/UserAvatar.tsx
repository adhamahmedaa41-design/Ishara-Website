import { useState } from 'react';
import { User } from 'lucide-react';

interface UserAvatarProps {
  user: { name?: string; profilePic?: string } | null;
  size?: number;
  className?: string;
  ringClassName?: string;
}

/** Default avatar for users without a profile picture - shows gradient circle with user icon or initials */
export function UserAvatar({ user, size = 40, className = '', ringClassName = 'ring-2 ring-white/30' }: UserAvatarProps) {
  const [imgError, setImgError] = useState(false);

  const initials = user?.name
    ? user.name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase()
    : '?';

  // Use profilePic only if it exists, is not a default placeholder, and hasn't errored
  const hasRealAvatar =
    user?.profilePic &&
    !user.profilePic.includes('default') &&
    !imgError;

  if (hasRealAvatar && user.profilePic) {
    const src = user.profilePic.startsWith('http')
      ? user.profilePic
      : user.profilePic.startsWith('/') ? user.profilePic : `/${user.profilePic.replace(/^\//, '')}`;

    return (
      <img
        src={src}
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
