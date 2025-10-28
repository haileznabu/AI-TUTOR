import 'package:flutter/material.dart';
import 'dart:math' as math;

class MindMapNode {
  final String id;
  final String label;
  final List<MindMapNode> children;
  final int level;

  MindMapNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.level = 0,
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json, {int level = 0}) {
    return MindMapNode(
      id: json['id'] as String,
      label: json['label'] as String,
      level: level,
      children: (json['children'] as List<dynamic>?)
              ?.map((child) => MindMapNode.fromJson(
                  child as Map<String, dynamic>,
                  level: level + 1))
              .toList() ??
          [],
    );
  }
}

class MindMapWidget extends StatefulWidget {
  final MindMapNode rootNode;

  const MindMapWidget({super.key, required this.rootNode});

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.5,
        maxScale: 2.0,
        child: CustomPaint(
          size: const Size(800, 600),
          painter: MindMapPainter(
            rootNode: widget.rootNode,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final bool isDark;

  MindMapPainter({required this.rootNode, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    _drawNode(canvas, rootNode, centerX, centerY, 0, 360, 120);
  }

  void _drawNode(Canvas canvas, MindMapNode node, double x, double y,
      double startAngle, double endAngle, double radius) {
    final nodeColor = _getColorForLevel(node.level);
    final textColor = isDark ? Colors.white : Colors.black87;

    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = nodeColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(x, y), 40, nodePaint);
    canvas.drawCircle(Offset(x, y), 40, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 70);
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );

    if (node.children.isEmpty) return;

    final angleStep = (endAngle - startAngle) / node.children.length;
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final angle =
          startAngle + angleStep * i + angleStep / 2 - 90;
      final radians = angle * math.pi / 180;

      final childX = x + math.cos(radians) * radius;
      final childY = y + math.sin(radians) * radius;

      final linePaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black87).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(Offset(x, y), Offset(childX, childY), linePaint);

      final childStartAngle = angle - angleStep / 2;
      final childEndAngle = angle + angleStep / 2;
      _drawNode(canvas, child, childX, childY, childStartAngle, childEndAngle,
          radius * 0.8);
    }
  }

  Color _getColorForLevel(int level) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFFf093fb),
      const Color(0xFF4facfe),
      const Color(0xFF00f2fe),
      const Color(0xFF43e97b),
    ];
    return colors[level % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
