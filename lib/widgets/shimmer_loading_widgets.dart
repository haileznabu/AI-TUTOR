import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import '../main.dart';

class ShimmerContinueLearningLoader extends StatelessWidget {
  const ShimmerContinueLearningLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              ShimmerBox(
                width: 20,
                height: 20,
                borderRadius: 4,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 150,
                height: 20,
                borderRadius: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ShimmerVisitedTopicTile(isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class ShimmerVisitedTopicTile extends StatelessWidget {
  final bool isDark;

  const ShimmerVisitedTopicTile({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      width: 44,
                      height: 44,
                      borderRadius: 10,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: double.infinity,
                            height: 13,
                            borderRadius: 4,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 80,
                            height: 11,
                            borderRadius: 4,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ShimmerBox(
                  width: 60,
                  height: 10,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                ShimmerBox(
                  width: double.infinity,
                  height: 6,
                  borderRadius: 4,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerRecommendedLoader extends StatelessWidget {
  const ShimmerRecommendedLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              ShimmerBox(
                width: 32,
                height: 32,
                borderRadius: 8,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 180,
                height: 20,
                borderRadius: 4,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 80,
                height: 20,
                borderRadius: 8,
                isDark: isDark,
              ),
            ],
          ),
        ),
        ShimmerBox(
          width: 250,
          height: 12,
          borderRadius: 4,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ShimmerRecommendedCard(isDark: isDark),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class ShimmerRecommendedCard extends StatelessWidget {
  final bool isDark;

  const ShimmerRecommendedCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.2) : kPrimaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      width: 44,
                      height: 44,
                      borderRadius: 12,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    ShimmerBox(
                      width: 70,
                      height: 24,
                      borderRadius: 8,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ShimmerBox(
                  width: 100,
                  height: 11,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 3),
                ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                ShimmerBox(
                  width: 180,
                  height: 14,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: double.infinity,
                  height: 11,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                ShimmerBox(
                  width: 150,
                  height: 11,
                  borderRadius: 4,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(
                      width: 60,
                      height: 11,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    ShimmerBox(
                      width: 16,
                      height: 16,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerTopicsListLoader extends StatelessWidget {
  const ShimmerTopicsListLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              ShimmerBox(
                width: 20,
                height: 20,
                borderRadius: 4,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 120,
                height: 20,
                borderRadius: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: ShimmerBox(
            width: 150,
            height: 20,
            borderRadius: 4,
            isDark: isDark,
          ),
        ),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerTopicCard(isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class ShimmerTopicCard extends StatelessWidget {
  final bool isDark;

  const ShimmerTopicCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              ShimmerBox(
                width: 56,
                height: 56,
                borderRadius: 12,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 100,
                      height: 12,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: double.infinity,
                      height: 13,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 4),
                    ShimmerBox(
                      width: 200,
                      height: 13,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 60,
                          height: 24,
                          borderRadius: 8,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 80,
                          height: 24,
                          borderRadius: 8,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 16,
                height: 16,
                borderRadius: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withOpacity(0.2)
          : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
