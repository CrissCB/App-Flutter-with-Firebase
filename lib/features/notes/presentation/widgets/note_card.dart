import 'package:flutter/material.dart';

import 'package:app_firebase_connection/features/notes/data/models/note_model.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDelete,
  });

  final NoteModel note;

  /// Se ejecuta al tocar la tarjeta (abre el editor).
  final VoidCallback onTap;

  /// Se ejecuta cuando el usuario CONFIRMA la eliminación.
  /// Si es null, no se muestra el botón ni se permite deslizar.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final preview = note.preview;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(note.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Eliminar nota',
                  icon: const Icon(Icons.delete_outline),
                  color: colors.onSurfaceVariant,
                  onPressed: () => _confirmAndDelete(context),
                ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    // Deslizar hacia la izquierda para eliminar (con confirmación).
    return Dismissible(
      key: ValueKey('note-${note.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _askConfirmation(context),
      onDismissed: (_) => onDelete!(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      child: card,
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await _askConfirmation(context);
    if (confirmed == true) onDelete?.call();
  }

  Future<bool?> _askConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text(
          '¿Eliminar "${note.displayTitle}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Formato simple sin dependencias: "Hoy 14:05", "Ayer 09:30" o "03/10/2026".
  static String _formatDate(DateTime? date) {
    // Mientras el servidor no confirma el serverTimestamp, la fecha es null.
    if (date == null) return 'Guardando...';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(date.hour)}:${two(date.minute)}';

    if (diff == 0) return 'Hoy $time';
    if (diff == 1) return 'Ayer $time';
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
