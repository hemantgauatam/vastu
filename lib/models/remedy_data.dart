import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemedyItem {
  final String id;
  final String title;
  final String subtitle;
  final String direction;
  final String purpose;
  final String category;
  final int price;
  final String whyYouNeed;
  final String howItWorks;
  final String whatYouGet;
  final String placement;
  final List<String> offers;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> installationImageUrls;
  final List<String> installationVideoUrls;
  final IconData icon;
  final List<Color> colors;

  const RemedyItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.direction,
    required this.purpose,
    this.category = 'General Remedies',
    required this.price,
    this.whyYouNeed = '',
    this.howItWorks = '',
    this.whatYouGet = '',
    this.placement = '',
    this.offers = const [],
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.installationImageUrls = const [],
    this.installationVideoUrls = const [],
    required this.icon,
    required this.colors,
  });

  factory RemedyItem.fromJson(Map<String, dynamic> json) {
    return RemedyItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      category: _categoryFromJson(json),
      price: (json['price'] as num?)?.toInt() ?? 0,
      whyYouNeed: json['whyYouNeed'] as String? ?? '',
      howItWorks: json['howItWorks'] as String? ?? '',
      whatYouGet: json['whatYouGet'] as String? ?? '',
      placement: json['placement'] as String? ?? '',
      offers: _stringList(json['offers'], 8),
      imageUrls: _urlList(json['imageUrls'], 10),
      videoUrls: _urlList(json['videoUrls'], 6),
      installationImageUrls: _urlList(json['installationImageUrls'], 10),
      installationVideoUrls: _urlList(json['installationVideoUrls'], 6),
      icon: Icons.spa_outlined,
      colors: const [Color(0xFF8AA4BE), Color(0xFFE8C87B)],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'direction': direction,
        'purpose': purpose,
        'category': category,
        'price': price,
        'whyYouNeed': whyYouNeed,
        'howItWorks': howItWorks,
        'whatYouGet': whatYouGet,
        'placement': placement,
        'offers': offers.take(8).toList(),
        'imageUrls': imageUrls.take(10).toList(),
        'videoUrls': videoUrls.take(6).toList(),
        'installationImageUrls': installationImageUrls.take(10).toList(),
        'installationVideoUrls': installationVideoUrls.take(6).toList(),
      };
}

List<String> _stringList(dynamic value, int limit) =>
    (value as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .take(limit)
        .toList();

List<String> _urlList(dynamic value, int limit) =>
    _stringList(value, limit).map((item) {
      final trimmed = item.trim();
      final markdownLink =
          RegExp(r'^\[[^\]]*\]\((https?://[^\s)]+)\)$').firstMatch(trimmed);
      return markdownLink?.group(1) ?? trimmed;
    }).where((item) {
      final uri = Uri.tryParse(item);
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    }).toList(growable: false);

class RemedyCatalog {
  static const String _assetPath = 'backend/data/remedies-catalog.json';

  /// Loads the complete premium catalogue bundled with the app. Keeping this
  /// data available locally means the Remedies page is useful before the
  /// backend starts and when a customer is temporarily offline.
  static Future<List<RemedyItem>> load() async {
    final source = await rootBundle.loadString(_assetPath);
    final rows = jsonDecode(source) as List<dynamic>;
    return rows
        .map((row) => RemedyItem.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static const List<RemedyItem> all = [
    RemedyItem(
      id: 'wealth-kalash',
      title: 'Wealth Kalash',
      subtitle: 'North prosperity balancing kit',
      direction: 'North',
      purpose: 'Prosperity and steady opportunities',
      category: 'Wealth & Prosperity',
      price: 799,
      icon: Icons.water_drop_outlined,
      colors: [Color(0xFF2E86C1), Color(0xFF87CEEB)],
    ),
    RemedyItem(
      id: 'agni-copper',
      title: 'Agni Copper Set',
      subtitle: 'Southeast fire element support',
      direction: 'Southeast',
      purpose: 'Energy, kitchen harmony, and transformation',
      category: 'Health & Energy',
      price: 1199,
      icon: Icons.local_fire_department_outlined,
      colors: [Color(0xFFE67E50), Color(0xFFC0392B)],
    ),
    RemedyItem(
      id: 'ishanya-crystal',
      title: 'Ishanya Crystal',
      subtitle: 'Northeast clarity and prayer corner remedy',
      direction: 'Northeast',
      purpose: 'Clarity, devotion, and peaceful study',
      category: 'Clarity & Spiritual Growth',
      price: 999,
      icon: Icons.diamond_outlined,
      colors: [Color(0xFF85C1E2), Color(0xFFE8C87B)],
    ),
    RemedyItem(
      id: 'vayu-bells',
      title: 'Vayu Bells',
      subtitle: 'Northwest movement and relationship remedy',
      direction: 'Northwest',
      purpose: 'Supportive relationships and better flow',
      category: 'Relationships & Harmony',
      price: 699,
      icon: Icons.notifications_active_outlined,
      colors: [Color(0xFF8AA4BE), Color(0xFFD5DBDB)],
    ),
  ];
}

String _categoryFromJson(Map<String, dynamic> json) {
  final category = (json['category'] as String? ?? '').trim();
  if (category.isNotEmpty) return category;
  final text =
      '${json['title']} ${json['purpose']} ${json['direction']}'.toLowerCase();
  if (text.contains('wealth') ||
      text.contains('prosper') ||
      text.contains('money')) {
    return 'Wealth & Prosperity';
  }
  if (text.contains('health') ||
      text.contains('energy') ||
      text.contains('fire')) {
    return 'Health & Energy';
  }
  if (text.contains('relationship') ||
      text.contains('harmony') ||
      text.contains('flow')) {
    return 'Relationships & Harmony';
  }
  if (text.contains('clarity') ||
      text.contains('study') ||
      text.contains('devotion')) {
    return 'Clarity & Spiritual Growth';
  }
  return 'General Remedies';
}
