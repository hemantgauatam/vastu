import 'package:flutter/material.dart';
import '../models/vastu_data.dart';
import '../services/capture_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CapturesScreen extends StatelessWidget {
  final CaptureStorage storage;

  const CapturesScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Container(
        decoration: AppTheme.appBackground(),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: storage,
            builder: (context, _) {
              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: storage.items.isEmpty
                        ? _buildEmpty()
                        : _buildList(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 380 ? 10.0 : 20.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 16),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAVED READINGS',
                      style: AppTheme.uiLabel(
                        size: 10,
                        color: AppTheme.gold.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capture History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.divineTitle(size: 22),
                    ),
                  ],
                ),
              ),
              if (storage.items.isNotEmpty)
                GlassIconButton(
                  icon: Icons.delete_sweep_outlined,
                  onTap: () => _confirmClear(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: AppTheme.gold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('No captures yet', style: AppTheme.divineTitle(size: 20)),
            const SizedBox(height: 8),
            Text(
              'Use the compass or live camera to save direction readings.\nThey will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.uiText(
                size: 13,
                color: AppTheme.cream.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 380 ? 10.0 : 16.0;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
          itemCount: storage.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = storage.items[i];
            final info =
                VastuData.directions[c.direction] ?? VastuData.directions['N']!;
            final chakraName = ChakraRegistry.all
                .firstWhere(
                  (x) => x.id == c.chakraId,
                  orElse: () => ChakraRegistry.all.first,
                )
                .name;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Dismissible(
                  key: ValueKey(c.time.millisecondsSinceEpoch),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                  onDismissed: (_) => storage.delete(c.time),
                  child: _buildCaptureCard(c, info, chakraName),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCaptureCard(
    CaptureEntry c,
    VastuDirection info,
    String chakraName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [info.color, info.color.withValues(alpha: 0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                info.name,
                style: AppTheme.uiText(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${c.heading.toStringAsFixed(1)} deg',
                      style: AppTheme.divineTitle(
                        size: 20,
                        color: AppTheme.goldBright,
                      ),
                    ),
                    Text(
                      info.deity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.uiText(
                        size: 13,
                        color: AppTheme.cream.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info.meaning,
                  style: AppTheme.uiText(
                    size: 11,
                    color: AppTheme.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(info.element, AppTheme.gold.withValues(alpha: 0.12)),
                    _chip(chakraName, AppTheme.gold.withValues(alpha: 0.08)),
                    Text(
                      _formatTime(c.time),
                      style: AppTheme.uiText(
                        size: 10,
                        color: AppTheme.cream.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.uiText(
          size: 9,
          color: AppTheme.body,
          weight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(MediaQuery.sizeOf(ctx).width < 360 ? 16 : 24),
          decoration: BoxDecoration(
            color: AppTheme.bgPanel.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear all captures?',
                style: AppTheme.divineTitle(size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'This will permanently remove all saved readings. This action cannot be undone.',
                style: AppTheme.uiText(
                  size: 13,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = constraints.maxWidth < 280
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: _dialogButton(
                          label: 'Cancel',
                          onTap: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: _dialogButton(
                          label: 'Clear All',
                          danger: true,
                          onTap: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await storage.clear();
    }
  }

  Widget _dialogButton({
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: danger
            ? BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              )
            : AppTheme.glassDecoration(radius: 12),
        child: Text(
          label,
          style: AppTheme.uiText(
            size: 13,
            weight: FontWeight.w600,
            color: danger ? Colors.redAccent : AppTheme.cream,
          ),
        ),
      ),
    );
  }
}
