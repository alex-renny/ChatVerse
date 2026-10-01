import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar that displays the user's profile picture or a colored
/// initials fallback if no URL is provided.
class UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    this.url,
    required this.name,
    this.radius = 24,
  });

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0x1AFF7A00),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0x1AFF7A00),
      child: _placeholder(),
    );
  }

  Widget _placeholder() => Text(
        _initial,
        style: TextStyle(
          color: const Color(0xFFFF7A00),
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      );
}
