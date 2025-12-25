import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/theme.dart';

/// Brain region identifiers for visualization
enum BrainRegion {
  prefrontalCortex,
  motorCortex,
  parietalLobe,
  temporalLobe,
  occipitalLobe,
  anteriorCingulate,
  basalGanglia,
  cerebellum,
}

extension BrainRegionExtension on BrainRegion {
  String get displayName {
    switch (this) {
      case BrainRegion.prefrontalCortex:
        return 'Prefrontal Cortex';
      case BrainRegion.motorCortex:
        return 'Motor Cortex';
      case BrainRegion.parietalLobe:
        return 'Parietal Lobe';
      case BrainRegion.temporalLobe:
        return 'Temporal Lobe';
      case BrainRegion.occipitalLobe:
        return 'Occipital Lobe';
      case BrainRegion.anteriorCingulate:
        return 'Anterior Cingulate';
      case BrainRegion.basalGanglia:
        return 'Basal Ganglia';
      case BrainRegion.cerebellum:
        return 'Cerebellum';
    }
  }

  String get function {
    switch (this) {
      case BrainRegion.prefrontalCortex:
        return 'Executive function, decision making, working memory';
      case BrainRegion.motorCortex:
        return 'Movement planning and execution';
      case BrainRegion.parietalLobe:
        return 'Spatial processing, attention, sensory integration';
      case BrainRegion.temporalLobe:
        return 'Memory, language, auditory processing';
      case BrainRegion.occipitalLobe:
        return 'Visual processing';
      case BrainRegion.anteriorCingulate:
        return 'Conflict monitoring, error detection, cognitive control';
      case BrainRegion.basalGanglia:
        return 'Motor control, learning, habit formation';
      case BrainRegion.cerebellum:
        return 'Motor coordination, timing, procedural learning';
    }
  }
}

/// Maps cognitive test types to the brain regions they activate
List<BrainRegion> getActivatedRegions(CognitiveTestType testType) {
  switch (testType) {
    case CognitiveTestType.reactionTime:
      return [
        BrainRegion.motorCortex,
        BrainRegion.basalGanglia,
        BrainRegion.prefrontalCortex,
      ];
    case CognitiveTestType.nBack:
      return [
        BrainRegion.prefrontalCortex,
        BrainRegion.parietalLobe,
      ];
    case CognitiveTestType.stroop:
      return [
        BrainRegion.anteriorCingulate,
        BrainRegion.prefrontalCortex,
      ];
    case CognitiveTestType.trailMaking:
      return [
        BrainRegion.prefrontalCortex,
        BrainRegion.parietalLobe,
        BrainRegion.motorCortex,
      ];
    case CognitiveTestType.flanker:
      return [
        BrainRegion.anteriorCingulate,
        BrainRegion.prefrontalCortex,
        BrainRegion.parietalLobe,
      ];
  }
}

/// Interactive brain visualization widget
class BrainVisualization extends StatefulWidget {
  final CognitiveTestType testType;
  final bool animate;
  final double size;

  const BrainVisualization({
    super.key,
    required this.testType,
    this.animate = true,
    this.size = 280,
  });

  @override
  State<BrainVisualization> createState() => _BrainVisualizationState();
}

