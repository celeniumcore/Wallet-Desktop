import 'package:flutter/material.dart';

import '../services/wallet_data.dart';
import '../theme.dart';

/// Balance line for the wallet card. Draws only what was sampled on device, so
/// a fresh wallet shows its caller's empty state instead of an invented curve.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.samples,
    this.color = CenTheme.acid,
  });

  final List<BalanceSample> samples;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparkPainter(
        values: samples.map((s) => s.pradha).toList(growable: false),
        color: color,
      ),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = hi == lo
        ? (hi.abs() ~/ 1000 < 1 ? 1 : hi.abs() ~/ 1000)
        : hi - lo;
    final pad = size.height < 24 ? 2.0 : 5.0;
    final usable = size.height - pad * 2;
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int index) {
      final ratio = values[index] == lo && hi == lo
          ? 0.5
          : (values[index] - lo) / span;
      return Offset(index * stepX, size.height - pad - ratio * usable);
    }

    final points = List<Offset>.generate(values.length, pointAt);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 3.4, Paint()..color = color);
    canvas.drawCircle(
      last,
      5.6,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) =>
      oldDelegate.color != color || !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}