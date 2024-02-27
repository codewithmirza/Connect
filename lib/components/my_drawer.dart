import 'package:flutter/material.dart';
import 'package:connect/pages/profile_card.dart';
import 'package:connect/pages/settings_page.dart';

import '../auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  Future<void> logout() async {
    final auth = AuthService();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Logo
               DrawerHeader(
                child: Center(
                  child: Image.asset(
                    "assets/images/connect-icon.png",
                    width: 60,
                    height: 60,
                    color: const Color(0xFF00A8FF),
                  ),
                ),
              ),

              // Profile
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: const Text("Profile"),
                  leading: const Icon(Icons.person),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileCard(),
                        ));
                  },
                ),
              ),

              // Settings
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: const Text("Settings"),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ));
                  },
                ),
              ),
            ],
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 80),
            child: ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: logout,
            ),
          ),
        ],
      ),
    );
  }
}
