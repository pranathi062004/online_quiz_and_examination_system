import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exam_record_model.dart';
import '../../state/exam_provider.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  String _selectedCategoryFilter = 'global';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).fetchGlobalLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exam = Provider.of<ExamProvider>(context);

    // Get list of unique category filters
    final categories = ['global'];
    final seen = <String>{};
    for (var rec in exam.globalLeaderboard) {
      if (seen.add(rec.categoryId)) {
        categories.add(rec.categoryId);
      }
    }

    // Filtered list
    final List<ExamRecordModel> rankings = _selectedCategoryFilter == 'global'
        ? exam.globalLeaderboard
        : exam.globalLeaderboard.where((r) => r.categoryId == _selectedCategoryFilter).toList();

    // Split top 3 and others
    final top3 = rankings.take(3).toList();
    final others = rankings.skip(3).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: exam.isLoadingRecords
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await exam.fetchGlobalLeaderboard();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Horizontal Filter Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((catId) {
                          final isSelected = _selectedCategoryFilter == catId;
                          final label = catId == 'global'
                              ? 'Global Rankings'
                              : exam.globalLeaderboard.firstWhere((r) => r.categoryId == catId).categoryName.split('(').first.trim();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.darkBorder,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategoryFilter = catId);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 36),

                    if (rankings.isEmpty) ...[
                      const SizedBox(height: 80),
                      const Center(
                        child: Text(
                          'No records logged yet. Be the first to top the boards!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ] else ...[
                      // Podium for Top 3
                      _buildPodium(top3),
                      const SizedBox(height: 32),

                      // Rest of lists
                      if (others.isNotEmpty) ...[
                        const Text(
                          'Rankings',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: others.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final rec = others[index];
                            final rank = index + 4; // since skipped 3
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Row(
                                children: [
                                  // Rank badge
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.darkSurface,
                                      border: Border.all(color: AppColors.darkBorder),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // User avatar placeholder
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      rec.userName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name and category details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.userName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          'Category: ${rec.categoryName.split('(').first.trim()} • Speed: ${(rec.timeTakenSeconds / 60).floor()}m ${rec.timeTakenSeconds % 60}s',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Score
                                  Text(
                                    '${rec.score}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPodium(List<ExamRecordModel> top3) {
    // top3 can have 1, 2, or 3 elements
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2nd Place (Left)
        Expanded(
          child: _buildPodiumCol(
            rec: second,
            rank: 2,
            podiumHeight: 95,
            badgeColor: const Color(0xFF94A3B8), // Silver grey
            medalText: '🥈',
          ),
        ),
        const SizedBox(width: 8),

        // 1st Place (Center)
        Expanded(
          child: _buildPodiumCol(
            rec: first,
            rank: 1,
            podiumHeight: 130,
            badgeColor: const Color(0xFFF59E0B), // Gold amber
            medalText: '👑',
            glow: true,
          ),
        ),
        const SizedBox(width: 8),

        // 3rd Place (Right)
        Expanded(
          child: _buildPodiumCol(
            rec: third,
            rank: 3,
            podiumHeight: 80,
            badgeColor: const Color(0xFFB45309), // Bronze brown
            medalText: '🥉',
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumCol({
    required ExamRecordModel? rec,
    required int rank,
    required double podiumHeight,
    required Color badgeColor,
    required String medalText,
    bool glow = false,
  }) {
    if (rec == null) {
      return Column(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.darkSurface,
            child: Icon(Icons.person_outline, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Container(
            height: podiumHeight,
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
            ),
            child: const Center(
              child: Text(
                '-',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        ],
      );
    }

    final isPassed = rec.score >= 60;

    return Column(
      children: [
        // Medal, avatar and details
        Text(medalText, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: rank == 1 ? 26 : 22,
          backgroundColor: badgeColor.withValues(alpha: 0.15),
          child: CircleAvatar(
            radius: rank == 1 ? 23 : 19,
            backgroundColor: AppColors.darkSurface,
            child: Text(
              rec.userName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: rank == 1 ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          rec.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 14 : 12,
            color: rank == 1 ? badgeColor : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${rec.score}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 16 : 14,
            color: isPassed ? AppColors.success : AppColors.danger,
          ),
        ),
        const SizedBox(height: 10),

        // Podium Pillar
        Container(
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkSurface,
                AppColors.darkSurface.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: glow ? badgeColor.withValues(alpha: 0.7) : AppColors.darkBorder,
              width: glow ? 1.5 : 1,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, -4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${(rec.timeTakenSeconds / 60).floor()}m ${rec.timeTakenSeconds % 60}s',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
