import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('mediProfile');
    if (jsonStr != null) {
      final data = jsonDecode(jsonStr);
      _nameController.text = data['name'] ?? '';
      _ageController.text = data['age'] ?? '';
      _bloodController.text = data['blood'] ?? '';
      _allergiesController.text = data['allergies'] ?? '';
      _conditionsController.text = data['conditions'] ?? '';
    } else {
      // Try to get name from auth session if profile empty
      String? userJson = prefs.getString('user_data');
      if (userJson != null) {
        final user = jsonDecode(userJson);
        _nameController.text = user['name'] ?? user['username'] ?? '';
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': _nameController.text,
      'age': _ageController.text,
      'blood': _bloodController.text,
      'allergies': _allergiesController.text,
      'conditions': _conditionsController.text,
    };
    await prefs.setString('mediProfile', jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medical Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person,
                          size: 50, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildCard(
                      title: "Personal Information",
                      icon: Icons.badge,
                      children: [
                        _buildField("Full Name", _nameController),
                        _buildField("Age", _ageController, isNumber: true),
                      ]),
                  const SizedBox(height: 20),
                  _buildCard(
                      title: "Medical Details",
                      icon: Icons.medical_services,
                      children: [
                        _buildField("Blood Type", _bloodController),
                        _buildField("Allergies", _allergiesController),
                        _buildField(
                            "Chronic Conditions", _conditionsController),
                      ]),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Save Changes"),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 25),
          ...children
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
