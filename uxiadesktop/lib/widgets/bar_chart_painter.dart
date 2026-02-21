import 'package:flutter/material.dart';
import '../models/tag_stats.dart';

class BarChartPainter extends CustomPainter {
  final List<TagStats> stats;

  BarChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final double spacing = 20.0;
    // Calculamos el ancho de cada barra según el espacio disponible
    final double barWidth =
        (size.width - (spacing * (stats.length + 1))) / stats.length;

    // Buscamos el valor máximo para que la barra más alta llegue al tope
    final int maxCount = stats
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < stats.length; i++) {
      final tag = stats[i];
      paint.color = tag.color;

      // Altura proporcional (dejando 40px para textos)
      double availableHeight = size.height - 40;
      double barHeight = (tag.count / maxCount) * availableHeight;

      double xLeft = spacing + i * (barWidth + spacing);
      double yBottom = size.height - 20; // Margen para el nombre inferior
      double yTop = yBottom - barHeight;

      // Dibujar la barra con bordes redondeados arriba
      Rect rect = Rect.fromLTWH(xLeft, yTop, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );

      // Dibujar Nombre debajo
      _drawText(canvas, tag.name, xLeft, yBottom + 5, barWidth, fontSize: 10);

      // Dibujar Cantidad encima
      _drawText(
        canvas,
        tag.count.toString(),
        xLeft,
        yTop - 20,
        barWidth,
        isBold: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double width, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(minWidth: width, maxWidth: width);
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}
