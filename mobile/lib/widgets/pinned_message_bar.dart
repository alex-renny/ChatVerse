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
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(
          bottom: BorderSide(color: Color(0xFFFFEDD5), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Color(0xFFFF7A00), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pinned Message',
                  style: TextStyle(
                    color: Color(0xFFFF7A00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF2C2C2C), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            onPressed: onUnpin,
          ),
        ],
      ),
    );
  }
}
