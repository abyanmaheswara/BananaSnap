import 'package:flutter/material.dart';
import '../main.dart';
import '../services/history_database.dart';

class StatsWidget extends StatefulWidget {
  final HistoryDatabase db;

  const StatsWidget({super.key, required this.db});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  Map<String, int> _stats = {'total': 0, 'fresh': 0, 'rotten': 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.db.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Deteksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatBox(value: '${_stats['total']}', label: 'Total', color: AppTheme.primary),
            const SizedBox(width: 12),
            _StatBox(value: '${_stats['fresh']}',  label: 'Layak',       color: AppTheme.fresh),
            const SizedBox(width: 12),
            _StatBox(value: '${_stats['rotten']}', label: 'Tidak Layak', color: AppTheme.rotten),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;

  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }
}
