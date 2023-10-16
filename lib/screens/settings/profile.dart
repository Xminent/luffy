import "package:flutter/material.dart";

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text("Edit Profile"),
            subtitle: const Text("Update your profile information"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle edit profile tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Change Password"),
            subtitle: const Text("Update your account password"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle change password tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Privacy Settings"),
            subtitle: const Text("Manage your privacy settings"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle privacy settings tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Email Preferences"),
            subtitle: const Text("Manage your email notification preferences"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle email preferences tap
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Delete Account"),
            subtitle: const Text("Permanently delete your account"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle delete account tap
            },
          ),
        ],
      ),
    );
  }
}
