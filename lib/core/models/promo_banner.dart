class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.imageUrl,
  });

  final int id;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String? imageUrl;

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    eyebrow: json['eyebrow']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    buttonLabel: json['buttonLabel']?.toString() ?? 'Pesan lapangan',
    imageUrl: json['imageUrl']?.toString(),
  );

  Map<String, dynamic> toPayload() => {
    'eyebrow': eyebrow,
    'title': title,
    'subtitle': subtitle,
    'buttonLabel': buttonLabel,
  };
}
