import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  // Hydration
  int _waterCount = 0;
  final int _waterGoal = 8;

  // Mood
  String _selectedMood = '';

  // Sleep
  TimeOfDay? _wakeTime;
  List<String> _sleepTimes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCount = prefs.getInt('waterCount') ?? 0;
    });
  }

  Future<void> _updateWater(int delta) async {
    setState(() {
      _waterCount = (_waterCount + delta).clamp(0, 20);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waterCount', _waterCount);
  }

  void _calculateSleepTimes() {
    if (_wakeTime == null) return;

    final now = DateTime.now();
    DateTime wakeDateTime = DateTime(
        now.year, now.month, now.day, _wakeTime!.hour, _wakeTime!.minute);

    // If wake time is earlier than now, assume tomorrow
    if (wakeDateTime.isBefore(now)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }

    // Cycles: 6 (9h), 5 (7.5h), 4 (6h)
    List<int> cycles = [6, 5, 4];
    List<String> times = [];

    for (int c in cycles) {
      DateTime sleepTime = wakeDateTime.subtract(Duration(minutes: c * 90));
      // Format simple HH:mm
      String period = sleepTime.hour >= 12 ? 'PM' : 'AM';
      int hour = sleepTime.hour > 12
          ? sleepTime.hour - 12
          : (sleepTime.hour == 0 ? 12 : sleepTime.hour);
      String min = sleepTime.minute.toString().padLeft(2, '0');
      times.add("$hour:$min $period (${c * 1.5} Hours)");
    }

    setState(() {
      _sleepTimes = times;
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _wakeTime) {
      setState(() {
        _wakeTime = picked;
      });
      _calculateSleepTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wellness Center"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Hydration Tracker
            _buildCard(
                "Hydration Tracker",
                Icons.water_drop,
                Colors.blue,
                Column(
                  children: [
                    Text("$_waterCount / $_waterGoal Glasses",
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleBtn(Icons.remove, () => _updateWater(-1)),
                        const SizedBox(width: 20),
                        Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child:
                              const Icon(Icons.local_drink, color: Colors.blue),
                        ),
                        const SizedBox(width: 20),
                        _buildCircleBtn(Icons.add, () => _updateWater(1)),
                      ],
                    )
                  ],
                )),
            const SizedBox(height: 20),

            // 2. Mood Tracker
            _buildCard(
                "Mood Tracker",
                Icons.mood,
                Colors.amber,
                Wrap(
                  spacing: 15,
                  children: [
                    _buildMoodBtn(
                        "Happy", Icons.sentiment_very_satisfied, Colors.green),
                    _buildMoodBtn(
                        "Neutral", Icons.sentiment_neutral, Colors.grey),
                    _buildMoodBtn(
                        "Sad", Icons.sentiment_very_dissatisfied, Colors.blue),
                    _buildMoodBtn("Stressed", Icons.bolt, Colors.red),
                  ],
                )),
            const SizedBox(height: 20),

            // 3. Sleep Calculator
            _buildCard(
                "Sleep Calculator",
                Icons.bedtime,
                Colors.indigo,
                Column(
                  children: [
                    const Text("When should I sleep to wake up at...",
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _selectTime(context),
                      child: Text(_wakeTime == null
                          ? "Select Wake Time"
                          : _wakeTime!.format(context)),
                    ),
                    const SizedBox(height: 15),
                    if (_sleepTimes.isNotEmpty)
                      ..._sleepTimes.map((t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.nightlight_round,
                                    size: 16, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Text(t,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                          )),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          content
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildMoodBtn(String label, IconData icon, Color color) {
    bool isSelected = _selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMood = label);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Mood logged: $label")));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.white : color),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}
