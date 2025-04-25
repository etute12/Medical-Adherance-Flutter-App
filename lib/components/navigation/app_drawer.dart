import 'package:flutter/material.dart';
import 'package:kobi_projet/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';


class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final Function(String) onRouteChanged;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final bool isDoctor = user?.role == 'doctor';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (isDoctor) ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Patients'),
              selected: currentRoute == 'patients',
              onTap: () {
                onRouteChanged('patients');
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Medications'),
              selected: currentRoute == 'medications',
              onTap: () {
                onRouteChanged('medications');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              selected: currentRoute == 'calendar',
              onTap: () {
                onRouteChanged('calendar');
                Navigator.pop(context);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            selected: currentRoute == 'profile',
            onTap: () {
              onRouteChanged('profile');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
