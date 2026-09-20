import 'package:flutter/material.dart';

class FieldModel {
  const FieldModel({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.category,
    required this.color,
  });

  final String id;
  final String name;
  final String location;
  final String price;
  final double rating;
  final String category;
  final Color color;
}

const List<FieldModel> sampleFields = [
  FieldModel(
    id: 'arena-hijau',
    name: 'Arena Hijau Futsal',
    location: 'Jl. Merdeka No. 12',
    price: 'Rp 180.000 / jam',
    rating: 4.8,
    category: 'Futsal',
    color: Color(0xFF1F7A8C),
  ),
];
