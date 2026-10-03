import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_firebase_connection/features/auth/presentation/providers/auth_provider.dart';

/// Versión temporal: solo muestra al usuario y permite cerrar sesión.
/// Se reemplaza en el paso 19 por la lista de archivos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.isLoading
                ? null
                : () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.initial,
                              style: theme.textTheme.headlineMedium,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nameOrEmail,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sesión iniciada correctamente',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
