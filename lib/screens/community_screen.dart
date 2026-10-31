import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/content_models.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final ContentService _service = ContentService();
  late final TabController _tabs;
  final ScrollController _blogScroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  List<VideoItem> _videos = const [];
  List<BlogPost> _blogs = const [];
  List<Testimonial> _testimonials = const [];
  bool _loadingVideos = true;
  bool _loadingBlogs = true;
  bool _loadingTestimonials = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _blogPage = 1;
  String? _videoError;
  String? _blogError;
  String? _testimonialError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _blogScroll.addListener(_handleBlogScroll);
    unawaited(_loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait(
        [_loadVideos(), _loadBlogs(reset: true), _loadTestimonials()]);
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        _loadingVideos = true;
        _videoError = null;
      });
    }
    try {
      final value = await _service.fetchVideos(refresh: refresh);
      if (mounted) setState(() => _videos = value);
    } catch (error) {
      if (mounted) setState(() => _videoError = '$error');
    } finally {
      if (mounted) setState(() => _loadingVideos = false);
    }
  }

  Future<void> _loadBlogs({required bool reset}) async {
    if (reset) {
      _blogPage = 1;
      if (mounted) {
        setState(() {
          _loadingBlogs = true;
          _blogError = null;
        });
      }
    } else {
      if (_loadingMore || !_hasMore) return;
      if (mounted) setState(() => _loadingMore = true);
    }
    try {
      final page = await _service.fetchBlogs(
        page: _blogPage,
        query: _search.text,
        refresh: reset,
      );
      if (!mounted) return;
      setState(() {
        _blogs = reset ? page.items : [..._blogs, ...page.items];
        _hasMore = page.hasMore;
        if (page.hasMore) _blogPage++;
      });
    } catch (error) {
      if (mounted) setState(() => _blogError = '$error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingBlogs = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadTestimonials({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        _loadingTestimonials = true;
        _testimonialError = null;
      });
    }
    try {
      final value = await _service.fetchTestimonials(refresh: refresh);
      if (mounted) setState(() => _testimonials = value);
    } catch (error) {
      if (mounted) setState(() => _testimonialError = '$error');
    } finally {
      if (mounted) setState(() => _loadingTestimonials = false);
    }
  }

  void _handleBlogScroll() {
    if (_blogScroll.position.extentAfter < 280) {
      unawaited(_loadBlogs(reset: false));
    }
  }

  void _searchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _loadBlogs(reset: true),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabs.dispose();
    _blogScroll.dispose();
    _search.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Discover', style: AppTheme.divineTitle(size: 24)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.muted,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Videos'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Blogs'),
            Tab(icon: Icon(Icons.star_outline), text: 'Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_videoTab(), _blogTab(), _testimonialTab()],
      ),
    );
  }

  Widget _videoTab() => RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () => _loadVideos(refresh: true),
        child: _loadingVideos
            ? const _LoadingList()
            : _videoError != null
                ? _StateView(message: _videoError!, onRetry: _loadVideos)
                : _videos.isEmpty
                    ? const _StateView(message: 'No videos published yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                        itemCount: _videos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _VideoCard(
                          video: _videos[index],
                          onTap: () => _openVideo(_videos[index]),
                        ),
                      ),
      );

  Widget _blogTab() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: TextField(
              controller: _search,
              onChanged: _searchChanged,
              decoration: AppTheme.inputDecoration(
                label: 'Search articles',
                icon: Icons.search,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.gold,
              onRefresh: () => _loadBlogs(reset: true),
              child: _loadingBlogs
                  ? const _LoadingList()
                  : _blogError != null
                      ? _StateView(
                          message: _blogError!,
                          onRetry: () => _loadBlogs(reset: true))
                      : _blogs.isEmpty
                          ? const _StateView(message: 'No matching blog posts.')
                          : ListView.builder(
                              controller: _blogScroll,
                              padding:
                                  const EdgeInsets.fromLTRB(14, 8, 14, 100),
                              itemCount: _blogs.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (_, index) {
                                if (index == _blogs.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: AppTheme.gold)),
                                  );
                                }
                                final post = _blogs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _BlogCard(
                                    post: post,
                                    onTap: () => Navigator.of(context).push(
                                      _premiumRoute(
                                          BlogDetailScreen(post: post)),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      );

  Widget _testimonialTab() => RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () => _loadTestimonials(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Client Experiences',
                      style: AppTheme.divineTitle(size: 26)),
                ),
                FilledButton.icon(
                  onPressed: _showFeedbackDialog,
                  icon: const Icon(Icons.rate_review_outlined, size: 17),
                  label: const Text('Write Review'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loadingTestimonials)
              const _LoadingList()
            else if (_testimonialError != null)
              _StateView(
                  message: _testimonialError!, onRetry: _loadTestimonials)
            else if (_testimonials.isEmpty)
              const _StateView(message: 'No approved testimonials yet.')
            else
              _AutoTestimonials(items: _testimonials),
          ],
        ),
      );

  void _openVideo(VideoItem video) {
    Navigator.of(context).push(_premiumRoute(VideoPlayerScreen(video: video)));
  }

  Future<void> _showFeedbackDialog() async {
    final name = TextEditingController();
    final review = TextEditingController();
    var rating = 5;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Write Review', style: AppTheme.divineTitle(size: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: AppTheme.inputDecoration(label: 'Your name')),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (index) => IconButton(
                          onPressed: () =>
                              setDialogState(() => rating = index + 1),
                          icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: AppTheme.gold),
                        )),
              ),
              TextField(
                controller: review,
                minLines: 3,
                maxLines: 5,
                decoration: AppTheme.inputDecoration(label: 'Your experience'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty ||
                    review.text.trim().length < 10) {
                  return;
                }
                try {
                  await _service.submitFeedback(
                      name: name.text.trim(),
                      rating: rating,
                      review: review.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text('$error')));
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    review.dispose();
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you. Your review is awaiting approval.')),
      );
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  const VideoPlayerScreen({super.key, required this.video});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
          showFullscreenButton: true, strictRelatedVideos: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.video.title,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: Center(
            child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9)),
      );
}

