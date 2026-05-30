import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/shop_repository.dart';
import '../domain/product_models.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p =
        await ref.read(shopRepositoryProvider).productById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = p;
      _loading = false;
    });
  }

  Future<void> _addToCart() async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(shopRepositoryProvider);
    await repo.addToCart(widget.productId);
    ref.invalidate(cartProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _writeReview() async {
    int rating = 5;
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Write review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(builder: (context, setS) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                    onPressed: () => setS(() => rating = i + 1),
                  );
                }),
              );
            }),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(shopRepositoryProvider)
          .postReview(widget.productId, rating, ctrl.text.trim());
      ref.invalidate(reviewsProvider(widget.productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final p = _product;
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Not found')));
    }
    final reviewsAsync = ref.watch(reviewsProvider(widget.productId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _RoundIcon(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: _RoundIcon(
              icon: Icons.share_rounded,
              onTap: () => Share.share(
                '${p.displayTitle("ar")} — ${p.price.toStringAsFixed(0)} ${p.currency}\n${p.images.firstOrNull ?? ""}',
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
          child: Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [teal, orange],
                  ).createShader(rect),
                  child: Text(
                    '${p.price.toStringAsFixed(0)} ${p.currency}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      fontFamily:
                          theme.textTheme.displayLarge?.fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IsharaActionTile(
                  label: 'Add to cart',
                  icon: Icons.add_shopping_cart_rounded,
                  onTap: _addToCart,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.4),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              if (p.images.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: p.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image_rounded),
                      ),
                      // Fade-to-surface gradient at bottom for text overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                theme.colorScheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayTitle('ar'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber.shade700,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${p.ratingAvg.toStringAsFixed(1)} · ${p.ratingCount} reviews',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      p.displayDescription('ar'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Expanded(
                          child: IsharaSectionLabel('Reviews'),
                        ),
                        TextButton.icon(
                          onPressed: _writeReview,
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Write a review'),
                          style: TextButton.styleFrom(
                            foregroundColor: teal,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    reviewsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Text(
                        'Failed: $e',
                        style: theme.textTheme.bodySmall,
                      ),
                      data: (reviews) {
                        if (reviews.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No reviews yet — be the first.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? IsharaColors.mutedDark
                                    : IsharaColors.mutedLight,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final r in reviews) ...[
                              IsharaSurface(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [teal, orange],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          r.userName.isEmpty
                                              ? '?'
                                              : r.userName.characters.first
                                                  .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r.userName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme.textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < r.rating
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_border_rounded,
                                                    size: 13,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r.comment,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(height: 1.45),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      radius: 24,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
