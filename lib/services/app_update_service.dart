import 'package:package_info_plus/package_info_plus.dart';

import 'backend_api.dart';

class AppUpdateInfo {
  final bool enabled;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppUpdateInfo({
    required this.enabled,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  bool get hasDownloadLink => downloadUrl.trim().isNotEmpty;

  bool get hasUpdate {
    if (!enabled) return false;
    if (latestBuildNumber > currentBuildNumber) return true;
    return _compareVersions(latestVersion, currentVersion) > 0;
  }

  String get currentLabel => '$currentVersion+$currentBuildNumber';
  String get latestLabel => '$latestVersion+$latestBuildNumber';

  static int _compareVersions(String a, String b) {
    final left = _versionParts(a);
    final right = _versionParts(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }

  static List<int> _versionParts(String value) {
    return value
        .split('.')
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}

class AppUpdateService {
  final BackendApi _api;

  AppUpdateService({BackendApi? api}) : _api = api ?? BackendApi();

  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final data = await _api.fetchAppUpdate();
    if (data == null) return null;

    final update = (data['update'] as Map<String, dynamic>?) ?? data;
    return AppUpdateInfo(
      enabled: update['enabled'] as bool? ?? true,
      currentVersion: packageInfo.version,
      currentBuildNumber: currentBuildNumber,
      latestVersion: update['latestVersion'] as String? ?? packageInfo.version,
      latestBuildNumber:
          (update['latestBuildNumber'] as num?)?.toInt() ?? currentBuildNumber,
      downloadUrl: update['downloadUrl'] as String? ?? '',
      releaseNotes: update['releaseNotes'] as String? ?? '',
      forceUpdate: update['forceUpdate'] as bool? ?? false,
    );
  }
}
