// lib/core/widgets/metric_card.dart
//
// Reusable card for displaying a single telemetry metric value.
// Follows DetaDesign: flat, 1px border, JetBrains Mono for the value,
// Inter for label and unit. No elevation, no shadow.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A fixed-size instrument card for one telemetry metric.
///
/// Usage:
/// ```dart
/// MetricCard(
///   label: 'eCO₂',
///   value: '450',
///   unit: 'ppm',
///   valueColor: AppColors.metricEco2,
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// Short metric label displayed above the value (e.g., "eCO₂", "Temp").
  final String label;

  /// Formatted numeric value as a string (e.g., "450", "24.5").
  final String value;

  /// Unit suffix displayed below/beside the value (e.g., "ppm", "°C", "%").
  final String unit;

  /// Optional override color for the value text. Defaults to [AppColors.textPrimary].
  final Color? valueColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional list of real received points for the mini graph under the value.
  final List<double>? history;

  /// Line and gradient tint color for the received-data mini graph.
  final Color? chartColor;

  /// A concise label for the data cadence shown beside a real trend.
  final String trendLabel;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.onTap,
    this.history,
    this.chartColor,
    this.trendLabel = 'recent',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final unitColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final dataColor = valueColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final graphColor = chartColor ?? dataColor;

    final hasGraph = history != null && history!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: hasGraph ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(kRadiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTheme.monoStyle(
                          fontSize: 9, fontWeight: FontWeight.w600)
                      .copyWith(color: labelColor, letterSpacing: 0.8),
                ),
                if (hasGraph)
                  Text(
                    trendLabel,
                    style: AppTheme.monoStyle(
                            fontSize: 8, fontWeight: FontWeight.w600)
                        .copyWith(color: unitColor),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Value + Unit
            if (hasGraph) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: AppTheme.monoStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: dataColor, height: 1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: AppTheme.monoStyle(fontSize: 10)
                        .copyWith(color: unitColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PerSecondGraphPainter(
                    data: history!,
                    color: graphColor,
                  ),
                ),
              ),
            ] else ...[
              Text(
                value,
                style: AppTheme.monoStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ).copyWith(color: dataColor, height: 1),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                style:
                    AppTheme.monoStyle(fontSize: 11).copyWith(color: unitColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for received telemetry data.
/// Renders a smooth cubic Bezier curve, area gradient fill, and live pulse dot.
class _PerSecondGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _PerSecondGraphPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final w = size.width;
    final h = size.height;

    double minVal = data.first;
    double maxVal = data.first;
    for (final v in data) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    // Dynamic auto-scaling (Style.md 4.2)
    double range = maxVal - minVal;
    if (range < 0.001) {
      minVal -= 0.5;
      maxVal += 0.5;
      range = 1.0;
    } else {
      final pad = range * 0.15;
      minVal -= pad;
      maxVal += pad;
      range = maxVal - minVal;
    }

    final double stepX = data.length > 1 ? w / (data.length - 1) : w;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = ((data[i] - minVal) / range).clamp(0.0, 1.0);
      final y = (h - 4) - (normalized * (h - 7)) + 1;
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, 2.5, Paint()..color = color);
      return;
    }

    // Smooth cubic curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Area fill gradient (Style.md 4.1)
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, h)
      ..lineTo(points.first.dx, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Curve line stroke (Style.md 4.1: clean 1.5 - 2.0px stroke)
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Pulse dot at current second (far right)
    final lastPoint = points.last;
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(lastPoint, 2.2, dotPaint);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(lastPoint, 4.2, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _PerSecondGraphPainter oldDelegate) => true;
}

/// A compact variant of [MetricCard] for list rows and summary strips.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final unitColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final dataColor = valueColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label ',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: labelColor),
        ),
        Text(
          value,
          style: AppTheme.monoStyle(fontSize: 13, fontWeight: FontWeight.w600)
              .copyWith(color: dataColor),
        ),
        Text(
          ' $unit',
          style: AppTheme.monoStyle(fontSize: 10).copyWith(color: unitColor),
        ),
      ],
    );
  }
}
