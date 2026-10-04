import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  /// ID del documento en Firestore (vacío si la nota aún no se ha guardado).
  final String id;

  final String title;
  final String content;

  /// Pueden ser null un instante: mientras el servidor aún no confirma
  /// el serverTimestamp(), el valor llega vacío en el primer evento local.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nota vacía, útil para el editor al crear una nueva.
  const NoteModel.empty()
    : id = '',
      title = '',
      content = '',
      createdAt = null,
      updatedAt = null;

  bool get isNew => id.isEmpty;

  /// Título para mostrar en listas: si está vacío, un texto por defecto.
  String get displayTitle => title.trim().isEmpty ? 'Sin título' : title.trim();

  /// Vista previa del contenido (una sola línea, sin saltos).
  String get preview => content.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Crea la nota a partir de un documento de Firestore.
  factory NoteModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NoteModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Datos para CREAR la nota. Ambas fechas las pone el servidor.
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title.trim(),
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Datos para ACTUALIZAR la nota. No toca `createdAt`.
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  NoteModel copyWith({String? title, String? content}) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel &&
          other.id == id &&
          other.title == title &&
          other.content == content &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, content, createdAt, updatedAt);
}
