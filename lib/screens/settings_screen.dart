import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rehab_session_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RehabSessionProvider>();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            automaticallyImplyLeading: false,
            title: const Text('Settings',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Default Exercise ──
                _SectionHeader(title: 'DEFAULT EXERCISE'),
                const SizedBox(height: 10),
                ...kExerciseNames.asMap().entries.map((e) {
                  final isSelected = e.key == provider.selectedExerciseIndex;
                  return GestureDetector(
                    onTap: () => provider.setExercise(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.1) : AppTheme.surfaceCard,
                        border: Border.all(
                          color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.5) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center_rounded,
                            size: 18,
                            color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(e.value,
                              style: TextStyle(
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontFamily: 'Outfit',
                              )),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.accentBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── About ──
                _SectionHeader(title: 'ABOUT'),
                const SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.bluetooth_rounded,
                  title: 'BLE Device Name',
                  subtitle: 'RehabCoach-S1',
                ),
                const SizedBox(height: 8),
                _InfoCard(
                  icon: Icons.memory_rounded,
                  title: 'AI Model',
                  subtitle: 'Random Forest — ONNX (83.82% accuracy)',
                ),
                const SizedBox(height: 8),
                _InfoCard(
                  icon: Icons.timer_rounded,
                  title: 'Window Size',
                  subtitle: '10 seconds (500 frames @ 50 Hz)',
                ),
                const SizedBox(height: 8),
                _InfoCard(
                  icon: Icons.analytics_rounded,
                  title: 'Feature Vector',
                  subtitle: '424 engineered features (Phase 2)',
                ),

                const SizedBox(height: 24),

                // ── Version ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text('RehabCoach',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                      const Text('Version 1.0.0 · Phase 8',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Outfit')),
                      const SizedBox(height: 4),
                      const Text('Stroke Rehabilitation — Group 15 Final Year Project',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'Outfit')),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      fontFamily: 'Outfit',
    ));
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.surfaceCard,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'Outfit')),
                Text(subtitle,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
