/// Skeleton loaders para estados de carga.
///
/// Muestra placeholders animados (shimmer) que mejoran la percepcion
/// de performance vs un spinner generico.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Widget base que pinta un rectangulo skeleton con animacion shimmer.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = AppSpacing.lg,
    this.borderRadius = AppRadii.sm,
    this.margin,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceBright,
                colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1 + _animation.value, 0),
              end: Alignment(1 + _animation.value, 0),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para una card tipica (titulo + subtitulo + valor).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 120, height: 14),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(width: 80, height: 28),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 160, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para la home page.
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const SkeletonBox(width: 64, height: 64, borderRadius: 32),
          const SizedBox(height: AppSpacing.xxl),
          const SkeletonBox(width: 180, height: 28),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: AppSpacing.xxxl),
          const SkeletonCard(),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonCard(),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(
              width: double.infinity, height: 52, borderRadius: AppRadii.xl),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(
              width: double.infinity, height: 52, borderRadius: AppRadii.xl),
        ],
      ),
    );
  }
}

/// Skeleton para listas (history, filaments, printers).
class ListPageSkeleton extends StatelessWidget {
  const ListPageSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) => _listItemSkeleton(context),
    );
  }

  Widget _listItemSkeleton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const SkeletonBox(
                width: 40, height: 40, borderRadius: AppRadii.xxxl),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 150, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
            const SkeletonBox(
                width: 24, height: 24, borderRadius: AppRadii.xs),
          ],
        ),
      ),
    );
  }
}
