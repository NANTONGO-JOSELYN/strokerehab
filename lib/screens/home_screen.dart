import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rehab_session_provider.dart';
import '../services/ble_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/live_chart_widget.dart';
import '../widgets/quality_badge.dart';
import '../widgets/sensor_status_bar.dart';
import 'exercise_selection_screen.dart';
import 'feedback_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _DashboardTab(),
          FeedbackScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RehabSessionProvider>();
    final isConnected = provider.isConnected;
    final sessionActive = provider.sessionActive;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.accessibility_new_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RehabCoach',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      'Stroke Rehabilitation',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (isConnected)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed: () => provider.disconnect(),
                    icon: const Icon(Icons.bluetooth_disabled_rounded,
                        color: AppTheme.textSecondary),
                    tooltip: 'Disconnect sensors',
                  ),
                ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Dual Sensor Status ──
                SensorStatusBar(
                  state: provider.connectionState,
                  deviceName: provider.deviceName,
                  frameCount: provider.frameCount,
                  wristConnected: provider.wristConnected,
                  lowerBackConnected: provider.lowerBackConnected,
                  isSimulated: provider.isSimulated,
                ),

                const SizedBox(height: 20),

                // ── Quality Badge ──
                Center(
                  child: QualityBadge(
                    result: provider.latestResult,
                    size: 220,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Exercise Selector or Session Info ──
                if (!sessionActive && isConnected) ...[
                  const Text(
                    'SELECT EXERCISE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ExercisePicker(
                    selected: provider.selectedExerciseIndex,
                    onSelect: (i) => provider.setExercise(i),
                  ),
                  const SizedBox(height: 20),
                ] else if (sessionActive) ...[
                  _SessionInfoRow(provider: provider),
                  const SizedBox(height: 16),
                ],

                // ── Live Chart (always visible when connected) ──
                if (isConnected)
                  LiveChartWidget(frames: provider.chartWindow),

                const SizedBox(height: 24),

                // ── Main Action Area ──
                _ActionArea(provider: provider),

                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Picker ───────────────────────────────────────────────────────────

class _ExercisePicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _ExercisePicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kExerciseNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surfaceCard,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.surfaceCard.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                kExerciseNames[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Session Info Row ──────────────────────────────────────────────────────────

class _SessionInfoRow extends StatefulWidget {
  final RehabSessionProvider provider;
  const _SessionInfoRow({required this.provider});

  @override
  State<_SessionInfoRow> createState() => _SessionInfoRowState();
}

class _SessionInfoRowState extends State<_SessionInfoRow> {
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, _) {
        final dur = widget.provider.sessionDuration;
        final mm = dur.inMinutes.toString().padLeft(2, '0');
        final ss = (dur.inSeconds % 60).toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppTheme.surfaceCard,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoCell(
                label: 'EXERCISE',
                value: widget.provider.selectedExerciseName,
              ),
              _InfoCell(
                label: 'DURATION',
                value: '$mm:$ss',
              ),
              _InfoCell(
                label: 'INFERENCES',
                value: '${widget.provider.sessionResults.length}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label, value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Outfit',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.1,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}

// ── Action Area ───────────────────────────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  final RehabSessionProvider provider;

  const _ActionArea({required this.provider});

  /// Shows a bottom sheet so the user can choose real BLE or simulation.
  void _showConnectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connect Sensors',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how to connect your Wrist and Lower Back sensors.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 24),

              // — Real BLE option —
              _SheetOption(
                icon: Icons.bluetooth_searching_rounded,
                title: 'Connect Real Sensors',
                subtitle: 'Scans for ESP32 RehabCoach-S1 via Bluetooth',
                iconColor: AppTheme.accentBlue,
                onTap: () {
                  Navigator.pop(context);
                  provider.connectAndStart();
                },
              ),
              const SizedBox(height: 14),

              // — Simulate option —
              _SheetOption(
                icon: Icons.science_rounded,
                title: 'Simulate Dual-Sensor Setup',
                subtitle: 'Demo mode — instantly connects Wrist & Lower Back sensors',
                iconColor: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  provider.simulateConnect();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = provider.isConnected;
    final sessionActive = provider.sessionActive;
    final isScanning = provider.connectionState == BleConnectionState.scanning ||
        provider.connectionState == BleConnectionState.connecting;

    // ── While scanning / connecting ──
    if (isScanning && !isConnected) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceCard,
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accentBlue),
              ),
              SizedBox(width: 12),
              Text(
                'Scanning for sensors…',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontFamily: 'Outfit'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Not connected — show connect button ──
    if (!isConnected) {
      return Column(
        children: [
          // Sensor placement guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SENSOR PLACEMENT GUIDE',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                _PlacementRow(
                  icon: Icons.watch_rounded,
                  label: 'Wrist Sensor',
                  detail: 'Strap firmly on your dominant wrist',
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(height: 10),
                _PlacementRow(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Lower Back Sensor',
                  detail: 'Clip on waistband at lumbar spine',
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _GradientButton(
            label: 'Connect Sensors',
            icon: Icons.bluetooth_searching_rounded,
            onTap: () => _showConnectSheet(context),
          ),
        ],
      );
    }

    // ── Connected but no active session ──
    if (!sessionActive) {
      return Column(
        children: [
          _GradientButton(
            label: 'Start Full Rehabilitation Session',
            icon: Icons.fitness_center_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExerciseSelectionScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _GradientButton(
            label: 'Quick-Start Session',
            icon: Icons.play_arrow_rounded,
            onTap: () => provider.startSession(),
          ),
        ],
      );
    }

    // ── Session active — stop button ──
    return GestureDetector(
      onTap: () async => provider.stopSession(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.qualityPoor.withValues(alpha: 0.6), width: 2),
          color: AppTheme.qualityPoor.withValues(alpha: 0.1),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop_rounded, color: AppTheme.qualityPoor),
              SizedBox(width: 8),
              Text(
                'Stop Session',
                style: TextStyle(
                  color: AppTheme.qualityPoor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet Option ──────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Placement Row ─────────────────────────────────────────────────────────────

class _PlacementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  const _PlacementRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.analytics_rounded, label: 'Feedback', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.history_rounded, label: 'History', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.settings_rounded, label: 'Settings', index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? AppTheme.accentBlue.withValues(alpha: 0.15) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? AppTheme.accentBlue : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accentBlue : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
