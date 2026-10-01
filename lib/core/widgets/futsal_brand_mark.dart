import 'package:flutter/material.dart';

class FutsalBrandMark extends StatelessWidget {
  const FutsalBrandMark({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width * 0.72,
            height: width * 0.48,
            child: const CustomPaint(painter: _FutsalMarkPainter()),
          ),
          const SizedBox(height: 8),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(
                  text: 'Futsal',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Go',
                  style: TextStyle(color: Color(0xFF00D47A)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FutsalSplashBackdrop extends StatelessWidget {
  const FutsalSplashBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SplashBackdropPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class _FutsalMarkPainter extends CustomPainter {
  const _FutsalMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 108);
    final green = Paint()
      ..color = const Color(0xFF00D47A)
      ..style = PaintingStyle.fill;
    final white = Paint()
      ..color = const Color(0xFFF7FAF8)
      ..style = PaintingStyle.fill;
    final dark = Paint()
      ..color = const Color(0xFF05090A)
      ..style = PaintingStyle.fill;

    for (var index = 0; index < 3; index++) {
      final y = 31.0 + index * 11;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4 + index * 3, y, 30 - index * 5, 6),
          const Radius.circular(3),
        ),
        green,
      );
    }

    final fMark = Path()
      ..moveTo(25, 85)
      ..lineTo(61, 16)
      ..quadraticBezierTo(66, 7, 77, 7)
      ..lineTo(147, 7)
      ..lineTo(128, 24)
      ..lineTo(83, 24)
      ..lineTo(75, 39)
      ..lineTo(116, 39)
      ..lineTo(98, 56)
      ..lineTo(66, 56)
      ..lineTo(51, 85)
      ..close();
    canvas.drawPath(fMark, white);

    const center = Offset(119, 65);
    canvas.drawCircle(center, 34, dark);
    canvas.drawCircle(
      center,
      32,
      Paint()
        ..color = const Color(0xFF00D47A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(center, 25, white);

    final pentagon = Path()
      ..moveTo(119, 52)
      ..lineTo(131, 60)
      ..lineTo(126, 74)
      ..lineTo(112, 74)
      ..lineTo(107, 60)
      ..close();
    canvas.drawPath(pentagon, dark);

    final panels = Paint()
      ..color = const Color(0xFF05090A)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(107, 60), const Offset(99, 57), panels);
    canvas.drawLine(const Offset(131, 60), const Offset(139, 56), panels);
    canvas.drawLine(const Offset(112, 74), const Offset(108, 84), panels);
    canvas.drawLine(const Offset(126, 74), const Offset(132, 83), panels);
    canvas.drawLine(const Offset(119, 52), const Offset(119, 40), panels);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashBackdropPainter extends CustomPainter {
  const _SplashBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF030708), BlendMode.src);
    final bright = Paint()..color = const Color(0xFF00D47A);
    final middle = Paint()..color = const Color(0xFF087A4D);
    final soft = Paint()..color = const Color(0xFF063B2A);

    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.48, 0)
      ..lineTo(size.width * 0.24, size.height * 0.13)
      ..lineTo(0, size.height * 0.13)
      ..close();
    canvas.drawPath(top, soft);
    final topStripe = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.27, 0)
      ..lineTo(size.width * 0.10, size.height * 0.10)
      ..lineTo(0, size.height * 0.10)
      ..close();
    canvas.drawPath(topStripe, bright);
    final secondTop = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.07, size.height * 0.14)
      ..lineTo(0, size.height * 0.14)
      ..close();
    canvas.drawPath(secondTop, middle);

    final bottom = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.86)
      ..lineTo(size.width, size.height * 0.86)
      ..close();
    canvas.drawPath(bottom, soft);
    final bottomStripe = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.73, size.height)
      ..lineTo(size.width * 0.90, size.height * 0.90)
      ..lineTo(size.width, size.height * 0.90)
      ..close();
    canvas.drawPath(bottomStripe, bright);
    final secondBottom = Path()
      ..moveTo(size.width * 0.88, size.height)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 0.93, size.height * 0.86)
      ..lineTo(size.width, size.height * 0.86)
      ..close();
    canvas.drawPath(secondBottom, middle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
