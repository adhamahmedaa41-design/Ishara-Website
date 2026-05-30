import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

// Hardcoded Ishara brand handles — update when accounts go live.
const _kLinks = [
  _SocialLink(
    platform: 'Instagram',
    handle: '@ishara.app',
    url: 'https://instagram.com/ishara.app',
    icon: Icons.camera_alt_rounded,
    color: Color(0xFFE1306C),
  ),
  _SocialLink(
    platform: 'Facebook',
    handle: 'Ishara App',
    url: 'https://facebook.com/isharaapp',
    icon: Icons.facebook_rounded,
    color: Color(0xFF1877F2),
  ),
  _SocialLink(
    platform: 'X / Twitter',
    handle: '@ishara_app',
    url: 'https://twitter.com/ishara_app',
    icon: Icons.alternate_email_rounded,
    color: Color(0xFF1DA1F2),
  ),
  _SocialLink(
    platform: 'TikTok',
    handle: '@ishara.app',
    url: 'https://tiktok.com/@ishara.app',
    icon: Icons.music_note_rounded,
    color: Color(0xFF010101),
  ),
  _SocialLink(
    platform: 'YouTube',
    handle: '@IsharaApp',
    url: 'https://youtube.com/@IsharaApp',
    icon: Icons.play_circle_rounded,
    color: Color(0xFFFF0000),
  ),
  _SocialLink(
    platform: 'WhatsApp Business',
    handle: 'Ishara Support',
    url: 'https://wa.me/message/isharasupport',
    icon: Icons.chat_rounded,
    color: Color(0xFF25D366),
  ),
];

class SocialLinksScreen extends StatelessWidget {
  const SocialLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.6),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              children: [
                IsharaHero(
                  eyebrow: 'Follow',
                  title: 'Stay connected',
                  description:
                      'Follow Ishara across the apps you already use for updates, tips, and the community.',
                  icon: Icons.sign_language_rounded,
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _kLinks.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LinkTile(link: _kLinks[i])
                        .animate()
                        .fadeIn(
                          duration: IsharaMotion.base,
                          delay: Duration(milliseconds: 40 * i),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link});
  final _SocialLink link;

  Future<void> _open() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: isDark
                ? IsharaColors.darkCard
                : IsharaColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: link.color.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: link.color.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      link.color,
                      link.color.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: link.color.withValues(alpha: 0.36),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Icon(link.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.platform,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.handle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: link.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: link.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: link.color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLink {
  const _SocialLink({
    required this.platform,
    required this.handle,
    required this.url,
    required this.icon,
    required this.color,
  });

  final String platform;
  final String handle;
  final String url;
  final IconData icon;
  final Color color;
}
