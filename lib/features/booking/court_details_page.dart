import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';

class CourtDetailsPage extends ConsumerStatefulWidget {
  const CourtDetailsPage({
    super.key,
    required this.courtName,
    required this.description,
    required this.surface,
    this.imageUrl,
  });

  final String courtName;
  final String description;
  final String surface;
  final String? imageUrl;

  @override
  ConsumerState<CourtDetailsPage> createState() => _CourtDetailsPageState();
}

class _CourtDetailsPageState extends ConsumerState<CourtDetailsPage> {
  late Future<CourtReviewSummary> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<CourtReviewSummary> _loadReviews() async {
    final response = await ref
        .read(apiServiceProvider)
        .get('/courts/${Uri.encodeComponent(widget.courtName)}/reviews');
    return CourtReviewSummary.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  void _reloadReviews() {
    setState(() {
      _reviewsFuture = _loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail lapangan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SizedBox(
            height: 230,
            child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                  memCacheWidth: 1200,
                  maxWidthDiskCache: 1600,
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (_, _) => const _CourtImageFallback(),
                  errorWidget: (_, _, _) => const _CourtImageFallback(),
                  )
                : const _CourtImageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courtName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.surface.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Permukaan: ${widget.surface}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Deskripsi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description.isEmpty
                      ? 'Deskripsi lapangan belum tersedia.'
                      : widget.description,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rating dan komentar',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Muat ulang ulasan',
                      onPressed: _reloadReviews,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                FutureBuilder<CourtReviewSummary>(
                  future: _reviewsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(snapshot.error.toString()),
                          TextButton.icon(
                            onPressed: _reloadReviews,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      );
                    }

                    final summary = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFE3A800),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              summary.reviewCount == 0
                                  ? 'Belum ada rating'
                                  : '${summary.averageRating.toStringAsFixed(1)} dari 5 · ${summary.reviewCount} ulasan',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _writeReview,
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Tulis atau ubah ulasan'),
                        ),
                        const SizedBox(height: 12),
                        if (summary.reviews.isEmpty)
                          const Text(
                            'Jadilah pelanggan pertama yang memberi ulasan.',
                          )
                        else
                          ...summary.reviews.map(
                            (review) => _ReviewTile(review: review),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _writeReview() async {
    final comment = TextEditingController();
    var rating = 5;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ulas lapangan'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      tooltip: '${index + 1} bintang',
                      onPressed: () => setDialogState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFE3A800),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Komentar',
                    hintText: 'Ceritakan pengalaman bermainmu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) {
      comment.dispose();
      return;
    }
    if (comment.text.trim().length < 2) {
      comment.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar minimal 2 karakter.')),
        );
      }
      return;
    }

    try {
      await ref.read(apiServiceProvider).post(
        '/courts/${Uri.encodeComponent(widget.courtName)}/reviews',
        {'rating': rating, 'comment': comment.text.trim()},
      );
      if (!mounted) return;
      setState(() => _reviewsFuture = _loadReviews());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil disimpan.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      comment.dispose();
    }
  }
}

class CourtReviewSummary {
  const CourtReviewSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  final double averageRating;
  final int reviewCount;
  final List<CourtReview> reviews;

  factory CourtReviewSummary.fromJson(Map<String, dynamic> json) {
    return CourtReviewSummary(
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (review) => CourtReview.fromJson(Map<String, dynamic>.from(review)),
          )
          .toList(),
    );
  }
}

class CourtReview {
  const CourtReview({
    required this.customerName,
    required this.rating,
    required this.comment,
  });

  final String customerName;
  final int rating;
  final String comment;

  factory CourtReview.fromJson(Map<String, dynamic> json) {
    return CourtReview(
      customerName: json['customerName']?.toString() ?? 'Pelanggan',
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString() ?? '',
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final CourtReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 17,
                  color: const Color(0xFFE3A800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment),
          const Divider(height: 20),
        ],
      ),
    );
  }
}

class _CourtImageFallback extends StatelessWidget {
  const _CourtImageFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          size: 72,
          color: scheme.primary,
        ),
      ),
    );
  }
}