class BlogDetailScreen extends StatelessWidget {
  final BlogPost post;
  const BlogDetailScreen({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(post.category),
          actions: [
            IconButton(
              onPressed: () =>
                  Share.share('${post.title}\n\n${post.description}'),
              icon: const Icon(Icons.share_outlined),
            )
          ],
        ),
        body: Hero(
          tag: 'blog-${post.id}',
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 80),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                            imageUrl: post.imageUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 18),
                    Text(post.title,
                        style: AppTheme.divineTitle(
                            size: 32, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${post.category} • ${_date(post.publishedAt)}',
                        style:
                            AppTheme.uiLabel(size: 11, color: AppTheme.gold)),
                    const SizedBox(height: 18),
                    Text(post.content.isEmpty ? post.description : post.content,
                        style: AppTheme.uiText(size: 15, color: AppTheme.body)
                            .copyWith(height: 1.7)),
                  ]),
            ),
          ),
        ),
      );
}

class _VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: AppTheme.cardDecoration(radius: 16),
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(alignment: Alignment.center, children: [
              AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppTheme.goldSoft),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.ondemand_video, size: 48),
                  )),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: AppTheme.accentRed, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 30)),
            ]),
            Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.uiText(
                              size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(_date(video.publishedAt),
                          style: AppTheme.uiLabel(size: 10)),
                    ])),
          ]),
        ),
      );
}

class _BlogCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onTap;
  const _BlogCard({required this.post, required this.onTap});
  @override
  Widget build(BuildContext context) => Hero(
        tag: 'blog-${post.id}',
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.cardDecoration(radius: 16),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 104,
                          height: 104,
                          child: post.imageUrl.isEmpty
                              ? const ColoredBox(
                                  color: AppTheme.goldSoft,
                                  child: Icon(Icons.auto_stories,
                                      color: AppTheme.gold))
                              : CachedNetworkImage(
                                  imageUrl: post.imageUrl, fit: BoxFit.cover))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(post.category.toUpperCase(),
                            style: AppTheme.uiLabel(
                                size: 9, color: AppTheme.gold)),
                        const SizedBox(height: 4),
                        Text(post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.uiText(
                                size: 15, weight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(post.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.uiText(
                                size: 11, color: AppTheme.muted)),
                      ])),
                ]),
              ),
            )),
      );
}

class _AutoTestimonials extends StatefulWidget {
  final List<Testimonial> items;
  const _AutoTestimonials({required this.items});
  @override
  State<_AutoTestimonials> createState() => _AutoTestimonialsState();
}

class _AutoTestimonialsState extends State<_AutoTestimonials> {
  final PageController _page = PageController(viewportFraction: .9);
  Timer? _timer;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.items.length < 2) return;
      _index = (_index + 1) % widget.items.length;
      _page.animateToPage(_index,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _page,
        itemCount: widget.items.length,
        itemBuilder: (_, index) {
          final item = widget.items[index];
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(radius: 18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            radius: 25,
                            backgroundColor: AppTheme.goldSoft,
                            backgroundImage: item.profileImageUrl.isEmpty
                                ? null
                                : CachedNetworkImageProvider(
                                    item.profileImageUrl),
                            child: item.profileImageUrl.isEmpty
                                ? Text(item.name.characters.first.toUpperCase())
                                : null),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(item.name,
                                style: AppTheme.uiText(
                                    size: 15, weight: FontWeight.w800)))
                      ]),
                      const SizedBox(height: 12),
                      Row(
                          children: List.generate(
                              5,
                              (star) => Icon(
                                  star < item.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppTheme.gold,
                                  size: 19))),
                      const SizedBox(height: 12),
                      Expanded(
                          child: Text('“${item.review}”',
                              style: AppTheme.divineItalic(
                                      size: 18, color: AppTheme.body)
                                  .copyWith(height: 1.4),
                              overflow: TextOverflow.fade)),
                    ]),
              ));
        },
      ));
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 4,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.goldSoft,
          highlightColor: AppTheme.bgPanel,
          child: Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
        ),
      );
}

class _StateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _StateView({required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => ListView(children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .18),
        Icon(Icons.cloud_off_outlined, size: 46, color: AppTheme.gold),
        const SizedBox(height: 12),
        Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.uiText(size: 13, color: AppTheme.muted))),
        if (onRetry != null)
          Center(
              child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again')))
      ]);
}

Route<T> _premiumRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) =>
          FadeTransition(opacity: animation, child: page),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween(begin: const Offset(.035, .02), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child)),
      transitionDuration: const Duration(milliseconds: 380),
    );

String _date(DateTime? date) {
  if (date == null) return 'Recently published';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
