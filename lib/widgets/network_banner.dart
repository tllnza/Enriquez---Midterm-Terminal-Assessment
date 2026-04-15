import 'package:flutter/material.dart';

class NetworkBanner extends StatelessWidget {
  final bool online;

  const NetworkBanner({super.key, required this.online});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = online
        ? const Color(0xFF0D7A4F)
        : theme.colorScheme.errorContainer;
    final fg = online ? Colors.white : theme.colorScheme.onErrorContainer;

    return Material(
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: fg.withValues(alpha: 0.15),
              child: Icon(
                online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: fg,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    online ? 'You are online' : 'You are offline',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    online
                        ? 'Firestore sync and weather are available.'
                        : 'Tasks stay on this device until you reconnect.',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.92),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
