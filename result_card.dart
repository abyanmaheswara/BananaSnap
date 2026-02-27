import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../main.dart';
import '../services/banana_classifier.dart';

class ResultCard extends StatelessWidget {
  final PredictionResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.isFresh ? AppTheme.fresh : AppTheme.rotten;
    final bgColor = result.isFresh
        ? AppTheme.fresh.withOpacity(0.08)
        : AppTheme.rotten.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(result.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.statusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      result.isFresh
                          ? 'Pisang aman untuk dikonsumsi'
                          : 'Pisang sudah tidak segar',
                      style: TextStyle(
                        fontSize: 13,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Confidence bar
          Row(
            children: [
              const Text(
                'Tingkat kepercayaan:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                result.confidencePercent,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: result.confidence,
            backgroundColor: Colors.grey.shade100,
            progressColor: color,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 800,
          ),

          const SizedBox(height: 16),

          // Waktu deteksi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Text(
                _formatTime(result.timestamp),
                style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s - ${dt.day}/${dt.month}/${dt.year}';
  }
}
