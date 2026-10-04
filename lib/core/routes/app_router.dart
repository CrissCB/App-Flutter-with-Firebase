import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_firebase_connection/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_firebase_connection/features/auth/presentation/screens/login_screen.dart';
import 'package:app_firebase_connection/features/auth/presentation/screens/register_screen.dart';
import 'package:app_firebase_connection/features/notes/presentation/screens/home_screen.dart';
import 'package:app_firebase_connection/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:app_firebase_connection/core/widgets/loading_indicator.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const newNote = '/notes/new';
  static const editNote = '/notes/:id';

  /// Ruta para editar una nota concreta: /notes/<id>
  static String note(String id) => '/notes/$id';
}

class AppRouter {
  AppRouter._();

  /// Crea el router. Debe llamarse UNA sola vez (ver main.dart), no dentro
  /// de un build(), o se reiniciaría la navegación en cada reconstrucción.
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      // Reevalúa el redirect cada vez que AuthProvider notifica cambios.
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;

        // 1. Firebase aún no informa si hay sesión guardada: esperar en el
        //    splash, recordando a dónde quería ir el usuario (por ejemplo,
        //    al recargar /notes/abc en web).
        if (!auth.isInitialized) {
          if (location == AppRoutes.splash) return null;
          final from = Uri.encodeComponent(state.uri.toString());
          return '${AppRoutes.splash}?from=$from';
        }

        final loggedIn = auth.isAuthenticated;
        final onAuthPage =
            location == AppRoutes.login || location == AppRoutes.register;

        // 2. Sin sesión: solo se permiten login y registro.
        if (!loggedIn) {
          return onAuthPage ? null : AppRoutes.login;
        }

        // 3. Con sesión: no tiene sentido ver login, registro ni splash.
        if (location == AppRoutes.splash) {
          final from = state.uri.queryParameters['from'];
          final validFrom =
              from != null &&
              from.startsWith('/') &&
              !from.startsWith('//') &&
              !from.startsWith(AppRoutes.splash);
          return validFrom ? from : AppRoutes.home;
        }
        if (onAuthPage) return AppRoutes.home;

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
        // IMPORTANTE: /notes/new debe ir ANTES de /notes/:id; si no, "new"
        // se interpretaría como el id de una nota.
        GoRoute(
          path: AppRoutes.newNote,
          builder: (context, state) => const NoteEditorScreen(),
        ),
        GoRoute(
          path: AppRoutes.editNote,
          builder: (context, state) =>
              NoteEditorScreen(noteId: state.pathParameters['id']),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
      ),
    );
  }
}
