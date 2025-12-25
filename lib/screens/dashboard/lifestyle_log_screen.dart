import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';

class LifestyleLogScreen extends StatefulWidget {
  const LifestyleLogScreen({super.key});

  @override
  State<LifestyleLogScreen> createState() => _LifestyleLogScreenState();
}

class _LifestyleLogScreenState extends State<LifestyleLogScreen> {
  // Sleep
  double _sleepHours = 7.0;
  int _sleepQuality = 3;

  // Caffeine
  int _caffeineServings = 1;

  // Exercise
  int _exerciseMinutes = 0;
  int _exerciseIntensity = 3;

  // Mental state
  int _stressLevel = 3;
  int _moodLevel = 3;
  int _energyLevel = 3;

  // Meditation
  bool _meditationDone = false;
  int _meditationMinutes = 0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingLog();
  }

  Future<void> _loadExistingLog() async {
    final appState = context.read<AppState>();
    final existingLog = appState.todayLog;

    if (existingLog != null) {
      setState(() {
        _sleepHours = existingLog.sleepHours ?? 7.0;
        _sleepQuality = existingLog.sleepQuality ?? 3;
        _caffeineServings = existingLog.caffeineIntake ?? 1;
        _exerciseMinutes = existingLog.exerciseMinutes ?? 0;
        _exerciseIntensity = existingLog.exerciseIntensity ?? 3;
        _stressLevel = existingLog.stressLevel ?? 3;
        _moodLevel = existingLog.moodLevel ?? 3;
        _energyLevel = existingLog.energyLevel ?? 3;
        _meditationDone = existingLog.meditationDone ?? false;
        _meditationMinutes = existingLog.meditationMinutes ?? 0;
      });
    }
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final appState = context.read<AppState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final log = LifestyleLog(
      id: appState.todayLog?.id ?? appState.generateId(),
      userId: appState.currentUser!.id,
      date: today,
      loggedAt: now,
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      caffeineIntake: _caffeineServings,
      exerciseMinutes: _exerciseMinutes,
      exerciseIntensity: _exerciseMinutes > 0 ? _exerciseIntensity : null,
      stressLevel: _stressLevel,
      moodLevel: _moodLevel,
      energyLevel: _energyLevel,
      meditationDone: _meditationDone,
      meditationMinutes: _meditationDone ? _meditationMinutes : null,
    );

    await appState.saveLifestyleLog(log);

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily log saved!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your day?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Log lifestyle factors to discover patterns in your cognition.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Sleep Section
            _buildSectionCard(
              icon: Icons.bedtime_outlined,
              title: 'Sleep',
              children: [
                _buildSliderRow(
                  label: 'Hours slept',
                  value: _sleepHours,
                  min: 0,
                  max: 12,
                  divisions: 24,
                  displayValue: '${_sleepHours.toStringAsFixed(1)}h',
                  onChanged: (v) => setState(() => _sleepHours = v),
                ),
                const SizedBox(height: 16),
                _buildRatingRow(
                  label: 'Sleep quality',
                  value: _sleepQuality,
                  onChanged: (v) => setState(() => _sleepQuality = v),
                  lowLabel: 'Poor',
                  highLabel: 'Excellent',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Caffeine Section
            _buildSectionCard(
              icon: Icons.coffee_outlined,
              title: 'Caffeine',
              children: [
                _buildCounterRow(
                  label: 'Servings today',
                  value: _caffeineServings,
                  onDecrement: () {
                    if (_caffeineServings > 0) {
                      setState(() => _caffeineServings--);
                    }
                  },
                  onIncrement: () {
                    if (_caffeineServings < 10) {
                      setState(() => _caffeineServings++);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Exercise Section
            _buildSectionCard(
              icon: Icons.fitness_center_outlined,
              title: 'Exercise',
              children: [
                _buildSliderRow(
                  label: 'Minutes',
                  value: _exerciseMinutes.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  displayValue: '${_exerciseMinutes}min',
                  onChanged: (v) => setState(() => _exerciseMinutes = v.round()),
                ),
                if (_exerciseMinutes > 0) ...[
                  const SizedBox(height: 16),
                  _buildRatingRow(
                    label: 'Intensity',
                    value: _exerciseIntensity,
                    onChanged: (v) => setState(() => _exerciseIntensity = v),
                    lowLabel: 'Light',
                    highLabel: 'Intense',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Mental State Section
            _buildSectionCard(
              icon: Icons.psychology_outlined,
              title: 'Mental State',
              children: [
                _buildRatingRow(
                  label: 'Stress level',
                  value: _stressLevel,
                  onChanged: (v) => setState(() => _stressLevel = v),
                  lowLabel: 'Calm',
                  highLabel: 'Stressed',
                  invertColors: true,
                ),
                const SizedBox(height: 20),
                _buildRatingRow(
                  label: 'Mood',
                  value: _moodLevel,
                  onChanged: (v) => setState(() => _moodLevel = v),
                  lowLabel: 'Low',
                  highLabel: 'Great',
                ),
                const SizedBox(height: 20),
                _buildRatingRow(
                  label: 'Energy',
                  value: _energyLevel,
                  onChanged: (v) => setState(() => _energyLevel = v),
                  lowLabel: 'Tired',
                  highLabel: 'Energized',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meditation Section
            _buildSectionCard(
              icon: Icons.self_improvement_outlined,
              title: 'Meditation',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Did you meditate today?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Switch(
                      value: _meditationDone,
                      onChanged: (v) => setState(() => _meditationDone = v),
                      activeColor: AppTheme.accentTeal,
                    ),
                  ],
                ),
                if (_meditationDone) ...[
                  const SizedBox(height: 16),
                  _buildSliderRow(
                    label: 'Duration',
                    value: _meditationMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    displayValue: '${_meditationMinutes}min',
                    onChanged: (v) =>
                        setState(() => _meditationMinutes = v.round()),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Check-in'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.primaryBlue,
          inactiveColor: AppTheme.surfaceMedium,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRatingRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required String lowLabel,
    required String highLabel,
    bool invertColors = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              lowLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  final isSelected = rating == value;
                  Color color;
                  if (invertColors) {
                    // For stress: low is good (green), high is bad (red)
                    color = Color.lerp(
                      AppTheme.success,
                      AppTheme.error,
                      index / 4,
                    )!;
                  } else {
                    // Normal: low is bad, high is good
                    color = Color.lerp(
                      AppTheme.error,
                      AppTheme.success,
                      index / 4,
                    )!;
                  }

                  return GestureDetector(
                    onTap: () => onChanged(rating),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : AppTheme.surfaceMedium,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$rating',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Text(
              highLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.textSecondary,
            ),
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}
