import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences across app launches:
/// - Last active chakra
/// - Last used floor plan path
class SettingsStorage {
  static const _kChakra = 'divinewall.chakra.v1';
  static const _kMapPath = 'divinewall.map_path.v1';
  static const _kMapRotation = 'divinewall.map_rotation.v1';
  static const _kMapScale = 'divinewall.map_scale.v1';

  Future<String?> getChakra() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kChakra);
  }

  Future<void> setChakra(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChakra, id);
  }

  Future<String?> getMapPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMapPath);
  }

  Future<void> setMapPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kMapPath);
    } else {
      await prefs.setString(_kMapPath, path);
    }
  }

  Future<double?> getMapRotation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kMapRotation);
  }

  Future<void> setMapRotation(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMapRotation, v);
  }

  Future<double?> getMapScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kMapScale);
  }

  Future<void> setMapScale(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMapScale, v);
  }
}
