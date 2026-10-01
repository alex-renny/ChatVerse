import 'package:flutter/material.dart';
import '../models/message_model.dart';

/// A sticky bar shown at the top of the chat when a message is pinned.
class PinnedMessageBar extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final VoidCallback onUnpin;

  const PinnedMessageBar({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final preview = message.text.isNotEmpty ? message.text : '[Attachment]';

    return Container(
      color: const Color(0xFF14142B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Color(0xFF7C3AED), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pinned Message',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            onPressed: onUnpin,
          ),
        ],
      ),
    );
  }
}
