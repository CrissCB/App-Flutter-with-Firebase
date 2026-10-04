import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:app_firebase_connection/features/auth/data/models/user_model.dart';

/// Se lanza cuando el usuario cierra o cancela el flujo de Google.
/// El provider la ignora sin mostrar error.
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'AuthCancelledException: inicio de sesión cancelado';
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Solo necesario en Android/iOS. Es el "Web client ID" de Firebase Console
  /// → Authentication → Sign-in method → Google → Web SDK configuration.
  /// En web (localhost) no se usa.
  // static const String? _serverClientId = null;
  static const String? _serverClientId =
      '149617547684-jblqhp5m7lnkfaphjq0ag9dvqafgdpv2.apps.googleusercontent.com';

  Future<void>? _googleInit;

  /// En google_sign_in 7.x, initialize() debe llamarse una vez antes de usarlo.
  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn
        .initialize(serverClientId: _serverClientId)
        .catchError((Object e) {
          _googleInit = null; // permite reintentar si falló
          throw e;
        });
  }

  /// Usuario actual (null si no hay sesión).
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  /// Emite el usuario cada vez que cambia la sesión (null = sin sesión).
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : UserModel.fromFirebaseUser(user),
    );
  }

  /// Registro con correo y contraseña.
  Future<UserModel> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    return UserModel.fromFirebaseUser(_auth.currentUser ?? user);
  }

  /// Inicio de sesión con correo y contraseña.
  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  /// Inicio de sesión con Google.
  /// Web: popup de Firebase. Móvil: google_sign_in 7.x + credencial de Firebase.
  Future<UserModel> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        final credential = await _auth.signInWithPopup(GoogleAuthProvider());
        return UserModel.fromFirebaseUser(credential.user!);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw const AuthCancelledException();
        }
        rethrow;
      }
    }

    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In no está soportado en esta plataforma.',
      );
    }

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google no devolvió un idToken.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return UserModel.fromFirebaseUser(result.user!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
  }

  /// Cierra la sesión de Firebase y, en móvil, también la de Google.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Si Google falla, igual cerramos la sesión de Firebase.
      }
    }
    await _auth.signOut();
  }
}
