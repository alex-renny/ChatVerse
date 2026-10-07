import 'package:flutter/material.dart';

/// Animated ReSender chat bubbles for app and conversation loading states.
class ResenderLoader extends StatefulWidget {
  final bool showLabel;
  final double scale;

  const ResenderLoader({super.key, this.showLabel = false, this.scale = 1});

  @override
  State<ResenderLoader> createState() => _ResenderLoaderState();
}

class _ResenderLoaderState extends State<ResenderLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 78 * scale,
          height: 58 * scale,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(-7 + 5 * _controller.value, -5) * scale,
                  child: _bubble(Colors.black12, 39 * scale, 30 * scale, 0.0),
                ),
                Transform.translate(
                  offset: Offset(7 - 5 * _controller.value, 5) * scale,
                  child: _bubble(const Color(0xFFFF7A00), 43 * scale,
                      34 * scale, _controller.value),
                ),
              ],
            ),
          ),
        ),
        if (widget.showLabel) ...[
          SizedBox(height: 8 * scale),
          Text(
            'Connecting your conversations',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12 * scale),
          ),
        ],
      ],
    );
  }

  Widget _bubble(Color color, double width, double height, double phase) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5 * widget.scale),
              child: Opacity(
                opacity: .4 + .6 * ((phase + i / 3) % 1),
                child: Container(
                  width: 4 * widget.scale,
                  height: 4 * widget.scale,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
