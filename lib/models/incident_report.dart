import 'package:equatable/equatable.dart';

enum IncidentType {
  illegalCutting,
  landReclamation,
  pollution,
  dumping,
  other
}

enum ReportStatus {
  pending,
  verified,
  rejected,
  resolved
}

enum SeverityLevel {
  low,
  medium,
  high,
  critical
}

extension IncidentTypeExtension on IncidentType {
  String get displayName {
    switch (this) {
      case IncidentType.illegalCutting:
        return 'Illegal Cutting';
      case IncidentType.landReclamation:
        return 'Land Reclamation';
      case IncidentType.pollution:
        return 'Pollution';
      case IncidentType.dumping:
        return 'Illegal Dumping';
      case IncidentType.other:
        return 'Other';
    }
  }
}

class IncidentReport extends Equatable {
  final String id;
  final String userId;
  final String title;
  final IncidentType type;
  final String description;
  final String? imagePath;
  final List<String> images;
  final SeverityLevel severity;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? aiPrediction;
  final ReportStatus status;
  final int points;
  final int verificationCount;

  const IncidentReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.description,
    this.imagePath,
    this.images = const [],
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.aiPrediction,
    required this.status,
    this.points = 0,
    this.verificationCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.name,
      'description': description,
      'imagePath': imagePath,
      'images': images,
      'severity': severity.name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'aiPrediction': aiPrediction,
      'status': status.name,
      'points': points,
      'verificationCount': verificationCount,
    };
  }

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    // Handle both direct coordinates and nested location object
    double latitude = 0.0;
    double longitude = 0.0;
    
    if (json['location'] != null && json['location'] is Map) {
      latitude = (json['location']['latitude'] ?? 0.0).toDouble();
      longitude = (json['location']['longitude'] ?? 0.0).toDouble();
    } else {
      latitude = (json['latitude'] ?? 0.0).toDouble();
      longitude = (json['longitude'] ?? 0.0).toDouble();
    }
    
    return IncidentReport(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? 'unknown',
      title: json['title'] ?? json['description']?.toString().substring(0, json['description'].toString().length > 30 ? 30 : json['description'].toString().length) ?? 'Untitled',
      type: IncidentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IncidentType.other,
      ),
      description: json['description'] ?? '',
      imagePath: json['imagePath'],
      images: List<String>.from(json['images'] ?? []),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.name == (json['severity'] ?? 'medium'),
        orElse: () => SeverityLevel.medium,
      ),
      latitude: latitude,
      longitude: longitude,
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
      aiPrediction: json['aiPrediction'] ?? json['mlPrediction'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
      points: json['points'] ?? 0,
      verificationCount: json['verificationCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    type,
    description,
    imagePath,
    images,
    severity,
    latitude,
    longitude,
    timestamp,
    aiPrediction,
    status,
    points,
    verificationCount,
  ];
}
