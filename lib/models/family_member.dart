import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation; // e.g. Dad, Mom, Grandpa, Myself, Child
  final DateTime? dateOfBirth;
  final int? _manualAge;
  final int colorValue; // Color stored as 32-bit int
  final String avatarEmoji; // e.g. 👨, 👩, 👴, 👵, 🧑
  final String? familyId;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.dateOfBirth,
    int? age,
    required this.colorValue,
    required this.avatarEmoji,
    this.familyId,
  }) : _manualAge = age;

  /// Dynamic age calculated from date of birth, or manual fallback
  int get age {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int calculated = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        calculated--;
      }
      return calculated >= 0 ? calculated : 0;
    }
    return _manualAge ?? 0;
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'age': age,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'colorValue': colorValue,
      'avatarEmoji': avatarEmoji,
      'familyId': familyId,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      age: map['age'] as int?,
      dateOfBirth: (map['dateOfBirth'] ?? map['date_of_birth']) != null
          ? DateTime.tryParse((map['dateOfBirth'] ?? map['date_of_birth']) as String)
          : null,
      colorValue: (map['colorValue'] ?? map['color_value']) as int,
      avatarEmoji: (map['avatarEmoji'] ?? map['avatar_emoji']) as String,
      familyId: (map['familyId'] ?? map['family_id']) as String?,
    );
  }

  /// Converts model for Supabase table `public.patient_profiles`
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'age': age,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'color_value': colorValue,
      'avatar_emoji': avatarEmoji,
      if (familyId != null) 'family_id': familyId,
    };
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relation,
    DateTime? dateOfBirth,
    int? age,
    int? colorValue,
    String? avatarEmoji,
    String? familyId,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? _manualAge,
      colorValue: colorValue ?? this.colorValue,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      familyId: familyId ?? this.familyId,
    );
  }
}
