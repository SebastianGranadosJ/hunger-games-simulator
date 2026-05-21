import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/tribute.dart';

class TributeCard extends StatelessWidget {
  final TributeModel tribute;
  final String? imageUrl;
  final bool compact;

  const TributeCard({
    super.key,
    required this.tribute,
    this.imageUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.goldBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _TributePortrait(
            name: tribute.name,
            imageUrl: imageUrl,
            size: compact ? 36.0 : 44.0,
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tribute.name,
                        style: TextStyle(
                          color: AppColors.offWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _DistrictBadge(district: tribute.district),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      tribute.gender == 'M' ? Icons.male : Icons.female,
                      size: 12,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      tribute.gender == 'M' ? 'Male' : 'Female',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.sports_kabaddi,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(
                        '${tribute.kills} kill${tribute.kills != 1 ? "s" : ""}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!compact && tribute.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tribute.items.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TributePortrait extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const _TributePortrait({
    required this.name,
    this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(size, name),
          ),
        ),
      );
    }
    return _placeholder(size, name);
  }

  Widget _placeholder(double size, String name) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfaceVariant,
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

class _DistrictBadge extends StatelessWidget {
  final int district;
  const _DistrictBadge({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.goldDark.withValues(alpha: 0.25),
        border: Border.all(color: AppColors.goldDark),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'D$district',
        style: GoogleFonts.cinzel(
          color: AppColors.gold,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Small inline portrait used in event tiles
class InlinePortrait extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const InlinePortrait({super.key, required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          ),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.surfaceVariant,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
