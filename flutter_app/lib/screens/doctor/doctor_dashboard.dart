import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  // Mock Data mimicking script.js MOCK_APPOINTMENTS
  final List<Map<String, dynamic>> _appointments = [
    {
      "id": 101,
      "patient": "Alice Cooper",
      "date": "Today at 2:00 PM",
      "reason": "Annual physical",
      "type": "standard"
    },
    {
      "id": 102,
      "patient": "Bob Brown",
      "date": "Today at 3:15 PM",
      "reason": "Chest pain follow-up",
      "type": "urgent"
    },
    {
      "id": 103,
      "patient": "Charlie Davis",
      "date": "Today at 4:30 PM",
      "reason": "Skin rash evaluation",
      "type": "standard"
    },
    {
      "id": 104,
      "patient": "Diana Prince",
      "date": "Tomorrow at 9:00 AM",
      "reason": "Migraine check",
      "type": "review"
    },
    {
      "id": 105,
      "patient": "Evan Wright",
      "date": "Tomorrow at 10:30 AM",
      "reason": "Diabetes management",
      "type": "review"
    },
    {
      "id": 106,
      "patient": "Fiona Green",
      "date": "Tomorrow at 11:45 AM",
      "reason": "High fever & cough",
      "type": "urgent"
    },
    {
      "id": 117,
      "patient": "Quinn Fabray",
      "date": "Sat at 10:00 AM",
      "reason": "Broken arm follow-up",
      "type": "urgent"
    },
  ];

  // Mock Patients Data mimicking script.js mockPatients
  final List<Map<String, dynamic>> _patients = [
    {
      "name": "Alice Cooper",
      "age": 34,
      "condition": "Hypertension",
      "lastVisit": "2 days ago"
    },
    {
      "name": "Bob Brown",
      "age": 45,
      "condition": "Arrhythmia",
      "lastVisit": "1 week ago"
    },
    {
      "name": "Charlie Davis",
      "age": 29,
      "condition": "Eczema",
      "lastVisit": "Yesterday"
    },
    {
      "name": "Diana Prince",
      "age": 31,
      "condition": "Routine Checkup",
      "lastVisit": "Today"
    },
    {
      "name": "Evan Wright",
      "age": 50,
      "condition": "Diabetes Type 2",
      "lastVisit": "3 weeks ago"
    },
  ];

  String _docStatus = 'Online';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    // Fallback if 'name' isn't in user object (e.g. clean backend response)
    final doctorName = user?['name'] ?? user?['username'] ?? 'Doctor';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("MediMind Doctor Portal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: Icon(Icons.circle, size: 12, color: _getStatusColor()),
              label: Text(_docStatus),
              backgroundColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf0fdf4),
              Color(0xFFdcfce7)
            ], // Greenish tint for doctors
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome, Dr. $doctorName",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                const SizedBox(height: 20),

                // Stats Row
                _buildStatsRow(),
                const SizedBox(height: 30),

                // Patients Section
                _buildSectionHeader("My Patients", Icons.people_outline),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientCard(_patients[index]);
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Appointments Section
                _buildSectionHeader(
                    "Upcoming Appointments", Icons.calendar_today),
                const SizedBox(height: 10),
                _buildAppointmentsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_docStatus == 'Online') return Colors.green;
    if (_docStatus == 'Away') return Colors.amber;
    return Colors.red;
  }

  Widget _buildStatsRow() {
    int urgentCount = _appointments.where((a) => a['type'] == 'urgent').length;
    int reviewCount = _appointments.where((a) => a['type'] == 'review').length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard("Total Appts", "${_appointments.length}",
                Icons.calendar_month, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                "Urgent", "$urgentCount", Icons.warning_amber, Colors.red)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard("Reviews", "$reviewCount",
                Icons.assignment_ind, Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${patient['name']}&background=random'),
            child: Text(patient['name'][0],
                style: const TextStyle(color: Colors.blue)),
          ),
          const SizedBox(height: 8),
          Text(patient['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(patient['condition'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAppointmentsGrid() {
    // A simplified vertical list instead of a grid for better mobile view, or a grid if preferred.
    // The plan said "Grid", but functionality wise a list is robust. Let's use GridView inside Column?
    // Or just a column of cards. Clean cards are better.
    return Column(
      children:
          _appointments.map((appt) => _buildAppointmentCard(appt)).toList(),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    bool isUrgent = appt['type'] == 'urgent';
    bool isReview = appt['type'] == 'review';

    Color borderColor = Colors.transparent;
    Color badgeColor = Colors.grey;
    String badgeText = "Standard";

    if (isUrgent) {
      borderColor = Colors.red.withValues(alpha: 0.5);
      badgeColor = Colors.red;
      badgeText = "Urgent";
    } else if (isReview) {
      badgeColor = Colors.purple;
      badgeText = "Review";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isUrgent ? borderColor : Colors.transparent,
            width: isUrgent ? 1 : 0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(appt['date'].split(' at ')[0],
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold)), // Today/Tmrw
                Text(appt['date'].split(' at ')[1],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(appt['patient'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    if (isUrgent || isReview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badgeText,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      )
                  ],
                ),
                Text(appt['reason'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Viewing details for ${appt['patient']}")));
            },
          )
        ],
      ),
    );
  }
}
