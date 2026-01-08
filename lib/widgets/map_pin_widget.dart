import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPinWidget {
  /// Generates a custom map marker with price displayed
  static Future<BitmapDescriptor> createCustomMarker({
    required double price,
    required bool isSelected,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Format price (remove decimals)
    final priceText = 'Rs${price.toInt()}';
    
    // Colors
    final bgColor = backgroundColor ?? const Color(0xFF1E293B);
    final txtColor = textColor ?? Colors.white;
    
    // Dimensions
    const double height = 36.0;
    const double borderRadius = 18.0;
    const double padding = 12.0;
    
    // Calculate text width
    final textPainter = TextPainter(
      text: TextSpan(
        text: priceText,
        style: TextStyle(
          color: txtColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final double width = textPainter.width + (padding * 2);
    
    // Draw shadow (for depth)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.3 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, width, height),
        const Radius.circular(borderRadius),
      ),
      shadowPaint,
    );
    
    // Draw background pill
    final backgroundPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(borderRadius),
      ),
      backgroundPaint,
    );
    
    // Draw border (white border for selected)
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          const Radius.circular(borderRadius),
        ),
        borderPaint,
      );
    }
    
    // Draw text
    textPainter.paint(
      canvas,
      Offset(padding, (height - textPainter.height) / 2),
    );
    
    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width.toInt() + 4, height.toInt() + 4);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
