import "package:flutter/material.dart";

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          "Oops",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(
              "Okay",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
