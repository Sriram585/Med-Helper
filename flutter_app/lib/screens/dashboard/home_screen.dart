import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../features/chat_screen.dart';
import '../features/lab_analyser_screen.dart';
import '../features/bmi_screen.dart';
import '../features/diet_screen.dart';
import '../features/workout_screen.dart';
import '../features/doctor_screen.dart';
import '../features/wellness_screen.dart';
import '../features/habit_tracker.dart';
import '../features/wearable_simulation.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Helper to switch view or navigate
  // Since we have separate screens for tools, we will keep them as separate screens
  // for mobile, but for parity, we might want to embed them?
  // The user asked for "functionality parity". The web app is an SPA.
  // For now, linking to screens is cleaner in Flutter, but the layout structure
  // needs to look like the web dashboard.

  @override
  Widget build(BuildContext context) {
    // Check screen size for Responsive Layout
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isDesktop ? null : _buildMobileAppBar(),
      drawer: isDesktop ? null : _buildMobileDrawer(),
      body: Stack(
        children: [
          // 1. Background (Gradient + Orbs)
          _buildBackground(),

          // 2. Main Layout
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      _buildSidebar(width: 280),
                      Expanded(child: _buildMainContent(isDesktop: true)),
                    ],
                  )
                : _buildMainContent(isDesktop: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: AppTheme.backgroundDecoration,
      child: Stack(
        children: [
          // Orb 1 (Top Left)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.4), // Primary Glow
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Orb 2 (Bottom Right)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final username = user?['username'] ?? 'User';
    return AppBar(
      title:
          const Text("MediMind", style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: _showNotifications),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=$username&background=6366f1&color=fff'),
          ),
        )
      ],
    );
  }

  Widget _buildSidebar({required double width}) {
    return Container(
      width: width,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4))
                    ]),
                child: const Icon(Icons.monitor_heart,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("MediMind",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain))
            ],
          ),
          const SizedBox(height: 40),

          // Menu
          const Text("MAIN MENU",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1)),
          const SizedBox(height: 15),
          _buildNavItem("Dashboard", Icons.grid_view, isActive: true),
          _buildNavItem("AI Health Chat", Icons.chat_bubble_outline,
              onTap: () => _navTo(const ChatScreen())),
          _buildNavItem("Find Doctors", Icons.person_search,
              onTap: () => _navTo(const DoctorScreen())),
          _buildNavItem("Diet Plan", Icons.restaurant_menu,
              onTap: () => _navTo(const DietScreen())),
          _buildNavItem("Workouts", Icons.fitness_center,
              onTap: () => _navTo(const WorkoutScreen())),

          const SizedBox(height: 20),
          const Text("WELLNESS",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1)),
          const SizedBox(height: 15),
          _buildNavItem("Wearables", Icons.watch,
              onTap: () => _navTo(const WearableSimulationScreen())),
          _buildNavItem("BMI Calculator", Icons.monitor_weight_outlined,
              onTap: () => _navTo(const BmiScreen())),
          _buildNavItem("Hydration", Icons.water_drop_outlined,
              onTap: () => _navTo(const WellnessScreen())),
          _buildNavItem("Mood Tracker", Icons.mood,
              onTap: () => _navTo(const WellnessScreen())),
          _buildNavItem("Sleep Calc", Icons.bedtime_outlined,
              onTap: () => _navTo(const WellnessScreen())),
          _buildNavItem("Lab Analyzer", Icons.science_outlined,
              onTap: () => _navTo(const LabAnalyserScreen())),

          const Spacer(),
          _buildNavItem("Logout", Icons.logout, color: Colors.red, onTap: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon,
      {bool isActive = false, Color? color, VoidCallback? onTap}) {
    final textColor =
        color ?? (isActive ? AppTheme.primary : AppTheme.textSecondary);
    final bgColor = isActive ? Colors.white : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                        color: textColor,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      child: _buildSidebar(width: double.infinity), // Reuse sidebar content
    );
  }

  Widget _buildMainContent({required bool isDesktop}) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final username = user?['username'] ?? 'User';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 30 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desktop Top Bar
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.textMain, AppTheme.primary])
                          .createShader(bounds),
                      child: const Text("Dashboard",
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors
                                  .white)), // Color needs to be white for mask
                    ),
                    const Text("Your Health Overview",
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: _showNotifications),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => _navTo(const ProfileScreen()),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                            'https://ui-avatars.com/api/?name=$username&background=6366f1&color=fff&size=128',
                            width: 48,
                            height: 48),
                      ),
                    )
                  ],
                )
              ],
            ),

          if (isDesktop)
            const SizedBox(height: 40)
          else ...[
            const Text("Dashboard",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain)),
            const Text("Your Health Overview",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
          ],

          // Dashboard Stats Widgets (Hydration / Mood)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navTo(const WellnessScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child:
                              const Icon(Icons.water_drop, color: Colors.blue),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("0/8",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("Hydration",
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navTo(const WellnessScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.mood, color: Colors.amber),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("-",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("Last Mood",
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Symptom Checker Input
          Container(
            padding: const EdgeInsets.all(30),
            decoration: AppTheme.glassDecoration,
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        color: AppTheme
                            .textMain), // Using close match for stethoscope
                    SizedBox(width: 10),
                    Text("Describe Your Symptoms",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        "e.g. I have a severe headache, sensitivity to light...",
                    fillColor: Color(0xFFF1F5F9), // bg-slate-100
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _navTo(const ChatScreen()),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Run Analysis"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      backgroundColor:
                          Colors.transparent, // Gradient hack below
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => null), // for Ink
                      elevation: WidgetStateProperty.all(0),
                    ),
                  ),
                ).thenApplyGradient(
                    isDesktop) // Custom extension or wrap in container
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Quick Tools Grid (Adding this for parity with the "Quick access" feel of the web dashboard)
          Text("Quick Tools",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2, // Responsive Grid
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildToolCard("AI Health Chat", Icons.chat_bubble_outline,
                  Colors.purple, const ChatScreen()),
              _buildToolCard("Find Doctors", Icons.person_search, Colors.indigo,
                  const DoctorScreen()),
              _buildToolCard("Lab Analyzer", Icons.science_outlined,
                  Colors.teal, const LabAnalyserScreen()),
              _buildToolCard("Diet Plan", Icons.restaurant_menu, Colors.green,
                  const DietScreen()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToolCard(
      String title, IconData icon, Color color, Widget target) {
    return GestureDetector(
      onTap: () => _navTo(target),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
          ],
        ),
      ),
    );
  }

  void _navTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showNotifications() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Notifications",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child:
                          const Icon(Icons.calendar_today, color: Colors.blue),
                    ),
                    title: const Text("Appointment Reminder"),
                    subtitle: const Text("Dr. Smith available next week."),
                    onTap: () {
                      Navigator.pop(context);
                      _navTo(const DoctorScreen());
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child:
                          const Icon(Icons.check_circle, color: Colors.green),
                    ),
                    title: const Text("Habit Tracker"),
                    subtitle: const Text("Don't forget to log your water!"),
                    onTap: () {
                      Navigator.pop(context);
                      _navTo(const HabitTrackerScreen());
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ));
  }
}

// Simple text extension for the Gradient Button simulation would be complex in one file.
// Instead, I'll wrap the button in a Container with Gradient in the widget above if needed.
// For now, standard primary color is close enough to gradient for constraints.

extension ButtonGradient on Widget {
  // Helper to apply gradient to button container
  Widget thenApplyGradient(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary]),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: this,
    );
  }
}
