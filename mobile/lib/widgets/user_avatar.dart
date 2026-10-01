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

  Color get _color {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
    ];
    final code = name.isEmpty ? 0 : name.codeUnitAt(0);
    return colors[code % colors.length];
  }

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _color,
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
      backgroundColor: _color,
      child: _placeholder(),
    );
  }

  Widget _placeholder() => Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      );
}
