import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';

class TestInfoSheet extends StatelessWidget {
  final CognitiveTestType testType;

  const TestInfoSheet({super.key, required this.testType});

  @override
  Widget build(BuildContext context) {
    final info = _getTestInfo(testType);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        info.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testType.displayName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.accentTeal,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // What it measures
                _buildSection(
                  context,
                  title: 'What It Measures',
                  icon: Icons.analytics_outlined,
                  content: info.whatItMeasures,
                ),
                const SizedBox(height: 20),

                // The science
                _buildSection(
                  context,
                  title: 'The Science',
                  icon: Icons.science_outlined,
                  content: info.theScience,
                ),
                const SizedBox(height: 20),

                // Brain regions
                _buildSection(
                  context,
                  title: 'Brain Regions Involved',
                  icon: Icons.psychology_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: info.brainRegions.map((region) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          region,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Neurotransmitters
                _buildSection(
                  context,
                  title: 'Key Neurotransmitters',
                  icon: Icons.bubble_chart_outlined,
                  child: Column(
                    children: info.neurotransmitters.map((nt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accentTeal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nt.name,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    nt.role,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Factors that affect it
                _buildSection(
                  context,
                  title: 'Factors That Affect Performance',
                  icon: Icons.tune_outlined,
                  child: Column(
                    children: info.factors.map((factor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              factor.isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: factor.isPositive
                                  ? AppTheme.success
                                  : AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                factor.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Pro tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.accentTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pro Tip',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.accentTeal,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info.proTip,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? content,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        if (child != null) child,
      ],
    );
  }

  _TestInfo _getTestInfo(CognitiveTestType type) {
    switch (type) {
      case CognitiveTestType.reactionTime:
        return _TestInfo(
          icon: Icons.speed,
          subtitle: 'Psychomotor Vigilance Test (PVT)',
          whatItMeasures:
              'Simple reaction time measures the speed at which you can respond to a stimulus. It reflects your baseline alertness, processing speed, and the efficiency of your sensory-motor pathways. This is one of the most sensitive measures of fatigue and sleep deprivation.',
          theScience:
              'When a stimulus appears, light hits your retina and triggers a cascade: photoreceptors convert light to electrical signals, which travel through the optic nerve to the visual cortex. Your brain then recognizes the stimulus, decides to act, and sends motor commands to your muscles. All of this happens in about 150-300 milliseconds.',
          brainRegions: [
            'Primary Visual Cortex',
            'Motor Cortex',
            'Basal Ganglia',
            'Reticular Activating System',
            'Prefrontal Cortex',
          ],
          neurotransmitters: [
            _Neurotransmitter(
              name: 'Dopamine',
              role: 'Drives motivation and motor initiation. Low dopamine slows reaction time.',
            ),
            _Neurotransmitter(
              name: 'Norepinephrine',
              role: 'Maintains alertness and arousal. Released by the locus coeruleus.',
            ),
            _Neurotransmitter(
              name: 'Acetylcholine',
              role: 'Enables attention and neuromuscular signaling for rapid motor responses.',
            ),
          ],
          factors: [
            _Factor('Good sleep (7-9 hours) improves reaction time', true),
            _Factor('Caffeine can improve alertness and speed', true),
            _Factor('Regular exercise enhances processing speed', true),
            _Factor('Sleep deprivation severely impairs performance', false),
            _Factor('Alcohol slows reaction time significantly', false),
            _Factor('High stress can impair or paradoxically improve speed', false),
          ],
          proTip:
              'Test at the same time each day to control for circadian rhythm effects. Your reaction time is typically slowest in early morning and late night, peaking in late afternoon.',
        );

      case CognitiveTestType.nBack:
        return _TestInfo(
          icon: Icons.grid_view,
          subtitle: 'Working Memory Assessment',
          whatItMeasures:
              'The N-Back test measures working memory capacity—your ability to temporarily hold and manipulate information. It assesses how well you can update your mental workspace while ignoring irrelevant information.',
          theScience:
              'Working memory relies on a network of brain regions that temporarily maintain and process information. The dorsolateral prefrontal cortex acts as the "central executive," coordinating information flow, while the parietal cortex helps maintain spatial and sequential information.',
          brainRegions: [
            'Dorsolateral Prefrontal Cortex',
            'Posterior Parietal Cortex',
            'Anterior Cingulate Cortex',
            'Hippocampus',
          ],
          neurotransmitters: [
            _Neurotransmitter(
              name: 'Dopamine',
              role: 'Critical for maintaining stable representations in prefrontal cortex.',
            ),
            _Neurotransmitter(
              name: 'Glutamate',
              role: 'The primary excitatory neurotransmitter, enabling rapid neural communication.',
            ),
            _Neurotransmitter(
              name: 'GABA',
              role: 'Provides inhibitory control, helping filter distracting information.',
            ),
          ],
          factors: [
            _Factor('Mindfulness meditation improves working memory', true),
            _Factor('Adequate sleep consolidates memory processes', true),
            _Factor('Regular practice can increase capacity', true),
            _Factor('Chronic stress impairs prefrontal function', false),
            _Factor('Multitasking fragments attention and memory', false),
          ],
          proTip:
              'Working memory has a limited capacity of about 4 items. Chunking information (grouping related items) can help you hold more in mind.',
        );

      case CognitiveTestType.stroop:
        return _TestInfo(
          icon: Icons.color_lens,
          subtitle: 'Cognitive Control & Inhibition',
          whatItMeasures:
              'The Stroop test measures cognitive control and response inhibition—your ability to suppress automatic responses in favor of goal-directed behavior. It reveals how well you can override habitual patterns.',
          theScience:
              'Reading is highly automated, making it difficult to ignore words when naming colors. The conflict between reading and color-naming activates the anterior cingulate cortex, which detects conflicts, and the dorsolateral prefrontal cortex, which implements top-down control.',
          brainRegions: [
            'Anterior Cingulate Cortex',
            'Dorsolateral Prefrontal Cortex',
            'Inferior Frontal Gyrus',
            'Visual Word Form Area',
          ],
          neurotransmitters: [
            _Neurotransmitter(
              name: 'Dopamine',
              role: 'Modulates prefrontal control and conflict resolution.',
            ),
            _Neurotransmitter(
              name: 'Norepinephrine',
              role: 'Enhances signal-to-noise ratio for better cognitive control.',
            ),
            _Neurotransmitter(
              name: 'Serotonin',
              role: 'Influences impulse control and behavioral inhibition.',
            ),
          ],
          factors: [
            _Factor('Exercise improves executive function', true),
            _Factor('Good sleep enhances cognitive control', true),
            _Factor('Acute stress can temporarily sharpen focus', true),
            _Factor('Fatigue reduces inhibitory control', false),
            _Factor('Aging naturally slows inhibition speed', false),
          ],
          proTip:
              'The Stroop effect is stronger in the morning for most people. If you struggle with impulse control, try tackling demanding tasks earlier in the day.',
        );

      case CognitiveTestType.trailMaking:
        return _TestInfo(
          icon: Icons.timeline,
          subtitle: 'Executive Function & Flexibility',
          whatItMeasures:
              'Trail Making measures executive function, particularly cognitive flexibility and task-switching. It assesses your ability to sequence information, shift between mental sets, and maintain goal-directed behavior.',
          theScience:
              'Trail Making engages a widespread frontoparietal network. The prefrontal cortex coordinates the task rules, the parietal cortex tracks spatial locations, and the anterior cingulate monitors for errors. Switching between letters and numbers requires flexible updating of task rules.',
          brainRegions: [
            'Prefrontal Cortex',
            'Posterior Parietal Cortex',
            'Motor Planning Areas',
            'Visual Processing Areas',
          ],
          neurotransmitters: [
            _Neurotransmitter(
              name: 'Dopamine',
              role: 'Enables flexible switching between task sets.',
            ),
            _Neurotransmitter(
              name: 'Acetylcholine',
              role: 'Supports attention and visual-motor coordination.',
            ),
          ],
          factors: [
            _Factor('Cognitive training can improve flexibility', true),
            _Factor('Aerobic exercise enhances executive function', true),
            _Factor('Sleep deprivation impairs task-switching', false),
            _Factor('Age-related decline affects processing speed', false),
          ],
          proTip:
              'Mental flexibility is like a muscle—practicing tasks that require switching between rules can strengthen these neural pathways.',
        );

      case CognitiveTestType.flanker:
        return _TestInfo(
          icon: Icons.arrow_forward,
          subtitle: 'Selective Attention Test',
          whatItMeasures:
              'The Flanker test measures selective attention and response inhibition—your ability to focus on relevant information while filtering out distracting stimuli. It reveals the efficiency of your attentional control.',
          theScience:
              'When flanking arrows point in the opposite direction as the target, they create response conflict. Your brain must suppress the automatic tendency to respond to the flankers while selectively attending to the center arrow. This engages attention control networks.',
          brainRegions: [
            'Anterior Cingulate Cortex',
            'Lateral Prefrontal Cortex',
            'Parietal Attention Networks',
            'Visual Cortex',
          ],
          neurotransmitters: [
            _Neurotransmitter(
              name: 'Acetylcholine',
              role: 'Sharpens selective attention and filters distractors.',
            ),
            _Neurotransmitter(
              name: 'Dopamine',
              role: 'Modulates the strength of goal-relevant signals.',
            ),
            _Neurotransmitter(
              name: 'GABA',
              role: 'Suppresses irrelevant neural activity for cleaner signals.',
            ),
          ],
          factors: [
            _Factor('Meditation improves attentional control', true),
            _Factor('Caffeine can enhance selective attention', true),
            _Factor('Environmental noise impairs focus', false),
            _Factor('Fatigue reduces filtering efficiency', false),
          ],
          proTip:
              'Your ability to filter distractions improves with practice. Regular meditation has been shown to strengthen the same attention networks used in this task.',
        );
    }
  }
}

class _TestInfo {
  final IconData icon;
  final String subtitle;
  final String whatItMeasures;
  final String theScience;
  final List<String> brainRegions;
  final List<_Neurotransmitter> neurotransmitters;
  final List<_Factor> factors;
  final String proTip;

  _TestInfo({
    required this.icon,
    required this.subtitle,
    required this.whatItMeasures,
    required this.theScience,
    required this.brainRegions,
    required this.neurotransmitters,
    required this.factors,
    required this.proTip,
  });
}

class _Neurotransmitter {
  final String name;
  final String role;

  _Neurotransmitter({required this.name, required this.role});
}

class _Factor {
  final String description;
  final bool isPositive;

  _Factor(this.description, this.isPositive);
}
