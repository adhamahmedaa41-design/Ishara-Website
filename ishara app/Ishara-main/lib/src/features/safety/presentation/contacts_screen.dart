/// Multi-contact emergency contacts manager — bold layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/contacts_repository.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final contactsAsync = ref.watch(contactsListProvider);

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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.invalidate(contactsListProvider);
            },
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _openEditor(context, ref, null);
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [teal, orange]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Add contact',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Red-toned aurora for safety screens
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -80,
                    child: IsharaGlowBlob(
                      size: 320,
                      color: const Color(0xFFEF4444),
                      opacity: 0.20,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: -6,
                          end: 6,
                          duration: 4400.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    top: 200,
                    left: -80,
                    child: IsharaGlowBlob(
                      size: 260,
                      color: orange,
                      opacity: 0.18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                IsharaHero(
                  eyebrow: 'Contacts',
                  title: 'Emergency contacts',
                  description:
                      'These are the people we\'ll alert when you press SOS. Add their phone, email, and preferred channels.',
                  icon: Icons.contact_phone_rounded,
                ),
                Expanded(
                  child: contactsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load: $e',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: teal.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Icon(
                                    Icons.contacts_rounded,
                                    size: 40,
                                    color: teal,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'No contacts yet',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add at least one emergency contact so SOS can reach someone.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(22, 8, 22, 120),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return _ContactCard(
                            dto: c,
                            teal: teal,
                            orange: orange,
                            isDark: isDark,
                            onEdit: () => _openEditor(context, ref, c),
                            onDelete: () async {
                              HapticFeedback.mediumImpact();
                              await ref
                                  .read(contactsRepositoryProvider)
                                  .remove(c.id);
                              ref.invalidate(contactsListProvider);
                            },
                          ).animate().fadeIn(
                                duration: IsharaMotion.base,
                                delay: Duration(milliseconds: 40 * i),
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    EmergencyContactDto? existing,
  ) async {
    final saved = await showModalBottomSheet<EmergencyContactDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactEditor(initial: existing),
    );
    if (saved == null) return;
    final repo = ref.read(contactsRepositoryProvider);
    if (existing == null) {
      await repo.add(saved);
    } else {
      await repo.update(saved);
    }
    ref.invalidate(contactsListProvider);
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.dto,
    required this.teal,
    required this.orange,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });
  final EmergencyContactDto dto;
  final Color teal;
  final Color orange;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = dto.name.isEmpty
        ? '?'
        : dto.name.characters.first.toUpperCase();

    return IsharaSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [teal, orange]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: teal.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dto.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dto.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (dto.relationship.isNotEmpty)
                      _SmallChip(
                        label: dto.relationship,
                        icon: Icons.person_outline_rounded,
                        color: teal,
                      ),
                    _SmallChip(
                      label: _appLabel(dto.app),
                      icon: _appIcon(dto.app),
                      color: orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? IsharaColors.mutedDark
                  : IsharaColors.mutedLight,
            ),
            onSelected: (v) {
              if (v == 'edit') {
                HapticFeedback.selectionClick();
                onEdit();
              }
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  String _appLabel(String app) {
    switch (app) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'telegram':
        return 'Telegram';
      case 'sms':
        return 'SMS';
      default:
        return 'All channels';
    }
  }

  IconData _appIcon(String app) {
    switch (app) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'telegram':
        return Icons.send_rounded;
      case 'sms':
        return Icons.sms_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({this.initial});
  final EmergencyContactDto? initial;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone =
      TextEditingController(text: widget.initial?.phone ?? '');
  late final _rel =
      TextEditingController(text: widget.initial?.relationship ?? '');
  late final _tg = TextEditingController(
    text: widget.initial?.telegramChatId ?? '',
  );
  late String _app = widget.initial?.app ?? 'all';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rel.dispose();
    _tg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final isEditing = widget.initial != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark
                        ? IsharaColors.mutedDark
                        : IsharaColors.mutedLight)
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isEditing ? 'Edit contact' : 'Add contact',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          _BoldField(
            controller: _name,
            hint: 'Name',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          _BoldField(
            controller: _phone,
            hint: 'Phone (with country code)',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _BoldField(
            controller: _rel,
            hint: 'Relationship (e.g. Mother)',
            icon: Icons.handshake_rounded,
          ),
          const SizedBox(height: 10),
          _BoldField(
            controller: _tg,
            hint: 'Telegram chat ID (optional)',
            icon: Icons.send_rounded,
          ),
          const SizedBox(height: 16),
          Text(
            'CHANNELS',
            style: TextStyle(
              color: teal,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ('all', 'All', Icons.bolt_rounded),
              ('whatsapp', 'WhatsApp', Icons.chat_rounded),
              ('telegram', 'Telegram', Icons.send_rounded),
              ('sms', 'SMS', Icons.sms_rounded),
            ].map((c) {
              final (val, label, icon) = c;
              final selected = _app == val;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _app = val);
                },
                child: AnimatedContainer(
                  duration: IsharaMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(colors: [teal, teal])
                        : null,
                    color: selected
                        ? null
                        : (isDark
                            ? IsharaColors.darkCard
                            : IsharaColors.lightCard),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? teal
                          : (isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: selected ? Colors.white : teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? Colors.white : teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          IsharaActionTile(
            label: isEditing ? 'Save changes' : 'Add contact',
            icon: Icons.save_rounded,
            onTap: () {
              if (_name.text.trim().isEmpty ||
                  _phone.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and phone are required'),
                  ),
                );
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(
                EmergencyContactDto(
                  id: widget.initial?.id ?? '',
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                  relationship: _rel.text.trim(),
                  app: _app,
                  priority: widget.initial?.priority ?? 0,
                  telegramChatId: _tg.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BoldField extends StatelessWidget {
  const _BoldField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: teal),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor:
            isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? IsharaColors.darkBorder
                : IsharaColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? IsharaColors.darkBorder
                : IsharaColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: teal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }
}
