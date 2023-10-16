import "package:flutter/material.dart";
import "package:luffy/main.dart";
import "package:luffy/screens/settings/notifications.dart";
import "package:luffy/screens/settings/profile.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text("Profile"),
            subtitle: const Text("Edit your profile information"),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Configure notification settings"),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Privacy"),
            subtitle: const Text("Manage your privacy settings"),
            leading: const Icon(Icons.lock),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle privacy tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Help & Support"),
            subtitle: const Text("Get help and support"),
            leading: const Icon(Icons.help),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle help & support tap
            },
          ),
          const Divider(),
          if (MyApp.of(context)!.malToken != null)
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.exit_to_app),
              onTap: () {
                MyApp.of(context)!.setToken(null);
              },
            ),
        ],
      ),
    );
  }
}
