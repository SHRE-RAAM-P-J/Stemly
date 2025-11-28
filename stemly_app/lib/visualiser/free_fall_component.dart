// lib/visualiser/free_fall_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class FreeFallComponent extends PositionComponent {
  final double h; // Initial height (m)
  final double g; // Gravity (m/s²)

  double elapsedTime = 0.0;
  double totalFallTime = 0.0;
  
  final Paint ballPaint = Paint();
  final Paint shadowPaint = Paint();
  final Paint rulerPaint = Paint();
  final Paint groundPaint = Paint();
  final Paint velocityBarPaint = Paint();
  
  final double pixelsPerMeter = 30.0;

  FreeFallComponent({
    required this.h,
    required this.g,
    required Vector2 position,
  }) : super(position: position, size: Vector2(400, 400));

  @override
  Future<void> onLoad() async {
    // Calculate total fall time
    totalFallTime = sqrt(2 * h / g);
    
    // Initialize paints
    ballPaint.color = const Color(0xFFE91E63);
    shadowPaint.color = Colors.black.withOpacity(0.3);
    shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    rulerPaint.color = Colors.black87;
    rulerPaint.strokeWidth = 2;
    
    groundPaint.color = const Color(0xFF795548);
    
    velocityBarPaint.color = const Color(0xFF2196F3);
    
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    elapsedTime += dt;
    
    // Reset when fall completes (with small bounce delay)
    if (elapsedTime > totalFallTime + 0.5) {
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
    super.render(canvas);
    
    // Background gradient
    final bgGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE1F5FE), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgGradient);
    
    // Transform: origin at bottom center
    canvas.save();
    canvas.translate(size.x / 2, size.y - 60);
    canvas.scale(1, -1);
    
    // Draw ruler on the left
    _drawRuler(canvas);
    
    // Draw ground
    _drawGround(canvas);
    
    // Calculate current state
    final currentHeight = _calculateHeight(elapsedTime);
    final currentVelocity = _calculateVelocity(elapsedTime);
    final displayY = currentHeight * pixelsPerMeter;
    
    // Draw height indicator line
    _drawHeightIndicator(canvas, displayY);
    
    // Draw motion blur if moving fast
    if (currentVelocity > 5) {
      _drawMotionBlur(canvas, displayY, currentVelocity);
    }
    
    // Draw shadow
    final shadowSize = 12 + (h - currentHeight) * 2;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: shadowSize, height: shadowSize / 2),
      shadowPaint,
    );
    
    // Draw ball with gradient
    final ballGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF48FB1),
          const Color(0xFFE91E63),
        ],
      ).createShader(Rect.fromCircle(center: Offset(0, displayY), radius: 12));
    canvas.drawCircle(Offset(0, displayY), 12, ballGradient);
    
    // Ball highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset(-3, displayY + 3), 4, highlightPaint);
    
    // Draw impact effect
    if (elapsedTime > totalFallTime && elapsedTime < totalFallTime + 0.2) {
      _drawImpactEffect(canvas);
    }
    
    canvas.restore();
    
    // Draw velocity meter
    _drawVelocityMeter(canvas, currentVelocity);
    
    // Draw labels
    _drawLabels(canvas, currentHeight, currentVelocity);
  }

  void _drawRuler(Canvas canvas) {
    final rulerX = -80.0;
    final maxHeight = h * pixelsPerMeter;
    
    // Ruler background
    canvas.drawRect(
      Rect.fromLTWH(rulerX - 15, 0, 30, maxHeight + 20),
      Paint()..color = Colors.white.withOpacity(0.8),
    );
    
    // Ruler line
    canvas.drawLine(
      Offset(rulerX, 0),
      Offset(rulerX, maxHeight + 10),
      rulerPaint,
    );
    
    // Tick marks
    for (double m = 0; m <= h; m += 1) {
      final y = m * pixelsPerMeter;
      final tickLength = m % 5 == 0 ? 12.0 : 6.0;
      
      canvas.drawLine(
        Offset(rulerX - tickLength / 2, y),
        Offset(rulerX + tickLength / 2, y),
        rulerPaint..strokeWidth = m % 5 == 0 ? 2 : 1,
      );
      
      // Labels every 5 meters
      if (m % 5 == 0 && m > 0) {
        canvas.save();
        canvas.scale(1, -1);
        _drawText(canvas, '${m.toInt()}m', rulerX - 25, -y - 5, fontSize: 10);
        canvas.restore();
      }
    }
  }

  void _drawGround(Canvas canvas) {
    final groundRect = Rect.fromLTWH(-size.x / 2, -15, size.x, 15);
    canvas.drawRect(groundRect, groundPaint);
    
    // Ground pattern
    final grassPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 2;
    
    for (double x = -size.x / 2; x < size.x / 2; x += 5) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, 4),
        grassPaint,
      );
    }
  }

  void _drawHeightIndicator(Canvas canvas, double y) {
    final indicatorPaint = Paint()
      ..color = const Color(0xFFFF9800).withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Dashed line from ball to ground
    final dashPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 1.5;
    
    for (double dy = 0; dy < y; dy += 10) {
      if ((dy / 10) % 2 == 0) {
        canvas.drawLine(
          Offset(0, dy),
          Offset(0, min(dy + 5, y)),
          dashPaint,
        );
      }
    }
  }

  void _drawMotionBlur(Canvas canvas, double y, double velocity) {
    final blurPaint = Paint()
      ..color = const Color(0xFFE91E63).withOpacity(0.2);
    
    final blurHeight = min(velocity * 2, 30.0);
    for (double i = 0; i < blurHeight; i += 3) {
      canvas.drawCircle(
        Offset(0, y + i),
        12 - i * 0.2,
        blurPaint..color = blurPaint.color.withOpacity(0.3 - i / blurHeight * 0.3),
      );
    }
  }

  void _drawImpactEffect(Canvas canvas) {
    final impactProgress = (elapsedTime - totalFallTime) / 0.2;
    final impactSize = 20 * impactProgress;
    
    final impactPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withOpacity(1 - impactProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        const Offset(0, 0),
        impactSize + i * 8,
        impactPaint..strokeWidth = 3 - i,
      );
    }
  }

  void _drawVelocityMeter(Canvas canvas, double velocity) {
    final meterX = size.x - 80;
    final meterY = 60.0;
    final meterHeight = 200.0;
    final maxVelocity = sqrt(2 * g * h);
    
    // Meter background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY, 50, meterHeight),
        const Radius.circular(25),
      ),
      Paint()..color = Colors.grey.shade200,
    );
    
    // Velocity bar
    final fillHeight = (velocity / maxVelocity) * meterHeight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY + meterHeight - fillHeight, 50, fillHeight),
        const Radius.circular(25),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFFFFEB3B),
            const Color(0xFFFF5722),
          ],
        ).createShader(Rect.fromLTWH(meterX, meterY, 50, meterHeight)),
    );
    
    // Meter border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY, 50, meterHeight),
        const Radius.circular(25),
      ),
      Paint()
        ..color = Colors.black38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Velocity text
    _drawText(
      canvas,
      'v = ${velocity.toStringAsFixed(1)} m/s',
      meterX - 10,
      meterY + meterHeight + 15,
      bold: true,
    );
  }

  void _drawLabels(Canvas canvas, double height, double velocity) {
    // Parameters box
    final paramsBg = Paint()
      ..color = Colors.white.withOpacity(0.9);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 130, 100),
        const Radius.circular(8),
      ),
      paramsBg,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 130, 100),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Text
    _drawText(canvas, 'Free Fall', 20, 25, bold: true);
    _drawText(canvas, 'h₀ = ${h.toStringAsFixed(1)} m', 20, 45);
    _drawText(canvas, 'g = ${g.toStringAsFixed(2)} m/s²', 20, 60);
    _drawText(canvas, 'h = ${height.toStringAsFixed(1)} m', 20, 80, color: const Color(0xFFFF9800));
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      {bool bold = false, double fontSize = 12, Color color = Colors.black87}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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
