import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise_quality_result.dart';
import '../models/session_record.dart';
import '../providers/rehab_session_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RehabSessionProvider>();
    final history = provider.history;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Session History',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, provider),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.qualityPoor),
                    label: const Text('Clear', style: TextStyle(color: AppTheme.qualityPoor, fontFamily: 'Outfit')),
                  ),
              ],
            ),
          ),
          // List
          Expanded(
            child: history.isEmpty
                ? _EmptyHistory()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: history.length,
                    itemBuilder: (ctx, i) => _SessionCard(
                      record: history[i],
                      onDelete: () => provider.deleteHistoryRecord(history[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, RehabSessionProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Clear All History', style: TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit')),
        content: const Text('This will permanently delete all session records.', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Outfit')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () { provider.clearHistory(); Navigator.pop(context); },
            child: const Text('Clear All', style: TextStyle(color: AppTheme.qualityPoor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceCard),
            child: const Icon(Icons.history_rounded, size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text('No Sessions Yet',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
          const SizedBox(height: 8),
          const Text('Completed sessions will appear here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'Outfit')),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionRecord record;
  final VoidCallback onDelete;

  const _SessionCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dur = record.endTime.difference(record.startTime);
    final mm = dur.inMinutes.toString().padLeft(2, '0');
    final ss = (dur.inSeconds % 60).toString().padLeft(2, '0');

    final total = record.results.length;
    final good = record.results.where((r) => r.quality == QualityLevel.good).length;
    final warn = record.results.where((r) => r.quality == QualityLevel.needsImprovement).length;
    final poor = record.results.where((r) => r.quality == QualityLevel.poor).length;

    final dominantColor = poor > good && poor > warn
        ? AppTheme.qualityPoor
        : warn > good
            ? AppTheme.qualityWarning
            : AppTheme.qualityGood;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surfaceCard,
        border: Border.all(color: dominantColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: dominantColor.withValues(alpha: 0.15),
                  ),
                  child: Text(record.exerciseName,
                    style: TextStyle(color: dominantColor, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textSecondary),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Duration', value: '$mm:$ss'),
                _Stat(label: 'Assessments', value: '$total'),
                _Stat(label: 'Date',
                  value: '${record.startTime.day}/${record.startTime.month}/${record.startTime.year}'),
              ],
            ),
            const SizedBox(height: 14),
            // Distribution bar
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      if (good > 0) Flexible(flex: good, child: Container(color: AppTheme.qualityGood)),
                      if (warn > 0) Flexible(flex: warn, child: Container(color: AppTheme.qualityWarning)),
                      if (poor > 0) Flexible(flex: poor, child: Container(color: AppTheme.qualityPoor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MiniLegend(color: AppTheme.qualityGood, label: '$good Good'),
                  const SizedBox(width: 12),
                  _MiniLegend(color: AppTheme.qualityWarning, label: '$warn Improve'),
                  const SizedBox(width: 12),
                  _MiniLegend(color: AppTheme.qualityPoor, label: '$poor Poor'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Outfit')),
    ],
  );
}

class _MiniLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MiniLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontFamily: 'Outfit')),
    ],
  );
}
