import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
import '../services/banana_classifier.dart';
import '../services/history_database.dart';
import '../widgets/result_card.dart';
import '../widgets/stats_widget.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BananaClassifier _classifier = BananaClassifier();
  final HistoryDatabase _db = HistoryDatabase();
  final ImagePicker _picker = ImagePicker();

  int _currentTab = 0;

  File? _selectedImage;
  PredictionResult? _result;
  bool _isLoading = false;
  bool _isModelReady = false;

  late AnimationController _resultCtrl;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  late AnimationController _scannerCtrl;

  final ScreenshotController _screenshotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut),
    );
    _resultSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic),
    );

    _scannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      if (mounted) setState(() => _isModelReady = true);
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isModelReady) {
      _snack('Model belum siap, harap tunggu...');
      return;
    }
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;
      HapticFeedback.lightImpact();
      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
        _isLoading = true;
      });
      await _runDetection(File(picked.path));
    } catch (e) {
      _snack('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runDetection(File imageFile) async {
    try {
      final result = await _classifier.predict(imageFile);
      String savedPath = imageFile.path;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        savedPath = p.join(
            appDir.path, 'banana_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageFile.copy(savedPath);
      }
      await _db.insertDetection(result: result, imagePath: savedPath);

      if (result.label != 'BUKAN_PISANG') {
        final prefs = await SharedPreferences.getInstance();
        int points = prefs.getInt('total_points') ?? 0;
        await prefs.setInt('total_points', points + 10);

        // --- SINKRONISASI CLOUD FIREBASE ---
        await FirebaseService().incrementPoints(10);

        _snack('Selamat! +10 Poin 🍌💰');
      }

      HapticFeedback.mediumImpact();

      setState(() {
        _result = result;
        _isLoading = false;
      });
      _resultCtrl.reset();
      _resultCtrl.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Gagal mendeteksi: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Sumber Gambar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _SheetBtn(
                  emoji: '📷',
                  label: 'Kamera',
                  color: AppTheme.yellow,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                )),
                const SizedBox(width: 14),
                Expanded(
                    child: _SheetBtn(
                  emoji: '🖼️',
                  label: 'Galeri',
                  color: AppTheme.green,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    _resultCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    if (_selectedImage == null || _result == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Menyimpan ke Galeri...'),
            duration: Duration(seconds: 1)),
      );

      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Render an off-screen widget for a clean shareable card
      final imageBytes = await _screenshotCtrl.captureFromWidget(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppTheme.scaffoldDark : AppTheme.bgCream,
                isDark ? AppTheme.cardDark : Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍌', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 8),
                  Text('BanaSnap AI',
                      style: GoogleFonts.fredoka(
                          fontSize: 24, color: AppTheme.yellowDark)),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: kIsWeb
                    ? Image.network(_selectedImage!.path,
                        height: 250, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(_selectedImage!,
                        height: 250, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Material(
                  color: Colors.transparent,
                  child: ResultCard(result: _result!)),
            ],
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(imageBytes),
          quality: 90,
          name: "BanaSnap_${DateTime.now().millisecondsSinceEpoch}");

      if (mounted) {
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Berhasil disimpan ke Galeri!'),
                backgroundColor: AppTheme.greenDark),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('❌ Gagal menyimpan gambar'),
                backgroundColor: AppTheme.redDark),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.redDark),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.scaffoldDark : AppTheme.bgCream,
      body: Column(
        children: [
          if (_currentTab == 0) _buildHeader(),
          Expanded(
            child: _currentTab == 0
                ? _buildHomeTab()
                : (_currentTab == 1
                    ? const LeaderboardScreen()
                    : const HistoryScreen(embedded: true)),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header Modern ──
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.yellow, AppTheme.yellowDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.yellow.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                      child: Text('🍌', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BanaSnap',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'AI Scanner',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.yellowDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Model status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _isModelReady
                          ? AppTheme.green.withValues(alpha: 0.15)
                          : AppTheme.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isModelReady
                            ? AppTheme.green.withValues(alpha: 0.3)
                            : AppTheme.yellow.withValues(alpha: 0.3),
                      )),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _isModelReady
                                ? AppTheme.green
                                : AppTheme.yellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isModelReady
                                        ? AppTheme.green
                                        : AppTheme.yellow)
                                    .withValues(alpha: 0.5),
                                blurRadius: 4,
                              )
                            ]),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isModelReady ? 'Ready' : 'Loading',
                        style: GoogleFonts.nunito(
                          color: _isModelReady
                              ? AppTheme.greenDark
                              : AppTheme.yellowDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Home Tab ──
  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StatsWidget(
              key: ValueKey(_result?.timestamp.millisecondsSinceEpoch ?? 0),
              db: _db,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Analisa Pisangmu',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textDark,
                          letterSpacing: -0.5,
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Image area
                GestureDetector(
                  onTap: _showSourceSheet,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _selectedImage != null
                              ? AppTheme.yellowDark
                              : AppTheme.yellow,
                          width: 2.5,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _buildImageArea(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                        child: _ActionBtn(
                      emoji: '📷',
                      label: 'Kamera',
                      color: AppTheme.yellow,
                      shadow: const Color(0x40F5A623),
                      onTap: () => _pickImage(ImageSource.camera),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _ActionBtn(
                      emoji: '🖼️',
                      label: 'Galeri',
                      color: AppTheme.green,
                      shadow: const Color(0x406BCB77),
                      textColor: Colors.white,
                      onTap: () => _pickImage(ImageSource.gallery),
                    )),
                  ],
                ),

                const SizedBox(height: 20),

                // Result
                if (_isLoading)
                  _buildLoadingCard()
                else if (_result != null)
                  FadeTransition(
                    opacity: _resultFade,
                    child: SlideTransition(
                      position: _resultSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ Hasil Analisa AI',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 14),
                          ResultCard(result: _result!),
                          const SizedBox(height: 20),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _saveToGallery,
                              icon:
                                  const Icon(Icons.download_rounded, size: 20),
                              label: const Text('Simpan ke Galeri'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                side: const BorderSide(
                                    color: AppTheme.yellowDark, width: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Tips
                _buildTipsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          kIsWeb
              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
              : Image.file(_selectedImage!, fit: BoxFit.cover),
          if (_isLoading)
            AnimatedBuilder(
              animation: _scannerCtrl,
              builder: (context, child) {
                // Moving from top (0) to bottom (1)
                return Positioned(
                  top: _scannerCtrl.value *
                      250, // Image area height is around 250-300
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.yellow,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.yellow.withValues(alpha: 0.8),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppTheme.green.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          else ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 13, color: AppTheme.textGrey),
                    SizedBox(width: 4),
                    Text('Tap untuk ganti',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]
        ],
      );
    }

    if (_isLoading) {
      // Fallback if somehow loading without an image
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
          child: CircularProgressIndicator(
              color: AppTheme.yellowDark, strokeWidth: 3),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Floating banana bg
        const Text('🍌',
            style: TextStyle(fontSize: 80, color: Color(0x10000000))),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.yellow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.yellow.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child:
              const Center(child: Text('📷', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 12),
        const Text('Tap untuk foto pisang',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 4),
        const Text('Kamera atau galeri',
            style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16)
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  color: AppTheme.yellowDark, strokeWidth: 3)),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menganalisa...',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('Model AI sedang bekerja',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark
                  ? Colors.white12
                  : AppTheme.yellow.withValues(alpha: 0.3),
              width: 1.5),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppTheme.yellow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.yellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text('Tips Foto Terbaik',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 16),
          for (final tip in [
            ['📸', 'Pencahayaan cukup & terang'],
            ['🍌', 'Pisang terlihat jelas & penuh'],
            ['📏', 'Jarak 20–30 cm dari kamera'],
            ['🚫', 'Hindari bayangan pada buah'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(tip[0], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 14),
                  Text(tip[1],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppTheme.textGrey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom Nav ──
  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                  emoji: '🏠',
                  label: 'Beranda',
                  active: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0)),
              _NavItem(
                  emoji: '🏆',
                  label: 'Leaderboard',
                  active: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1)),
              _NavItem(
                  emoji: '📜',
                  label: 'Riwayat',
                  active: _currentTab == 2,
                  onTap: () => setState(() => _currentTab = 2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ──

class _SheetBtn extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _SheetBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = AppTheme.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String emoji, label;
  final Color color, shadow;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.shadow,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20), // More rounded corners
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                  color: shadow.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor ?? AppTheme.textDark)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String emoji, label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.emoji,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: active ? 56 : 48,
              height: 44,
              decoration: BoxDecoration(
                color: active ? AppTheme.yellow : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    active && Theme.of(context).brightness == Brightness.light
                        ? [
                            BoxShadow(
                                color: AppTheme.yellow.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]
                        : [],
              ),
              child: Center(
                  child: Text(emoji,
                      style: TextStyle(
                        fontSize: active ? 24 : 20,
                      ))),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.yellow
                        : AppTheme.yellowDark)
                    : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
