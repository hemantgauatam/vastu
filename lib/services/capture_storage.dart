import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vastu_data.dart';

/// Stores capture history in SharedPreferences as JSON.
/// Exposes a ChangeNotifier so screens rebuild when captures are added/deleted.
class CaptureStorage extends ChangeNotifier {
  static const _key = 'divinewall.captures.v1';
  static const _maxCaptures = 100;

  List<CaptureEntry> _items = [];
  bool _loaded = false;

  List<CaptureEntry> get items => List.unmodifiable(_items);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items = list
            .map((e) {
              try {
                return CaptureEntry.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Kubar Vastu: Failed to parse capture entry: $e');
                return null;
              }
            })
            .whereType<CaptureEntry>()
            .toList();
      }
    } catch (e) {
      debugPrint('Kubar Vastu: Failed to load captures: $e');
      // Corrupt data — start fresh rather than crashing.
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(CaptureEntry entry) async {
    _items.insert(0, entry);
    if (_items.length > _maxCaptures) {
      _items = _items.sublist(0, _maxCaptures);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> delete(DateTime time) async {
    _items.removeWhere((e) => e.time == time);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('Kubar Vastu: Failed to persist captures: $e');
    }
  }
}
