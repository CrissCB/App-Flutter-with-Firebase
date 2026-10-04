import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_firebase_connection/features/notes/data/models/note_model.dart';

class NoteService {
  NoteService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Colección de notas de un usuario: users/{uid}/notes
  CollectionReference<Map<String, dynamic>> _notesRef(String uid) {
    return _db.collection('users').doc(uid).collection('notes');
  }

  /// Stream en tiempo real de las notas del usuario, de la más
  /// recientemente editada a la más antigua.
  Stream<List<NoteModel>> watchNotes(String uid) {
    return _notesRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NoteModel.fromDoc).toList());
  }

  /// Obtiene una nota por su ID (null si no existe).
  Future<NoteModel?> getNote(String uid, String noteId) async {
    final doc = await _notesRef(uid).doc(noteId).get();
    return doc.exists ? NoteModel.fromDoc(doc) : null;
  }

  /// Crea una nota nueva y devuelve su ID.
  Future<String> createNote(
    String uid, {
    required String title,
    required String content,
  }) async {
    final note = NoteModel(id: '', title: title, content: content);
    final doc = await _notesRef(uid).add(note.toCreateMap());
    return doc.id;
  }

  /// Actualiza título y contenido de una nota existente.
  Future<void> updateNote(
    String uid,
    String noteId, {
    required String title,
    required String content,
  }) {
    final note = NoteModel(id: noteId, title: title, content: content);
    return _notesRef(uid).doc(noteId).update(note.toUpdateMap());
  }

  /// Elimina una nota.
  Future<void> deleteNote(String uid, String noteId) {
    return _notesRef(uid).doc(noteId).delete();
  }
}
