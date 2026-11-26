import 'package:flutter/material.dart';

import '../theme.dart';

/// Empty state for dashboard cards. Icon, headline, one explanation line, and
/// an optional hint that tells the user what will fill the card — never lorem
/// or a fake row.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    this.icon,
    this.graphic,
    required this.title,
    this.body,
    this.hint,
    this.center = false,
    this.justifyBody = false,
  }) : assert(icon != null || graphic != null,
            'EmptyPanel needs an icon or a graphic');

  final IconData? icon;
  final Widget? graphic;
  final String title;
  final String? body;
  final String? hint;

  /// Lays the block out as a centered column instead of the default left-aligned
  /// row. Used where the card is empty and the copy has to sit in the middle.
  final bool center;

  /// Justifies the body/hint copy (rata kanan-kiri) in centered layout.
  final bool justifyBody;

  @override
  Widget build(BuildContext context) {
    if (center) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          graphic ??
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CenTheme.acid.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: CenTheme.acid.withValues(alpha: 0.16)),
                ),
                child: Icon(icon!,
                    size: 21, color: CenTheme.acid.withValues(alpha: 0.85)),
              ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CenTheme.txt,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          if (body != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                body!,
                textAlign: justifyBody ? TextAlign.justify : TextAlign.center,
                style: const TextStyle(
                  color: CenTheme.sub,
                  fontSize: 11.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CenTheme.muted,
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          graphic ??
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CenTheme.acid.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: CenTheme.acid.withValues(alpha: 0.16)),
                ),
                child: Icon(icon!,
                    size: 19, color: CenTheme.acid.withValues(alpha: 0.85)),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CenTheme.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    body!,
                    style: const TextStyle(
                      color: CenTheme.sub,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
                if (hint != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 5, right: 7),
                        decoration: const BoxDecoration(
                          color: CenTheme.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          hint!,
                          style: const TextStyle(
                            color: CenTheme.muted,
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
