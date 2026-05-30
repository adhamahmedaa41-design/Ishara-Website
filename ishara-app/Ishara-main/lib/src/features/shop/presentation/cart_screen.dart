import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/shop_repository.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final cartAsync = ref.watch(cartProvider);

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
            child: Column(
              children: [
                IsharaHero(
                  eyebrow: 'Cart',
                  title: 'Your basket',
                  description:
                      'Review what you\'re about to buy. Checkout opens WhatsApp with your order pre-filled.',
                  icon: Icons.shopping_cart_rounded,
                ),
                Expanded(
                  child: cartAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Failed: $e',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_basket_outlined,
                                  size: 56,
                                  color: teal.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your cart is empty',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Browse the shop to add something.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final total = items.fold<double>(
                        0,
                        (a, i) => a + i.price * i.qty,
                      );
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                8,
                                22,
                                12,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return IsharaSurface(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    8,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.price.toStringAsFixed(0)} ${item.currency} · ×${item.qty}',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: teal,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _QtyButton(
                                        icon: Icons
                                            .remove_circle_outline_rounded,
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          await ref
                                              .read(
                                                shopRepositoryProvider,
                                              )
                                              .updateQty(
                                                item.productId,
                                                item.qty - 1,
                                              );
                                          ref.invalidate(cartProvider);
                                        },
                                      ),
                                      Container(
                                        width: 30,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.qty}',
                                          style:
                                              theme.textTheme.titleMedium
                                                  ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      _QtyButton(
                                        icon: Icons
                                            .add_circle_outline_rounded,
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          await ref
                                              .read(
                                                shopRepositoryProvider,
                                              )
                                              .updateQty(
                                                item.productId,
                                                item.qty + 1,
                                              );
                                          ref.invalidate(cartProvider);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _QtyButton(
                                        icon: Icons.delete_outline_rounded,
                                        color: const Color(0xFFEF4444),
                                        onTap: () async {
                                          HapticFeedback.mediumImpact();
                                          await ref
                                              .read(
                                                shopRepositoryProvider,
                                              )
                                              .removeFromCart(item.productId);
                                          ref.invalidate(cartProvider);
                                        },
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(
                                      duration: IsharaMotion.base,
                                      delay: Duration(milliseconds: 30 * i),
                                    );
                              },
                            ),
                          ),

                          // ── Total + checkout block ──────────────────
                          Container(
                            margin: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                            padding: const EdgeInsets.fromLTRB(
                              22,
                              22,
                              22,
                              22,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0F1A),
                              borderRadius: IsharaColors.surfaceRadius,
                              boxShadow: IsharaColors.elevatedShadow(
                                dark: true,
                                glow: true,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    color: teal,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (rect) =>
                                          LinearGradient(
                                        colors: [teal, orange],
                                      ).createShader(rect),
                                      child: Text(
                                        total.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 60,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                          letterSpacing: -2,
                                          fontFamily: theme.textTheme
                                              .displayLarge?.fontFamily,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'EGP',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22,
                                          fontFamily: theme.textTheme
                                              .titleLarge?.fontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                IsharaActionTile(
                                  label: 'Checkout via WhatsApp',
                                  icon: Icons.chat_rounded,
                                  onTap: () async {
                                    HapticFeedback.mediumImpact();
                                    final r = await ref
                                        .read(shopRepositoryProvider)
                                        .checkout();
                                    if (r.whatsappUrl != null) {
                                      await launchUrl(
                                        Uri.parse(r.whatsappUrl!),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                    ref.invalidate(cartProvider);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final c = color ?? teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
    );
  }
}
