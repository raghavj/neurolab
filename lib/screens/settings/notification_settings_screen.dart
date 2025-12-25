import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyTestReminder = true;
  bool _lifestyleLogReminder = true;
  bool _experimentReminder = true;
  bool _weeklyInsights = true;
  TimeOfDay _testReminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _logReminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _dailyTestReminder = prefs.getBool('dailyTestReminder') ?? true;
      _lifestyleLogReminder = prefs.getBool('lifestyleLogReminder') ?? true;
      _experimentReminder = prefs.getBool('experimentReminder') ?? true;
      _weeklyInsights = prefs.getBool('weeklyInsights') ?? true;

      final testHour = prefs.getInt('testReminderHour') ?? 9;
      final testMinute = prefs.getInt('testReminderMinute') ?? 0;
      _testReminderTime = TimeOfDay(hour: testHour, minute: testMinute);

      final logHour = prefs.getInt('logReminderHour') ?? 21;
      final logMinute = prefs.getInt('logReminderMinute') ?? 0;
      _logReminderTime = TimeOfDay(hour: logHour, minute: logMinute);

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dailyTestReminder', _dailyTestReminder);
    await prefs.setBool('lifestyleLogReminder', _lifestyleLogReminder);
    await prefs.setBool('experimentReminder', _experimentReminder);
    await prefs.setBool('weeklyInsights', _weeklyInsights);
    await prefs.setInt('testReminderHour', _testReminderTime.hour);
    await prefs.setInt('testReminderMinute', _testReminderTime.minute);
    await prefs.setInt('logReminderHour', _logReminderTime.hour);
    await prefs.setInt('logReminderMinute', _logReminderTime.minute);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      Icons.notifications_active_outlined,
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
                          'Stay Consistent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reminders help build lasting habits',
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
            const SizedBox(height: 32),

            // Daily Reminders Section
            Text(
              'Daily Reminders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _NotificationTile(
              title: 'Cognitive Test Reminder',
              description: 'Daily reminder to complete a test',
              icon: Icons.psychology_outlined,
              isEnabled: _dailyTestReminder,
              onChanged: (value) {
                setState(() => _dailyTestReminder = value);
              },
              trailing: _dailyTestReminder
                  ? _TimeButton(
                      time: _testReminderTime,
                      onTap: () => _selectTime(true),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            _NotificationTile(
              title: 'Lifestyle Log Reminder',
              description: 'Evening reminder to log your day',
              icon: Icons.edit_note,
              isEnabled: _lifestyleLogReminder,
              onChanged: (value) {
                setState(() => _lifestyleLogReminder = value);
              },
              trailing: _lifestyleLogReminder
                  ? _TimeButton(
                      time: _logReminderTime,
                      onTap: () => _selectTime(false),
                    )
                  : null,
            ),
            const SizedBox(height: 24),

            // Other Notifications Section
            Text(
              'Other Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _NotificationTile(
              title: 'Experiment Reminders',
              description: 'Reminders during active experiments',
              icon: Icons.science_outlined,
              isEnabled: _experimentReminder,
              onChanged: (value) {
                setState(() => _experimentReminder = value);
              },
            ),
            const SizedBox(height: 12),

            _NotificationTile(
              title: 'Weekly Insights',
              description: 'Summary of your cognitive trends',
              icon: Icons.insights_outlined,
              isEnabled: _weeklyInsights,
              onChanged: (value) {
                setState(() => _weeklyInsights = value);
              },
            ),
            const SizedBox(height: 32),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.accentTeal,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pro Tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                    'Test at the same time daily for consistent baseline data',
                  ),
                  const SizedBox(height: 8),
                  _buildTip(
                    'Log your lifestyle before bed for best accuracy',
                  ),
                  const SizedBox(height: 8),
                  _buildTip(
                    'Consistency matters more than frequency',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(bool isTestReminder) async {
    final initialTime =
        isTestReminder ? _testReminderTime : _logReminderTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.background,
              hourMinuteColor: AppTheme.surfaceLight,
              dialBackgroundColor: AppTheme.surfaceLight,
              dayPeriodColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isTestReminder) {
          _testReminderTime = picked;
        } else {
          _logReminderTime = picked;
        }
      });
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  const _NotificationTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: isEnabled
            ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                      : AppTheme.surfaceMedium,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppTheme.primaryBlue : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: onChanged,
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          if (trailing != null && isEnabled) ...[
            const Divider(height: 24),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.access_time,
            color: AppTheme.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Remind at ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$hour:$minute $period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.edit,
            color: AppTheme.textMuted,
            size: 16,
          ),
        ],
      ),
    );
  }
}
