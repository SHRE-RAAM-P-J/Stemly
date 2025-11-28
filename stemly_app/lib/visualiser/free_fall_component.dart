// lib/visualiser/free_fall_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class FreeFallGame extends FlameGame {
  final double h;
  final double g;
  
  FreeFallGame({required this.h, required this.g});
  
  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);
  
  @override
  Future<void> onLoad() async {
    await add(FreeFallVisualizer(h: h, g: g));
  }
}

class FreeFallVisualizer extends Component with HasGameRef {
  final double h;
  final double g;
  
  double elapsedTime = 0.0;
  double totalFallTime = 0.0;
  
  FreeFallVisualizer({required this.h, required this.g});
  
  @override
  Future<void> onLoad() async {
    totalFallTime = sqrt(2 * h / g);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    elapsedTime += dt;
    
    if (elapsedTime > totalFallTime + 1.5) {
      elapsedTime = 0.0;
    }
  }
  
  double _calculateHeight(double t) {
    if (t > totalFallTime) return 0;
    return h - 0.5 * g * t * t;
  }
  
  double _calculateVelocity(double t) {
    if (t > totalFallTime) return 0;
    return g * t;
  }
  
  @override
  void render(Canvas canvas) {
    final size = gameRef.size;
    
    // Calculate scale
    final marginY = size.y * 0.15;
    final scale = (size.y - 2 * marginY) / h;
    
    final centerX = size.x / 2;
    final groundY = size.y - marginY;
    
    // Draw background
    final bgGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgGradient);
    
    // Draw ruler
    _drawRuler(canvas, centerX - 120, groundY, scale, h);
    
    // Draw ground
    _drawGround(canvas, size, groundY);
    
    // Calculate current state
    final currentHeight = _calculateHeight(elapsedTime);
    final currentVelocity = _calculateVelocity(elapsedTime);
    final ballY = groundY - currentHeight * scale;
    
    // Draw height indicator
    if (currentHeight > 0) {
      _drawHeightLine(canvas, centerX, groundY, ballY);
    }
    
    // Draw ball
    _drawBall(canvas, centerX, ballY, groundY, currentVelocity);
    
    // Draw velocity meter
    _drawVelocityMeter(canvas, size, currentVelocity, sqrt(2 * g * h));
    
    // Draw info panel
    _drawInfoPanel(canvas, currentHeight, currentVelocity);
    
    // Draw impact effect
    if (elapsedTime > totalFallTime && elapsedTime < totalFallTime + 0.3) {
      _drawImpact(canvas, centerX, groundY, (elapsedTime - totalFallTime) / 0.3);
    }
  }
  
  void _drawRuler(Canvas canvas, double x, double groundY, double scale, double maxHeight) {
    // Ruler background
    canvas.drawRect(
      Rect.fromLTWH(x - 15, groundY - maxHeight * scale - 20, 50, maxHeight * scale + 40),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    
    // Ruler line
    canvas.drawLine(
      Offset(x, groundY),
      Offset(x, groundY - maxHeight * scale),
      Paint()..color = Colors.black87..strokeWidth = 2,
    );
    
    // Tick marks
    final step = maxHeight > 30 ? 10.0 : maxHeight > 10 ? 5.0 : 1.0;
    for (double m = 0; m <= maxHeight; m += step) {
      final y = groundY - m * scale;
      final tickLength = m % (step * 2) == 0 ? 12.0 : 6.0;
      
      canvas.drawLine(
        Offset(x - tickLength / 2, y),
        Offset(x + tickLength / 2, y),
        Paint()..color = Colors.black87..strokeWidth = 2,
      );
      
      if (m % (step * 2) == 0 && m > 0) {
        _drawText(canvas, '${m.toInt()}m', x + 20, y - 8, size: 12);
      }
    }
  }
  
  void _drawGround(Canvas canvas, Vector2 size, double groundY) {
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, size.y - groundY),
      Paint()..color = const Color(0xFF8BC34A),
    );
  }
  
  void _drawHeightLine(Canvas canvas, double centerX, double groundY, double ballY) {
    final dashPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 2;
    
    for (double y = groundY; y > ballY; y -= 10) {
      if (((groundY - y) / 10) % 2 == 0) {
        canvas.drawLine(
          Offset(centerX, y),
          Offset(centerX, max(y - 5, ballY)),
          dashPaint,
        );
      }
    }
  }
  
  void _drawBall(Canvas canvas, double x, double y, double groundY, double velocity) {
    // Shadow
    final shadowSize = 15 + (groundY - y) * 0.05;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, groundY), width: shadowSize, height: shadowSize / 2),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    
    // Motion blur
    if (velocity > 5) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawCircle(
          Offset(x, y + i * 8),
          15 - i * 2,
          Paint()..color = const Color(0xFFE91E63).withOpacity(0.2 - i * 0.05),
        );
      }
    }
    
    // Ball gradient
    final gradient = RadialGradient(
      colors: [const Color(0xFFF48FB1), const Color(0xFFE91E63)],
    );
    canvas.drawCircle(
      Offset(x, y),
      15,
      Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset(x, y), radius: 15)),
    );
    
    // Highlight
    canvas.drawCircle(
      Offset(x - 4, y - 4),
      5,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }
  
  void _drawVelocityMeter(Canvas canvas, Vector2 size, double velocity, double maxVelocity) {
    final meterX = size.x - 80;
    final meterY = 60.0;
    final meterHeight = 200.0;
    
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY, 50, meterHeight),
        const Radius.circular(25),
      ),
      Paint()..color = Colors.grey.shade200,
    );
    
    // Fill
    final fillHeight = min((velocity / maxVelocity) * meterHeight, meterHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY + meterHeight - fillHeight, 50, fillHeight),
        const Radius.circular(25),
      ),
      Paint()..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFFFF5722)],
      ).createShader(Rect.fromLTWH(meterX, meterY, 50, meterHeight)),
    );
    
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY, 50, meterHeight),
        const Radius.circular(25),
      ),
      Paint()..color = Colors.black38..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    _drawText(canvas, 'Velocity', meterX - 5, meterY - 20, size: 12, bold: true);
    _drawText(canvas, '${velocity.toStringAsFixed(1)} m/s', meterX - 15, meterY + meterHeight + 15, 
        size: 13, bold: true, color: const Color(0xFF2196F3));
  }
  
  void _drawImpact(Canvas canvas, double x, double groundY, double progress) {
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(x, groundY),
        20 * progress + i * 10,
        Paint()
          ..color = const Color(0xFFFFEB3B).withOpacity((1 - progress) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - i,
      );
    }
  }
  
  void _drawInfoPanel(Canvas canvas, double height, double velocity) {
    final panelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 10, 180, 130),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(panelRect, Paint()..color = Colors.white.withOpacity(0.95));
    canvas.drawRRect(
      panelRect,
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    _drawText(canvas, 'Free Fall', 20, 30, size: 16, bold: true, color: const Color(0xFF1976D2));
    _drawText(canvas, 'Initial Height: ${h.toStringAsFixed(1)} m', 20, 55, size: 13);
    _drawText(canvas, 'Gravity: ${g.toStringAsFixed(2)} m/s²', 20, 75, size: 13);
    _drawText(canvas, 'Current Height:', 20, 95, size: 13, color: const Color(0xFFFF9800), bold: true);
    _drawText(canvas, '${height.toStringAsFixed(1)} m', 20, 115, size: 14, color: const Color(0xFFFF9800), bold: true);
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
