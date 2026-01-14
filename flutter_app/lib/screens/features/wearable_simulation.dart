import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WearableSimulationScreen extends StatefulWidget {
  const WearableSimulationScreen({super.key});

  @override
  State<WearableSimulationScreen> createState() =>
      _WearableSimulationScreenState();
}

class _WearableSimulationScreenState extends State<WearableSimulationScreen> {
  Timer? _timer;
  final List<double> _heartRates = List.filled(30, 70.0); // Keep last 30 points
  int _currentHeartRate = 72;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        // Random fluctuation between 60 and 100
        double newRate = 60 + _random.nextInt(40).toDouble();
        _currentHeartRate = newRate.toInt();
        _heartRates.add(newRate);
        if (_heartRates.length > 30) {
          _heartRates.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Health Monitor"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // BPM Display
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text("$_currentHeartRate",
                      style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const Text("BPM",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 40),

          // Chart
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Real-time Heart Rate",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: CustomPaint(
                      painter: ChartPainter(_heartRates),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (data.isEmpty) return;

    double xStep = size.width / (data.length - 1);
    // Scale Y: map 50-120 range to height
    double minVal = 50;
    double maxVal = 120;

    // Normalize and draw
    for (int i = 0; i < data.length; i++) {
      double val = data[i].clamp(minVal, maxVal);
      double normalized = (val - minVal) / (maxVal - minVal);
      double y = size.height - (normalized * size.height);
      double x = i * xStep;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Simple linear line, could utilize quadraticBezierTo for smoothing
        path.lineTo(x, y);
      }
    }

    // Gradient fill below
    Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return true; // Always repaint on new data
  }
}
