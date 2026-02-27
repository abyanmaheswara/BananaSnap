import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
import '../services/banana_classifier.dart';
import '../services/history_database.dart';
import '../widgets/result_card.dart';
import '../widgets/stats_widget.dart';
import 'history_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
      final appDir = await getApplicationDocumentsDirectory();
      final saved = p.join(
          appDir.path, 'banana_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageFile.copy(saved);
      await _db.insertDetection(result: result, imagePath: saved);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _currentTab == 0
                ? _buildHomeTab()
                : const HistoryScreen(embedded: true),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.yellow, AppTheme.yellowDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        // Menghapus drop shadow header per desain rujukan web HTML
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20,
              40), // inner padding di bottom ditambah jadi 40 (ruang untuk stats overlapping)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                        child: Text('🍌', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BanaSnap',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Model status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isModelReady
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _isModelReady ? Colors.white : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isModelReady ? 'AI Ready' : 'Loading...',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Cek Pisangmu! 🍌',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Foto pisang → deteksi dalam 1 detik',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Home Tab ──
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats (ditarik ke atas agar nabrak ke header per HTML design)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Transform.translate(
              offset: const Offset(0, -24), // overlap -24px margin in HTML
              child: StatsWidget(
                key: ValueKey(_result?.timestamp.millisecondsSinceEpoch ?? 0),
                db: _db,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text('📸 Deteksi Sekarang',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    )),
                const SizedBox(height: 12),

                // Image area
                GestureDetector(
                  onTap: _showSourceSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    constraints: const BoxConstraints(minHeight: 180),
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
                          const Text('✅ Hasil Deteksi',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 12),
                          ResultCard(result: _result!),
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
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      color: AppTheme.yellowDark, strokeWidth: 3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Menganalisa gambar...',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Model AI sedang bekerja',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          ],
        ),
      );
    }

    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
        ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.yellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Tips Foto Terbaik',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 10),
          for (final tip in [
            ['📸', 'Pencahayaan cukup & terang'],
            ['🍌', 'Pisang terlihat jelas & penuh'],
            ['📏', 'Jarak 20–30 cm dari kamera'],
            ['🚫', 'Hindari bayangan pada buah'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(tip[0], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text(tip[1],
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom Nav ──
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                  emoji: '🏠',
                  label: 'Beranda',
                  active: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0)),
              _NavItem(
                  emoji: '📜',
                  label: 'Riwayat',
                  active: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1)),
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
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.shadow,
    required this.onTap,
    this.textColor = AppTheme.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textColor)),
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
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? AppTheme.yellow : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: AppTheme.yellow.withValues(alpha: 0.4),
                            blurRadius: 12)
                      ]
                    : [],
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: active ? AppTheme.yellowDark : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
