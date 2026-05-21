import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/event.dart';
import '../models/tribute.dart';
import 'tribute_card.dart';

class EventTile extends StatelessWidget {
  final EventModel event;
  final Map<String, TributeModel> allTributesById;
  final Map<String, String> tributeImages;

  const EventTile({
    super.key,
    required this.event,
    required this.allTributesById,
    required this.tributeImages,
  });

  @override
  Widget build(BuildContext context) {
    final isDeath = event.isDeath;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDeath
            ? AppColors.deathRedDark.withValues(alpha: 0.18)
            : AppColors.surface,
        border: Border.all(
          color: isDeath ? AppColors.deathRed.withValues(alpha: 0.5) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDeath
                  ? AppColors.deathRedDark.withValues(alpha: 0.4)
                  : AppColors.surfaceVariant,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(2)),
            ),
            child: Row(
              children: [
                Text(
                  event.periodLabel,
                  style: GoogleFonts.cinzel(
                    fontSize: 9,
                    color: isDeath ? AppColors.deathRed : AppColors.muted,
                    letterSpacing: 2.0,
                  ),
                ),
                if (isDeath) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '☠',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.deathRed,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Narrative text
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              event.narrative,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDeath ? AppColors.deathRed : AppColors.offWhite,
                height: 1.65,
                fontFamily: 'serif',
                fontWeight: isDeath ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),

          // Death row: show who died
          if (isDeath && event.killedTributeId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: event.killedTributeId!.map((id) {
                  final tribute = allTributesById[id];
                  final name =
                      tribute?.name ?? 'Tribute #$id';
                  final imageUrl = tributeImages[name];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        InlinePortrait(name: name, imageUrl: imageUrl),
                        const SizedBox(width: 8),
                        const Text(
                          '☠',
                          style: TextStyle(
                            color: AppColors.deathRed,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.deathRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'has fallen',
                          style: TextStyle(
                            color: AppColors.deathRed,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
