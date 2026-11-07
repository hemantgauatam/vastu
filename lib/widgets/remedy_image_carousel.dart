import 'package:flutter/material.dart';

/// Product photos can be browsed from the listing without opening the product.
class RemedyImageCarousel extends StatefulWidget {
  final List<String> images;
  final Widget Function(BuildContext, String) imageBuilder;

  const RemedyImageCarousel({
    super.key,
    required this.images,
    required this.imageBuilder,
  });

  @override
  State<RemedyImageCarousel> createState() => _RemedyImageCarouselState();
}

class _RemedyImageCarouselState extends State<RemedyImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant RemedyImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length ||
        !oldWidget.images.asMap().entries.every((entry) =>
            entry.key < widget.images.length &&
            widget.images[entry.key] == entry.value)) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int offset) {
    if (!_controller.hasClients || widget.images.length < 2) return;
    _controller.animateToPage(
      (_index + offset + widget.images.length) % widget.images.length,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) =>
                widget.imageBuilder(context, widget.images[index]),
          ),
          if (widget.images.length > 1) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _arrow('Previous product image', Icons.chevron_left, -1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _arrow('Next product image', Icons.chevron_right, 1),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_index + 1} / ${widget.images.length}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _arrow(String label, IconData icon, int offset) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton.filledTonal(
          tooltip: label,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .9),
            foregroundColor: Colors.black87,
          ),
          onPressed: () => _move(offset),
          icon: Icon(icon),
        ),
      );
}
