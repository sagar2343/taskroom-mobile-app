import 'package:flutter/material.dart';
import '../../model/analytics_model.dart';
import '../../../../../config/theme/app_pallete.dart';

class ScoreCard extends StatelessWidget {
  final int rank;
  final EmployeeScore score;

  const ScoreCard({super.key, required this.rank, required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final gradeColor = switch (score.grade) {
      'A' => Pallete.successColor,
      'B' => Pallete.infoColor,
      'C' => Pallete.primaryColor,
      _ => Pallete.errorColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: textTheme.labelSmall!.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              image: score.profilePicture != null
                  ? DecorationImage(
                image: NetworkImage(score.profilePicture!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: score.profilePicture == null
                ? Center(
              child: Text(
                score.fullName.isNotEmpty
                    ? score.fullName[0].toUpperCase()
                    : '?',
                style: textTheme.bodyMedium!.copyWith(
                  color: Pallete.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 14),

          // Name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        score.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (score.isOnline) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Pallete.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${score.stats.daysPresent}d • ${score.stats.totalHours}h • '
                      '${score.stats.tasksCompleted}/${score.stats.tasksAssigned} tasks',
                  style: textTheme.labelSmall!.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.score / 100,
                    minHeight: 5,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Score + grade
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: textTheme.headlineSmall!.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  score.grade,
                  style: textTheme.labelSmall!.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}