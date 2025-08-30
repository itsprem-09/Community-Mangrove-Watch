import 'package:equatable/equatable.dart';

enum UserRole {
  citizen,
  ngo,
  government,
  researcher,
  admin
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.government:
        return 'Government';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? organization;
  final String? phone;
  final String? location;
  final int points;
  final List<String> badges;
  final bool isVerified;
  final bool isAdmin;
  final DateTime joinedDate;
  final int? rank;
  final int? totalReports;
  final int? verifiedReports;
  final int level;
  final String? avatarUrl;
  final DateTime? joinDate;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organization,
    this.phone,
    this.location,
    this.points = 0,
    this.badges = const [],
    this.isVerified = false,
    this.isAdmin = false,
    required this.joinedDate,
    this.rank,
    this.totalReports,
    this.verifiedReports,
    this.level = 1,
    this.avatarUrl,
    DateTime? joinDate,
  }) : joinDate = joinDate ?? joinedDate;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.byName(json['role']),
      organization: json['organization'],
      phone: json['phone'],
      location: json['location'],
      points: json['points'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      isVerified: json['is_verified'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      joinedDate: DateTime.parse(json['joined_date']),
      rank: json['rank'],
      totalReports: json['total_reports'],
      verifiedReports: json['verified_reports'],
      level: json['level'] ?? 1,
      avatarUrl: json['avatar_url'],
      joinDate: json['join_date'] != null ? DateTime.parse(json['join_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'organization': organization,
      'phone': phone,
      'location': location,
      'points': points,
      'badges': badges,
      'is_verified': isVerified,
      'is_admin': isAdmin,
      'joined_date': joinedDate.toIso8601String(),
      'rank': rank,
      'total_reports': totalReports,
      'verified_reports': verifiedReports,
      'level': level,
      'avatar_url': avatarUrl,
      'join_date': joinDate?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? organization,
    String? phone,
    String? location,
    int? points,
    List<String>? badges,
    bool? isVerified,
    bool? isAdmin,
    DateTime? joinedDate,
    int? rank,
    int? totalReports,
    int? verifiedReports,
    int? level,
    String? avatarUrl,
    DateTime? joinDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      joinedDate: joinedDate ?? this.joinedDate,
      rank: rank ?? this.rank,
      totalReports: totalReports ?? this.totalReports,
      verifiedReports: verifiedReports ?? this.verifiedReports,
      level: level ?? this.level,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        organization,
        phone,
        location,
        points,
        badges,
        isVerified,
        isAdmin,
        joinedDate,
        rank,
        totalReports,
        verifiedReports,
        level,
        avatarUrl,
        joinDate,
      ];
}
