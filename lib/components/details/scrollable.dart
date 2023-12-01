import "package:flutter/material.dart";

class Scrollable<T> extends StatelessWidget {
  const Scrollable({
    super.key,
    required this.items,
    required this.title,
    required this.builder,
    this.spaceBetween = 8,
  });

  final List<T> items;
  final String title;
  final Widget Function(BuildContext, int) builder;
  final double spaceBetween;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: builder,
            separatorBuilder: (_, __) => SizedBox(width: spaceBetween),
          ),
        ),
      ],
    );
  }
}
