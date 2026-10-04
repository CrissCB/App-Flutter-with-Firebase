import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_firebase_connection/core/widgets/loading_indicator.dart';
import 'package:app_firebase_connection/features/notes/data/models/note_model.dart';
import 'package:app_firebase_connection/features/notes/presentation/providers/note_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  /// [noteId] null = nota nueva (/notes/new). Con valor = editar (/notes/:id).
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _loading = false; // cargando una nota existente
  bool _notFound = false;

  /// Texto original, para detectar cambios sin guardar.
  String _initialTitle = '';
  String _initialContent = '';

  bool get _isNew => widget.noteId == null;

  bool get _hasChanges =>
      _titleController.text != _initialTitle ||
      _contentController.text != _initialContent;

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      _loading = true;
      _loadNote();
      _titleController.addListener(_onTextChanged);
      _contentController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final note = await context.read<NoteProvider>().getNote(widget.noteId!);
    if (!mounted) return;

    if (note == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    _fill(note);
    setState(() => _loading = false);
  }

  void _fill(NoteModel note) {
    _initialTitle = note.title;
    _initialContent = note.content;
    _titleController.text = note.title;
    _contentController.text = note.content;
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty && content.trim().isEmpty) {
      _showMessage('Escribe un título o contenido antes de guardar.');
      return;
    }

    FocusScope.of(context).unfocus();
    final provider = context.read<NoteProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = _isNew
        ? await provider.createNote(title: title, content: content)
        : await provider.updateNote(
            widget.noteId!,
            title: title,
            content: content,
          );

    if (!mounted) return;

    if (ok) {
      // Marcamos como guardado para que el cierre no pregunte por cambios.
      _initialTitle = _titleController.text;
      _initialContent = _contentController.text;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nota guardada')));
      _close();
    } else {
      _showMessage(provider.errorMessage ?? 'No se pudo guardar la nota.');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('Esta acción no se puede deshacer.'),
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
    if (confirmed != true || !mounted) return;

    final provider = context.read<NoteProvider>();
    final ok = await provider.deleteNote(widget.noteId!);
    if (!mounted) return;

    if (ok) {
      // Sin cambios pendientes: nada que preguntar al salir.
      _initialTitle = _titleController.text;
      _initialContent = _contentController.text;
      _close();
    } else {
      _showMessage(provider.errorMessage ?? 'No se pudo eliminar la nota.');
    }
  }

  /// Vuelve a la lista. Si no hay pantalla anterior (por ejemplo, tras
  /// recargar /notes/:id en web), va a /home.
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Pregunta si descartar los cambios sin guardar.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Tienes cambios sin guardar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _onBack() async {
    if (!_hasChanges || await _confirmDiscard()) {
      if (mounted) _close();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = context.select<NoteProvider, bool>((p) => p.isSaving);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingIndicator(message: 'Cargando nota...'),
      );
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _close)),
        body: const Center(child: Text('La nota no existe o fue eliminada.')),
      );
    }

    return PopScope(
      // Interceptamos el "atrás" del sistema solo si hay cambios sin guardar.
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Nueva nota' : 'Editar nota'),
          leading: BackButton(onPressed: isSaving ? null : _onBack),
          actions: [
            if (!_isNew)
              IconButton(
                tooltip: 'Eliminar nota',
                icon: const Icon(Icons.delete_outline),
                onPressed: isSaving ? null : _delete,
              ),
            if (isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Guardar',
                icon: const Icon(Icons.check),
                onPressed: _save,
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLines: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Título',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        enabled: !isSaving,
                        autofocus: _isNew,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu nota...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
