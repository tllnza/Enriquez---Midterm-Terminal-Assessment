import 'package:flutter/material.dart';

class NetworkBanner extends StatelessWidget {
  final bool online;

  const NetworkBanner({super.key, required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: online ? Colors.green.shade600 : Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(online ? Icons.wifi : Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              online
                  ? 'Online mode: Firestore sync available.'
                  : 'Offline mode: Tasks saved locally.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
