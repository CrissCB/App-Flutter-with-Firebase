import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// ID único del usuario en Firebase Auth.
  final String uid;

  /// Correo electrónico (puede venir vacío en algunos proveedores).
  final String email;

  /// Nombre para mostrar (Google lo entrega; el registro por correo no).
  final String? displayName;

  /// URL de la foto de perfil (solo con Google).
  final String? photoUrl;

  /// Crea el modelo a partir del `User` de Firebase.
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Nombre a mostrar en la interfaz: usa `displayName` si existe,
  /// y si no, la parte del correo antes del @.
  String get nameOrEmail {
    final name = displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return email.contains('@') ? email.split('@').first : email;
  }

  /// Inicial para mostrar en un avatar cuando no hay foto.
  String get initial {
    final source = nameOrEmail;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          other.uid == uid &&
          other.email == email &&
          other.displayName == displayName &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoUrl);
}
