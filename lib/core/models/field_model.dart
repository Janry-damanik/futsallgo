import 'package:flutter/material.dart';

class FieldModel {
  const FieldModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.color,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String price;
  final String category;
  final Color color;
  final String? imageUrl;
}
