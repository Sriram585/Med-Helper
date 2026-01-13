import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _goalController = TextEditingController(text: "Weight Loss");
  final _prefController = TextEditingController(text: "Vegetarian");
  bool _isLoading = false;
  List<dynamic>? _dietPlan;

  void _generateDiet() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.generateDiet(
        _goalController.text,
        _prefController.text,
      );
      setState(() => _dietPlan =
          response['data']); // Access list via key set in ApiService
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
        title: const Text("AI Nutritionist"),
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
                    controller: _goalController,
                    decoration: const InputDecoration(
                        labelText: "Your Goal",
                        hintText: "e.g. Muscle Gain, Weight Loss",
                        prefixIcon: Icon(Icons.flag)),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _prefController,
                    decoration: const InputDecoration(
                        labelText: "Preferences / Allergies",
                        hintText: "e.g. Vegan, No Nuts",
                        prefixIcon: Icon(Icons.restaurant_menu)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateDiet,
                      icon: _isLoading
                          ? const SizedBox()
                          : const Icon(Icons.auto_awesome),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Generate Meal Plan"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_dietPlan != null)
              ..._dietPlan!.map((day) => _buildDayCard(day)),

            if (_dietPlan == null && !_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                      "Enter your goals above to get a customized 7-day meal plan powered by AI.",
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
    // Handling different potential JSON structures gracefully
    String dayTitle = dayData['day'] ?? "Day";
    List<dynamic> meals = dayData['meals'] ?? [];

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
          border:
              Border(left: BorderSide(color: Colors.green.shade400, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayTitle,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const Divider(),
          ...meals.map((meal) {
            String m = meal.toString();
            // Replicating logic from script.js to style
            String type = "Meal";
            Color typeColor = Colors.grey;
            if (m.contains("Breakfast")) {
              type = "Breakfast";
              typeColor = Colors.orange;
            }
            if (m.contains("Lunch")) {
              type = "Lunch";
              typeColor = Colors.blue;
            }
            if (m.contains("Dinner")) {
              type = "Dinner";
              typeColor = Colors.deepPurple;
            }
            if (m.contains("Snack")) {
              type = "Snack";
              typeColor = Colors.teal;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(type,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(m.replaceAll("$type:", "").trim(),
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
