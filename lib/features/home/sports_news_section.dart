import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/auth_provider.dart';

class SportsNewsSection extends ConsumerStatefulWidget {
  const SportsNewsSection({super.key});

  @override
  ConsumerState<SportsNewsSection> createState() => _SportsNewsSectionState();
}

class _SportsNewsSectionState extends ConsumerState<SportsNewsSection> {
  late Future<List<SportsNewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _loadNews();
  }

  Future<List<SportsNewsArticle>> _loadNews() async {
    final response = await ref.read(apiServiceProvider).get('/sports-news');
    final data = response['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map(
          (article) =>
              SportsNewsArticle.fromJson(Map<String, dynamic>.from(article)),
        )
        .toList();
  }

  void _refresh() {
    setState(() {
      _newsFuture = _loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Berita olahraga',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang berita',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<SportsNewsArticle>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 190,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              );
            }

            final articles = snapshot.data ?? const [];
            if (articles.isEmpty) {
              return SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Belum ada berita olahraga.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _SportsNewsCard(
                  article: articles[index],
                  onTap: () => _openArticle(articles[index].url),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel tidak dapat dibuka.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel tidak dapat dibuka.')),
      );
    }
  }
}

class SportsNewsArticle {
  const SportsNewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.url,
    required this.source,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String url;
  final String source;

  factory SportsNewsArticle.fromJson(Map<String, dynamic> json) {
    return SportsNewsArticle(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

class _SportsNewsCard extends StatelessWidget {
  const _SportsNewsCard({required this.article, required this.onTap});

  final SportsNewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                    ? Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _NewsImageFallback(),
                      )
                    : const _NewsImageFallback(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.source.isNotEmpty)
                        Text(
                          article.source.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              article.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.open_in_new_rounded, size: 17),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsImageFallback extends StatelessWidget {
  const _NewsImageFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          size: 42,
          color: scheme.primary,
        ),
      ),
    );
  }
}
