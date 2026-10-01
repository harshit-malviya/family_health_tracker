import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation; // e.g. Dad, Mom, Grandpa, Myself, Child
  final int age;
  final int colorValue; // Color stored as 32-bit int
  final String avatarEmoji; // e.g. 👨, 👩, 👴, 👵, 🧑

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.age,
    required this.colorValue,
    required this.avatarEmoji,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'age': age,
      'colorValue': colorValue,
      'avatarEmoji': avatarEmoji,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      age: map['age'] as int,
      colorValue: map['colorValue'] as int,
      avatarEmoji: map['avatarEmoji'] as String,
    );
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relation,
    int? age,
    int? colorValue,
    String? avatarEmoji,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      age: age ?? this.age,
      colorValue: colorValue ?? this.colorValue,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
}
