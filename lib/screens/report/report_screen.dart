import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../blocs/report/report_bloc.dart';
import '../../models/incident_report.dart';
import '../../models/location_result.dart';
import '../../services/location_service.dart';
import '../../widgets/loading_overlay.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  IncidentType _selectedType = IncidentType.pollution;
  SeverityLevel _severityLevel = SeverityLevel.medium;
  File? _selectedImage;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _locationErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationErrorMessage = '';
    });

    try {
      final locationResult = await _locationService.getCurrentPositionWithStatus();
      
      if (locationResult.isSuccess) {
        setState(() {
          _currentPosition = locationResult.position;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationErrorMessage = locationResult.message;
          _isLoadingLocation = false;
        });
        
        // Handle different error cases
        if (mounted) {
          _handleLocationError(locationResult);
        }
      }
    } catch (e) {
      setState(() {
        _locationErrorMessage = 'Failed to get location: $e';
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }
  
  void _handleLocationError(LocationResult result) {
    switch (result.error) {
      case LocationError.servicesDisabled:
        _showLocationDialog(
          'Location Services Disabled',
          'Location services are turned off. Please enable them to report incidents.',
          'Open Settings',
          () async {
            Navigator.of(context).pop();
            final opened = await _locationService.openLocationSettings();
            if (opened) {
              // Retry after user returns
              Future.delayed(const Duration(seconds: 1), _getCurrentLocation);
            }
          },
        );
        break;
        
      case LocationError.permissionDenied:
        _showLocationDialog(
          'Location Permission Required',
          'Location permission is required to report incidents with accurate location data.',
          'Grant Permission',
          () {
            Navigator.of(context).pop();
            _getCurrentLocation(); // Retry permission request
          },
        );
        break;
        
      case LocationError.permissionDeniedForever:
        _showLocationDialog(
          'Permission Permanently Denied',
          'Location permission has been permanently denied. Please enable it in app settings.',
          'Open App Settings',
          () async {
            Navigator.of(context).pop();
            await _locationService.openAppPermissionSettings();
            // User will need to manually retry after granting permission
          },
        );
        break;
        
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
    }
  }
  
  void _showLocationDialog(String title, String content, String actionText, VoidCallback onAction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      // Make image optional for testing
      // if (_selectedImage == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please add a photo of the incident')),
      //   );
      //   return;
      // }

      // Use default location if current position is not available (for testing)
      final latitude = _currentPosition?.latitude ?? 13.0827;
      final longitude = _currentPosition?.longitude ?? 80.2707;
      
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using default location. For accurate reporting, enable location services.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      final report = IncidentReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.isNotEmpty ? _titleController.text : 'Incident Report',
        description: _descriptionController.text,
        type: _selectedType,
        severity: _severityLevel,
        latitude: latitude,
        longitude: longitude,
        images: _selectedImage != null ? [_selectedImage!.path] : [],
        userId: 'current_user_id', // TODO: Get from auth
        timestamp: DateTime.now(),
        status: ReportStatus.pending,
        verificationCount: 0,
      );

      context.read<ReportBloc>().add(ReportSubmitted(report: report));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        elevation: 0,
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          } else if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Section
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add photo',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Incident Title',
                          hintText: 'Brief description of the incident',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide detailed information about the incident',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Incident Type Dropdown
                      DropdownButtonFormField<IncidentType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Incident Type',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: IncidentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Severity Level
                      DropdownButtonFormField<SeverityLevel>(
                        value: _severityLevel,
                        decoration: InputDecoration(
                          labelText: 'Severity Level',
                          prefixIcon: const Icon(Icons.warning),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: SeverityLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: _getSeverityColor(level),
                                ),
                                const SizedBox(width: 8),
                                Text(level.name.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _severityLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _currentPosition != null 
                              ? Colors.green[50] 
                              : (_locationErrorMessage.isNotEmpty ? Colors.red[50] : Colors.blue[50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentPosition != null 
                                ? Colors.green[200]! 
                                : (_locationErrorMessage.isNotEmpty ? Colors.red[200]! : Colors.blue[200]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _currentPosition != null 
                                      ? Icons.check_circle 
                                      : Icons.location_on,
                                  color: _currentPosition != null 
                                      ? Colors.green[700] 
                                      : (_locationErrorMessage.isNotEmpty ? Colors.red[700] : Colors.blue[700]),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isLoadingLocation
                                        ? 'Getting location...'
                                        : _currentPosition != null
                                            ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                            : _locationErrorMessage.isNotEmpty 
                                                ? 'Location unavailable'
                                                : 'Waiting for location...',
                                    style: TextStyle(
                                      color: _currentPosition != null 
                                          ? Colors.green[700] 
                                          : (_locationErrorMessage.isNotEmpty ? Colors.red[700] : Colors.blue[700]),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (_isLoadingLocation)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (_currentPosition == null && !_isLoadingLocation)
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _getCurrentLocation,
                                    tooltip: 'Retry getting location',
                                  ),
                              ],
                            ),
                            if (_locationErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _locationErrorMessage,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: state is ReportSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Report',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state is ReportSubmitting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Submitting report...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return Colors.yellow;
      case SeverityLevel.medium:
        return Colors.orange;
      case SeverityLevel.high:
        return Colors.red;
      case SeverityLevel.critical:
        return Colors.purple;
    }
  }
}
