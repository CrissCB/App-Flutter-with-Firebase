import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:app_firebase_connection/features/auth/data/models/user_model.dart';
import 'package:app_firebase_connection/features/auth/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _subscription = _authService.authStateChanges().listen(
      (user) {
        _user = user;
        _initialized = true;
        notifyListeners();
      },
      onError: (Object e) {
        _initialized = true;
        _errorMessage = _mapError(e);
        notifyListeners();
      },
    );
  }

  final AuthService _authService;
  late final StreamSubscription<UserModel?> _subscription;

  UserModel? _user;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Usuario actual (null si no hay sesión).
  UserModel? get user => _user;

  /// true cuando hay sesión activa.
  bool get isAuthenticated => _user != null;

  /// false hasta que Firebase informa el estado inicial de la sesión.
  /// El router lo usa para no redirigir al login antes de tiempo.
  bool get isInitialized => _initialized;

  /// true mientras se ejecuta una operación (login, registro, etc.).
  bool get isLoading => _isLoading;

  /// Último mensaje de error listo para mostrar al usuario.
  String? get errorMessage => _errorMessage;

  /// Registro con correo y contraseña. Devuelve true si salió bien.
  Future<bool> signUp(String email, String password, {String? displayName}) {
    return _run(() async {
      _user = await _authService.signUpWithEmail(
        email,
        password,
        displayName: displayName,
      );
    });
  }

  /// Inicio de sesión con correo y contraseña.
  Future<bool> signIn(String email, String password) {
    return _run(() async {
      _user = await _authService.signInWithEmail(email, password);
    });
  }

  /// Inicio de sesión con Google. Si el usuario cancela, no hay error.
  Future<bool> signInWithGoogle() {
    return _run(() async {
      _user = await _authService.signInWithGoogle();
    });
  }

  /// Cierra la sesión.
  Future<void> signOut() async {
    await _run(() async {
      await _authService.signOut();
      _user = null;
    });
  }

  /// Limpia el error (por ejemplo, al cambiar de pantalla).
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta una acción con control de carga y errores.
  Future<bool> _run(Future<void> Function() action) async {
    if (_isLoading) return false; // evita toques repetidos
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthCancelledException {
      return false; // cancelado por el usuario: sin mensaje
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Traduce los errores técnicos a mensajes en español.
  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo.';
        case 'weak-password':
          return 'La contraseña es muy débil (mínimo 6 caracteres).';
        case 'operation-not-allowed':
          return 'Este método de acceso no está habilitado en Firebase.';
        case 'too-many-requests':
          return 'Demasiados intentos. Inténtalo más tarde.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        case 'account-exists-with-different-credential':
          return 'Ya existe una cuenta con ese correo usando otro método.';
        case 'popup-blocked':
          return 'El navegador bloqueó la ventana de Google. Permite popups.';
        case 'missing-google-id-token':
          return 'No se pudo obtener la credencial de Google.';
        default:
          return 'Error de autenticación (${error.code}).';
      }
    }

    if (error is GoogleSignInException) {
      return 'No se pudo iniciar sesión con Google. '
          'Revisa la configuración (SHA-1 y Web client ID).';
    }

    if (error is UnsupportedError) {
      return 'Esta función no está disponible en tu plataforma.';
    }

    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
