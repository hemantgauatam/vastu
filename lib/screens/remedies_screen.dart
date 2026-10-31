import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/remedy_data.dart';
import '../services/account_storage.dart';
import '../services/backend_api.dart';
import '../theme/app_theme.dart';

class _RemedyNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final ImageErrorWidgetBuilder? errorWidget;

  const _RemedyNetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: errorWidget,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      fit: fit,
      errorWidget: errorWidget == null
          ? null
          : (context, _, error) => errorWidget!(context, error, null),
    );
  }
}

class RemediesScreen extends StatelessWidget {
  final AccountStorage account;
  final VoidCallback onOpenProfile;
  static final BackendApi _api = BackendApi();
  const RemediesScreen({
    super.key,
    required this.account,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: account,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 380 ? 10.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 8, padding, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'VASTU REMEDIES',
                        style: AppTheme.uiLabel(
                          size: 10,
                          color: AppTheme.gold.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          Expanded(
                            child: Text(
                              'Remedies',
                              style: AppTheme.divineTitle(size: 30),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          _CartButton(
                            count: account.cartCount,
                            onPressed: () => _showCart(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        account.hasAccount
                            ? 'Signed in as ${account.profile!.name}'
                            : 'Add remedies to cart and login later to sync purchases.',
                        style: AppTheme.uiText(
                          size: 12,
                          color: AppTheme.cream.withValues(alpha: 0.62),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FutureBuilder<List<RemedyItem>>(
                        future: _api.fetchRemedies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final remedies = snapshot.data!;
                          final sections = <String, List<RemedyItem>>{};
                          for (final remedy in remedies) {
                            sections
                                .putIfAbsent(remedy.category, () => [])
                                .add(remedy);
                          }
                          return Column(
                            children: sections.entries
                                .map((entry) => _RemedySection(
                                      title: entry.key,
                                      remedies: entry.value,
                                      account: account,
                                      onOpenProfile: onOpenProfile,
                                      onOpenCart: () => _showCart(context),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCart(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        account: account,
        onLoginRequired: () {
          Navigator.of(context).pop();
          onOpenProfile();
        },
      ),
    );
  }
}

class _RemedySection extends StatelessWidget {
  final String title;
  final List<RemedyItem> remedies;
  final AccountStorage account;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCart;

  const _RemedySection({
    required this.title,
    required this.remedies,
    required this.account,
    required this.onOpenProfile,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTheme.divineTitle(size: 21)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: AppTheme.glassDecoration(radius: 12),
                child: Text(
                  '${remedies.length}',
                  style: AppTheme.uiText(
                    size: 10,
                    color: AppTheme.goldBright,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 430
                  ? 1
                  : constraints.maxWidth < 720
                      ? 2
                      : constraints.maxWidth < 1000
                          ? 3
                          : 4;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: remedies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 24,
                  mainAxisExtent: columns == 1 ? 410 : 390,
                ),
                itemBuilder: (context, index) => _RemedyCard(
                  remedy: remedies[index],
                  account: account,
                  relatedRemedies: remedies,
                  onOpenProfile: onOpenProfile,
                  onOpenCart: onOpenCart,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemedyCard extends StatelessWidget {
  final RemedyItem remedy;
  final AccountStorage account;
  final List<RemedyItem> relatedRemedies;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCart;

  const _RemedyCard({
    required this.remedy,
    required this.account,
    required this.relatedRemedies,
    required this.onOpenProfile,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    final activePurchase = account.activePurchaseFor(remedy.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProduct(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: AppTheme.cardDecoration(radius: 14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF8F6F0),
                        child: remedy.imageUrls.isEmpty
                            ? _ProductPlaceholder(remedy: remedy)
                            : _RemedyNetworkImage(
                                url: remedy.imageUrls.first,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) =>
                                    _ProductPlaceholder(remedy: remedy),
                              ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: IconButton.filledTonal(
                        tooltip: 'Save ${remedy.title}',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${remedy.title} saved.'),
                        )),
                        icon: const Icon(Icons.bookmark_border, size: 21),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remedy.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.uiText(size: 15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Rs ${remedy.price}.00',
                      style: AppTheme.uiText(
                        size: 14,
                        color: AppTheme.goldBright,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: activePurchase == null
                            ? () => _buyNow(context)
                            : null,
                        child: Text(
                            activePurchase == null ? 'Buy Now' : 'Purchased'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buyNow(BuildContext context) async {
    await account.addToCart(remedy);
    if (!context.mounted) return;
    onOpenCart();
  }

  Future<void> _showProduct(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _ProductDetailDialog(
        remedy: remedy,
        account: account,
        relatedRemedies: relatedRemedies,
        onOpenProfile: onOpenProfile,
        onOpenCart: onOpenCart,
      ),
    );
  }
}

class _ProductDetailDialog extends StatefulWidget {
  final RemedyItem remedy;
  final AccountStorage account;
  final List<RemedyItem> relatedRemedies;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCart;

  const _ProductDetailDialog({
    required this.remedy,
    required this.account,
    required this.relatedRemedies,
    required this.onOpenProfile,
    required this.onOpenCart,
  });

  @override
  State<_ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<_ProductDetailDialog> {
  int _quantity = 1;
  int _selectedImage = 0;
  bool _adding = false;

  RemedyItem get remedy => widget.remedy;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.width < 760;
    final content = compact
        ? Column(
            children: [
              _gallery(height: 330),
              _details(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _gallery(height: 620)),
              const SizedBox(width: 28),
              Expanded(flex: 5, child: _details()),
            ],
          );
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF8F4EA),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close product',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'KUBER VASTU REMEDIES',
                    style: AppTheme.uiLabel(
                      size: 11,
                      color: const Color(0xFF8A6827),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 32,
                  12,
                  compact ? 16 : 32,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gallery({required double height}) {
    final images = remedy.imageUrls.take(10).toList();
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: ListView.separated(
              itemCount: images.isEmpty ? 4 : images.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) => InkWell(
                onTap: images.isEmpty
                    ? null
                    : () => setState(() => _selectedImage = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: index == _selectedImage
                          ? const Color(0xFFB88923)
                          : const Color(0xFFE4DCCB),
                      width: index == _selectedImage ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: images.isEmpty
                      ? Icon(
                          index == 0
                              ? remedy.icon
                              : Icons.auto_awesome_outlined,
                          color: const Color(0xFFB88923),
                        )
                      : _RemedyNetworkImage(
                          url: images[index],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(remedy.icon),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4DCCB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: images.isEmpty
                        ? _ProductPlaceholder(remedy: remedy)
                        : InkWell(
                            onTap: () => _showImageZoom(
                              context,
                              images[_selectedImage],
                            ),
                            mouseCursor: SystemMouseCursors.zoomIn,
                            child: _RemedyNetworkImage(
                              url: images[_selectedImage],
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  _ProductPlaceholder(remedy: remedy),
                            ),
                          ),
                  ),
                  if (images.length > 1) ...[
                    Positioned(
                      left: 10,
                      child: _imageArrow(
                        Icons.chevron_left,
                        () => setState(() {
                          _selectedImage =
                              (_selectedImage - 1 + images.length) %
                                  images.length;
                        }),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: _imageArrow(
                        Icons.chevron_right,
                        () => setState(() {
                          _selectedImage = (_selectedImage + 1) % images.length;
                        }),
                      ),
                    ),
                  ],
                  if (images.isNotEmpty)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.zoom_in, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Zoom',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
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

  Widget _imageArrow(IconData icon, VoidCallback onPressed) => Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(
          tooltip: icon == Icons.chevron_left ? 'Previous image' : 'Next image',
          onPressed: onPressed,
          icon: Icon(icon, color: const Color(0xFF17130D)),
        ),
      );

  Future<void> _showImageZoom(BuildContext context, String imageUrl) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        builder: (dialogContext) => Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 6,
                child: Center(
                  child: _RemedyNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: SafeArea(
                child: IconButton.filled(
                  tooltip: 'Close zoom',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _details() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              remedy.category,
              style: AppTheme.uiText(
                size: 12,
                color: const Color(0xFF806F55),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${remedy.title} - ${remedy.subtitle}',
              style: const TextStyle(
                fontSize: 29,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17130D),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),
            Text(
              'Rs ${remedy.price}.00',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17130D),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tax included. Shipping calculated at checkout.',
              style: TextStyle(fontSize: 11, color: Color(0xFF806F55)),
            ),
            const SizedBox(height: 22),
            const Text('Quantity', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8CFBE)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _adding ? null : () => _addToCart(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF17130D),
                      side: const BorderSide(color: Color(0xFF17130D)),
                    ),
                    child: const Text('Add to cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _adding ? null : () => _addToCart(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF17130D),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _benefit(
              'Why you need it',
              remedy.whyYouNeed.isEmpty ? remedy.purpose : remedy.whyYouNeed,
              Icons.help_outline,
            ),
            _benefit(
              'How it works',
              remedy.howItWorks.isEmpty ? remedy.subtitle : remedy.howItWorks,
              Icons.auto_awesome_outlined,
            ),
            _benefit(
              'What you get',
              remedy.whatYouGet.isEmpty ? remedy.purpose : remedy.whatYouGet,
              Icons.verified_outlined,
            ),
            _benefit(
              'Where to place it',
              remedy.placement.isEmpty ? remedy.direction : remedy.placement,
              Icons.explore_outlined,
            ),
            const SizedBox(height: 4),
            _offers(),
            const SizedBox(height: 24),
            _installationGuide(),
            const SizedBox(height: 28),
            _relatedProducts(),
          ],
        ),
      );

  Widget _offers() {
    final offers = remedy.offers.isEmpty
        ? const [
            'Extra 5% off on prepaid orders.',
            'Available coupons are shown during checkout.',
          ]
        : remedy.offers;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5C981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 20, color: Color(0xFF9B7428)),
              SizedBox(width: 8),
              Text(
                'Offers',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final offer in offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $offer'),
            ),
        ],
      ),
    );
  }

  Widget _installationGuide() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Installation Guide',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17130D),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _guideStep('1', 'Identify', 'Confirm the correct Vastu zone.'),
              const SizedBox(width: 8),
              _guideStep('2', 'Place', 'Position it in ${remedy.direction}.'),
              const SizedBox(width: 8),
              _guideStep(
                  '3', 'Activate', 'Keep the area clean and intentional.'),
            ],
          ),
          if (remedy.installationImageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: remedy.installationImageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _RemedyNetworkImage(
                    url: remedy.installationImageUrls[index],
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (remedy.installationVideoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(Uri.parse(remedy.installationVideoUrls.first)),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch installation video'),
            ),
          ],
        ],
      );

  Widget _guideStep(String number, String title, String body) => Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4DCCB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFB88923),
                child: Text(number,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      );

  Widget _relatedProducts() {
    final related = widget.relatedRemedies
        .where((item) => item.id != remedy.id)
        .take(4)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You may also like',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17130D),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final item = related[index];
              return InkWell(
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  showDialog<void>(
                    context: navigator.context,
                    useSafeArea: false,
                    builder: (_) => _ProductDetailDialog(
                      remedy: item,
                      account: widget.account,
                      relatedRemedies: widget.relatedRemedies,
                      onOpenProfile: widget.onOpenProfile,
                      onOpenCart: widget.onOpenCart,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 145,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4DCCB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: Icon(item.icon,
                              size: 52, color: const Color(0xFFB88923)),
                        ),
                      ),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text('Rs ${item.price}',
                          style: const TextStyle(color: Color(0xFF9B7428))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _benefit(String title, String body, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF9B7428)),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF31291F),
                    fontSize: 13,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: body),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _addToCart(bool buyNow) async {
    setState(() => _adding = true);
    for (var index = 0; index < _quantity; index++) {
      await widget.account.addToCart(remedy);
    }
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          buyNow
              ? 'Added to cart. Open the cart to checkout.'
              : '$_quantity × ${remedy.title} added to cart.',
        ),
      ),
    );
    if (buyNow) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOpenCart();
      });
    }
  }
}

class _ProductPlaceholder extends StatelessWidget {
  final RemedyItem remedy;

  const _ProductPlaceholder({required this.remedy});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              remedy.colors.first.withValues(alpha: 0.16),
              remedy.colors.last.withValues(alpha: 0.28),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(remedy.icon, size: 104, color: const Color(0xFFB88923)),
              const SizedBox(height: 20),
              Text(
                remedy.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF493A22),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                remedy.direction,
                style: const TextStyle(color: Color(0xFF806F55)),
              ),
            ],
          ),
        ),
      );
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _CartButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton.filledTonal(
            tooltip: 'Open cart',
            onPressed: onPressed,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.accentRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: AppTheme.uiText(
                    size: 9,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      );
}

class _CartSheet extends StatefulWidget {
  final AccountStorage account;
  final VoidCallback onLoginRequired;

  const _CartSheet({required this.account, required this.onLoginRequired});

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  bool _checkingOut = false;
  String _paymentStatus = '';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.account,
        builder: (context, _) {
          final cart = widget.account.cart;
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.bgPanel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your Cart (${widget.account.cartCount})',
                            style: AppTheme.divineTitle(size: 25),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: cart.isEmpty
                        ? Center(
                            child: Text(
                              'Your cart is empty.',
                              style: AppTheme.uiText(
                                size: 14,
                                color: AppTheme.muted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: cart.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final line = cart[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: AppTheme.cardDecoration(radius: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.remedy.title,
                                            style: AppTheme.uiText(
                                              size: 14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Rs ${line.remedy.price} each - Rs ${line.total}',
                                            style: AppTheme.uiText(
                                              size: 11,
                                              color: AppTheme.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => widget.account
                                          .setCartQuantity(line.remedy.id,
                                              line.quantity - 1),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                    ),
                                    Text('${line.quantity}'),
                                    IconButton(
                                      onPressed: () => widget.account
                                          .setCartQuantity(line.remedy.id,
                                              line.quantity + 1),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  if (cart.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: AppTheme.uiText(size: 14)),
                              Text(
                                'Rs ${widget.account.cartTotal}',
                                style: AppTheme.uiText(
                                  size: 18,
                                  color: AppTheme.goldBright,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_paymentStatus.isNotEmpty) ...[
                            Text(
                              _paymentStatus,
                              textAlign: TextAlign.center,
                              style: AppTheme.uiText(
                                size: 11,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _checkingOut ? null : _checkout,
                              icon: _checkingOut
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.lock_outline),
                              label: Text(widget.account.isLoggedIn
                                  ? 'Proceed to Secure Payment'
                                  : 'Login to Checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );

  Future<void> _checkout() async {
    if (!widget.account.isLoggedIn) {
      widget.onLoginRequired();
      return;
    }
    final shipping = await showDialog<ShippingDetails>(
      context: context,
      builder: (_) => _ShippingDialog(profile: widget.account.profile),
    );
    if (shipping == null || !mounted) return;
    setState(() => _checkingOut = true);
    try {
      final session = await widget.account.createPaymentSession(shipping);
      final checkoutUri = Uri.tryParse(session.checkoutUrl);
      if (checkoutUri == null || !await launchUrl(checkoutUri)) {
        throw Exception('Unable to open Razorpay checkout.');
      }
      if (mounted) {
        setState(() {
          _paymentStatus =
              'Complete payment in Razorpay. Verification will happen automatically.';
        });
      }
      var paid = false;
      for (var attempt = 0; attempt < 150 && !paid; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        paid = await widget.account.refreshPayment(session);
      }
      if (!mounted) return;
      if (!paid) {
        throw Exception('Payment is still pending. Please check again.');
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment completed. Your remedy is valid for one year.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }
}

class _ShippingDialog extends StatefulWidget {
  final UserProfile? profile;

  const _ShippingDialog({required this.profile});

  @override
  State<_ShippingDialog> createState() => _ShippingDialogState();
}

class _ShippingDialogState extends State<_ShippingDialog> {
  static const _citiesByState = <String, List<String>>{
    'Andhra Pradesh': [
      'Amaravati',
      'Guntur',
      'Tirupati',
      'Vijayawada',
      'Visakhapatnam'
    ],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang'],
    'Assam': ['Dibrugarh', 'Guwahati', 'Jorhat', 'Silchar'],
    'Bihar': ['Bhagalpur', 'Gaya', 'Muzaffarpur', 'Patna'],
    'Chhattisgarh': ['Bhilai', 'Bilaspur', 'Durg', 'Raipur'],
    'Goa': ['Margao', 'Mapusa', 'Panaji', 'Vasco da Gama'],
    'Gujarat': ['Ahmedabad', 'Gandhinagar', 'Rajkot', 'Surat', 'Vadodara'],
    'Haryana': ['Faridabad', 'Gurugram', 'Hisar', 'Karnal', 'Panipat'],
    'Himachal Pradesh': ['Dharamshala', 'Mandi', 'Solan', 'Shimla'],
    'Jharkhand': ['Bokaro', 'Dhanbad', 'Jamshedpur', 'Ranchi'],
    'Karnataka': ['Bengaluru', 'Hubballi', 'Mangaluru', 'Mysuru'],
    'Kerala': [
      'Kochi',
      'Kollam',
      'Kozhikode',
      'Thiruvananthapuram',
      'Thrissur'
    ],
    'Madhya Pradesh': ['Bhopal', 'Gwalior', 'Indore', 'Jabalpur', 'Ujjain'],
    'Maharashtra': ['Mumbai', 'Nagpur', 'Nashik', 'Pune', 'Thane'],
    'Manipur': ['Imphal', 'Thoubal'],
    'Meghalaya': ['Shillong', 'Tura'],
    'Mizoram': ['Aizawl', 'Lunglei'],
    'Nagaland': ['Dimapur', 'Kohima'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Puri', 'Rourkela'],
    'Punjab': ['Amritsar', 'Bathinda', 'Jalandhar', 'Ludhiana', 'Patiala'],
    'Rajasthan': ['Ajmer', 'Jaipur', 'Jodhpur', 'Kota', 'Udaipur'],
    'Sikkim': ['Gangtok', 'Namchi'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Salem',
      'Tiruchirappalli'
    ],
    'Telangana': ['Hyderabad', 'Karimnagar', 'Nizamabad', 'Warangal'],
    'Tripura': ['Agartala', 'Dharmanagar'],
    'Uttar Pradesh': [
      'Agra',
      'Ghaziabad',
      'Kanpur',
      'Lucknow',
      'Noida',
      'Varanasi'
    ],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Haldwani', 'Nainital'],
    'West Bengal': ['Asansol', 'Durgapur', 'Howrah', 'Kolkata', 'Siliguri'],
    'Andaman and Nicobar Islands': ['Port Blair'],
    'Chandigarh': ['Chandigarh'],
    'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
    'Delhi': ['New Delhi', 'Delhi'],
    'Jammu and Kashmir': ['Jammu', 'Srinagar'],
    'Ladakh': ['Kargil', 'Leh'],
    'Lakshadweep': ['Kavaratti'],
    'Puducherry': ['Karaikal', 'Mahe', 'Puducherry', 'Yanam'],
  };
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.name ?? '');
  late final _phone = TextEditingController(text: widget.profile?.phone ?? '');
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  String? _selectedState;
  String? _selectedCity;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _address,
      _city,
      _state,
      _pincode
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboardType, int maxLines = 1, String? pattern}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Enter $label';
          if (pattern != null && !RegExp(pattern).hasMatch(text)) {
            return 'Enter a valid $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Shipping details'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Full name', _name),
                  _field('Mobile number', _phone,
                      keyboardType: TextInputType.phone,
                      pattern: r'^[0-9+() -]{10,16}$'),
                  _field('Full address', _address, maxLines: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'State / Union Territory',
                        border: OutlineInputBorder(),
                      ),
                      items: _citiesByState.keys
                          .map((state) => DropdownMenuItem(
                              value: state,
                              child:
                                  Text(state, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedState = value;
                        _selectedCity = null;
                        _city.clear();
                        _state.text = value ?? '';
                      }),
                      validator: (value) =>
                          value == null ? 'Select a state' : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selectedState),
                      initialValue: _selectedCity,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        ...?_citiesByState[_selectedState]?.map((city) =>
                            DropdownMenuItem(value: city, child: Text(city))),
                        if (_selectedState != null)
                          const DropdownMenuItem(
                              value: 'Other city', child: Text('Other city')),
                      ],
                      onChanged: _selectedState == null
                          ? null
                          : (value) => setState(() {
                                _selectedCity = value;
                                _city.text =
                                    value == 'Other city' ? '' : value ?? '';
                              }),
                      validator: (value) =>
                          value == null ? 'Select a city' : null,
                    ),
                  ),
                  if (_selectedCity == 'Other city') _field('Your city', _city),
                  _field('PIN code', _pincode,
                      keyboardType: TextInputType.number, pattern: r'^\d{6}$'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                  context,
                  ShippingDetails(
                    name: _name.text,
                    phone: _phone.text,
                    address: _address.text,
                    city: _city.text,
                    state: _state.text,
                    pincode: _pincode.text,
                  ));
            },
            child: const Text('Continue to payment'),
          ),
        ],
      );
}
