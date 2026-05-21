import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/event.dart';
import '../models/tribute.dart';
import '../services/api_service.dart';
import '../widgets/statistics_panel.dart';
import 'home_screen.dart';

class WinnerScreen extends StatefulWidget {
  final TributeModel winner;
  final Map<String, String> tributeImages;
  final List<EventModel> events;
  final Map<String, TributeModel> allTributesById;

  const WinnerScreen({
    super.key,
    required this.winner,
    required this.tributeImages,
    required this.events,
    required this.allTributesById,
  });

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openStatistics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatisticsPanel(
        events: widget.events,
        allTributesById: widget.allTributesById,
        tributeImages: widget.tributeImages,
      ),
    );
  }

  Future<void> _playAgain() async {
    setState(() => _isResetting = true);
    try {
      await ApiService.instance.resetSimulation();
    } catch (_) {
      // Best-effort reset — proceed regardless
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winner;
    final imageUrl = widget.tributeImages[winner.name];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.3,
                colors: [
                  Color(0xFF1A1000),
                  AppColors.background,
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Top ornament
                      _GoldRule(),
                      const SizedBox(height: 28),

                      // "AND THE WINNER IS..."
                      Text(
                        'AND THE WINNER IS',
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          color: AppColors.muted,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '—',
                        style: TextStyle(
                          color: AppColors.goldDark,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Portrait
                      _WinnerPortrait(
                        name: winner.name,
                        imageUrl: imageUrl,
                      ),

                      const SizedBox(height: 28),

                      // Winner name
                      Text(
                        winner.name.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontSize: 24,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.0,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      // District badge + gender
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DistrictBadge(district: winner.district),
                          const SizedBox(width: 10),
                          Text(
                            winner.gender == 'M' ? 'Male' : 'Female',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Kill count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: winner.kills > 0
                              ? AppColors.deathRedDark.withValues(alpha: 0.25)
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: winner.kills > 0
                                ? AppColors.deathRed.withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              winner.kills > 0 ? '☠ ' : '',
                              style: const TextStyle(
                                  color: AppColors.deathRed, fontSize: 16),
                            ),
                            Text(
                              winner.kills == 0
                                  ? 'Survived without a kill'
                                  : '${winner.kills} kill${winner.kills != 1 ? "s" : ""}',
                              style: TextStyle(
                                color: winner.kills > 0
                                    ? AppColors.deathRed
                                    : AppColors.muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Items (if any)
                      if (winner.items.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: winner.items.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                border:
                                    Border.all(color: AppColors.goldBorder),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _GoldRule(),

                      const Spacer(flex: 3),

                      // Play Again button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isResetting ? null : _playAgain,
                          child: _isResetting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : const Text('PLAY AGAIN'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Statistics button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              widget.events.isEmpty ? null : _openStatistics,
                          icon: const Icon(Icons.bar_chart_rounded, size: 16),
                          label: const Text('VIEW STATISTICS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.goldBorder),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'THE CAPITOL THANKS YOU FOR WATCHING',
                        style: GoogleFonts.cinzel(
                          fontSize: 8,
                          color: const Color(0xFF2A2A22),
                          letterSpacing: 2.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _WinnerPortrait extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _WinnerPortrait({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 120;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2.5),
        color: AppColors.surfaceVariant,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(name, size),
              )
            : _initials(name, size),
      ),
    );
  }

  Widget _initials(String name, double size) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GoldRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 80, height: 1, color: AppColors.goldDark),
        const SizedBox(width: 8),
        Container(width: 6, height: 6, color: AppColors.gold),
        const SizedBox(width: 8),
        Container(width: 80, height: 1, color: AppColors.goldDark),
      ],
    );
  }
}

class _DistrictBadge extends StatelessWidget {
  final int district;
  const _DistrictBadge({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldDark.withValues(alpha: 0.25),
        border: Border.all(color: AppColors.goldDark),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'DISTRICT $district',
        style: GoogleFonts.cinzel(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