class _BrainVisualizationState extends State<BrainVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  BrainRegion? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activatedRegions = getActivatedRegions(widget.testType);

    return Column(
      children: [
        // Brain title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.psychology,
              color: AppTheme.accentTeal,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Brain Regions Activated',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Brain visualization
        SizedBox(
          width: widget.size,
          height: widget.size * 0.85,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: BrainPainter(
                  activatedRegions: activatedRegions,
                  selectedRegion: _selectedRegion,
                  pulseValue: _pulseAnimation.value,
                ),
                child: Stack(
                  children: [
                    // Tap targets for each region
                    ..._buildRegionTapTargets(activatedRegions),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Region info
        if (_selectedRegion != null)
          _buildRegionInfo(_selectedRegion!)
        else
          _buildRegionsList(activatedRegions),
      ],
    );
  }

  List<Widget> _buildRegionTapTargets(List<BrainRegion> activatedRegions) {
    return activatedRegions.map((region) {
      final position = _getRegionPosition(region);
      return Positioned(
        left: position.dx * widget.size - 20,
        top: position.dy * widget.size * 0.85 - 20,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedRegion = _selectedRegion == region ? null : region;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }).toList();
  }

  Offset _getRegionPosition(BrainRegion region) {
    switch (region) {
      case BrainRegion.prefrontalCortex:
        return const Offset(0.25, 0.35);
      case BrainRegion.motorCortex:
        return const Offset(0.45, 0.20);
      case BrainRegion.parietalLobe:
        return const Offset(0.55, 0.30);
      case BrainRegion.temporalLobe:
        return const Offset(0.35, 0.60);
      case BrainRegion.occipitalLobe:
        return const Offset(0.78, 0.45);
      case BrainRegion.anteriorCingulate:
        return const Offset(0.38, 0.40);
      case BrainRegion.basalGanglia:
        return const Offset(0.45, 0.50);
      case BrainRegion.cerebellum:
        return const Offset(0.75, 0.70);
    }
  }

  Widget _buildRegionInfo(BrainRegion region) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                region.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedRegion = null),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            region.function,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionsList(List<BrainRegion> regions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: regions.map((region) {
        return GestureDetector(
          onTap: () => setState(() => _selectedRegion = region),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Text(
              region.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom painter for the brain visualization
class BrainPainter extends CustomPainter {
  final List<BrainRegion> activatedRegions;
  final BrainRegion? selectedRegion;
  final double pulseValue;

  BrainPainter({
    required this.activatedRegions,
    this.selectedRegion,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw brain outline (side view)
    _drawBrainOutline(canvas, size, paint);

    // Draw and highlight regions
    _drawBrainRegions(canvas, size);
  }

  void _drawBrainOutline(Canvas canvas, Size size, Paint paint) {
    paint.color = AppTheme.surfaceMedium;

    final path = Path();

    // Brain outline - simplified side view
    path.moveTo(size.width * 0.15, size.height * 0.50);

    // Frontal curve
    path.quadraticBezierTo(
      size.width * 0.10, size.height * 0.25,
      size.width * 0.30, size.height * 0.15,
    );

    // Top of brain
    path.quadraticBezierTo(
      size.width * 0.50, size.height * 0.05,
      size.width * 0.70, size.height * 0.20,
    );

    // Back of brain
    path.quadraticBezierTo(
      size.width * 0.90, size.height * 0.35,
      size.width * 0.85, size.height * 0.55,
    );

    // Cerebellum bump
    path.quadraticBezierTo(
      size.width * 0.82, size.height * 0.75,
      size.width * 0.70, size.height * 0.80,
    );

    // Bottom
    path.quadraticBezierTo(
      size.width * 0.50, size.height * 0.85,
      size.width * 0.30, size.height * 0.75,
    );

    // Brain stem area
    path.quadraticBezierTo(
      size.width * 0.20, size.height * 0.65,
      size.width * 0.15, size.height * 0.50,
    );

    canvas.drawPath(path, paint);

    // Draw some internal structure lines for detail
    paint.strokeWidth = 1;
    paint.color = AppTheme.surfaceMedium.withValues(alpha: 0.5);

    // Central sulcus (divides frontal and parietal)
    final centralSulcus = Path();
    centralSulcus.moveTo(size.width * 0.48, size.height * 0.10);
    centralSulcus.quadraticBezierTo(
      size.width * 0.50, size.height * 0.35,
      size.width * 0.45, size.height * 0.55,
    );
    canvas.drawPath(centralSulcus, paint);

    // Lateral fissure (divides temporal)
    final lateralFissure = Path();
    lateralFissure.moveTo(size.width * 0.25, size.height * 0.50);
    lateralFissure.quadraticBezierTo(
      size.width * 0.45, size.height * 0.55,
      size.width * 0.65, size.height * 0.45,
    );
    canvas.drawPath(lateralFissure, paint);
  }

  void _drawBrainRegions(Canvas canvas, Size size) {
    for (final region in BrainRegion.values) {
      final isActivated = activatedRegions.contains(region);
      final isSelected = selectedRegion == region;

      if (isActivated) {
        _drawRegion(canvas, size, region, isSelected);
      }
    }
  }

  void _drawRegion(Canvas canvas, Size size, BrainRegion region, bool isSelected) {
    final position = _getRegionCenter(region, size);
    final regionSize = _getRegionSize(region, size);

    // Calculate pulse effect
    final pulseScale = isSelected ? 1.0 : (0.85 + pulseValue * 0.15);
    final opacity = isSelected ? 0.8 : (0.4 + pulseValue * 0.3);

    final paint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Draw glow effect
    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: opacity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: regionSize.width * pulseScale * 1.5,
        height: regionSize.height * pulseScale * 1.5,
      ),
      glowPaint,
    );

    // Draw the region
    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: regionSize.width * pulseScale,
        height: regionSize.height * pulseScale,
      ),
      paint,
    );

    // Draw border for selected region
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawOval(
        Rect.fromCenter(
          center: position,
          width: regionSize.width * pulseScale,
          height: regionSize.height * pulseScale,
        ),
        borderPaint,
      );
    }
  }

  Offset _getRegionCenter(BrainRegion region, Size size) {
    switch (region) {
      case BrainRegion.prefrontalCortex:
        return Offset(size.width * 0.25, size.height * 0.35);
      case BrainRegion.motorCortex:
        return Offset(size.width * 0.45, size.height * 0.20);
      case BrainRegion.parietalLobe:
        return Offset(size.width * 0.58, size.height * 0.28);
      case BrainRegion.temporalLobe:
        return Offset(size.width * 0.38, size.height * 0.62);
      case BrainRegion.occipitalLobe:
        return Offset(size.width * 0.78, size.height * 0.42);
      case BrainRegion.anteriorCingulate:
        return Offset(size.width * 0.38, size.height * 0.38);
      case BrainRegion.basalGanglia:
        return Offset(size.width * 0.45, size.height * 0.48);
      case BrainRegion.cerebellum:
        return Offset(size.width * 0.75, size.height * 0.72);
    }
  }

  Size _getRegionSize(BrainRegion region, Size size) {
    switch (region) {
      case BrainRegion.prefrontalCortex:
        return Size(size.width * 0.22, size.height * 0.25);
      case BrainRegion.motorCortex:
        return Size(size.width * 0.12, size.height * 0.15);
      case BrainRegion.parietalLobe:
        return Size(size.width * 0.18, size.height * 0.20);
      case BrainRegion.temporalLobe:
        return Size(size.width * 0.20, size.height * 0.18);
      case BrainRegion.occipitalLobe:
        return Size(size.width * 0.14, size.height * 0.18);
      case BrainRegion.anteriorCingulate:
        return Size(size.width * 0.10, size.height * 0.12);
      case BrainRegion.basalGanglia:
        return Size(size.width * 0.10, size.height * 0.10);
      case BrainRegion.cerebellum:
        return Size(size.width * 0.16, size.height * 0.16);
    }
  }

  @override
  bool shouldRepaint(covariant BrainPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedRegion != selectedRegion ||
        oldDelegate.activatedRegions != activatedRegions;
  }
}

/// A compact brain card widget for showing in result screens
class BrainActivationCard extends StatelessWidget {
  final CognitiveTestType testType;

  const BrainActivationCard({
    super.key,
    required this.testType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BrainVisualization(
        testType: testType,
        size: MediaQuery.of(context).size.width - 80,
      ),
    );
  }
}
