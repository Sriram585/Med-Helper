import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock Doctors mimicking script.js loadDoctors()
  final List<Map<String, dynamic>> _doctors = [
    {
      "name": "Dr. Smith",
      "spec": "Cardiologist",
      "rating": 4.9,
      "fee": "\$100"
    },
    {
      "name": "Dr. Sarah Lee",
      "spec": "Dermatologist",
      "rating": 4.8,
      "fee": "\$80"
    },
    {
      "name": "Dr. Emily Chen",
      "spec": "General Physician",
      "rating": 4.7,
      "fee": "\$50"
    },
    {
      "name": "Dr. Mike Ross",
      "spec": "Neurologist",
      "rating": 4.9,
      "fee": "\$150"
    },
    {
      "name": "Dr. Lisa Cuddy",
      "spec": "Endocrinologist",
      "rating": 4.6,
      "fee": "\$120"
    },
    {
      "name": "Dr. Gregory House",
      "spec": "Diagnostician",
      "rating": 5.0,
      "fee": "\$500"
    },
  ];

  List<Map<String, dynamic>> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _filteredDoctors = _doctors;
    _searchController.addListener(_filterDoctors);
  }

  void _filterDoctors() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _doctors.where((doc) {
        return doc['name'].toLowerCase().contains(query) ||
            doc['spec'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _bookAppointment(String doctorName) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Confirm Booking"),
              content: Text("Book an appointment with $doctorName?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Appointment booked with $doctorName!")));
                  },
                  child: const Text("Confirm"),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find A Specialist"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: "Search doctors, specialties...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15),
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doc = _filteredDoctors[index];
                return _buildDoctorCard(doc);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${doc['name']}&background=random'),
            child: Text(doc['name'][0],
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
          ),
          const SizedBox(height: 10),
          Text(doc['name'],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(doc['spec'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(doc['rating'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _bookAppointment(doc['name']),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              child: const Text("Book"),
            ),
          )
        ],
      ),
    );
  }
}
