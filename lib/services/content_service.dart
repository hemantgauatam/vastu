import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import 'backend_api.dart';

class ContentPage<T> {
  final List<T> items;
  final bool hasMore;

  const ContentPage(this.items, this.hasMore);
}

class ContentService {
  static const _cachePrefix = 'kubar.content.v1.';
  final http.Client _client;

  ContentService({http.Client? client}) : _client = client ?? http.Client();

  Future<bool> get isOffline async {
    final states = await Connectivity().checkConnectivity();
    return states.contains(ConnectivityResult.none);
  }

  Future<List<VideoItem>> fetchVideos({bool refresh = false}) async {
    return _cachedList<VideoItem>(
      key: 'videos',
      refresh: refresh,
      path: '/api/content/videos',
      arrayKey: 'videos',
      fromJson: VideoItem.fromJson,
      toJson: (item) => item.toJson(),
    );
  }

  Future<ContentPage<BlogPost>> fetchBlogs({
    int page = 1,
    int limit = 8,
    String query = '',
    bool refresh = false,
  }) async {
    final uri = Uri.parse(
      '${BackendApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/blogs',
    ).replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (query.trim().isNotEmpty) 'q': query.trim(),
    });
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ContentException('Unable to load blogs');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body['blogs'] as List<dynamic>? ?? const [])
          .map((row) => BlogPost.fromJson(row as Map<String, dynamic>))
          .toList();
      if (page == 1 && query.trim().isEmpty) {
        await _writeCache('blogs', items.map((e) => e.toJson()).toList());
      }
      return ContentPage(
          items, body['hasMore'] as bool? ?? items.length == limit);
    } catch (error) {
      if (page == 1 && query.trim().isEmpty) {
        final cached = await _readCache('blogs');
        if (cached.isNotEmpty) {
          return ContentPage(
            cached.map((e) => BlogPost.fromJson(e)).toList(),
            false,
          );
        }
      }
      rethrow;
    }
  }

  Future<List<Testimonial>> fetchTestimonials({bool refresh = false}) async {
    return _cachedList<Testimonial>(
      key: 'testimonials',
      refresh: refresh,
      path: '/api/testimonials',
      arrayKey: 'testimonials',
      fromJson: Testimonial.fromJson,
      toJson: (item) => item.toJson(),
    );
  }

  static const _blockedKey = 'kubar.blockedAuthors.v1';
  static const _hiddenKey = 'kubar.hiddenReviews.v1';

  Future<List<Testimonial>> visibleTestimonials(List<Testimonial> items) async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList(_blockedKey) ?? [];
    final hidden = prefs.getStringList(_hiddenKey) ?? [];
    return items
        .where((item) =>
            !hidden.contains(item.id) &&
            (item.authorId.isEmpty || !blocked.contains(item.authorId)))
        .toList();
  }

  Future<void> blockAuthor(Testimonial item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = item.authorId.isEmpty ? _hiddenKey : _blockedKey;
    final value = item.authorId.isEmpty ? item.id : item.authorId;
    final items = {...?prefs.getStringList(key), value};
    if (!await prefs.setStringList(key, items.toList())) {
      throw const ContentException('Unable to save blocked contributor');
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('divinewall.sessionToken.v1');
    if (token == null || token.isEmpty) {
      throw const ContentException('Please log in from Profile to continue.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  Future<void> reportTestimonial(Testimonial item, String reason) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '${BackendApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/testimonials/${Uri.encodeComponent(item.id)}/report');
    final response = await _client
        .post(uri, headers: headers, body: jsonEncode({'reason': reason}))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ContentException('Unable to send report. Please try again.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _hiddenKey, {...?prefs.getStringList(_hiddenKey), item.id}.toList());
  }

  Future<void> submitFeedback({
    required String name,
    required int rating,
    required String review,
  }) async {
    final uri = Uri.parse(
      '${BackendApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/testimonials',
    );
    final headers = await _authHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'name': name, 'rating': rating, 'review': review}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContentException('Feedback could not be submitted');
    }
  }

  Future<List<T>> _cachedList<T>({
    required String key,
    required bool refresh,
    required String path,
    required String arrayKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    if (!refresh) {
      final cached = await _readCache(key);
      if (cached.isNotEmpty) {
        // Return cached content immediately when offline. Online callers still
        // fetch below so newly published content appears automatically.
        if (await isOffline) return cached.map(fromJson).toList();
      }
    }
    final uri = Uri.parse(
      '${BackendApi.baseUrl.replaceFirst(RegExp(r'/$'), '')}$path',
    );
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ContentException('Unable to refresh content');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body[arrayKey] as List<dynamic>? ?? const [])
          .map((row) => fromJson(row as Map<String, dynamic>))
          .toList();
      await _writeCache(key, items.map(toJson).toList());
      return items;
    } catch (_) {
      final cached = await _readCache(key);
      if (cached.isNotEmpty) return cached.map(fromJson).toList();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _readCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$key');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$key', jsonEncode(value));
  }

  void dispose() => _client.close();
}

class ContentException implements Exception {
  final String message;
  const ContentException(this.message);
  @override
  String toString() => message;
}
