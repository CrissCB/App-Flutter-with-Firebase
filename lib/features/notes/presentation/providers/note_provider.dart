import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:app_firebase_connection/features/notes/data/models/note_model.dart';
import 'package:app_firebase_connection/features/notes/data/services/note_service.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider({NoteService? noteService})
    : _service = noteService ?? NoteService();

  final NoteService _service;

  /// Si el servidor no confirma una escritura en este tiempo (por ejemplo,
  /// sin internet), la damos por guardada: Firestore la deja en cola local
  /// y la sincroniza al reconectar.
  static const Duration _writeTimeout = Duration(seconds: 6);

  StreamSubscription<List<NoteModel>>? _subscription;
  String? _uid;

  List<NoteModel> _notes = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _disposed = false;
  String? _errorMessage;

  /// Notas del usuario actual, de la más reciente a la más antigua.
  List<NoteModel> get notes => _notes;

  /// true hasta que llega la primera lista desde Firestore.
  bool get isLoading => _isLoading;

  /// true mientras se crea, actualiza o elimina una nota.
  bool get isSaving => _isSaving;

  /// Último error listo para mostrar al usuario.
  String? get errorMessage => _errorMessage;

  bool get isEmpty => !_isLoading && _notes.isEmpty;

  /// Lo llama el ProxyProvider cada vez que cambia el AuthProvider.
  /// Solo reinicia la escucha cuando cambia el uid (login, logout o cambio
  /// de cuenta), así nunca se ven notas de otro usuario.
  ///
  /// No llama a notifyListeners() a propósito: se ejecuta durante el build
  /// del árbol de widgets y notificar ahí lanzaría un error. Los eventos del
  /// stream, que son asíncronos, se encargan de notificar.
  void updateUser(String? uid) {
    if (uid == _uid) return;

    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _notes = const [];
    _errorMessage = null;
    _isSaving = false;

    if (uid == null) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    _subscription = _service
        .watchNotes(uid)
        .listen(
          (notes) {
            _notes = notes;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object e) {
            _isLoading = false;
            _errorMessage = _mapError(e);
            notifyListeners();
          },
        );
  }

  /// Busca una nota ya cargada en memoria (sin ir a Firestore).
  NoteModel? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// Obtiene una nota por ID: primero de la lista local y, si no está
  /// (por ejemplo, al recargar /notes/:id en web), desde Firestore.
  Future<NoteModel?> getNote(String id) async {
    final local = noteById(id);
    if (local != null) return local;

    final uid = _uid;
    if (uid == null) return null;

    try {
      return await _service.getNote(uid, id);
    } catch (e) {
      _errorMessage = _mapError(e);
      notifyListeners();
      return null;
    }
  }

  /// Crea una nota. Devuelve true si salió bien.
  Future<bool> createNote({required String title, required String content}) {
    return _write((uid) async {
      await _service.createNote(uid, title: title, content: content);
    });
  }

  /// Actualiza una nota existente. Devuelve true si salió bien.
  Future<bool> updateNote(
    String id, {
    required String title,
    required String content,
  }) {
    return _write((uid) {
      return _service.updateNote(uid, id, title: title, content: content);
    });
  }

  /// Elimina una nota. Devuelve true si salió bien.
  Future<bool> deleteNote(String id) {
    return _write((uid) => _service.deleteNote(uid, id));
  }

  /// Limpia el error mostrado.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta una escritura con control de estado y errores.
  Future<bool> _write(Future<void> Function(String uid) action) async {
    final uid = _uid;
    if (uid == null || _isSaving) return false; // sin sesión o doble toque

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action(uid).timeout(_writeTimeout);
      return true;
    } on TimeoutException {
      // Sin confirmación del servidor: queda en cola local y se sincroniza
      // al recuperar la conexión.
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Traduce los errores de Firestore a mensajes en español.
  String _mapError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permiso para esta acción. Revisa las reglas de Firestore.';
        case 'unavailable':
          return 'Sin conexión con el servidor. Revisa tu internet.';
        case 'not-found':
          return 'La nota ya no existe.';
        case 'unauthenticated':
          return 'Tu sesión expiró. Inicia sesión de nuevo.';
        case 'resource-exhausted':
          return 'Se alcanzó el límite de uso de Firestore. Inténtalo más tarde.';
        case 'failed-precondition':
          return 'Falta un índice o configuración en Firestore (${error.code}).';
        default:
          return 'Error de Firestore (${error.code}).';
      }
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  /// Evita notificar después de dispose (por ejemplo, si el usuario cierra
  /// sesión mientras una escritura sigue en curso).
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
