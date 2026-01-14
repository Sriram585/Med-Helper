import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LabAnalyserScreen extends StatefulWidget {
  const LabAnalyserScreen({super.key});

  @override
  State<LabAnalyserScreen> createState() => _LabAnalyserScreenState();
}

class _LabAnalyserScreenState extends State<LabAnalyserScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  void _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true, // Important for Web to get bytes
    );

    if (result != null) {
      // Use bytes instead of path for Web compatibility
      final bytes = result.files.single.bytes;
      final name = result.files.single.name;

      if (bytes != null) {
        setState(() => _isLoading = true);

        try {
          final data = await ApiService.uploadLabReport(bytes, name);
          setState(() => _results = data);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        // Fallback for native if bytes are null (though withData: true should provide them)
        // But since we removed dart:io, we must rely on bytes.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error reading file data")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Lab Analyzer"),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            const Text(
              "\"Let Food and Movement be thy Medicine\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary),
            ),
            const SizedBox(height: 10),
            const Text(
              "Interpret reports for wellness optimization.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 30),

            // Upload Box
            GestureDetector(
              onTap: _isLoading ? null : _pickAndUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                      style: BorderStyle
                          .solid), // Dashed ideal but complex in basic Flutter
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file,
                        size: 50,
                        color: AppTheme.primary.withValues(alpha: 0.8)),
                    const SizedBox(height: 15),
                    Text(
                        _isLoading
                            ? "Analyzing..."
                            : "Upload Lab Report (PDF/TXT)",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_isLoading)
                      const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator())
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Results
            if (_results != null) _buildResults(_results!),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> data) {
    // Parsing logic based on backend response structure (assumed based on JS)
    // Assuming backend returns { "findings": [...], "diet": [], "workout": [] }
    // If exact structure is unknown, we display raw JSON or try to parse generic list

    // Simplification for the example:
    final findings = data['findings'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
                left: BorderSide(color: AppTheme.secondary, width: 5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Wellness Interpretation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(data['summary'] ?? "Analysis Complete.",
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text("Key Biomarkers",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: findings.length,
          itemBuilder: (context, index) {
            final item = findings[index];
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: AppTheme.glassDecoration
                  .copyWith(borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name'] ?? 'Metric',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold)),
                  Text(item['value'] ?? '-',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textMain)),
                  Text(item['status'] ?? '',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
