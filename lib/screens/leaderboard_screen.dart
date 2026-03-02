import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../services/firebase_service.dart';
import '../main.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.scaffoldDark : AppTheme.bgLight,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    'Global Leaderboard',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      color: AppTheme.yellowDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService().getTopLeaderboard(30), // Ambil Top 30
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.yellowDark),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(isDark);
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildLeaderboardItem(
                          context, index, data, isDark);
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

// ... (will use multi_replace for the import)
  Widget _buildLeaderboardItem(
      BuildContext context, int index, Map<String, dynamic> data, bool isDark) {
    // Warna khusus untuk Top 3
    Color getMedalColor() {
      if (index == 0) return const Color(0xFFFFD700); // Gold
      if (index == 1) return const Color(0xFFC0C0C0); // Silver
      if (index == 2) return const Color(0xFFCD7F32); // Bronze
      return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    }

    final rank = index + 1;
    final name = data['deviceName'] ?? 'Unknown Player';
    final points = data['points'] ?? 0;

    final medalColor = getMedalColor();

    Widget content = Row(
      children: [
        // Rank Circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: index < 3
                ? Text(['🥇', '🥈', '🥉'][index],
                    style: const TextStyle(fontSize: 20))
                : Text('#$rank',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ),
        const SizedBox(width: 14),

        // Player Name
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: index < 3 ? FontWeight.w800 : FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Points
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.shade700.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$points',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueAccent.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: medalColor.withValues(alpha: index < 3 ? 0.5 : 0.2),
            width: index < 3 ? 2 : 1),
        boxShadow: index < 3 && !isDark
            ? [
                BoxShadow(
                  color: medalColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Background Shimmer hanya untuk Top 3
          if (index < 3)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Shimmer.fromColors(
                  baseColor: isDark ? AppTheme.cardDark : Colors.white,
                  highlightColor:
                      medalColor.withValues(alpha: isDark ? 0.2 : 0.3),
                  period: const Duration(milliseconds: 2500),
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Konten Utama Layer Atas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isDark ? 0.3 : 0.7,
              child: const Text('🏆', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Papan Peringkat Kosong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Jadilah pemain pertama yang menganalisa pisang dan dapatkan poin!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: isDark ? Colors.white54 : AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.redDark),
          const SizedBox(height: 16),
          const Text(
            'Koneksi Cloud Terputus',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Gagal mengambil data klasemen dari Firebase.',
            style:
                TextStyle(color: isDark ? Colors.white54 : AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
