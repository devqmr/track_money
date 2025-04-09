import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final String userId;
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.userId,
    this.isDefault = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    icon,
    userId,
    isDefault,
    createdAt,
  ];
} 