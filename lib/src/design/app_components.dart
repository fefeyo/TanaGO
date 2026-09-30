import 'package:flutter/material.dart';

/// A consistent, compact heading that still wraps on narrow screens.
class PageBanner extends StatelessWidget {
  const PageBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.description,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final IconData icon;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF246653), Color(0xFF174B3B)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFC7E4C4), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eyebrow,
                    style: const TextStyle(
                      color: Color(0xFFD7EADD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(
                description!,
                style: const TextStyle(
                  color: Color(0xFFE0EBE3),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      );
}

class CategorySymbol extends StatelessWidget {
  const CategorySymbol({super.key, this.categoryId});
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (categoryId) {
      'produce' => (Icons.eco_outlined, const Color(0xFF547A3D)),
      'meat' => (Icons.restaurant_outlined, const Color(0xFFA65253)),
      'seafood' => (Icons.set_meal_outlined, const Color(0xFF387B91)),
      'dairy' => (Icons.egg_outlined, const Color(0xFFAA782E)),
      'frozen' => (Icons.ac_unit, const Color(0xFF568997)),
      'bakery' => (Icons.bakery_dining_outlined, const Color(0xFFAA753D)),
      'snacks' => (Icons.cookie_outlined, const Color(0xFFA16A7F)),
      'beverages' => (Icons.local_cafe_outlined, const Color(0xFF608763)),
      'dry_goods' => (Icons.ramen_dining_outlined, const Color(0xFF9D843F)),
      'seasonings' => (Icons.kitchen_outlined, const Color(0xFF9B6B50)),
      'prepared_food' => (Icons.lunch_dining_outlined, const Color(0xFFA97438)),
      'daily_goods' => (Icons.spa_outlined, const Color(0xFF7779A0)),
      _ => (Icons.category_outlined, const Color(0xFF637D73)),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9EFE3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.7),
                ),
              ],
            ),
          ),
        ),
      );
}
