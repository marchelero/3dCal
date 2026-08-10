// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Linea de corte de plano: linea punteada de ruptura.
///
/// Separa la hoja de plano de su pie (o del borde de corte),
/// como el corte de guillotina punteado de un recibo. Se usa encima de
/// la barra del total para marcar el momento de arrancar la hoja.
class Perforation extends StatelessWidget {
  const Perforation({
    super.key,
    this.color,
    this.dash = 7,
    this.gap = 5,
    this.thickness = 1.5,
    this.height = 1.5,
    this.margin,
  });

  final Color? color;
  final double dash;
  final double gap;
  final double thickness;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _PerforationPainter(
          color: color ?? scheme.outlineVariant,
          dash: dash,
          gap: gap,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.thickness,
  });

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dash, size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness;
  }
}
