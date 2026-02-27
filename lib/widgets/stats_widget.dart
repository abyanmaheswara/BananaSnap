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
    _load();
  }

  Future<void> _load() async {
    final s = await widget.db.getStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${_stats['total']}',
          label: 'TOTAL',
          emoji: '🍌',
          color: AppTheme.yellowDark,
          bg: const Color(0xFFFFF3CC),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${_stats['fresh']}',
          label: 'LAYAK',
          emoji: '✅',
          color: AppTheme.greenDark,
          bg: const Color(0xFFE8F8EA),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${_stats['rotten']}',
          label: 'TDK LAYAK',
          emoji: '❌',
          color: AppTheme.redDark,
          bg: const Color(0xFFFFEEEE),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label, emoji;
  final Color color, bg;
  const _StatCard({
    required this.value, required this.label,
    required this.emoji, required this.color, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }
}
