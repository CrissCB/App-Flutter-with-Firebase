import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_firebase_connection/core/routes/app_router.dart';
import 'package:app_firebase_connection/core/theme/app_theme.dart';
import 'package:app_firebase_connection/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_firebase_connection/features/notes/presentation/providers/note_provider.dart';
import 'package:app_firebase_connection/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Se crean UNA sola vez, para que el router no se reinicie
  // en cada reconstrucción del widget.
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.create(_authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // .value porque el provider ya fue creado arriba (el router lo
        // necesita). Por eso lo liberamos manualmente en dispose().
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),

        // NoteProvider depende del usuario: cada vez que AuthProvider
        // notifica, se le pasa el uid actual. Solo reinicia la escucha de
        // Firestore cuando el uid cambia (login, logout o cambio de cuenta).
        ChangeNotifierProxyProvider<AuthProvider, NoteProvider>(
          create: (_) => NoteProvider(),
          update: (_, auth, previous) =>
              (previous ?? NoteProvider())..updateUser(auth.user?.uid),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mis notas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
