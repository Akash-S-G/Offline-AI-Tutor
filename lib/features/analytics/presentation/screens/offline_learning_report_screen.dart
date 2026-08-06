import 'package:flutter/material.dart';

import '../../../../core/theme/idp_colors.dart';
import '../../../../core/theme/idp_typography.dart';
import '../../../../core/theme/idp_theme.dart';
import '../../domain/learning_profile_models.dart';
import '../../application/learning_insights_service.dart';

class OfflineLearningReportScreen extends StatefulWidget {
  const OfflineLearningReportScreen({super.key});

  @override
  State<OfflineLearningReportScreen> createState() => _OfflineLearningReportScreenState();
}

class _OfflineLearningReportScreenState extends State<OfflineLearningReportScreen> {
  LearningProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final insights = await LearningInsightsService.create();
    final profile = await insights.generateProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Failed to load report')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent scaffold
      appBar: _buildTopAppBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: IDPSpacing.containerMargin, vertical: IDPSpacing.xl),
        children: [
          _buildHeroProfile(),
          const SizedBox(height: IDPSpacing.xxl),
          _buildAnalyticsGrid(),
          const SizedBox(height: IDPSpacing.xxl),
          _buildUnlockedAchievements(),
          const SizedBox(height: IDPSpacing.xxl),
          _buildAccountActions(),
          const SizedBox(height: IDPSpacing.xxl),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: IDPColors.surface.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: IDPColors.primary.withValues(alpha: 0.2),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.white.withValues(alpha: 0.1), BlendMode.dstATop),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: IDPColors.primary),
          const SizedBox(width: IDPSpacing.md),
          Text("OfflineTutor", style: IDPTypography.headlineLgMobile.copyWith(color: IDPColors.primary, fontSize: 20)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: IDPSpacing.containerMargin),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: IDPColors.primaryContainer, width: 2),
            color: IDPColors.surfaceVariant,
            image: const DecorationImage(
              image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuBdaEHDff6Ty4fV_8zWJV5jZ5EWcDnIpY-q1zfjIQvSs5EfFBHnrIL9xmcK69L5OBj3acCUZrl42jqfkzgXZyrr3b5ayCG4kF-PPb4kL3stP0pSN6rZ5eUOxVCucqJNlIY2rzNJnomcg3TsQcxBr3bF6E0XzH4sE5xTSBkXZbW--MrCFq4Rz45iH9_8_Ot5iy5aGefvac2djF4SGCKV8LJ9bHPDGg5DnZRQrTVTb0HTF004HqmFE1oAfnB1bauqDtc95kTb-unFLWCL"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroProfile() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        final profileImage = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: IDPColors.surfaceContainer, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
                image: const DecorationImage(
                  image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuDY14S3uqVgrccFV1SYta6oTz7DbNOBGRVFjXMVmfjp3PyUu_oK9OaZCAQ80zCz7H_HYvpUHmdWbASAdAA1ajdyf350E5lWOpt9tJ-14br-DwCQrRnte8Iq5aYmW_zWOu0V6Tza5gnjfmzEHWs4ftjRsN2-XIwfvFrPA-rp0sTgZBf3KZFyQEKw8u5PqX8b-DjSz06a4C3t0facCpb_iX8S-qhc9mN7em3xDhsHcFEtxxnWeB9PP_fIqq4UMjV-uRDdUmUu458wubsj"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: IDPColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(IDPRadius.full),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: IDPColors.onSecondaryContainer, size: 18),
                    const SizedBox(width: 4),
                    Text("${_profile?.studyStreakDays ?? 0} Day Streak", style: IDPTypography.labelMd.copyWith(color: IDPColors.onSecondaryContainer)),
                  ],
                ),
              ),
            ),
          ],
        );

        final profileDetails = Column(
          crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text("Alex Harrison", style: IDPTypography.headlineLg.copyWith(color: IDPColors.onBackground)),
            Text("Computer Science Undergraduate • Level 24", style: IDPTypography.bodyMd.copyWith(color: IDPColors.onSurfaceVariant)),
            const SizedBox(height: IDPSpacing.md),
            Wrap(
              spacing: IDPSpacing.sm,
              runSpacing: IDPSpacing.sm,
              alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: IDPColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(IDPRadius.full),
                  ),
                  child: Text("Top 5% this month", style: IDPTypography.labelMd.copyWith(color: IDPColors.primaryContainer)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: IDPColors.tertiaryFixedDim.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(IDPRadius.full),
                  ),
                  child: Text("Mastering Algorithms", style: IDPTypography.labelMd.copyWith(color: IDPColors.tertiaryContainer)),
                ),
              ],
            ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileImage,
              const SizedBox(width: IDPSpacing.lg),
              Expanded(child: profileDetails),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileImage,
              const SizedBox(height: IDPSpacing.lg),
              profileDetails,
            ],
          );
        }
      },
    );
  }

  Widget _buildAnalyticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        final items = [
          _buildAnalyticsCard(
            title: "Hours Studied",
            value: ((_profile?.totalLearningTimeMinutes ?? 0) / 60).toStringAsFixed(1),
            unit: "h",
            subtitle: "+12% vs last week",
            icon: Icons.schedule,
            iconColor: IDPColors.primary,
            iconBgColor: IDPColors.primaryContainer.withValues(alpha: 0.1),
            valueColor: IDPColors.primary,
          ),
          _buildAnalyticsCard(
            title: "Quizzes Completed",
            value: "${_profile?.completedChapters ?? 0}", // Mocking using completed chapters
            unit: "",
            subtitle: "New Record!",
            icon: Icons.quiz,
            iconColor: IDPColors.secondary,
            iconBgColor: IDPColors.secondaryContainer.withValues(alpha: 0.2),
            valueColor: IDPColors.onSecondaryContainer,
          ),
          _buildAnalyticsCard(
            title: "Avg Score",
            value: (_profile?.averageQuizAccuracy ?? 0).toStringAsFixed(0),
            unit: "%",
            subtitle: "Top Performance",
            icon: Icons.analytics,
            iconColor: IDPColors.tertiary,
            iconBgColor: IDPColors.tertiaryFixedDim.withValues(alpha: 0.2),
            valueColor: IDPColors.onTertiaryFixedVariant,
          ),
        ];

        if (isWide) {
          return Row(
            children: items.map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: IDPSpacing.sm), child: e))).toList(),
          );
        } else {
          return Column(
            children: items.map((e) => Padding(padding: const EdgeInsets.only(bottom: IDPSpacing.md), child: e)).toList(),
          );
        }
      },
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color valueColor,
  }) {
    return Container(
      height: 192,
      padding: const EdgeInsets.all(IDPSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(IDPRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(IDPRadius.md),
                ),
                child: Icon(icon, color: iconColor),
              ),
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: IDPTypography.labelMd.copyWith(color: iconColor),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: IDPTypography.labelMd.copyWith(color: IDPColors.onSurfaceVariant)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: IDPTypography.displayLg.copyWith(color: valueColor)),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(unit, style: IDPTypography.titleMd.copyWith(color: IDPColors.onSurfaceVariant)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedAchievements() {
    final achievements = _profile?.achievements ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Unlocked Achievements", style: IDPTypography.titleMd.copyWith(color: IDPColors.onBackground)),
                Text("You've earned ${achievements.length} rewards this month.", style: IDPTypography.bodyMd.copyWith(color: IDPColors.onSurfaceVariant)),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text("View All", style: IDPTypography.labelMd.copyWith(color: IDPColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: IDPSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: IDPSpacing.md,
                mainAxisSpacing: IDPSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: 4, // Max 4 achievements to show in grid
              itemBuilder: (context, index) {
                if (index < achievements.length) {
                  return _buildAchievementCard(achievements[index]);
                } else if (index == 3) {
                  return _buildLockedAchievementCard();
                } else {
                  return _buildLockedAchievementCard();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(StudentAchievement achievement) {
    List<Color> gradientColors;
    IconData iconData = Icons.emoji_events;
    if (achievement.title.contains("Fast")) {
      gradientColors = [IDPColors.primary, IDPColors.primaryContainer];
      iconData = Icons.emoji_events;
    } else if (achievement.title.contains("AI")) {
      gradientColors = [IDPColors.secondary, IDPColors.secondaryFixedDim];
      iconData = Icons.auto_awesome;
    } else if (achievement.title.contains("Owl") || achievement.title.contains("Night")) {
      gradientColors = [IDPColors.tertiary, IDPColors.tertiaryFixedDim];
      iconData = Icons.nightlight_round;
    } else {
      gradientColors = [IDPColors.primary, IDPColors.secondary];
    }

    return Container(
      padding: const EdgeInsets.all(IDPSpacing.md),
      decoration: BoxDecoration(
        color: IDPColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(IDPRadius.lg),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(color: gradientColors.last.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Center(
              child: Icon(iconData, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: IDPSpacing.md),
          Text(achievement.title, style: IDPTypography.labelMd.copyWith(color: IDPColors.onBackground), textAlign: TextAlign.center),
          const SizedBox(height: IDPSpacing.xs),
          Text(achievement.description, style: IDPTypography.caption.copyWith(color: IDPColors.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLockedAchievementCard() {
    return Container(
      padding: const EdgeInsets.all(IDPSpacing.md),
      decoration: BoxDecoration(
        color: IDPColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(IDPRadius.lg),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IDPColors.surfaceVariant,
              border: Border.all(color: IDPColors.outline, width: 2, style: BorderStyle.solid),
            ),
            child: const Center(
              child: Icon(Icons.lock, color: IDPColors.outline, size: 32),
            ),
          ),
          const SizedBox(height: IDPSpacing.md),
          Text("Global Sage", style: IDPTypography.labelMd.copyWith(color: IDPColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: IDPSpacing.xs),
          Text("Locked Achievement", style: IDPTypography.caption.copyWith(color: IDPColors.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            const Divider(color: IDPColors.outlineVariant, thickness: 0.3),
            const SizedBox(height: IDPSpacing.lg),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, color: IDPColors.onBackground),
              label: Text("Settings & Privacy", style: IDPTypography.labelMd.copyWith(color: IDPColors.onBackground)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.full)),
                side: BorderSide(color: IDPColors.outline.withValues(alpha: 0.3), width: 2),
              ),
            ),
            const SizedBox(height: IDPSpacing.md),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: IDPColors.error),
              label: Text("Logout", style: IDPTypography.labelMd.copyWith(color: IDPColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.full)),
                side: BorderSide(color: IDPColors.error.withValues(alpha: 0.2), width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
