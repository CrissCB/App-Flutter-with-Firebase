import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_firebase_connection/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_firebase_connection/features/auth/presentation/screens/login_screen.dart';
import 'package:app_firebase_connection/features/auth/presentation/screens/register_screen.dart';
import 'package:app_firebase_connection/features/notes/presentation/screens/home_screen.dart';
import 'package:app_firebase_connection/core/widgets/loading_indicator.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
}

class AppRouter {
  AppRouter._();

  /// Crea el router. Debe llamarse UNA sola vez (ver paso 12), no dentro
  /// de un build(), o se reiniciaría la navegación en cada reconstrucción.
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      // Reevalúa el redirect cada vez que AuthProvider notifica cambios
      // (sesión iniciada, cerrada o estado inicial resuelto).
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;

        // 1. Firebase aún no informa si hay sesión guardada: esperar.
        if (!auth.isInitialized) {
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        }

        final loggedIn = auth.isAuthenticated;
        final onAuthPage =
            location == AppRoutes.login || location == AppRoutes.register;

        // 2. Sin sesión: solo se permiten login y registro.
        if (!loggedIn) {
          return onAuthPage ? null : AppRoutes.login;
        }

        // 3. Con sesión: no tiene sentido ver login, registro ni splash.
        if (onAuthPage || location == AppRoutes.splash) {
          return AppRoutes.home;
        }

        return null; // sin redirección
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const Scaffold(body: LoadingIndicator()),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
      ),
    );
  }
}
