import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _levelController = TextEditingController(text: "Beginner");
  final _equipController = TextEditingController(text: "None (Bodyweight)");
  bool _isLoading = false;
  List<dynamic>? _workoutPlan;

  void _generateWorkout() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.generateWorkout(
        "General Fitness", // Default goal as per script.js logic
        _levelController.text,
        _equipController.text,
      );
      setState(() => _workoutPlan = response['data']);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Trainer"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Controls
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration,
              child: Column(
                children: [
                  TextField(
                    controller: _levelController,
                    decoration: const InputDecoration(
                        labelText: "Fitness Level",
                        hintText: "Beginner, Intermediate...",
                        prefixIcon: Icon(Icons.trending_up)),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _equipController,
                    decoration: const InputDecoration(
                        labelText: "Equipment Available",
                        hintText: "None, Dumbbells, Full Gym",
                        prefixIcon: Icon(Icons.fitness_center)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateWorkout,
                      icon: _isLoading
                          ? const SizedBox()
                          : const Icon(Icons.flash_on),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Build Workout Routine"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_workoutPlan != null)
              ..._workoutPlan!.map((day) => _buildDayCard(day)),

            if (_workoutPlan == null && !_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                      "Tell us your level and equipment to get a personalized weekly workout plan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    String dayTitle = dayData['day'] ?? "Day";
    String focus = dayData['focus'] ?? "Training";
    List<dynamic> exercises = dayData['exercises'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
          ],
          border: Border(
              left: BorderSide(color: Colors.orange.shade400, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dayTitle,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(focus,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              )
            ],
          ),
          const Divider(),
          ...exercises.map((ex) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(ex.toString(),
                            style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
