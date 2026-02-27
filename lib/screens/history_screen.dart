import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/history_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryDatabase _db = HistoryDatabase();
  List<DetectionHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _db.getAllHistory();
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int id) async {
    await _db.deleteDetection(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text('Semua riwayat akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.clearAll();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _history.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _HistoryItem(
                    item: _history[i],
                    onDelete: () => _deleteItem(_history[i].id!),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Belum ada riwayat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Mulai deteksi pisang untuk melihat riwayat',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final DetectionHistory item;
  final VoidCallback onDelete;

  const _HistoryItem({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = item.isFresh ? AppTheme.fresh : AppTheme.rotten;
    final dt = item.timestamp;
    final timeStr =
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key('history_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Thumbnail gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: File(item.imagePath).existsSync()
                  ? Image.file(File(item.imagePath),
                      width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64, height: 64,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported_rounded,
                          color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.isFresh ? '✅ LAYAK' : '❌ TIDAK LAYAK',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kepercayaan: ${(item.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            // Swipe hint
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
