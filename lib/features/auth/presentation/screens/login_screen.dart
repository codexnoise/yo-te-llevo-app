import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Yo Te Llevo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Carpooling de rutas fijas',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            const Text(
              'Login - En construcción',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
