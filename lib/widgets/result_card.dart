import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../main.dart';
import '../services/banana_classifier.dart';

class ResultCard extends StatelessWidget {
  final PredictionResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color  = result.isFresh ? AppTheme.greenDark : AppTheme.redDark;
    final bgColor = result.isFresh ? const Color(0xFFE8F8EA) : const Color(0xFFFFEEEE);
    final emoji  = result.isFresh ? '✅' : '❌';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isFresh ? 'LAYAK DIKONSUMSI' : 'TIDAK LAYAK',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900, color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        result.isFresh ? 'Pisang segar terdeteksi 🍌' : 'Pisang sudah tidak segar',
                        style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confidence
          Row(
            children: [
              const Text('Tingkat kepercayaan AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textGrey)),
              const Spacer(),
              Text(result.confidencePercent,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: result.confidence.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade100,
            linearGradient: LinearGradient(
              colors: result.isFresh
                  ? [AppTheme.green, AppTheme.greenDark]
                  : [AppTheme.red, AppTheme.redDark],
            ),
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 900,
          ),

          const SizedBox(height: 14),

          // Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textGrey),
              const SizedBox(width: 5),
              Text(_formatTime(result.timestamp),
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${dt.day}/${dt.month}/${dt.year}';
  }
}
