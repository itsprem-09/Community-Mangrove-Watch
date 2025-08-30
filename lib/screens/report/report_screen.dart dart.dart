import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'report_bloc.dart';
import '../../models/incident_report.dart';

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const ReportScreen({super.key, this.extra});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  IncidentType _selectedType = IncidentType.illegalCutting;
  String? _imagePath;
  double? _latitude;
  double? _longitude;
  bool _isAnalyzing = false;
  String? _aiPrediction;

  @override
  void initState() {
    super.initState();
    if (widget.extra != null) {
      _imagePath = widget.extra!['imagePath'];
      _latitude = widget.extra!['latitude'];
      _longitude = widget.extra!['longitude'];

      // Analyze image with Gemini API
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imagePath == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final prediction = await context.read<ReportBloc>().analyzeImageWithGemini(_imagePath!);
      setState(() {
        _aiPrediction = prediction;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Analysis failed: $e')),
      );
    }
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      final report = IncidentReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // Get from auth state
        title: 'Incident Report', // Default title - you may want to add a title field to the form
        type: _selectedType,
        description: _descriptionController.text,
        imagePath: _imagePath,
        severity: SeverityLevel.medium, // Default severity - you may want to add a severity dropdown
        latitude: _latitude!,
        longitude: _longitude!,
        timestamp: DateTime.now(),
        aiPrediction: _aiPrediction,
        status: ReportStatus.pending,
      );

      context.read<ReportBloc>().add(SubmitReport(report));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: Colors.green,
      ),
      body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted successfully!')),
            );
            context.go('/home');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                if (_imagePath != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                    ),
                  ),

                const SizedBox(height: 16),

                // AI Analysis result
                if (_isAnalyzing)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Analyzing image with AI...'),
                        ],
                      ),
                    ),
                  ),

                if (_aiPrediction != null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Analysis Result:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_aiPrediction!),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Incident type dropdown
                DropdownButtonFormField<IncidentType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Incident Type',
                    border: OutlineInputBorder(),
                  ),
                  items: IncidentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),

                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about the incident...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Location info
                if (_latitude != null && _longitude != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Lat: ${_latitude!.toStringAsFixed(6)}'),
                          Text('Lng: ${_longitude!.toStringAsFixed(6)}'),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit Report',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
