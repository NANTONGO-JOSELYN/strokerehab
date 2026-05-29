import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rehab_session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quality_badge.dart';
import '../widgets/recommendation_card.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RehabSessionProvider>();
    final result = provider.latestResult;
    final recs = provider.recommendations;
    final sessionActive = provider.sessionActive;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Live Feedback',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Outfit',
              ),
            ),
            actions: [
              if (sessionActive)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.qualityGood.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.qualityGood.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.qualityGood,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('LIVE',
                          style: TextStyle(
                            color: AppTheme.qualityGood,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontFamily: 'Outfit',
                          )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!sessionActive && result == null) ...[
                  const SizedBox(height: 60),
                  _EmptyState(),
                ] else ...[
                  Center(child: QualityBadge(result: result, size: 200)),
                  const SizedBox(height: 24),
                  if (result != null) ...[
                    _DistributionCard(provider: provider),
                    const SizedBox(height: 20),
                  ],
                  if (recs.isNotEmpty) ...[
                    const Text('COACHING TIPS',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontFamily: 'Outfit',
                      )),
                    const SizedBox(height: 12),
                    ...recs.asMap().entries.map(
                      (e) => RecommendationCard(recommendation: e.value, index: e.key),
                    ),
                  ] else if (result?.quality == QualityLevel.good) ...[
                    _GoodBanner(),
                  ],
                  const SizedBox(height: 30),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceCard,
            border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(Icons.analytics_outlined, size: 44, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        const Text('No Feedback Yet',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
        const SizedBox(height: 10),
        const Text(
          'Start a session on the Home tab.\nFeedback appears after 10 s of IMU data.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6, fontFamily: 'Outfit'),
        ),
      ],
    );
  }
}

class _GoodBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          AppTheme.qualityGood.withValues(alpha: 0.2),
          AppTheme.qualityGood.withValues(alpha: 0.05),
        ]),
        border: Border.all(color: AppTheme.qualityGood.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.celebration_rounded, color: AppTheme.qualityGood, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Excellent Work!',
                  style: TextStyle(color: AppTheme.qualityGood, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                SizedBox(height: 4),
                Text('Your exercise quality is good.\nKeep maintaining this form and rhythm.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5, fontFamily: 'Outfit')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final RehabSessionProvider provider;
  const _DistributionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final results = provider.sessionResults;
    if (results.isEmpty) return const SizedBox.shrink();
    final good = results.where((r) => r.quality == QualityLevel.good).length;
    final warn = results.where((r) => r.quality == QualityLevel.needsImprovement).length;
    final poor = results.where((r) => r.quality == QualityLevel.poor).length;
    final total = results.length;
    String pct(int n) => total > 0 ? '${(n / total * 100).toStringAsFixed(0)}%' : '0%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SESSION DISTRIBUTION',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: 'Outfit')),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (good > 0) Flexible(flex: good, child: Container(color: AppTheme.qualityGood)),
                  if (warn > 0) Flexible(flex: warn, child: Container(color: AppTheme.qualityWarning)),
                  if (poor > 0) Flexible(flex: poor, child: Container(color: AppTheme.qualityPoor)),
                  if (total == 0) Flexible(flex: 1, child: Container(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DistCell(label: 'Good Quality', value: pct(good), color: AppTheme.qualityGood),
              _DistCell(label: 'Needs Work', value: pct(warn), color: AppTheme.qualityWarning),
              _DistCell(label: 'Poor Quality', value: pct(poor), color: AppTheme.qualityPoor),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DistCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Outfit')),
    ],
  );
}
