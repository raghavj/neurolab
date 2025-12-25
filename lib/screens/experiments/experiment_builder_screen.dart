import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import 'experiment_detail_screen.dart';

class ExperimentBuilderScreen extends StatefulWidget {
  final ExperimentTemplate? template;

  const ExperimentBuilderScreen({super.key, this.template});

  @override
  State<ExperimentBuilderScreen> createState() => _ExperimentBuilderScreenState();
}

class _ExperimentBuilderScreenState extends State<ExperimentBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hypothesisController = TextEditingController();
  final _interventionController = TextEditingController();

  CognitiveTestType _selectedTestType = CognitiveTestType.reactionTime;
  int _baselineDays = 7;
  int _interventionDays = 14;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleController.text = widget.template!.title;
      _hypothesisController.text = widget.template!.hypothesis;
      _interventionController.text = widget.template!.intervention;
      _selectedTestType = widget.template!.targetTest;
      _baselineDays = widget.template!.baselineDays;
      _interventionDays = widget.template!.interventionDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hypothesisController.dispose();
    _interventionController.dispose();
    super.dispose();
  }

  Future<void> _createExperiment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final appState = context.read<AppState>();
    final experiment = Experiment(
      id: appState.generateId(),
      userId: appState.currentUser!.id,
      title: _titleController.text.trim(),
      hypothesis: _hypothesisController.text.trim(),
      intervention: _interventionController.text.trim(),
      targetTest: _selectedTestType,
      status: ExperimentStatus.draft,
      createdAt: DateTime.now(),
      baselineDays: _baselineDays,
      interventionDays: _interventionDays,
    );

    await appState.createExperiment(experiment);

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExperimentDetailScreen(experiment: experiment),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Customize Experiment' : 'New Experiment'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Design Your Experiment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Test a hypothesis about your cognition',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Experiment Title',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Morning Meditation Effect',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Hypothesis
              Text(
                'Your Hypothesis',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'What do you expect to happen?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hypothesisController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Daily meditation will improve my reaction time',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your hypothesis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Intervention
              Text(
                'Intervention',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'What will you do differently?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _interventionController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 10 minutes of guided meditation each morning',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your intervention';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Target Test
              Text(
                'Measure With',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: CognitiveTestType.values
                      .where((t) => t != CognitiveTestType.trailMaking)
                      .map((type) {
                    return RadioListTile<CognitiveTestType>(
                      title: Text(type.displayName),
                      subtitle: Text(
                        type.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: type,
                      groupValue: _selectedTestType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedTestType = value);
                        }
                      },
                      activeColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Duration
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDurationSelector(
                      label: 'Baseline',
                      value: _baselineDays,
                      onChanged: (v) => setState(() => _baselineDays = v),
                      description: 'Normal behavior',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDurationSelector(
                      label: 'Intervention',
                      value: _interventionDays,
                      onChanged: (v) => setState(() => _interventionDays = v),
                      description: 'With change',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.accentTeal,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total duration: ${_baselineDays + _interventionDays} days',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _createExperiment,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Experiment'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > 3
                    ? () => onChanged(value - 1)
                    : null,
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
                onPressed: value < 30
                    ? () => onChanged(value + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          Text(
            'days',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
