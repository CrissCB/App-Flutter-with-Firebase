import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_firebase_connection/core/widgets/loading_indicator.dart';
import 'package:app_firebase_connection/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_firebase_connection/features/notes/presentation/providers/note_provider.dart';
import 'package:app_firebase_connection/features/notes/presentation/widgets/note_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _deleteNote(BuildContext context, String noteId) async {
    final provider = context.read<NoteProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await provider.deleteNote(noteId);
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nota eliminada')));
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'No se pudo eliminar la nota.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NoteProvider>();
    final notes = notesProvider.notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis notas'),
        actions: const [_UserMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
      body: _buildBody(context, notesProvider, notes),
    );
  }

  Widget _buildBody(BuildContext context, NoteProvider provider, List notes) {
    if (provider.isLoading) {
      return const LoadingIndicator(message: 'Cargando notas...');
    }

    // Error al escuchar Firestore (por ejemplo, reglas mal configuradas).
    if (provider.errorMessage != null && notes.isEmpty) {
      return _MessageState(
        icon: Icons.error_outline,
        title: 'No se pudieron cargar las notas',
        message: provider.errorMessage!,
      );
    }

    if (provider.isEmpty) {
      return const _MessageState(
        icon: Icons.note_add_outlined,
        title: 'Aún no tienes notas',
        message: 'Toca "Nueva nota" para crear la primera.',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          // Espacio inferior para que el botón flotante no tape la última nota.
          padding: const EdgeInsets.only(top: 8, bottom: 96),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return NoteCard(
              key: ValueKey(note.id),
              note: note,
              onTap: () => context.push('/notes/${note.id}'),
              onDelete: () => _deleteNote(context, note.id),
            );
          },
        ),
      ),
    );
  }
}

/// Avatar del usuario con menú: datos de la cuenta y cerrar sesión.
class _UserMenu extends StatelessWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, dynamic>((a) => a.user);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') context.read<AuthProvider>().signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.nameOrEmail, style: theme.textTheme.titleSmall),
              Text(
                user.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 16,
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(user.initial, style: const TextStyle(fontSize: 14))
              : null,
        ),
      ),
    );
  }
}

/// Estado vacío o de error, con icono, título y mensaje.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
