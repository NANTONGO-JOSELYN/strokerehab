import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rehab_session_provider.dart';
import 'live_monitoring_screen.dart';

class PainFatigueCheckScreen extends StatefulWidget {
  final List<String> selectedExerciseIds;

  const PainFatigueCheckScreen({
    super.key,
    required this.selectedExerciseIds,
  });

  @override
  State<PainFatigueCheckScreen> createState() => _PainFatigueCheckScreenState();
}

class _PainFatigueCheckScreenState extends State<PainFatigueCheckScreen> {
  int _painLevel = 0;
  int _fatigueLevel = 0;
  String _painLocation = 'None';
  bool _shouldContinue = true;

  final List<String> _painLocations = [
    'None',
    'Shoulder',
    'Elbow',
    'Wrist',
    'Hand',
    'Full Arm',
  ];

  @override
  void initState() {
    super.initState();
    _updateShouldContinue();
  }

  void _updateShouldContinue() {
    // Patient should not continue if pain or fatigue is too high
    setState(() {
      _shouldContinue = _painLevel < 7 && _fatigueLevel < 8;
    });
  }

  void _handleProceed() {
    if (!_shouldContinue) {
      _showWarningDialog();
      return;
    }

    // Sensors are already connected from the dashboard — go straight to live monitoring.
    final provider = context.read<RehabSessionProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMonitoringScreen(
          selectedExerciseIds: widget.selectedExerciseIds,
          connectedDevice: provider.deviceName.isNotEmpty
              ? provider.deviceName
              : 'Dual-sensor setup',
        ),
      ),
    );
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Text(
          'High Pain/Fatigue Levels',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _painLevel >= 7
              ? 'Your pain level is high. Please consult with your clinician before continuing.'
              : 'Your fatigue level is high. Consider resting before continuing.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pre-Exercise Assessment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Please assess your current pain and fatigue levels before starting exercises.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pain Level Section
            _AssessmentSection(
              title: 'Current Pain Level',
              description: '0 = No pain, 10 = Severe pain',
              value: _painLevel,
              onChanged: (value) {
                setState(() {
                  _painLevel = value;
                  _updateShouldContinue();
                });
              },
              color: _getPainColor(_painLevel),
            ),
            const SizedBox(height: 24),

            // Fatigue Level Section
            _AssessmentSection(
              title: 'Current Fatigue Level',
              description: '0 = Not fatigued, 10 = Extremely fatigued',
              value: _fatigueLevel,
              onChanged: (value) {
                setState(() {
                  _fatigueLevel = value;
                  _updateShouldContinue();
                });
              },
              color: _getFatigueColor(_fatigueLevel),
            ),
            const SizedBox(height: 24),

            // Pain Location
            const Text(
              'Pain Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _painLocations.map((location) {
                final isSelected = _painLocation == location;
                return GestureDetector(
                  onTap: () => setState(() => _painLocation = location),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.3)
                          : const Color(0xFF1A1F2B),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      location,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _shouldContinue
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                border: Border.all(
                  color: _shouldContinue
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.red.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _shouldContinue ? Icons.check_circle : Icons.warning,
                    color: _shouldContinue ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _shouldContinue
                          ? 'You are ready to start exercising!'
                          : 'High levels detected. Consider resting.',
                      style: TextStyle(
                        color: _shouldContinue ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getFatigueColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }
}

class _AssessmentSection extends StatelessWidget {
  final String title;
  final String description;
  final int value;
  final ValueChanged<int> onChanged;
  final Color color;

  const _AssessmentSection({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        // Value display
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 10,
                    onChanged: (val) => onChanged(val.toInt()),
                    activeColor: color,
                    inactiveColor: Colors.white24,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
