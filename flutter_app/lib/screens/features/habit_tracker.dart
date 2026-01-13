import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<Map<String, dynamic>> _habits = [];
  final TextEditingController _habitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? habitsJson = prefs.getString('mediHabits');
    if (habitsJson != null) {
      setState(() {
        _habits = List<Map<String, dynamic>>.from(jsonDecode(habitsJson));
      });
    } else {
      // Default habits
      _habits = [
        {'id': 1, 'text': 'Drink Water', 'completed': false},
        {'id': 2, 'text': 'Take Vitamins', 'completed': false},
        {'id': 3, 'text': 'Morning Walk', 'completed': false},
      ];
      _saveHabits();
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mediHabits', jsonEncode(_habits));
  }

  void _addHabit() {
    if (_habitController.text.isEmpty) return;
    setState(() {
      _habits.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'text': _habitController.text,
        'completed': false
      });
      _habitController.clear();
    });
    _saveHabits();
  }

  void _toggleHabit(int index) {
    setState(() {
      _habits[index]['completed'] = !_habits[index]['completed'];
    });
    _saveHabits();
  }

  void _deleteHabit(int index) {
    setState(() {
      _habits.removeAt(index);
    });
    _saveHabits();
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = _habits.where((h) => h['completed']).length;
    double progress = _habits.isEmpty ? 0 : completedCount / _habits.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Habits"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)])),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: Stack(
                        children: [
                          Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 5,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Center(
                              child: Text("${(progress * 100).toInt()}%",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Keep it up!",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                            "You've completed $completedCount/${_habits.length} habits today.",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Add Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5)
                  ],
                ),
                child: TextField(
                  controller: _habitController,
                  decoration: InputDecoration(
                    hintText: "Add a new habit...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    suffixIcon: IconButton(
                      icon:
                          const Icon(Icons.add_circle, color: AppTheme.primary),
                      onPressed: _addHabit,
                    ),
                  ),
                  onSubmitted: (_) => _addHabit(),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Dismissible(
                      key: Key(habit['id'].toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteHabit(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: habit['completed']
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent)),
                        child: ListTile(
                          leading: Checkbox(
                            value: habit['completed'],
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => _toggleHabit(index),
                          ),
                          title: Text(
                            habit['text'],
                            style: TextStyle(
                              decoration: habit['completed']
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: habit['completed']
                                  ? Colors.grey
                                  : AppTheme.textMain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
