import 'package:flutter/material.dart';
import '../theme.dart';
import '../strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CenTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/cen_logo_circle.png', width: 96, height: 96),
            const SizedBox(height: 24),
            Text(
              S.appName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CenTheme.txt,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.nonKustodial,
              style: const TextStyle(
                fontSize: 13,
                color: CenTheme.muted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CenTheme.acid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
