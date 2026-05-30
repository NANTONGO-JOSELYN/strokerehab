import 'package:flutter/material.dart';

import '../services/ble_manager.dart';
import '../theme/app_theme.dart';

/// Tri-sensor status panel — shows Wrist A, Wrist B and Trunk sensors individually.
class SensorStatusBar extends StatelessWidget {
  final BleConnectionState state;
  final String deviceName;
  final int frameCount;
  final bool wristAConnected;
  final bool wristBConnected;
  final bool trunkConnected;
  final bool isSimulated;

  const SensorStatusBar({
    super.key,
    required this.state,
    required this.deviceName,
    required this.frameCount,
    required this.wristAConnected,
    required this.wristBConnected,
    required this.trunkConnected,
    required this.isSimulated,
  });

  @override
  Widget build(BuildContext context) {
    final allConnected = wristAConnected && wristBConnected && trunkConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Text(
              'SENSOR STATUS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontFamily: 'Outfit',
              ),
            ),
            const Spacer(),
            if (isSimulated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_rounded, size: 10, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'DEMO MODE',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              )
            else if (allConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.qualityGood.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.qualityGood.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 10, color: AppTheme.qualityGood),
                    SizedBox(width: 4),
                    Text(
                      'ALL READY',
                      style: TextStyle(
                        color: AppTheme.qualityGood,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Sensor cards row
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                label: 'Wrist A',
                placement: 'Dominant Wrist',
                icon: Icons.watch_rounded,
                isConnected: wristAConnected,
                isScanning: state == BleConnectionState.scanning ||
                    state == BleConnectionState.connecting,
                frameCount: wristAConnected ? frameCount : 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                label: 'Wrist B',
                placement: 'Non-dominant Wrist',
                icon: Icons.watch_rounded,
                isConnected: wristBConnected,
                isScanning: state == BleConnectionState.scanning ||
                    state == BleConnectionState.connecting,
                frameCount: wristBConnected ? frameCount : 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                label: 'Trunk',
                placement: 'Lumbar Region',
                icon: Icons.accessibility_new_rounded,
                isConnected: trunkConnected,
                isScanning: state == BleConnectionState.scanning ||
                    state == BleConnectionState.connecting,
                frameCount: trunkConnected ? frameCount : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String placement;
  final IconData icon;
  final bool isConnected;
  final bool isScanning;
  final int frameCount;

  const _SensorCard({
    required this.label,
    required this.placement,
    required this.icon,
    required this.isConnected,
    required this.isScanning,
    required this.frameCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? AppTheme.qualityGood
        : isScanning
            ? AppTheme.accentBlue
            : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(color: color, active: isConnected),
              const SizedBox(width: 8),
              Icon(icon, size: 14, color: color),
              const Spacer(),
              if (isScanning)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
            ),
          ),
          Text(
            placement,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isConnected
                ? '$frameCount frames'
                : isScanning
                    ? 'Scanning…'
                    : 'Disconnected',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dot indicator.
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool active;

  const _PulseDot({required this.color, required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.6),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
