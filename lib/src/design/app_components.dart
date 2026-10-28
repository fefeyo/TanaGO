import 'package:flutter/material.dart';
import 'app_palette.dart';

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.softGreen,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppPalette.pistachio,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppPalette.forest, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppPalette.forest,
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
                      color: AppPalette.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: const TextStyle(
                  color: AppPalette.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
}

class CategorySymbol extends StatelessWidget {
  const CategorySymbol({super.key, this.categoryId, this.size = 44});
  final String? categoryId;
  final double size;

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
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
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
                    color: AppPalette.softGreen,
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

class BuySoonBadge extends StatelessWidget {
  const BuySoonBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF5D4BA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'すぐ買いたい！',
          style: TextStyle(
            fontSize: 11,
            color: AppPalette.peachInk,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class PurchaseCelebration extends StatelessWidget {
  const PurchaseCelebration({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.softGreen,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width < 360 ? 56 : 76,
                      height: MediaQuery.sizeOf(context).width < 360 ? 56 : 76,
                      child: const CustomPaint(painter: _ShoppingBagPainter()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'お買い物\nおつかれさま！',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$count点の購入が完了しました',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              '最近買ったものに保存しました。間違えたときは、下のボタンで取り消せます。',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppPalette.muted,
              ),
            ),
          ],
        ),
      );
}

/// Small vector artwork stays crisp at any screen density; no network asset.
class _ShoppingBagPainter extends CustomPainter {
  const _ShoppingBagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);
    canvas.drawCircle(
      const Offset(40, 40),
      38,
      Paint()..color = AppPalette.pistachio,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 26, 42, 42),
        const Radius.circular(10),
      ),
      Paint()..color = AppPalette.paper,
    );
    final line = Paint()
      ..color = AppPalette.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(29, 30)
        ..lineTo(29, 23)
        ..cubicTo(29, 9, 51, 9, 51, 23)
        ..lineTo(51, 30),
      line,
    );
    canvas.drawCircle(
      const Offset(32, 44),
      2,
      Paint()..color = AppPalette.forest,
    );
    canvas.drawCircle(
      const Offset(48, 44),
      2,
      Paint()..color = AppPalette.forest,
    );
    canvas.drawPath(
      Path()
        ..moveTo(34, 51)
        ..quadraticBezierTo(40, 57, 46, 51),
      line..strokeWidth = 2,
    );
    canvas.drawOval(
      const Rect.fromLTWH(24, 48, 8, 4),
      Paint()..color = AppPalette.peach,
    );
    canvas.drawOval(
      const Rect.fromLTWH(48, 48, 8, 4),
      Paint()..color = AppPalette.peach,
    );
    canvas.drawCircle(
      const Offset(65, 17),
      4,
      Paint()..color = AppPalette.peach,
    );
    canvas.drawCircle(
      const Offset(13, 48),
      3,
      Paint()..color = AppPalette.paper,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShoppingBagPainter oldDelegate) => false;
}
