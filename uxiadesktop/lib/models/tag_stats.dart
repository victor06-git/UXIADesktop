import 'package:flutter/material.dart';

class TagStats {
  final String name;
  final int count;
  final Color color;
  bool isSelected;

  TagStats({
    required this.name,
    required this.count,
    required this.color,
    this.isSelected = true,
  });

  // Factory para crear el objeto desde el JSON que devuelve tu API
  factory TagStats.fromJson(Map<String, dynamic> json, Color assignedColor) {
    return TagStats(
      name: json['name'] ?? 'Unknown',
      count: json['count'] ?? 0,
      color: assignedColor,
    );
  }
}
