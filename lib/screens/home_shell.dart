import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/compass_service.dart';
import '../services/capture_storage.dart';
import '../services/account_storage.dart';
import '../services/app_update_service.dart';
import '../models/vastu_data.dart';
import 'home_screen.dart';
import 'compass_screen.dart';
import 'map_screen.dart';
import 'camera_screen.dart';
import 'captures_screen.dart';
import 'remedies_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';

class HomeShell extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onThemeToggle;

  const HomeShell({
    super.key,
    this.darkMode = false,
    this.onThemeToggle = _noop,
  });

  static void _noop() {}

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _colorThemeKey = 'kubar_vastu.color_theme.v1';
  int _currentIndex = kIsWeb ? 0 : 2;
  int _colorThemeIndex = 0;

  // Shared services across tabs
  final CompassService _compass = CompassService();
  final CaptureStorage _storage = CaptureStorage();
  final AccountStorage _account = AccountStorage();
  final AppUpdateService _updates = AppUpdateService();

  // Shared state
  String _activeChakra = 'compass-chakra';
  bool _checkingUpdates = false;

  @override
  void initState() {
    super.initState();
    final returningFromPayment =
        kIsWeb && Uri.base.queryParameters['payment'] == 'success';
    if (returningFromPayment) _currentIndex = 4;
    _compass.start();
    _storage.load();
    _loadAccount(returningFromPayment: returningFromPayment);
    _loadColorTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(silent: true);
    });
  }

  Future<void> _loadAccount({required bool returningFromPayment}) async {
    await _account.load();
    if (!mounted || !returningFromPayment) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Payment successful. Your purchased remedies are shown below.'),
      ),
    );
  }

  Future<void> _loadColorTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getInt(_colorThemeKey) ?? 0).clamp(0, 5);
    if (mounted) setState(() => _colorThemeIndex = saved);
  }

  Widget _applyColorTheme(Widget child) {
    final filter = switch (_colorThemeIndex) {
      1 => const ColorFilter.mode(Color(0xFF176B57), BlendMode.hue),
      2 => const ColorFilter.mode(Color(0xFFB85C38), BlendMode.hue),
      3 => const ColorFilter.mode(Color(0xFF274C77), BlendMode.hue),
      4 => const ColorFilter.mode(Color(0xFF71806A), BlendMode.hue),
      5 => const ColorFilter.matrix([
          -0.72,
          0,
          0,
          0,
          235,
          0,
          -0.72,
          0,
          0,
          222,
          0,
          0,
          -0.72,
          0,
          190,
          0,
          0,
          0,
          1,
          0,
        ]),
      _ => null,
    };
    return filter == null
        ? child
        : ColorFiltered(colorFilter: filter, child: child);
  }

  @override
  void dispose() {
    _compass.dispose();
    _storage.dispose();
    _account.dispose();
    super.dispose();
  }

  void _onChakraChange(String id) {
    setState(() => _activeChakra = id);
  }

  void _onCapture(CaptureEntry entry) async {
    await _storage.add(entry);
  }

  void _openProfile() {
    setState(() => _currentIndex = 4);
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(
            child: CameraScreen(
              compass: _compass,
              activeChakra: _activeChakra,
              onChakraChange: _onChakraChange,
              onCapture: _onCapture,
            ),
          ),
        ),
      ),
    );
  }

  void _openCaptures() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CapturesScreen(storage: _storage),
      ),
    );
  }

  Future<void> _checkForUpdates({bool silent = false}) async {
    if (_checkingUpdates) return;
    setState(() => _checkingUpdates = true);
    try {
      final info = await _updates.checkForUpdate();
      if (!mounted) return;
      if (info == null || !info.hasUpdate) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.bgPanel,
              content: Text(
                'App is already up to date.',
                style: AppTheme.uiText(size: 13),
              ),
            ),
          );
        }
        return;
      }
      await _showUpdateDialog(info);
    } catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Update check failed: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo info) async {
    final canForce = info.forceUpdate && info.hasDownloadLink;
    await showDialog<void>(
      context: context,
      barrierDismissible: !canForce,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.bgPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.2)),
          ),
          title: Text(
            info.forceUpdate ? 'Update required' : 'New update available',
            style: AppTheme.divineTitle(size: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${info.currentLabel}\nLatest: ${info.latestLabel}',
                style: AppTheme.uiText(
                  size: 12,
                  color: AppTheme.muted,
                  weight: FontWeight.w600,
                ),
              ),
              if (info.releaseNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  info.releaseNotes.trim(),
                  style: AppTheme.uiText(size: 13, color: AppTheme.body),
                ),
              ],
              if (!info.hasDownloadLink) ...[
                const SizedBox(height: 12),
                Text(
                  'Download link is not configured in admin panel.',
                  style: AppTheme.uiText(
                    size: 12,
                    color: AppTheme.accentRed,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!canForce)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  info.hasDownloadLink ? 'Later' : 'Close',
                  style: AppTheme.uiText(
                    size: 13,
                    color: AppTheme.muted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            if (info.hasDownloadLink)
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.tryParse(info.downloadUrl.trim());
                  if (url == null) return;
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.system_update_alt, size: 16),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.cream,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final compactPhone = MediaQuery.sizeOf(context).width < 380;
    if (kIsWeb) return _applyColorTheme(_buildWebShell());

    final screens = [
      AnimatedBuilder(
        animation: _storage,
        builder: (context, _) => HomeScreen(
          activeChakra: _activeChakra,
          onChakraChange: _onChakraChange,
          onGoCompass: () => setState(() => _currentIndex = 2),
          onGoCamera: _openCamera,
          onUploadMap: () => setState(() => _currentIndex = 3),
          onSeeAllCaptures: _openCaptures,
          captures: _storage.items,
        ),
      ),
      RemediesScreen(account: _account, onOpenProfile: _openProfile),
      CompassScreen(
        compass: _compass,
        activeChakra: _activeChakra,
        onChakraChange: _onChakraChange,
        onOpenCamera: _openCamera,
      ),
      const MapScreen(),
      ProfileScreen(
        account: _account,
        onCheckForUpdates: () => _checkForUpdates(),
        checkingUpdates: _checkingUpdates,
      ),
      const CommunityScreen(),
    ];

    return _applyColorTheme(Scaffold(
      backgroundColor: _currentIndex == 3 ? Colors.white : AppTheme.bgDark,
      body: Container(
        color: _currentIndex == 3 ? Colors.white : const Color(0xFFF6F3EA),
        child: SafeArea(
          child: Column(
            children: [
              if (_currentIndex != 3) _buildBrandHeader(),
              Expanded(child: screens[_currentIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.bgPanel,
          border: Border(
            top: BorderSide(color: AppTheme.gold.withValues(alpha: 0.18)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.body.withValues(alpha: 0.1),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          height: compactPhone ? 56 : 64,
          labelBehavior: compactPhone
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          backgroundColor: AppTheme.bgPanel,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppTheme.goldSoft,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppTheme.gold : AppTheme.muted,
            );
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 20),
              selectedIcon: Icon(Icons.home, size: 20),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.spa_outlined, size: 20),
              selectedIcon: Icon(Icons.spa, size: 20),
              label: 'Remedies',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, size: 20),
              selectedIcon: Icon(Icons.explore, size: 20),
              label: 'Chakra',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, size: 20),
              selectedIcon: Icon(Icons.map, size: 20),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 20),
              selectedIcon: Icon(Icons.person, size: 20),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, size: 20),
              selectedIcon: Icon(Icons.explore, size: 20),
              label: 'Discover',
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildWebShell() {
    final screens = [
      AnimatedBuilder(
        animation: _storage,
        builder: (context, _) => HomeScreen(
          activeChakra: _activeChakra,
          onChakraChange: _onChakraChange,
          onGoCompass: () {},
          onGoCamera: _openCamera,
          onUploadMap: () => setState(() => _currentIndex = 2),
          onSeeAllCaptures: _openCaptures,
          captures: _storage.items,
        ),
      ),
      RemediesScreen(account: _account, onOpenProfile: _openProfile),
      const MapScreen(),
      const CommunityScreen(),
      ProfileScreen(
        account: _account,
        onCheckForUpdates: () => _checkForUpdates(),
        checkingUpdates: _checkingUpdates,
      ),
    ];
    final safeIndex = _currentIndex.clamp(0, screens.length - 1).toInt();
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) {
      final compact = width < 380;
      return Scaffold(
        backgroundColor: safeIndex == 2 ? Colors.white : AppTheme.bgDark,
        body: Container(
          decoration: safeIndex == 2
              ? const BoxDecoration(color: Colors.white)
              : AppTheme.appBackground(),
          child: SafeArea(
            child: Column(
              children: [
                if (safeIndex != 2) _buildBrandHeader(),
                Expanded(child: screens[safeIndex]),
              ],
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgPanel,
            border: Border(
              top: BorderSide(color: AppTheme.gold.withValues(alpha: 0.18)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.body.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              height: compact ? 58 : 64,
              labelBehavior: compact
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              elevation: 0,
              backgroundColor: AppTheme.bgPanel,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppTheme.goldSoft,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, size: 20),
                  selectedIcon: Icon(Icons.home, size: 20),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.spa_outlined, size: 20),
                  selectedIcon: Icon(Icons.spa, size: 20),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined, size: 20),
                  selectedIcon: Icon(Icons.map, size: 20),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined, size: 20),
                  selectedIcon: Icon(Icons.explore, size: 20),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline, size: 20),
                  selectedIcon: Icon(Icons.person, size: 20),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: safeIndex == 2 ? Colors.white : AppTheme.bgDark,
      body: Container(
        decoration: safeIndex == 2
            ? const BoxDecoration(color: Colors.white)
            : AppTheme.appBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildWebHeader(safeIndex),
              Expanded(child: screens[safeIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSidebar(int selectedIndex) {
    const items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.spa_outlined, Icons.spa, 'Services'),
      (Icons.map_outlined, Icons.map, 'Map Analysis'),
      (Icons.explore_outlined, Icons.explore, 'Discover'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppTheme.bgPanel.withValues(alpha: 0.98),
        border: Border(
          right: BorderSide(color: AppTheme.gold.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.body.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 18, 18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kuber Vastu',
                        style: AppTheme.divineTitle(size: 21),
                      ),
                      Text(
                        'Professional workspace',
                        style: AppTheme.uiText(
                          size: 10,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.gold.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                selected: selectedIndex == index,
                onTap: () => setState(() => _currentIndex = index),
                leading: Icon(
                  selectedIndex == index ? items[index].$2 : items[index].$1,
                  size: 21,
                ),
                title: Text(items[index].$3),
                trailing: selectedIndex == index
                    ? const Icon(Icons.chevron_right, size: 18)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selectedColor: AppTheme.gold,
                iconColor: AppTheme.muted,
                textColor: AppTheme.muted,
                selectedTileColor: AppTheme.gold.withValues(alpha: 0.11),
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWebPageHeader(int selectedIndex) {
    const pages = [
      ('Dashboard', 'Overview and recent activity', Icons.dashboard_outlined),
      ('Services', 'Vastu remedies and consultations', Icons.spa_outlined),
      (
        'Map Analysis',
        'Crop, align and export Vastu reports',
        Icons.map_outlined
      ),
      ('Discover', 'Articles, videos and community', Icons.explore_outlined),
      ('Profile', 'Account and application settings', Icons.person_outline),
    ];
    final page = pages[selectedIndex];
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(color: AppTheme.gold.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(page.$3, color: AppTheme.gold, size: 21),
          ),
          const SizedBox(width: 13),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(page.$1, style: AppTheme.divineTitle(size: 20)),
              const SizedBox(height: 2),
              Text(
                page.$2,
                style: AppTheme.uiText(size: 11, color: AppTheme.muted),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Kuber Vastu Web',
            style: AppTheme.uiLabel(size: 10, color: AppTheme.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader(int selectedIndex) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.spa_outlined, 'Services'),
      (Icons.map_outlined, 'Map Analysis'),
      (Icons.explore_outlined, 'Discover'),
      (Icons.person_outline, 'Profile'),
    ];
    const ink = Color(0xFF2A2117);
    const gold = Color(0xFF9B7428);
    final compactHeader = MediaQuery.sizeOf(context).width < 1100;
    return Container(
      height: 86,
      padding: EdgeInsets.symmetric(horizontal: compactHeader ? 18 : 46),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        border: Border(
          bottom: BorderSide(
            color: gold.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: gold.withValues(alpha: .28)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/images/app_logo.png'),
            ),
          ),
          SizedBox(width: compactHeader ? 8 : 12),
          if (!compactHeader) ...[
            const Text(
              'Kuber Vastu',
              style: TextStyle(
                color: ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 24),
          ] else
            const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _currentIndex = index),
                        icon: Icon(items[index].$1, size: 18),
                        label: Text(items[index].$2),
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          backgroundColor: selectedIndex == index
                              ? gold.withValues(alpha: 0.12)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:9828630111')),
                    icon: const Icon(Icons.phone_outlined, size: 17),
                    label: const Text('Call 9828630111'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Container(
      height: compact ? 46 : 54,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(
          bottom: BorderSide(color: AppTheme.gold.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              border: Border.all(color: AppTheme.gold.withValues(alpha: .32)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: .18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: compact ? 32 : 38,
                height: compact ? 32 : 38,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Kuber Vastu',
                style: AppTheme.divineTitle(size: compact ? 19 : 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
