// Kartu stand di beranda pembeli.

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_map.dart';
import '../models/stand_model.dart';
import 'common.dart';

class StandCard extends StatelessWidget {
  const StandCard({super.key, required this.stand, required this.onSelect});

  final StandModel stand;
  final ValueChanged<StandModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: stand.isOpen ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.surface),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => onSelect(stand),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconTile(
                  icon: iconFor(stand.icon),
                  size: 88,
                  iconSize: 30,
                  radius: 10,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stand.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: hapText(16,
                                  weight: FontWeight.w600, height: 1.25),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stand.isOpen ? 'Buka' : 'Tutup',
                            style: hapText(
                              12,
                              weight: FontWeight.w600,
                              color: stand.isOpen
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stand.foodTypes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hapText(14,
                            color: const Color(0xB3302B27), height: 1.25),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            stand.openHours,
                            style: hapText(12,
                                weight: FontWeight.w500,
                                color: AppColors.textMuted,
                                tabular: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
