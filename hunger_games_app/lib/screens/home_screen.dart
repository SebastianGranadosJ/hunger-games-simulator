import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial glow behind the title
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF1A1300),
                  AppColors.background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Top ornament
                _GoldDivider(),
                const SizedBox(height: 32),

                // Title
                Text(
                  'THE HUNGER GAMES',
                  style: GoogleFonts.cinzel(
                    fontSize: 26,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'SIMULATOR',
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    color: AppColors.offWhite,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Bottom ornament
                _GoldDivider(),
                const Spacer(flex: 3),

                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'MAY THE ODDS BE EVER IN YOUR FAVOR',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      color: AppColors.muted,
                      letterSpacing: 2.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        _capitalRouteTransition(const SetupScreen()),
                      ),
                      child: const Text('BEGIN THE GAMES'),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom Capitol seal text
                Text(
                  '— PANEM ET CIRCENSES —',
                  style: GoogleFonts.cinzel(
                    fontSize: 9,
                    color: const Color(0xFF333328),
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 60, height: 1, color: AppColors.goldDark),
        const SizedBox(width: 8),
        Container(width: 6, height: 6, color: AppColors.gold),
        const SizedBox(width: 8),
        Container(width: 60, height: 1, color: AppColors.goldDark),
      ],
    );
  }
}

PageRouteBuilder _capitalRouteTransition(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}
