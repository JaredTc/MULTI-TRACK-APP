import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_config.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/providers/session_meta_provider.dart';
import 'package:multitracks/screens/new_sesion_screen.dart';
import 'package:multitracks/services/hive_service.dart';

class AppBarNav extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final TextEditingController titleController;
  final String initialKeyNote;
  final int initialBpm;
  final String sessionId;
  final Function(String title, String keyNote, int bpm)? onChanged;

  const AppBarNav({
    Key? key,
    required this.titleController,
    this.initialKeyNote = 'C / DO',
    this.initialBpm = 120,
    this.sessionId = '',
    this.onChanged,
  }) : super(key: key);

  @override
  ConsumerState<AppBarNav> createState() => _AppBarNavState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarNavState extends ConsumerState<AppBarNav> {
  late String _currentKeyNote;
  late int _currentBpm;

  @override
  void initState() {
    super.initState();
    _currentKeyNote = widget.initialKeyNote;
    _currentBpm = widget.initialBpm;
  }

  void _notifyChanges() {
    if (widget.onChanged != null) {
      widget.onChanged!(
        widget.titleController.text,
        _currentKeyNote,
        _currentBpm,
      );
    }
  }

  Future<void> _handleCloseSession() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'are you sure you want to close the session? Unsaved changes will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancell',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () async {
              // 1. Cierra el modal de diálogo
              Navigator.pop(dialogContext);

              // 2. Detener audio y liberar fuentes nativas C++ en SoLoud
              await ref.read(sessionMetadataProvider.notifier).resetSession();

              // 3. Regresar al Home de forma segura comprobando la validez del context
              if (context.mounted) {
                // Regresa hasta la primera pantalla del stack (HomeScreen)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text(
              'Close Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLoadSession(Map<String, dynamic> sessionMap) async {
    // 1. Mostrar retroalimentación inicial al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.thirdColor,
        content: Text('Loading session "${sessionMap['title']}"...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // 2. Navegar PRIMERO a la pantalla de la sesión.
    // Esto permite que el árbol de widgets (incluyendo WaveTrack y el loader)
    // se monte correctamente en memoria.
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NewSesionScreen(
          sessionTitle: sessionMap['title'] ?? 'NEW SESSION',
          keyNote: sessionMap['keyNote'] ?? 'C / DO',
          bpm: (sessionMap['bpm'] as num?)?.toInt() ?? 120,
          sessionId: sessionMap['id'] ?? '',
        ),
      ),
    );

    // 3. Procesar e inicializar las fuentes de audio en SoLoud
    // mientras NewSesionScreen ya está activa y mostrando su loader.
    // await ref
    //     .read(soLoudSessionProvider.notifier)
    //     .loadSessionFromMap(sessionMap);
    // 3. Procesar e inicializar las fuentes de audio en SoLoud
    await ref
        .read(sessionMetadataProvider.notifier)
        .loadSessionFromMap(sessionMap);
  }

  Future<void> _handleSavedSessions() async {
    // 1. Obtener las sesiones guardadas desde Hive
    final sessions = HiveService.getAllSessions().cast<Map<String, dynamic>>();

    if (!mounted) return;

    // 2. Desplegar la modal bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador visual superior (drag handle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Encabezado
                  Row(
                    children: const [
                      Icon(
                        Icons.folder_special,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'LOAD SAVED SESSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de sesiones
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Text(
                              'No saved sessions found.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: sessions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final sessionMap = sessions[index];
                              final tracks =
                                  (sessionMap['tracks'] as List?) ?? [];

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.thirdColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sessionMap['title'] ?? 'No title',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tono: ${sessionMap['keyNote'] ?? 'C'} | BPM: ${sessionMap['bpm'] ?? 120} | Tracks: ${tracks.length}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        // Cerrar la modal antes de cargar
                                        Navigator.pop(modalContext);
                                        // Cargar la sesión seleccionada
                                        _handleLoadSession(sessionMap);
                                      },
                                      child: const Text(
                                        'LOAD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método para guardar la sesión en Hive
  Future<void> _handleSaveSession() async {
    FocusScope.of(context).unfocus();

    final sessionTitle = widget.titleController.text.trim().isEmpty
        ? 'New Session'
        : widget.titleController.text.trim();

    final success = await ref
        .read(sessionMetadataProvider.notifier)
        .saveCurrentSession(
          sessionId: widget.sessionId,
          title: sessionTitle,
          keyNote: _currentKeyNote,
          bpm: _currentBpm,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppTheme.thirdColor : Colors.redAccent,
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? AppTheme.primaryColor : Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                success
                    ? 'Session "$sessionTitle" saved!'
                    : 'Error saving session',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showBpmDialog() {
    final bpmController = TextEditingController(text: '$_currentBpm');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.thirdColor,
        title: const Text('Set BPM', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: bpmController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: 'Ej. 120',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newBpm = int.tryParse(bpmController.text);
              if (newBpm != null && newBpm > 0) {
                setState(() => _currentBpm = newBpm);
                _notifyChanges();
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.secondaryColor,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.graphic_eq, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'MULTITRACK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: widget.titleController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'SESSION NAME',
                  hintStyle: TextStyle(color: Colors.white30),
                ),
                onChanged: (_) => _notifyChanges(),
              ),
            ),
          ),
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.thirdColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                PopupMenuButton<String>(
                  color: AppTheme.thirdColor,
                  initialValue: _currentKeyNote,
                  onSelected: (String newKey) {
                    setState(() => _currentKeyNote = newKey);
                    _notifyChanges();
                  },
                  itemBuilder: (context) => AppConfig.keyNotes.map((key) {
                    return PopupMenuItem(
                      value: key,
                      child: Text(
                        key,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TONE (EN/ES)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentKeyNote,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                InkWell(
                  onTap: _showBpmDialog,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BPM',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_currentBpm',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _SessionPopupMenu(
            onSavePressed: _handleSaveSession,
            onSavedPressed: _handleSavedSessions,
            onClosePressed: _handleCloseSession,
          ),
        ),
      ],
    );
  }
}

class _SessionPopupMenu extends StatelessWidget {
  final VoidCallback onSavePressed;
  final VoidCallback onSavedPressed;
  final VoidCallback onClosePressed;

  const _SessionPopupMenu({
    required this.onSavePressed,
    required this.onSavedPressed,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppTheme.thirdColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'save') {
          onSavePressed();
        } else if (value == 'close') {
          onClosePressed();
        } else if (value == 'saved') {
          // Aquí puedes implementar la lógica para mostrar las sesiones guardadas
          onSavedPressed();
        } else if (value == 'export') {
          // Aquí puedes implementar la lógica para exportar la sesión
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export session (not implemented)')),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.save, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 10),
              Text('Save Sesion', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'saved',
          child: Row(
            children: [
              Icon(Icons.replay_outlined, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Text('Saved Sesion', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text('Export Sesion', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'close',
          child: Row(
            children: [
              Icon(Icons.close, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Close Sesion', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.save_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Sesion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
