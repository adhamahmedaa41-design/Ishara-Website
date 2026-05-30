/// Ishara in-app assistant — bold chat UI backed by `/api/chatbot/ask`.
///
/// Quick replies cover the most common how-to questions; deep-link tags like
/// `[open:safety]` in the assistant's reply route the user to the matching
/// screen with one tap.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/local_faq.dart';

class _Msg {
  _Msg({required this.role, required this.content});
  final String role; // user | assistant
  final String content;
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();
  final List<_Msg> _messages = [
    _Msg(
      role: 'assistant',
      content: 'مرحباً! 👋 I\'m the Ishara assistant. Ask me anything — '
          'pricing, sign language translation, how SOS works, smart glasses specs, '
          'learning hub, or any other feature!',
    ),
  ];
  bool _sending = false;
  bool _narrate = true;
  bool _inputFocused = false;
  // Suggested follow-up questions for the latest assistant reply. Updated on
  // every new reply so the chips stay contextual.
  List<String> _followUps = const [
    'How does SOS work?',
    'What can the Vision tab do?',
    'Tell me about the smart glasses',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Msg(role: 'user', content: trimmed));
      _sending = true;
    });
    _ctrl.clear();
    _scrollDown();

    String? serverReply;
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.post('/api/chatbot/ask', data: {
        'messages': _messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      });
      final reply = (r.data['reply'] ?? '').toString().trim();
      if (reply.isNotEmpty) serverReply = reply;
    } catch (_) {
      // Silent — fall through to local FAQ
    }

    final reply = serverReply ?? localFaqMatch(trimmed);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(role: 'assistant', content: reply));
      _sending = false;
      _followUps = suggestFollowUps(reply);
    });
    if (_narrate) {
      ref.read(ttsServiceProvider).speak(_stripTags(reply));
    }
    _scrollDown();
  }

  String _stripTags(String s) =>
      s.replaceAll(RegExp(r'\[open:[^\]]+\]'), '').trim();

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: IsharaMotion.standard,
        );
      }
    });
  }

  void _handleDeepLink(String reply) {
    final m = RegExp(r'\[open:([^\]]+)\]').firstMatch(reply);
    if (m == null) return;
    final target = m.group(1)!;
    final route = switch (target) {
      'translator' => '/translator',
      'vision' => '/vision',
      'safety' => '/safety',
      'learning' => '/learning',
      'shop' => '/shop',
      'profile/accessibility' => '/profile/accessibility',
      'profile/contacts' => '/profile/contacts',
      _ => null,
    };
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: _narrate ? 'Mute narration' : 'Enable narration',
            icon: Icon(_narrate
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _narrate = !_narrate);
              if (!_narrate) ref.read(ttsServiceProvider).stop();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.7),
          SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Hero ─────────────────────────────────────────────
                IsharaHero(
                  eyebrow: 'Assistant',
                  title: 'How can I help?',
                  description:
                      'Ask anything about Ishara — features, settings, '
                      'shortcuts. I speak Arabic and English.',
                  icon: Icons.auto_awesome_rounded,
                ),

                // ── Conversation ─────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      return _MessageBubble(
                        text: _stripTags(m.content),
                        hasDeepLink: !isUser &&
                            m.content.contains(RegExp(r'\[open:')),
                        isUser: isUser,
                        teal: teal,
                        orange: orange,
                        isDark: isDark,
                        onTap:
                            isUser ? null : () => _handleDeepLink(m.content),
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                          ).slideY(
                            begin: 0.06,
                            end: 0,
                            duration: IsharaMotion.base,
                          );
                    },
                  ),
                ),

                // ── Dynamic follow-up chips ──────────────────────────
                // Suggestions update after every assistant reply so the
                // conversation feels contextual instead of static.
                if (!_inputFocused && _followUps.isNotEmpty)
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _followUps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final label = _followUps[i];
                        return _QuickChip(
                          label: label,
                          icon: Icons.auto_awesome_rounded,
                          onTap: _sending ? null : () => _send(label),
                        );
                      },
                    ),
                  ),

                // ── Input ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AnimatedContainer(
                    duration: IsharaMotion.fast,
                    decoration: BoxDecoration(
                      color: isDark
                          ? IsharaColors.darkCard
                          : IsharaColors.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _inputFocused
                            ? teal.withValues(alpha: 0.6)
                            : (isDark
                                ? IsharaColors.darkBorder
                                : IsharaColors.lightBorder),
                        width: _inputFocused ? 2 : 1,
                      ),
                      boxShadow: _inputFocused
                          ? [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focusNode,
                            enabled: !_sending,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _send,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask anything…',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: (isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight)
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sending
                              ? null
                              : () => _send(_ctrl.text),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _sending
                                  ? null
                                  : LinearGradient(colors: [teal, orange]),
                              color: _sending
                                  ? (isDark
                                      ? IsharaColors.darkBorder
                                      : IsharaColors.lightBorder)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _sending
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: teal.withValues(alpha: 0.36),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                        spreadRadius: -2,
                                      ),
                                    ],
                            ),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.isUser,
    required this.teal,
    required this.orange,
    required this.isDark,
    required this.hasDeepLink,
    this.onTap,
  });
  final String text;
  final bool isUser;
  final Color teal;
  final Color orange;
  final bool isDark;
  final bool hasDeepLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        gradient: isUser ? LinearGradient(colors: [teal, orange]) : null,
        color: isUser
            ? null
            : (isDark
                ? IsharaColors.darkCard
                : IsharaColors.lightCard),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 22),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isDark
                    ? IsharaColors.darkBorder
                    : IsharaColors.lightBorder,
              ),
        boxShadow: isUser
            ? [
                BoxShadow(
                  color: teal.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isUser ? Colors.white : null,
              fontWeight: FontWeight.w600,
              height: 1.45,
              fontSize: 15,
            ),
          ),
          if (hasDeepLink) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: teal,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to open',
                  style: TextStyle(
                    color: teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: onTap == null
          ? bubble
          : GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              child: bubble,
            ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final disabled = onTap == null;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: teal.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: teal),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
