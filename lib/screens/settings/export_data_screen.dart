import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/export_service.dart';
import '../../utils/theme.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  String? _selectedDataType;
  ExportFormat _selectedFormat = ExportFormat.json;

  final List<Map<String, dynamic>> _dataTypes = [
    {
      'id': 'all',
      'title': 'All Data',
      'description': 'Complete export of all your data',
      'icon': Icons.folder_copy_outlined,
    },
    {
      'id': 'tests',
      'title': 'Test Results',
      'description': 'All cognitive test scores and metrics',
      'icon': Icons.psychology_outlined,
    },
    {
      'id': 'lifestyle',
      'title': 'Lifestyle Logs',
      'description': 'Sleep, caffeine, exercise, and mood data',
      'icon': Icons.edit_note,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.transparent,
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
                      Icons.download_outlined,
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
                          'Your Data, Your Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Export your cognitive data anytime',
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

            // Data type selection
            Text(
              'What to Export',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._dataTypes.map((dataType) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DataTypeCard(
                    title: dataType['title'] as String,
                    description: dataType['description'] as String,
                    icon: dataType['icon'] as IconData,
                    isSelected: _selectedDataType == dataType['id'],
                    onTap: () {
                      setState(() {
                        _selectedDataType = dataType['id'] as String;
                      });
                    },
                  ),
                )),
            const SizedBox(height: 24),

            // Format selection
            Text(
              'Format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FormatOption(
                    title: 'JSON',
                    description: 'Structured data',
                    isSelected: _selectedFormat == ExportFormat.json,
                    onTap: () {
                      setState(() {
                        _selectedFormat = ExportFormat.json;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatOption(
                    title: 'CSV',
                    description: 'Spreadsheet friendly',
                    isSelected: _selectedFormat == ExportFormat.csv,
                    onTap: () {
                      setState(() {
                        _selectedFormat = ExportFormat.csv;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedFormat == ExportFormat.csv && _selectedDataType == 'all')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CSV format will export test results only. Use JSON for complete data.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDataType == null || _isExporting
                    ? null
                    : _handleExport,
                child: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Export & Share'),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.accentTeal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your data stays on your device and is only shared when you choose to export.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    if (_selectedDataType == null) return;

    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    setState(() => _isExporting = true);

    try {
      String content;
      String filename;
      final timestamp = DateTime.now().toIso8601String().split('T')[0];

      switch (_selectedDataType) {
        case 'all':
          content = await _exportService.exportAll(
            appState.currentUser!.id,
            _selectedFormat,
          );
          filename = 'neurolab_export_$timestamp.${_selectedFormat == ExportFormat.json ? 'json' : 'csv'}';
          break;
        case 'tests':
          content = await _exportService.exportTestResults(
            appState.currentUser!.id,
            _selectedFormat,
          );
          filename = 'neurolab_tests_$timestamp.${_selectedFormat == ExportFormat.json ? 'json' : 'csv'}';
          break;
        case 'lifestyle':
          content = await _exportService.exportLifestyleLogs(
            appState.currentUser!.id,
            _selectedFormat,
          );
          filename = 'neurolab_lifestyle_$timestamp.${_selectedFormat == ExportFormat.json ? 'json' : 'csv'}';
          break;
        default:
          return;
      }

      await _exportService.shareExport(content, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export ready for sharing'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _DataTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DataTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                    : AppTheme.surfaceMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textPrimary,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
