import 'package:flutter/material.dart';

import '../../core/models/field_model.dart';

class FieldDetailPage extends StatelessWidget {
  const FieldDetailPage({super.key, required this.field});

  final FieldModel field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(field.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [field.color, theme.colorScheme.primary],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            field.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 6),
              Text(field.location),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 6),
              Text('${field.rating.toStringAsFixed(1)} rating'),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fasilitas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Mushola')),
                      Chip(label: Text('Parkiran')),
                      Chip(label: Text('Wi-Fi')),
                      Chip(label: Text('Kamar ganti')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Deskripsi',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lapangan futsal dengan kualitas rumput sintetis, pencahayaan terang, dan akses lokasi yang strategis untuk sesi latihan maupun pertandingan santai.',
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () {},
            child: Text('Pesan sekarang • ${field.price}'),
          ),
        ],
      ),
    );
  }
}
