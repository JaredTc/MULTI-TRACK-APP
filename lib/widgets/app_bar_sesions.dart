import 'package:flutter/material.dart';
import 'package:multitracks/config/app_theme.dart';

class AppBarNav extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController titleController;
  final String initialKeyNote;
  final int initialBpm;
  final Function(String title, String keyNote, int bpm)? onChanged;

  const AppBarNav({
    Key? key,
    required this.titleController,
    this.initialKeyNote = 'C / DO',
    this.initialBpm = 120,
    this.onChanged,
  }) : super(key: key);

  @override
  State<AppBarNav> createState() => _AppBarNavState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarNavState extends State<AppBarNav> {
  late String _currentKeyNote;
  late int _currentBpm;

  final List<String> _keyNotes = [
    'C / DO',
    'C# / DO#',
    'D / RE',
    'Eb / MIb',
    'E / MI',
    'F / FA',
    'F# / FA#',
    'G / SOL',
    'Ab / LAb',
    'A / LA',
    'Bb / SIb',
    'B / SI',
  ];

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

  void _showBpmDialog() {
    final bpmController = TextEditingController(text: '$_currentBpm');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.thirdColor,
        title: const Text('Ajustar BPM', style: TextStyle(color: Colors.white)),
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
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
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
            child: const Text('GUARDAR'),
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
                  hintText: 'NOMBRE DE SESIÓN',
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
                  itemBuilder: (context) => _keyNotes.map((key) {
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
                        'TONO (EN/ES)',
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
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: _SessionPopupMenu(),
        ),
      ],
    );
  }
}

class _SessionPopupMenu extends StatelessWidget {
  const _SessionPopupMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppTheme.thirdColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 48),
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
