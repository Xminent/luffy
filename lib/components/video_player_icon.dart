import "package:flutter/material.dart";

class VideoPlayerIcon extends StatelessWidget {
  const VideoPlayerIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.grey,
        splashFactory: InkRipple.splashFactory,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
