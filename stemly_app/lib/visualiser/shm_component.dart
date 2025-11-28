// lib/visualiser/shm_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SHMComponent extends PositionComponent {
  final double A; // Amplitude (m)
  final double m; // Mass (kg)
  final double k; // Spring constant (N/m)

  double elapsedTime = 0.0;
  late double omega; // Angular frequency
  late double period; // Time period
  
  final List<Offset> graphPoints = [];
  final int maxGraphPoints = 100;
  
  final Paint springPaint = Paint();
  final Paint massPaint = Paint();
  final Paint graphPaint = Paint();
  final Paint axisPaint = Paint();
  final Paint equilibriumPaint = Paint();

  SHMComponent({
    required this.A,
    required this.m,
    required this.k,
    required Vector2 position,
  }) : super(position: position, size: Vector2(400, 400));

  @override
  Future<void> onLoad() async {
    omega = sqrt(k / m);
    period = 2 * pi / omega;
    
    springPaint.color = const Color(0xFF9C27B0);
    springPaint.strokeWidth = 3;
    springPaint.style = PaintingStyle.stroke;
    
    massPaint.color = const Color(0xFF2196F3);
    
    graphPaint.color = const Color(0xFFFF5722);
    graphPaint.strokeWidth = 2;
    graphPaint.style = PaintingStyle.stroke;
    
    axisPaint.color = Colors.black54;
    axisPaint.strokeWidth = 1;
    
    equilibriumPaint.color = const Color(0xFF4CAF50);
    equilibriumPaint.strokeWidth = 2;
    equilibriumPaint.style = PaintingStyle.stroke;
    
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    elapsedTime += dt;
    
    // Add point to graph
    if (graphPoints.length >= maxGraphPoints) {
      graphPoints.removeAt(0);
    }
    graphPoints.add(Offset(elapsedTime, _calculatePosition(elapsedTime)));
    
    // Reset after 2 periods for smooth animation
    if (elapsedTime > period * 4) {
      elapsedTime = 0;
      graphPoints.clear();
    }
  }

  double _calculatePosition(double t) {
    return A * cos(omega * t);
  }

  double _calculateVelocity(double t) {
    return -A * omega * sin(omega * t);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Background gradient
    final bgGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3E5F5), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgGradient);
    
    // Left side: Spring animation
    canvas.save();
    canvas.translate(120, size.y / 2);
    _drawSpringSystem(canvas);
    canvas.restore();
    
    // Right side: Position-time graph
    canvas.save();
    canvas.translate(size.x / 2 + 20, size.y / 2);
    _drawGraph(canvas);
    canvas.restore();
    
    // Draw labels
    _drawLabels(canvas);
  }

  void _drawSpringSystem(Canvas canvas) {
    final currentPos = _calculatePosition(elapsedTime);
    final currentVel = _calculateVelocity(elapsedTime);
    final pixelsPerMeter = 60.0;
    final yOffset = currentPos * pixelsPerMeter;
    
    // Draw ceiling
    final ceilingPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-60, -150, 120, 10), ceilingPaint);
    
    // Ceiling pattern
    for (double x = -60; x < 60; x += 10) {
      canvas.drawLine(
        Offset(x, -150),
        Offset(x + 5, -140),
        Paint()..color = Colors.grey.shade600..strokeWidth = 2,
      );
    }
    
    // Draw equilibrium line
    canvas.drawLine(
      const Offset(-50, 0),
      const Offset(50, 0),
      equilibriumPaint..style = PaintingStyle.stroke,
    );
    
    canvas.save();
    canvas.scale(1, -1);
    _drawText(canvas, 'Equilibrium', -45, 8, fontSize: 9, color: const Color(0xFF4CAF50));
    canvas.restore();
    
    // Draw spring
    _drawSpring(canvas, -140, yOffset, 20);
    
    // Draw mass
    final massWidth = 40.0;
    final massHeight = 30.0;
    final massY = yOffset - massHeight / 2;
    
    // Mass shadow
    canvas.drawRect(
      Rect.fromCenter(center: Offset(3, massY + 3), width: massWidth, height: massHeight),
      Paint()..color = Colors.black.withOpacity(0.2),
    );
    
    // Mass body with gradient
    final massGradient = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF64B5F6),
          const Color(0xFF2196F3),
        ],
      ).createShader(Rect.fromCenter(center: Offset(0, massY), width: massWidth, height: massHeight));
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, massY), width: massWidth, height: massHeight),
        const Radius.circular(4),
      ),
      massGradient,
    );
    
    // Mass border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, massY), width: massWidth, height: massHeight),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Mass label
    canvas.save();
    canvas.scale(1, -1);
    _drawText(canvas, 'm', -5, -massY - 3, color: Colors.white, bold: true);
    canvas.restore();
    
    // Draw velocity arrow if moving
    if (currentVel.abs() > 0.1) {
      _drawVelocityArrow(canvas, Offset(0, massY), currentVel);
    }
    
    // Draw amplitude markers
    _drawAmplitudeMarkers(canvas, pixelsPerMeter);
  }

  void _drawSpring(Canvas canvas, double startY, double endY, double width) {
    final springLength = (endY - startY).abs();
    final  coils = 12;
    final coilHeight = springLength / coils;
    
    final path = Path();
    path.moveTo(0, startY);
    
    for (int i = 0; i < coils; i++) {
      final y = startY + i * coilHeight;
      path.lineTo(i % 2 == 0 ? width / 2 : -width / 2, y + coilHeight / 2);
      path.lineTo(0, y + coilHeight);
    }
    
    canvas.drawPath(path, springPaint);
  }

  void _drawAmplitudeMarkers(Canvas canvas, double pixelsPerMeter) {
    final markerPaint = Paint()
      ..color = const Color(0xFFFF9800).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Positive amplitude
    canvas.drawLine(
      Offset(-55, A * pixelsPerMeter),
      Offset(55, A * pixelsPerMeter),
      markerPaint,
    );
    
    // Negative amplitude
    canvas.drawLine(
      Offset(-55, -A * pixelsPerMeter),
      Offset(55, -A * pixelsPerMeter),
      markerPaint,
    );
    
    // Labels
    canvas.save();
    canvas.scale(1, -1);
    _drawText(canvas, '+A', 58, -A * pixelsPerMeter - 5, fontSize: 10, color: const Color(0xFFFF9800));
    _drawText(canvas, '-A', 58, A * pixelsPerMeter - 5, fontSize: 10, color: const Color(0xFFFF9800));
    canvas.restore();
  }

  void _drawVelocityArrow(Canvas canvas, Offset position, double velocity) {
    final arrowLength = min(velocity.abs() * 5, 40.0);
    final direction = velocity > 0 ? 1.0 : -1.0;
    
    final arrowPaint = Paint()
      ..color = const Color(0xFF00BCD4)
      ..strokeWidth = 2;
    
    final startY = position.dy;
    final endY = startY + arrowLength * direction;
    
    // Arrow shaft
    canvas.drawLine(
      Offset(position.dx + 30, startY),
      Offset(position.dx + 30, endY),
      arrowPaint,
    );
    
    // Arrow head
    final arrowHead = Path()
      ..moveTo(position.dx + 30, endY)
      ..lineTo(position.dx + 25, endY - 5 * direction)
      ..lineTo(position.dx + 35, endY - 5 * direction)
      ..close();
    
    canvas.drawPath(
      arrowHead,
      Paint()..color = const Color(0xFF00BCD4)..style = PaintingStyle.fill,
    );
    
    // Label
    canvas.save();
    canvas.scale(1, -1);
    _drawText(
      canvas,
      'v',
      position.dx + 40,
      -(startY + endY) / 2 - 5,
      fontSize: 10,
      color: const Color(0xFF00BCD4),
      bold: true,
    );
    canvas.restore();
  }

  void _drawGraph(Canvas canvas) {
    final graphWidth = 140.0;
    final graphHeight = 100.0;
    
    // Graph background
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: graphWidth, height: graphHeight),
      Paint()..color = Colors.white.withOpacity(0.8),
    );
    
    // Graph border
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: graphWidth, height: graphHeight),
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Title
    canvas.save();
    canvas.scale(1, -1);
    _drawText(canvas, 'Position vs Time', -60, graphHeight / 2 + 15, fontSize: 10, bold: true);
    canvas.restore();
    
    // Axes
    canvas.drawLine(
      Offset(-graphWidth / 2, 0),
      Offset(graphWidth / 2, 0),
      axisPaint,
    );
    
    canvas.drawLine(
      Offset(-graphWidth / 2, -graphHeight / 2),
      Offset(-graphWidth / 2, graphHeight / 2),
      axisPaint,
    );
    
    // Plot graph
    if (graphPoints.length > 1) {
      final path = Path();
      final pixelsPerSecond = graphWidth / (period * 2);
      final pixelsPerMeter = 30.0;
      
      for (int i = 0; i < graphPoints.length; i++) {
        final point = graphPoints[i];
        final x = -graphWidth / 2 + (point.dx % (period * 2)) * pixelsPerSecond;
        final y = point.dy * pixelsPerMeter;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, graphPaint);
      
      // Current position marker
      if (graphPoints.isNotEmpty) {
        final lastPoint = graphPoints.last;
        final x = -graphWidth / 2 + (lastPoint.dx % (period * 2)) * pixelsPerSecond;
        final y = lastPoint.dy * pixelsPerMeter;
        
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()..color = const Color(0xFFFF5722)..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawLabels(Canvas canvas) {
    // Parameters box
    final paramsBg = Paint()
      ..color = Colors.white.withOpacity(0.9);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 150, 110),
        const Radius.circular(8),
      ),
      paramsBg,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 150, 110),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Text
    _drawText(canvas, 'Simple Harmonic', 20, 25, bold: true);
    _drawText(canvas, 'Motion', 20, 40, bold: true);
    _drawText(canvas, 'A = ${A.toStringAsFixed(2)} m', 20, 60);
    _drawText(canvas, 'm = ${m.toStringAsFixed(1)} kg', 20, 75);
    _drawText(canvas, 'k = ${k.toStringAsFixed(1)} N/m', 20, 90);
    _drawText(canvas, 'T = ${period.toStringAsFixed(2)} s', 20, 105, color: const Color(0xFF9C27B0));
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      {bool bold = false, double fontSize = 12, Color color = Colors.black87}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
}
