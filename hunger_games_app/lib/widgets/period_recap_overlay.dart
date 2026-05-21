import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/tribute.dart';

class PeriodRecapOverlay extends StatelessWidget {
  final List<TributeModel> fallenTributes;
  final Map<String, String> tributeImages;
  final String phaseLabel;

  const PeriodRecapOverlay({
    super.key,
    required this.fallenTributes,
    required this.tributeImages,
    required this.phaseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppColors.background.withValues(alpha: 0.97),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(color: AppColors.border, height: 1),
              Expanded(child: _buildList()),
              _buildContinueButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Column(
        children: [
          const Text(
            '☠',
            style: TextStyle(fontSize: 36, color: AppColors.deathRed),
          ),
          const SizedBox(height: 16),
          Text(
            phaseLabel,
            style: GoogleFonts.cinzel(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'FALLEN TRIBUTES',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${fallenTributes.length} cannon${fallenTributes.length != 1 ? "s" : ""} fired',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: fallenTributes.length,
      itemBuilder: (_, i) => _FallenTributeCard(
        tribute: fallenTributes[i],
        imageUrl: tributeImages[fallenTributes[i].name],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CONTINUE'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual death card
// ─────────────────────────────────────────────

class _FallenTributeCard extends StatelessWidget {
  final TributeModel tribute;
  final String? imageUrl;

  const _FallenTributeCard({required this.tribute, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deathRedDark.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.deathRed.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _DeathPortrait(name: tribute.name, imageUrl: imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shots ring out on the horizon...',
                  style: GoogleFonts.cinzel(
                    color: AppColors.muted,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    children: [
                      TextSpan(
                        text: tribute.name,
                        style: const TextStyle(
                          color: AppColors.offWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' from District ${tribute.district} has perished.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Greyscale-bordered portrait
// ─────────────────────────────────────────────

class _DeathPortrait extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _DeathPortrait({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 56.0;
    final Widget inner = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => _initials(size),
          )
        : _initials(size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.deathRed.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _initials(double size) {
    return CircleAvatar(
      backgroundColor: AppColors.surfaceVariant,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.deathRed,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
