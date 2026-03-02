import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/history_database.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});
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
    _load();
  }

  Future<void> _load() async {
    final data = await _db.getAllHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    await _db.deleteDetection(id);
    _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Semua?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Semua riwayat akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.clearAll();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return SafeArea(bottom: false, child: _buildBody());
    }
    return Scaffold(
      backgroundColor: AppTheme.bgCream,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.yellowDark));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/empty_history.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat deteksi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Ayo mulai jepret pisang pertamamu!',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text('📜 Riwayat Deteksi',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (_history.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: const Text('Hapus Semua',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _HistoryItem(
              item: _history[i],
              onDelete: () => _delete(_history[i].id!),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final DetectionHistory item;
  final VoidCallback onDelete;
  const _HistoryItem({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = item.isFresh ? AppTheme.greenDark : AppTheme.redDark;
    final bg = item.isFresh ? const Color(0xFFE8F8EA) : const Color(0xFFFFEEEE);
    final dt = item.timestamp;
    final time =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key('h_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: bg,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb
                    ? Image.network(item.imagePath, fit: BoxFit.cover)
                    : (File(item.imagePath).existsSync()
                        ? Image.file(File(item.imagePath), fit: BoxFit.cover)
                        : Center(
                            child: Text(item.isFresh ? '✅' : '❌',
                                style: const TextStyle(fontSize: 28)))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isFresh ? '✅ LAYAK' : '❌ TIDAK LAYAK',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                      'Kepercayaan: ${(item.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(time,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGrey.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
