import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.onSignOut});

  final User user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аптечка', style: TextStyle(color: AppTheme.primaryDarkBlue)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Вы вошли как ${user.email}',
              style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
