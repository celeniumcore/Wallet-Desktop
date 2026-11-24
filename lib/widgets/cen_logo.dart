import 'package:flutter/material.dart';

/// Logo CEN dari master rounded resmi (`assets/cen_logo_rounded10.png`).
///
/// Decode dilakukan pada ukuran fisik layar supaya tepi rounded tetap tajam
/// di 30 px maupun 230 px, tanpa perlu menyimpan banyak salinan ukuran.
class CenLogo extends StatelessWidget {
  const CenLogo({super.key, required this.size, this.opacity = 1});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = Image.asset(
      'assets/cen_logo_rounded10.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      cacheWidth: (size * dpr).round(),
    );

    if (opacity >= 1) return image;
    return Opacity(opacity: opacity, child: image);
  }
}
