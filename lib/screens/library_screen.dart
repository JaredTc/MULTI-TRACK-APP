import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/providers/session_meta_provider.dart';
import 'package:multitracks/screens/new_sesion_screen.dart';
import 'package:multitracks/services/hive_service.dart';
import 'package:multitracks/widgets/app_bar_nav.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _navTitleController = TextEditingController(
    text: 'LIBRARY',
  );

  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  @override
  void dispose() {
    _navTitleController.dispose();
    super.dispose();
  }

  void _fetchSessions() {
    // Lee las sesiones almacenadas directamente en Hive
    setState(() {
      _sessionsFuture = Future.value(
        HiveService.getAllSessions().cast<Map<String, dynamic>>(),
      );
    });
  }

  Future<void> _handleLoadSession(Map<String, dynamic> sessionMap) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.thirdColor,
        content: Text('Loading session "${sessionMap['title']}"...'),
        duration: const Duration(seconds: 1),
      ),
    );

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

    // mientras NewSesionScreen ya está activa y mostrando su loader.
    // await ref
    //     .read(soLoudSessionProvider.notifier)
    //     .loadSessionFromMap(sessionMap);
    // 3. Procesar e inicializar las fuentes de audio en SoLoud
    await ref
        .read(sessionMetadataProvider.notifier)
        .loadSessionFromMap(sessionMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBarNav(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.folder_special,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'MY SAVED SESSIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  final sessions = snapshot.data ?? [];

                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved sessions found.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sessionMap = sessions[index];
                      final tracks = (sessionMap['tracks'] as List?) ?? [];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.thirdColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.church,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sessionMap['title'] ?? 'No title',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Tono: ${sessionMap['keyNote'] ?? 'C'}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'BPM: ${sessionMap['bpm'] ?? 120}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Tracks: ${tracks.length}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete Session',
                              onPressed: () async {
                                await HiveService.deleteSession(
                                  sessionMap['id'],
                                );
                                _fetchSessions();
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _handleLoadSession(sessionMap),
                              child: const Text(
                                'LOAD',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
