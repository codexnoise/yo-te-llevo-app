import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/user_role.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.passenger:
        return 'Pasajero';
      case UserRole.driver:
        return 'Conductor';
      case UserRole.both:
        return 'Pasajero y Conductor';
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        // El redirect del router lleva a /login automáticamente.
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Sin datos de perfil'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Center(child: Text(user.email)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rol'),
                subtitle: Text(_roleLabel(user.role)),
              ),
              if (user.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Teléfono'),
                  subtitle: Text(user.phone!),
                ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Calificación'),
                subtitle: Text(user.rating.toStringAsFixed(1)),
              ),
              ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: const Text('Viajes totales'),
                subtitle: Text('${user.totalTrips}'),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
