class VideoItem {
  final String id;
  final String title;
  final DateTime? publishedAt;
  final String thumbnailUrl;

  const VideoItem({
    required this.id,
    required this.title,
    required this.publishedAt,
    required this.thumbnailUrl,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) => VideoItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Kuber Vastu video',
        publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'publishedAt': publishedAt?.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
      };
}

class BlogPost {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime? publishedAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.publishedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
        id: json['id'] as String? ?? json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        content: json['content'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        category: json['category'] as String? ?? 'Vastu',
        publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'content': content,
        'imageUrl': imageUrl,
        'category': category,
        'publishedAt': publishedAt?.toIso8601String(),
      };
}

class Testimonial {
  final String id;
  final String name;
  final String profileImageUrl;
  final int rating;
  final String review;
  final DateTime? createdAt;

  const Testimonial({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        id: json['id'] as String? ?? json['_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Kuber Vastu client',
        profileImageUrl: json['profileImageUrl'] as String? ?? '',
        rating: (json['rating'] as num? ?? 5).round().clamp(1, 5),
        review: json['review'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileImageUrl': profileImageUrl,
        'rating': rating,
        'review': review,
        'createdAt': createdAt?.toIso8601String(),
      };
}
