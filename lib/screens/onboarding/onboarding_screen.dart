import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.psychology_outlined,
      title: 'Welcome to NeuroLab',
      subtitle: 'Your Personal Cognitive Science Laboratory',
      description:
          'Discover how your brain performs under different conditions. Run scientifically-grounded tests, track lifestyle factors, and uncover personalized insights about your mind.',
    ),
    const OnboardingPage(
      icon: Icons.science_outlined,
      title: 'Run Experiments',
      subtitle: 'Be a Scientist of Your Own Mind',
      description:
          'Take validated cognitive tests that measure reaction time, working memory, attention, and executive function. Each test includes explanations of the neuroscience behind it.',
    ),
    const OnboardingPage(
      icon: Icons.insights_outlined,
      title: 'Discover Insights',
      subtitle: 'Personalized to You',
      description:
          'Log lifestyle factors like sleep, caffeine, and exercise. NeuroLab finds correlations and surfaces insights like "Your focus is 23% better after 7+ hours of sleep."',
    ),
    const OnboardingPage(
      icon: Icons.auto_graph_outlined,
      title: 'Self-Experiment',
      subtitle: 'Test Your Hypotheses',
      description:
          'Set up structured experiments with baseline periods and interventions. Does meditation improve your reaction time? Find out with data.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final appState = context.read<AppState>();
    await appState.createUser(name);
    await appState.completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length + 1, // +1 for name input page
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildInfoPage(_pages[index]);
                  }
                  return _buildNameInputPage();
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentTeal,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Let's Get Started",
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _completeOnboarding(),
          ),
          const SizedBox(height: 16),
          Text(
            'Your data stays on your device. We take privacy seriously.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage >= _pages.length;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length + 1,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primaryBlue
                      : AppTheme.surfaceMedium,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentPage > 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: isLastPage ? _completeOnboarding : _nextPage,
                  child: Text(isLastPage ? 'Start Exploring' : 'Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
