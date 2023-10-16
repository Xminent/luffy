import "package:flutter/material.dart";

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text("Push Notifications"),
            subtitle: const Text("Enable or disable push notifications"),
            trailing: Switch(
              value: true, // Set the initial value based on user preferences
              onChanged: (value) {
                // Handle push notifications switch change
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Email Notifications"),
            subtitle: const Text("Configure email notification preferences"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle email notifications tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("In-App Notifications"),
            subtitle: const Text("Configure in-app notification preferences"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle in-app notifications tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Notification Sound"),
            subtitle: const Text("Select the sound for notifications"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle notification sound tap
            },
          ),
        ],
      ),
    );
  }
}
