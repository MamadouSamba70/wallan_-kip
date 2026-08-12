import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget réutilisable de chargement en mode Skeleton/Shimmer.
/// Remplace le CircularProgressIndicator pour une UX de chargement premium.
class AdminSkeletonLoader extends StatefulWidget {
  const AdminSkeletonLoader({super.key});

  @override
  State<AdminSkeletonLoader> createState() => _AdminSkeletonLoaderState();
}

class _AdminSkeletonLoaderState extends State<AdminSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton du header
              _SkeletonBox(
                width: double.infinity,
                height: 90,
                borderRadius: 20,
                opacity: _animation.value,
              ),
              const SizedBox(height: 20),

              // Skeleton titre section
              _SkeletonBox(width: 160, height: 16, borderRadius: 8, opacity: _animation.value),
              const SizedBox(height: 12),

              // Grille de 4 skeleton StatCards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  4,
                  (_) => _SkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 16,
                    opacity: _animation.value,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Skeleton titre section actions
              _SkeletonBox(width: 200, height: 16, borderRadius: 8, opacity: _animation.value),
              const SizedBox(height: 12),

              // Skeleton des boutons d'actions
              Row(
                children: [
                  Expanded(
                    child: _SkeletonBox(
                      width: double.infinity,
                      height: 46,
                      borderRadius: 12,
                      opacity: _animation.value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SkeletonBox(
                      width: double.infinity,
                      height: 46,
                      borderRadius: 12,
                      opacity: _animation.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SkeletonBox(
                      width: double.infinity,
                      height: 46,
                      borderRadius: 12,
                      opacity: _animation.value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SkeletonBox(
                      width: double.infinity,
                      height: 46,
                      borderRadius: 12,
                      opacity: _animation.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Skeleton titre devices
              _SkeletonBox(width: 220, height: 16, borderRadius: 8, opacity: _animation.value),
              const SizedBox(height: 12),

              // Skeleton liste de 3 devices
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SkeletonBox(
                    width: double.infinity,
                    height: 70,
                    borderRadius: 16,
                    opacity: _animation.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Boîte skeleton individuelle avec effet shimmer.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double opacity;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryLight,
              Colors.grey.shade200,
              AppTheme.primaryLight,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton spécifique pour un item de liste (patient ou alerte).
class SkeletonListItem extends StatefulWidget {
  const SkeletonListItem({super.key});

  @override
  State<SkeletonListItem> createState() => _SkeletonListItemState();
}

class _SkeletonListItemState extends State<SkeletonListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Opacity(
          opacity: _animation.value,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
