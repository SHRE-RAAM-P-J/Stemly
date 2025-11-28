// lib/visualiser/shm_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SHMGame extends FlameGame {
  final double A;
  final double m;
  final double k;
  
  SHMGame({required this.A, required this.m, required this.k});
  
  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);
  
  @override
  Future<void> onLoad() async {
    await add(SHMVisualizer(A: A, m: m, k: k));
  }
}

class SHMVisualizer extends Component with HasGameRef {
  final double A;
  final double m;
  final double k;
  
  double elapsedTime = 0.0;
  late double omega;
  late double period;
  final List<Offset> graphPoints = [];
  
  SHMVisualizer({required this.A, required this.m, required this.k});
  
  @override
  Future<void> onLoad() async {
    omega = sqrt(k / m);
    period = 2 * pi / omega;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    elapsedTime += dt;
    
    if (elapsedTime > period * 3) {
      elapsedTime = 0;
      graphPoints.clear();
    }
    
    // Add graph point
    if (graphPoints.isEmpty || elapsedTime - graphPoints.last.dx > 0.05) {
      graphPoints.add(Offset(elapsedTime, _calculatePosition(elapsedTime)));
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
    final size = gameRef.size;
    
    // Split screen: left for spring, right for graph
    final splitX = size.x * 0.5;
    
    // Draw spring system on left
    canvas.save();
    _drawSpringSystem(canvas, Vector2(splitX / 2, size.y / 2));
    canvas.restore();
    
    // Draw graph on right
    canvas.save();
    canvas.translate(splitX, 0);
    _drawGraph(canvas, Vector2(size.x - splitX, size.y));
    canvas.restore();
    
    // Draw info panel
    _drawInfoPanel(canvas);
  }
  
  void _drawSpringSystem(Canvas canvas, Vector2 center) {
    final currentPos = _calculatePosition(elapsedTime);
    final currentVel = _calculateVelocity(elapsedTime);
    final scale = 60.0;
    
    // Draw ceiling
    final ceilingY = center.y - 180;
    canvas.drawRect(
      Rect.fromLTWH(center.x - 60, ceilingY - 10, 120, 10),
      Paint()..color = Colors.grey.shade400,
    );
    
    // Ceiling pattern
    for (double x = -60; x < 60; x += 10) {
      canvas.drawLine(
        Offset(center.x + x, ceilingY),
        Offset(center.x + x + 5, ceilingY - 10),
        Paint()..color = Colors.grey.shade600..strokeWidth = 2,
      );
    }
    
    // Draw equilibrium line
    canvas.drawLine(
      Offset(center.x - 70, center.y),
      Offset(center.x + 70, center.y),
      Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 2..style = PaintingStyle.stroke,
    );
    
    _drawText(canvas, 'Equilibrium', center.x - 35, center.y + 5, size: 10, color: const Color(0xFF4CAF50));
    
    // Draw amplitude markers
    canvas.drawLine(
      Offset(center.x - 70, center.y + A * scale),
      Offset(center.x + 70, center.y + A * scale),
      Paint()..color = const Color(0xFFFF9800).withOpacity(0.6)..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(center.x - 70, center.y - A * scale),
      Offset(center.x + 70, center.y - A * scale),
      Paint()..color = const Color(0xFFFF9800).withOpacity(0.6)..strokeWidth = 1.5,
    );
    
    _drawText(canvas, '+A', center.x + 75, center.y - A * scale - 5, size: 10, color: const Color(0xFFFF9800));
    _drawText(canvas, '-A', center.x + 75, center.y + A * scale - 5, size: 10, color: const Color(0xFFFF9800));
    
    // Draw spring
    final massY = center.y + currentPos * scale;
    _drawSpring(canvas, center.x, ceilingY, massY - 20, 20);
    
    // Draw mass
    final massWidth = 50.0;
    final massHeight = 40.0;
    
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.x + 3, massY + 3), width: massWidth, height: massHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    
    // Mass gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.x, massY), width: massWidth, height: massHeight),
        const Radius.circular(4),
      ),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
      ).createShader(Rect.fromCenter(center: Offset(center.x, massY), width: massWidth, height: massHeight)),
    );
    
    // Mass border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.x, massY), width: massWidth, height: massHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    _drawText(canvas, 'm', center.x - 6, massY - 6, color: Colors.white, bold: true);
    
    // Velocity arrow
    if (currentVel.abs() > 0.1) {
      _drawVelocityArrow(canvas, center.x + 40, massY, currentVel * 3);
    }
  }
  
  void _drawSpring(Canvas canvas, double x, double startY, double endY, double width) {
    final coils = 10;
    final coilHeight = (endY - startY) / coils;
    
    final path = Path();
    path.moveTo(x, startY);
    
    for (int i = 0; i < coils; i++) {
      final y = startY + i * coilHeight;
      path.lineTo(i % 2 == 0 ? x + width / 2 : x - width / 2, y + coilHeight / 2);
      path.lineTo(x, y + coilHeight);
    }
    
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF9C27B0)..strokeWidth = 3..style = PaintingStyle.stroke,
    );
  }
  
  void _drawVelocityArrow(Canvas canvas, double x, double y, double velocity) {
    final length = min(velocity.abs() * 5, 50.0);
    final direction = velocity > 0 ? 1.0 : -1.0;
    
    // Arrow line
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + length * direction),
      Paint()..color = const Color(0xFF00BCD4)..strokeWidth = 2,
    );
    
    // Arrow head
    final arrowHead = Path()
      ..moveTo(x, y + length * direction)
      ..lineTo(x - 5, y + (length - 8) * direction)
      ..lineTo(x + 5, y + (length - 8) * direction)
      ..close();
    
    canvas.drawPath(arrowHead, Paint()..color = const Color(0xFF00BCD4));
    
    _drawText(canvas, 'v', x + 10, y + length * direction / 2 - 5, 
        size: 11, color: const Color(0xFF00BCD4), bold: true);
  }
  
  void _drawGraph(Canvas canvas, Vector2 size) {
    final graphWidth = size.x - 40;
    final graphHeight = size.y * 0.4;
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // Background
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY), width: graphWidth, height: graphHeight),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    
    // Border
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY), width: graphWidth, height: graphHeight),
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    // Title
    _drawText(canvas, 'Position vs Time', centerX - 60, centerY - graphHeight / 2 - 25, 
        size: 14, bold: true, color: const Color(0xFF1976D2));
    
    // Axes
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.x - 20, centerY),
      Paint()..color = Colors.black54..strokeWidth = 1,
    );
    
    canvas.drawLine(
      Offset(20, centerY - graphHeight / 2),
      Offset(20, centerY + graphHeight / 2),
      Paint()..color = Colors.black54..strokeWidth = 1,
    );
    
    // Plot graph
    if (graphPoints.length > 1) {
      final path = Path();
      final timeScale = graphWidth / (period * 2);
      final posScale = (graphHeight / 2) / A * 0.8;
      
      for (int i = 0; i < graphPoints.length; i++) {
        final point = graphPoints[i];
        final x = 20 + (point.dx % (period * 2)) * timeScale;
        final y = centerY - point.dy * posScale;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFFFF5722)..strokeWidth = 2..style = PaintingStyle.stroke,
      );
      
      // Current point marker
      if (graphPoints.isNotEmpty) {
        final last = graphPoints.last;
        final x = 20 + (last.dx % (period * 2)) * timeScale;
        final y = centerY - last.dy * posScale;
        
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = const Color(0xFFFF5722));
      }
    }
  }
  
  void _drawInfoPanel(Canvas canvas) {
    final panelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 10, 180, 140),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(panelRect, Paint()..color = Colors.white.withOpacity(0.95));
    canvas.drawRRect(
      panelRect,
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    _drawText(canvas, 'Simple Harmonic', 20, 30, size: 15, bold: true, color: const Color(0xFF1976D2));
    _drawText(canvas, 'Motion', 20, 48, size: 15, bold: true, color: const Color(0xFF1976D2));
    _drawText(canvas, 'Amplitude: ${A.toStringAsFixed(2)} m', 20, 72, size: 13);
    _drawText(canvas, 'Mass: ${m.toStringAsFixed(1)} kg', 20, 90, size: 13);
    _drawText(canvas, 'Spring k: ${k.toStringAsFixed(1)} N/m', 20, 108, size: 13);
    _drawText(canvas, 'Period: ${period.toStringAsFixed(2)} s', 20, 126, size: 13, 
        color: const Color(0xFF9C27B0), bold: true);
  }
  
  void _drawText(Canvas canvas, String text, double x, double y,
      {double size = 12, bool bold = false, Color color = Colors.black87}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
}
