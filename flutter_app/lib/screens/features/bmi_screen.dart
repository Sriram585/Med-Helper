import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmi;
  String _category = '';
  Color _categoryColor = Colors.grey;

  void _calculateBMI() {
    double h = double.tryParse(_heightController.text) ?? 0;
    double w = double.tryParse(_weightController.text) ?? 0;

    if (h > 0 && w > 0) {
      // Height usually in cm
      double hMeters = h / 100;
      double result = w / (hMeters * hMeters);

      String cat = '';
      Color col = Colors.grey;

      if (result < 18.5) {
        cat = 'Underweight';
        col = Colors.blue;
      } else if (result >= 18.5 && result < 24.9) {
        cat = 'Normal Weight';
        col = Colors.green;
      } else if (result >= 25 && result < 29.9) {
        cat = 'Overweight';
        col = Colors.orange;
      } else {
        cat = 'Obese';
        col = Colors.red;
      }

      setState(() {
        _bmi = result;
        _category = cat;
        _categoryColor = col;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Input Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration,
              child: Column(
                children: [
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Height (cm)",
                      prefixIcon: Icon(Icons.height),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Weight (kg)",
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculateBMI,
                      child: const Text("Calculate BMI"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Result
            if (_bmi != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _categoryColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                  border: Border.all(
                      color: _categoryColor.withValues(alpha: 0.5), width: 2),
                ),
                child: Column(
                  children: [
                    const Text("Your BMI",
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_bmi!.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: _categoryColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
