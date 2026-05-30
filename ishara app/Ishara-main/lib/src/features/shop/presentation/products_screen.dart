import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/shop_repository.dart';
import '../domain/product_models.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String? _category;
  static const _cats = <(String, IconData)>[
    ('all', Icons.apps_rounded),
    ('hearing', Icons.hearing_rounded),
    ('deaf', Icons.hearing_disabled_rounded),
    ('blind', Icons.visibility_off_rounded),
    ('low-vision', Icons.visibility_rounded),
    ('learning', Icons.school_rounded),
    ('hardware', Icons.memory_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final productsAsync = ref.watch(
      productsProvider(_category == 'all' ? null : _category),
    );

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
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withValues(alpha: 0.32)),
              ),
              child: Icon(Icons.shopping_cart_rounded, color: teal, size: 18),
            ),
            tooltip: 'Cart',
            onPressed: () => context.push('/shop/cart'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.6),
          SafeArea(
            top: false,
            child: Column(
              children: [
                IsharaHero(
                  eyebrow: 'Shop',
                  title: 'Accessibility gear',
                  description:
                      'Hand-picked devices and tools for hearing, vision, '
                      'speech, and learning support.',
                  icon: Icons.shopping_bag_rounded,
                ),

                // Category chips
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    scrollDirection: Axis.horizontal,
                    itemCount: _cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final (c, icon) = _cats[i];
                      final selected = (c == 'all' && _category == null) ||
                          c == _category;
                      return _CategoryChip(
                        label: c,
                        icon: icon,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _category = c == 'all' ? null : c,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Products grid
                Expanded(
                  child: productsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load: $e',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (products) {
                      if (products.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: teal.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No products yet',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Run the server seed script to populate the catalogue.',
                                  textAlign: TextAlign.center,
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
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.66,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        itemBuilder: (context, i) {
                          return _ProductCard(p: products[i])
                              .animate()
                              .fadeIn(
                                duration: IsharaMotion.base,
                                delay: Duration(milliseconds: 30 * i),
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
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: IsharaMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [teal, orange])
              : null,
          color: selected
              ? null
              : (isDark
                  ? IsharaColors.darkCard
                  : IsharaColors.lightCard),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                    ? IsharaColors.darkBorder
                    : IsharaColors.lightBorder),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ]
              : null,
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : teal,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.p});
  final Product p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Material(
      color: Colors.transparent,
      borderRadius: IsharaColors.surfaceRadius,
      child: InkWell(
        borderRadius: IsharaColors.surfaceRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/shop/product/${p.id}');
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? IsharaColors.darkCard
                : IsharaColors.lightCard,
            borderRadius: IsharaColors.surfaceRadius,
            border: Border.all(
              color: isDark
                  ? IsharaColors.darkBorder
                  : IsharaColors.lightBorder,
            ),
            boxShadow: IsharaColors.elevatedShadow(dark: isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: p.images.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainer,
                        child: const Icon(
                          Icons.image_rounded,
                          size: 48,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: p.images.first,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => const ColoredBox(
                          color: Colors.black12,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayTitle('ar'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: [
                              teal,
                              isDark
                                  ? IsharaColors.orangeDark
                                  : IsharaColors.orangeLight,
                            ],
                          ).createShader(rect),
                          child: Text(
                            '${p.price.toStringAsFixed(0)} ${p.currency}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          p.ratingAvg.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
