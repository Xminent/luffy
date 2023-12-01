import "package:flutter/material.dart";

const defaultThemeColors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.pink,
  Colors.teal,
  Colors.indigo,
];

void showThemeDialog(
  BuildContext context, {
  required Function(Color) onThemeChange,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Select Theme"),
        content: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: defaultThemeColors.map((color) {
            return GestureDetector(
              onTap: () {
                onThemeChange(color);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundColor: color,
                radius: 20.0,
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    this.themeColors = defaultThemeColors,
    required this.onThemeChange,
  });

  final List<Color> themeColors;
  final Function(Color) onThemeChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Select Theme"),
              content: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: themeColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      onThemeChange(color);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20.0,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.color_lens),
      ),
    );
  }
}
