import "package:flutter/material.dart";

class VideoPlayerIcon extends StatelessWidget {
  const VideoPlayerIcon({
    super.key,
    this.icon,
    required this.onPressed,
    this.label,
    this.color = Colors.white,
    this.border,
  });

  final IconData? icon;
  final VoidCallback onPressed;
  final String? label;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    assert(icon != null || label != null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.grey,
        splashFactory: InkRipple.splashFactory,
        child: Container(
          decoration: BoxDecoration(
            border: border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: color,
                ),
              if (label != null) ...[
                if (icon != null) const SizedBox(width: 8),
                Text(
                  label!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
