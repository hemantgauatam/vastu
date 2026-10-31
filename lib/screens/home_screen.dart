import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/vastu_data.dart';
import '../models/content_models.dart';
import '../theme/app_theme.dart';
import 'community_screen.dart';

class HomeScreen extends StatelessWidget {
  static const _primaryPhone = '9828630111';
  static const _secondaryPhone = '9314508455';
  static const _primaryWhatsApp = '919828630111';
  static const _secondaryWhatsApp = '919314508455';
  static const _youtubeChannelId = String.fromEnvironment(
    'YOUTUBE_CHANNEL_ID',
    defaultValue: '',
  );
  static const _facebookUrl = String.fromEnvironment(
    'FACEBOOK_URL',
    defaultValue: 'https://www.facebook.com/',
  );
  static const _instagramUrl = String.fromEnvironment(
    'INSTAGRAM_URL',
    defaultValue: 'https://www.instagram.com/',
  );
  static const _websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://kubervastu.com/',
  );

  static const List<_LaunchSlideData> _launchSlides = [
    _LaunchSlideData(
      Icons.auto_awesome_outlined,
      'Latest Launch',
      'No-Demolition Vastu Solutions',
      'Practical corrections for homes, offices, shops, and factories without structural damage.',
    ),
    _LaunchSlideData(
      Icons.video_call_outlined,
      'Online Consultation',
      'Astro Vastu Guidance',
      'Book a call and get personalized direction, energy, and remedy guidance from anywhere.',
    ),
    _LaunchSlideData(
      Icons.map_outlined,
      'New App Tool',
      'Floor Plan Chakra Mapping',
      'Upload a map, set direction, and analyze zones with Vastu chakras.',
    ),
  ];

  static const List<_ServiceData> _services = [
    _ServiceData(
      Icons.home_outlined,
      'Residential Vastu',
      'Create a harmonious home that supports health, happiness, peace, and prosperity.',
    ),
    _ServiceData(
      Icons.storefront_outlined,
      'Commercial Vastu',
      'Optimize offices, shops, showrooms, and commercial spaces for growth and success.',
    ),
    _ServiceData(
      Icons.factory_outlined,
      'Industrial Vastu',
      'Vastu solutions for factories, warehouses, and manufacturing units to improve productivity and profitability.',
    ),
    _ServiceData(
      Icons.trending_up,
      'Business Growth Vastu',
      'Strategic guidance to enhance expansion, sales, financial stability, and overall performance.',
    ),
    _ServiceData(
      Icons.auto_awesome_outlined,
      'Astro Vastu Consultation',
      'A unique combination of Vastu and Astrology for personalized, result-oriented solutions.',
    ),
    _ServiceData(
      Icons.pin_outlined,
      'Numerology Consultation',
      'Discover how numbers influence your life, career, relationships, and success.',
    ),
    _ServiceData(
      Icons.energy_savings_leaf_outlined,
      'Vastu Audit & Energy Analysis',
      'A comprehensive property assessment with practical remedies for energy imbalances.',
    ),
    _ServiceData(
      Icons.construction_outlined,
      'No-Demolition Vastu Solutions',
      'Advanced corrections without structural changes, saving both time and money.',
    ),
    _ServiceData(
      Icons.account_balance_wallet_outlined,
      'Wealth & Prosperity Vastu',
      'Energy corrections designed to attract financial growth, abundance, and opportunities.',
    ),
    _ServiceData(
      Icons.videocam_outlined,
      'Online Vastu Consultation',
      'Professional video consultation available across India and worldwide.',
    ),
  ];

  static const List<String> _founderParagraphs = [
    'Vijay Kumar Goyal is the Founder & CEO of Kuber Vastu - The Miracle King, a trusted name in modern Vastu consultation dedicated to transforming lives through ancient wisdom, scientific understanding, and practical solutions.',
    'His journey into Vastu began in 2011. With Traditional Vastu, Pyramid Vastu, Astro Vastu, Jyotish, Numerology, and Energy Balancing, he developed a practical approach focused on results without unnecessary demolition or disruption.',
    'Today, he has guided more than 1,000 families, homeowners, entrepreneurs, and businesses across India for prosperity, career, business growth, health, relationships, and overall well-being.',
  ];

  static const List<_HighlightData> _highlights = [
    _HighlightData(
      Icons.workspace_premium_outlined,
      'Experience',
      '15+ Years',
      'Trusted Expertise',
    ),
    _HighlightData(
      Icons.groups_outlined,
      'Consultations',
      '1,000+',
      'Happy Clients Across India',
    ),
    _HighlightData(
      Icons.auto_awesome_outlined,
      'Specialization',
      'Advanced Vastu',
      'Astro Vastu, Jyotish, Numerology',
    ),
    _HighlightData(
      Icons.home_repair_service_outlined,
      'Solutions',
      'No Demolition',
      'Practical and Cost-Effective',
    ),
    _HighlightData(
      Icons.trending_up_outlined,
      'Focus',
      'Prosperity',
      'Health and Business Growth',
    ),
    _HighlightData(
      Icons.apartment_outlined,
      'Guidance',
      'Home & Office',
      'Commercial and Industrial',
    ),
    _HighlightData(
      Icons.psychology_outlined,
      'Approach',
      'Scientific',
      'Personalized and Result-Oriented',
    ),
    _HighlightData(
      Icons.spa_outlined,
      'Mission',
      'Transforming Lives',
      'Through Positive Energy',
    ),
  ];

  static const List<_VideoData> _fallbackVideos = [
    _VideoData('ccJZyHd_6EA', 'Kuber Vastu Video', 'Watch on YouTube'),
    _VideoData('dEpKvAtxqEU', 'Featured Vastu Video', 'Watch on YouTube'),
  ];

  final String activeChakra;
  final ValueChanged<String> onChakraChange;
  final VoidCallback onGoCompass;
  final VoidCallback onGoCamera;
  final VoidCallback onUploadMap;
  final VoidCallback onSeeAllCaptures;
  final List<CaptureEntry> captures;

  const HomeScreen({
    super.key,
    required this.activeChakra,
    required this.onChakraChange,
    required this.onGoCompass,
    required this.onGoCamera,
    required this.onUploadMap,
    required this.onSeeAllCaptures,
    required this.captures,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _HomePalette.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (kIsWeb && constraints.maxWidth >= 900) {
            return _buildWebsiteHome(context, constraints.maxWidth);
          }
          final padding = kIsWeb
              ? (constraints.maxWidth < 480
                  ? 10.0
                  : constraints.maxWidth < 800
                      ? 20.0
                      : 36.0)
              : constraints.maxWidth < 380
                  ? 10.0
                  : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 10, padding, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: kIsWeb ? 1180 : 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AnimatedHomeSection(order: 0, child: _buildHero()),
                    const SizedBox(height: 14),
                    _AnimatedHomeSection(order: 1, child: _buildActionGrid()),
                    const SizedBox(height: 18),
                    _AnimatedHomeSection(
                      order: 2,
                      child: _buildWelcomeSlider(context),
                    ),
                    const SizedBox(height: 20),
                    _AnimatedHomeSection(
                      order: 3,
                      child: _buildHighlightsGrid(),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedHomeSection(
                      order: 4,
                      child: _buildFounderCard(),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(
                      order: 4,
                      child: _buildServices(context),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(
                      order: 5,
                      child: _buildVideos(context),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(
                      order: 6,
                      child: _buildSocialSlides(context),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(
                      order: 7,
                      child: _buildContact(context),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(order: 8, child: _buildInfoCard()),
                    const SizedBox(height: 22),
                    _AnimatedHomeSection(order: 10, child: _buildQuoteCard()),
                    const SizedBox(height: 18),
                    if (captures.isNotEmpty) ...[
                      _buildRecentHeader(),
                      const SizedBox(height: 10),
                      ...captures.take(3).map(_buildCaptureItem),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebsiteHome(BuildContext context, double availableWidth) {
    final pagePadding = availableWidth >= 1300 ? 34.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnimatedHomeSection(
                order: 0,
                child: _buildWebsiteLandingHero(context),
              ),
              const SizedBox(height: 34),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _AnimatedHomeSection(
                      order: 3,
                      child: _buildFounderCard(),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 7,
                    child: _AnimatedHomeSection(
                      order: 4,
                      child: _buildHighlightsGrid(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _AnimatedHomeSection(order: 5, child: _buildServices(context)),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AnimatedHomeSection(
                      order: 6,
                      child: _buildVideos(context),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _AnimatedHomeSection(
                      order: 7,
                      child: _buildSocialSlides(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AnimatedHomeSection(
                      order: 8,
                      child: _buildContact(context),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _AnimatedHomeSection(
                      order: 9,
                      child: _buildInfoCard(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _AnimatedHomeSection(order: 10, child: _buildQuoteCard()),
              if (captures.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildRecentHeader(),
                const SizedBox(height: 10),
                ...captures.take(3).map(_buildCaptureItem),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebsiteLandingHero(BuildContext context) {
    const ink = Color(0xFF2A2117);
    const green = Color(0xFF3C3022);
    const accent = Color(0xFFB88A32);
    final compactDesktop = MediaQuery.sizeOf(context).width < 1180;
    final headlineSize = compactDesktop ? 52.0 : 68.0;
    return Container(
      constraints: BoxConstraints(minHeight: compactDesktop ? 540 : 610),
      padding: EdgeInsets.fromLTRB(8, compactDesktop ? 28 : 46, 8, 26),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: SizedBox(
              height: compactDesktop ? 500 : 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 28, height: 2, color: accent),
                      const SizedBox(width: 14),
                      const Text(
                        'ANCIENT WISDOM • MODERN PRECISION',
                        style: TextStyle(
                          color: green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Find the right\ndirection for',
                    style: TextStyle(
                      color: ink,
                      fontSize: headlineSize,
                      height: 0.96,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -3.2,
                    ),
                  ),
                  Text(
                    'every space.',
                    style: TextStyle(
                      color: accent,
                      fontSize: headlineSize,
                      height: 1.02,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      letterSpacing: compactDesktop ? -2.2 : -3.2,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: 610,
                    child: Text(
                      'Understand the energy of your home or workplace through precise direction mapping, expert consultation and practical Vastu remedies.',
                      style: TextStyle(
                        color: Color(0xFF76664D),
                        fontSize: compactDesktop ? 15 : 18,
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: onUploadMap,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Start map analysis'),
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 18,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      SizedBox(width: compactDesktop ? 10 : 24),
                      TextButton.icon(
                        onPressed: () => _openLink(
                          context,
                          _phoneUrl(_primaryPhone),
                        ),
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Talk to us'),
                        style: TextButton.styleFrom(foregroundColor: green),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const _WebsiteStat('15+', 'YEARS OF PRACTICE'),
                      SizedBox(width: compactDesktop ? 28 : 64),
                      const _WebsiteStat('1,000+', 'CLIENTS GUIDED'),
                      SizedBox(width: compactDesktop ? 28 : 64),
                      const _WebsiteStat('16', 'DIRECTION ANALYSIS'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compactDesktop ? 16 : 34),
          Expanded(
            flex: 9,
            child: SizedBox(
              height: compactDesktop ? 500 : 560,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: compactDesktop ? 390 : 480,
                    height: compactDesktop ? 390 : 480,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0DFC0),
                      border: Border.all(color: accent.withValues(alpha: .18)),
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.025,
                    child: Container(
                      width: compactDesktop ? 350 : 430,
                      height: compactDesktop ? 290 : 330,
                      padding: EdgeInsets.all(compactDesktop ? 26 : 34),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(90),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(90),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220B2B24),
                            blurRadius: 34,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF6E9188)),
                              SizedBox(width: 8),
                              CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF6E9188)),
                              SizedBox(width: 8),
                              CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF6E9188)),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'VASTU MAP STUDIO',
                            style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Upload • Align • Understand',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '16 DIRECTIONAL ZONES',
                            style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    top: 36,
                    child: _WebsiteBadge(
                      icon: Icons.north_east,
                      title: '16 directions',
                      subtitle: 'Accurate alignment',
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 30,
                    child: _WebsiteBadge(
                      icon: Icons.verified_outlined,
                      title: 'No demolition',
                      subtitle: 'Practical remedies',
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

  Widget _buildWelcomeSlider(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    final veryCompact = MediaQuery.sizeOf(context).width < 360;
    return SizedBox(
      height: compact ? 238 : 228,
      child: _AutoPageView(
        itemCount: _launchSlides.length,
        itemBuilder: (context, index) {
          final slide = _launchSlides[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: _homeHeroDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _logoMark(
                          size: veryCompact
                              ? 34
                              : compact
                                  ? 40
                                  : 46),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Kuber Vastu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.divineTitle(
                                size: veryCompact
                                    ? 17
                                    : compact
                                        ? 20
                                        : 24,
                                color: _HomePalette.title,
                              ),
                            ),
                            Text(
                              'The Miracle King',
                              style: AppTheme.uiText(
                                size: 11,
                                color: _HomePalette.goldDark,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _HomePalette.goldSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(slide.icon, color: _HomePalette.goldDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.eyebrow,
                              style: _homeLabel(),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              slide.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _homeText(
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _homeText(
                      size: 12,
                      color: _HomePalette.muted,
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _filledAction(
                          context,
                          'Book Now',
                          Icons.event_available_outlined,
                          _phoneUrl(_primaryPhone),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _outlineAction(
                          context,
                          'WhatsApp',
                          Icons.chat_outlined,
                          _whatsAppUrl(
                            _primaryWhatsApp,
                            'Hello, I want to book a Kuber Vastu consultation.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2117), Color(0xFF49371F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFB88A32).withValues(alpha: .5),
        ),
        boxShadow: [
          BoxShadow(
            color: _HomePalette.title.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF1),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/images/app_logo.png'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KUBER VASTU',
                      style: _homeLabel(
                        size: 10,
                        color: const Color(0xFFE4C783),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'The Miracle King',
                      style: AppTheme.divineTitle(
                        size: 24,
                        color: const Color(0xFFFFFBF1),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFE4C783),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Find the right direction\nfor every space.',
            style: AppTheme.divineTitle(
              size: 31,
              color: const Color(0xFFFFFBF1),
              weight: FontWeight.w600,
            ).copyWith(height: 1.05),
          ),
          const SizedBox(height: 11),
          Text(
            'Precise direction mapping, expert consultation and practical Vastu remedies—without demolition.',
            style: _homeText(size: 12, color: const Color(0xFFE7DDC9))
                .copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _MobileHeroStat('15+', 'Years')),
              SizedBox(width: 8),
              Expanded(child: _MobileHeroStat('1,000+', 'Clients')),
              SizedBox(width: 8),
              Expanded(child: _MobileHeroStat('16', 'Directions')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFounderCard() {
    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _founderPhoto(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vijay Kumar Goyal',
                      style: AppTheme.divineTitle(
                        size: 26,
                        color: _HomePalette.title,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Founder & CEO - Kuber Vastu',
                      style: _homeText(
                        size: 12,
                        color: _HomePalette.goldDark,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '15+ years in Vastu Science, Astro Vastu, Jyotish, Numerology & Energy Transformation',
                      style: _homeText(size: 11, color: _HomePalette.muted)
                          .copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._founderParagraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                paragraph,
                style: _homeText(size: 12.5, color: _HomePalette.body)
                    .copyWith(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsGrid() {
    var expanded = false;
    return StatefulBuilder(
      builder: (context, setInnerState) {
        final visible = expanded ? _highlights : _highlights.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Highlights',
              style: AppTheme.divineTitle(
                size: 24,
                color: _HomePalette.title,
              ),
            ),
            const SizedBox(height: 10),
            ...visible.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HighlightCard(data: item),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setInnerState(() => expanded = !expanded),
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(expanded ? 'Show Less' : 'Know More'),
                style: TextButton.styleFrom(
                  foregroundColor: _HomePalette.goldDark,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Services',
          style: AppTheme.divineTitle(size: 25, color: _HomePalette.title),
        ),
        const SizedBox(height: 5),
        Text(
          'Personalized guidance for homes, businesses, industries, and new projects.',
          style: _homeText(size: 12, color: _HomePalette.muted),
        ),
        const SizedBox(height: 14),
        ..._services.map(
          (service) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: _homeCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconBox(service.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: _homeText(
                              size: 13.5,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            style:
                                _homeText(size: 11.5, color: _HomePalette.muted)
                                    .copyWith(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _filledAction(
                        context,
                        'Book Now',
                        Icons.event_available_outlined,
                        _phoneUrl(_primaryPhone),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _outlineAction(
                        context,
                        'WhatsApp Order Now',
                        Icons.chat_outlined,
                        _whatsAppUrl(
                          _primaryWhatsApp,
                          'Hello, I want to book ${service.title}.',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideos(BuildContext context) {
    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.play_circle_outline, 'Latest YouTube Videos'),
          const SizedBox(height: 12),
          FutureBuilder<List<_VideoData>>(
            future: _loadYouTubeVideos(),
            builder: (context, snapshot) {
              final videos = snapshot.data ?? _fallbackVideos;
              return SizedBox(
                height: 205,
                child: _AutoPageView(
                  itemCount: videos.length,
                  itemBuilder: (context, index) =>
                      _videoCard(context, videos[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSlides(BuildContext context) {
    const slides = [
      _SocialSlideData(
        Icons.facebook_outlined,
        'Facebook Updates',
        'See latest posts, videos, remedies, and event updates.',
        _facebookUrl,
      ),
      _SocialSlideData(
        Icons.camera_alt_outlined,
        'Instagram Reels',
        'Watch short Vastu tips, reels, and social updates.',
        _instagramUrl,
      ),
    ];

    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.slideshow_outlined, 'Facebook & Instagram'),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: PageView.builder(
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => _openLink(context, slide.url),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _HomePalette.goldSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _iconBox(slide.icon),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slide.title,
                                  style: _homeText(
                                    size: 15,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  slide.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _homeText(
                                    size: 11.5,
                                    color: _HomePalette.muted,
                                  ).copyWith(height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContact(BuildContext context) {
    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.contact_phone_outlined, 'Contact & Consult Me'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _filledAction(
                  context,
                  'Call 1',
                  Icons.phone_outlined,
                  _phoneUrl(_primaryPhone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _outlineAction(
                  context,
                  'WhatsApp',
                  Icons.chat_outlined,
                  _whatsAppUrl(
                    _primaryWhatsApp,
                    'Hello, I want a Vastu consultation.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _filledAction(
                  context,
                  'Call 2',
                  Icons.phone_outlined,
                  _phoneUrl(_secondaryPhone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _outlineAction(
                  context,
                  'WhatsApp 2',
                  Icons.chat_outlined,
                  _whatsAppUrl(
                    _secondaryWhatsApp,
                    'Hello, I want a Vastu consultation.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _contactLine(Icons.phone_outlined, _primaryPhone),
          _contactLine(Icons.phone_outlined, _secondaryPhone),
          _contactLine(
            Icons.location_on_outlined,
            '73, Sardar Patel Marg, Patel Colony, C-Scheme, Jaipur',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the App',
            style: AppTheme.divineTitle(size: 22, color: _HomePalette.title),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuber Vastu helps users check live direction, align floor plans with Vastu chakras, review zone degrees, and save practical observations for remedies and consultation.',
            style: _homeText(size: 13, color: _HomePalette.muted)
                .copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, 'Founder', 'Vijay Kumar Goyal'),
          _infoRow(Icons.explore_outlined, 'Core tool', 'Live compass'),
          _infoRow(Icons.map_outlined, 'Map tool', 'Floor plan alignment'),
          _infoRow(Icons.devices_outlined, 'Platforms', 'Android, iOS, Web'),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 330;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: twoColumns ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: twoColumns ? 1.25 : 2.8,
          children: [
            if (!kIsWeb)
              _ActionCard(
                icon: Icons.explore_outlined,
                title: 'Compass',
                desc: 'Live direction',
                onTap: onGoCompass,
              ),
            _ActionCard(
              icon: Icons.upload_file,
              title: 'Floor Plan',
              desc: 'Upload map',
              onTap: onUploadMap,
            ),
            _ActionCard(
              icon: Icons.camera_alt_outlined,
              title: 'Live View',
              desc: 'Camera only',
              onTap: onGoCamera,
            ),
            if (!kIsWeb)
              _ActionCard(
                icon: Icons.visibility_outlined,
                title: 'Chakras',
                desc: 'Explore all',
                onTap: onGoCompass,
              ),
            if (!kIsWeb)
              _ActionCard(
                icon: Icons.language_outlined,
                title: 'Website',
                desc: 'Open directly',
                onTap: () => _openLink(context, _websiteUrl),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuoteCard() {
    return _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _HomePalette.goldDark,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"Vastu is not merely about transforming spaces; it is about transforming lives. When the right energy aligns with the right direction, extraordinary possibilities become reality."',
            style: AppTheme.divineItalic(
              size: 17,
              color: _HomePalette.title,
            ),
          ),
          const SizedBox(height: 8),
          Text('VIJAY KUMAR GOYAL', style: _homeLabel()),
        ],
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('RECENT CAPTURES', style: _homeLabel()),
          InkWell(
            onTap: onSeeAllCaptures,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SEE ALL',
                  style: _homeLabel(color: _HomePalette.goldDark),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: _HomePalette.goldDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureItem(CaptureEntry c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _homeCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _iconBox(Icons.explore),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.direction} - ${c.heading.toStringAsFixed(1)} deg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _homeText(size: 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(c.time),
                    style: _homeText(size: 10, color: _HomePalette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _founderPhoto() {
    return Container(
      width: 108,
      height: 132,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _HomePalette.goldSoft,
        border:
            Border.all(color: _HomePalette.goldDark.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/khubar_vastu_ceo.jpeg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => Container(
            color: _HomePalette.panel,
            alignment: Alignment.center,
            child: Text(
              'VG',
              style: _homeText(
                size: 24,
                color: _HomePalette.goldDark,
                weight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoMark({double size = 58}) {
    return _BreathingLogo(
      child: Container(
        width: size * 2.55,
        height: size,
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.08,
          vertical: size * 0.06,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          color: _HomePalette.panel,
          border:
              Border.all(color: _HomePalette.goldDark.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.16),
          child: Image.asset(
            'assets/images/kuber_vastu_logo.jpeg',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                'Kuber Vastu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.divineTitle(
                  size: size * 0.22,
                  color: _HomePalette.goldDark,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _HomePalette.goldDark, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: AppTheme.divineTitle(size: 22, color: _HomePalette.title),
          ),
        ),
      ],
    );
  }

  Widget _videoCard(BuildContext context, _VideoData video) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              video: VideoItem(
                id: video.videoId,
                title: video.title,
                publishedAt: null,
                thumbnailUrl: video.thumbnailUrl,
              ),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: _HomePalette.goldSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _HomePalette.goldDark.withValues(alpha: 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: _HomePalette.goldSoft,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: AppTheme.gold,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        color: _HomePalette.panel,
                        child: Icon(
                          Icons.ondemand_video_outlined,
                          color: _HomePalette.goldDark,
                          size: 42,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _homeText(size: 13, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _homeText(size: 10.5, color: _HomePalette.muted),
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

  Widget _contactLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _HomePalette.goldDark),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: _homeText(size: 12, color: _HomePalette.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _HomePalette.goldDark),
          const SizedBox(width: 10),
          SizedBox(width: 76, child: Text(label, style: _homeLabel(size: 9))),
          Expanded(
            child: Text(
              value,
              style: _homeText(size: 12, color: _HomePalette.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _HomePalette.goldSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: _HomePalette.goldDark),
    );
  }

  Widget _homeCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: _homeCardDecoration(),
      child: child,
    );
  }

  BoxDecoration _homeCardDecoration() {
    return BoxDecoration(
      color: _HomePalette.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _HomePalette.goldDark.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: _HomePalette.body.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  BoxDecoration _homeHeroDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF1), Color(0xFFF1E0BE)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _HomePalette.goldDark.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: _HomePalette.body.withValues(alpha: 0.1),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  Widget _filledAction(
    BuildContext context,
    String label,
    IconData icon,
    String url,
  ) {
    final iconOnly = url.startsWith('tel:') || url.contains('wa.me/');
    final action = InkWell(
        onTap: () => _openLink(context, url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          decoration: BoxDecoration(
            color: url.contains('wa.me/')
                ? const Color(0xFF25D366)
                : _HomePalette.goldDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: iconOnly
              ? Center(child: Icon(icon, size: 22, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
        ));
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(message: label, child: action),
    );
  }

  Widget _outlineAction(
    BuildContext context,
    String label,
    IconData icon,
    String url,
  ) {
    final iconOnly = url.startsWith('tel:') || url.contains('wa.me/');
    final action = InkWell(
        onTap: () => _openLink(context, url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: _HomePalette.goldDark.withValues(alpha: 0.3)),
          ),
          child: iconOnly
              ? Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: url.contains('wa.me/')
                        ? const Color(0xFF25D366)
                        : _HomePalette.goldDark,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: _HomePalette.goldDark),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _HomePalette.goldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
        ));
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(message: label, child: action),
    );
  }

  TextStyle _homeText({
    double size = 13,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    return AppTheme.uiText(
      size: size,
      color: color ?? _HomePalette.body,
      weight: weight,
    );
  }

  TextStyle _homeLabel({double size = 10, Color? color}) {
    return AppTheme.uiLabel(
      size: size,
      color: color ?? _HomePalette.goldDark,
    );
  }

  Future<List<_VideoData>> _loadYouTubeVideos() async {
    if (_youtubeChannelId.trim().isEmpty) return _fallbackVideos;
    try {
      final uri = Uri.parse(
        'https://www.youtube.com/feeds/videos.xml?channel_id=$_youtubeChannelId',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackVideos;
      }
      final body = response.body;
      final entries = RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(body);
      final videos = <_VideoData>[];
      for (final entry in entries.take(8)) {
        final chunk = entry.group(1) ?? '';
        final id = RegExp(r'<yt:videoId>(.*?)</yt:videoId>')
            .firstMatch(chunk)
            ?.group(1);
        final title =
            RegExp(r'<title>(.*?)</title>').firstMatch(chunk)?.group(1);
        final published =
            RegExp(r'<published>(.*?)</published>').firstMatch(chunk)?.group(1);
        if (id == null || title == null) continue;
        videos.add(
          _VideoData(
            id,
            _decodeXml(title),
            published == null
                ? 'Latest YouTube video'
                : _formatDateLabel(published),
          ),
        );
      }
      return videos.isEmpty ? _fallbackVideos : videos;
    } catch (_) {
      return _fallbackVideos;
    }
  }

  String _decodeXml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  String _formatDateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return 'Latest YouTube video';
    return 'Published ${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _phoneUrl(String phone) => 'tel:$phone';

  String _whatsAppUrl(String phone, String message) {
    return 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
  }

  Future<void> _openLink(BuildContext context, String value) async {
    final opened =
        await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _HomePalette {
  static const background = Color(0xFFF5EEDD);
  static const panel = Color(0xFFFFFBF1);
  static const title = Color(0xFF2A2117);
  static const body = Color(0xFF3C3022);
  static const muted = Color(0xFF76664D);
  static const goldDark = Color(0xFF9B7428);
  static const goldSoft = Color(0xFFF0DFC0);
}

class _AnimatedHomeSection extends StatefulWidget {
  final int order;
  final Widget child;

  const _AnimatedHomeSection({
    required this.order,
    required this.child,
  });

  @override
  State<_AnimatedHomeSection> createState() => _AnimatedHomeSectionState();
}

class _AnimatedHomeSectionState extends State<_AnimatedHomeSection> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 80 * widget.order), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.06),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _BreathingLogo extends StatefulWidget {
  final Widget child;

  const _BreathingLogo({required this.child});

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _AutoPageView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _AutoPageView({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<_AutoPageView> createState() => _AutoPageViewState();
}

class _AutoPageViewState extends State<_AutoPageView> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _AutoPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _page = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.itemCount < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _page = (_page + 1) % widget.itemCount;
      _controller.animateToPage(
        _page,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.itemCount,
      onPageChanged: (page) => _page = page,
      itemBuilder: widget.itemBuilder,
    );
  }
}

class _LaunchSlideData {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;

  const _LaunchSlideData(
    this.icon,
    this.eyebrow,
    this.title,
    this.description,
  );
}

class _HighlightData {
  final IconData icon;
  final String label;
  final String title;
  final String detail;

  const _HighlightData(this.icon, this.label, this.title, this.detail);
}

class _ServiceData {
  final IconData icon;
  final String title;
  final String description;

  const _ServiceData(this.icon, this.title, this.description);
}

class _VideoData {
  final String videoId;
  final String title;
  final String subtitle;

  const _VideoData(this.videoId, this.title, this.subtitle);

  String get url => 'https://www.youtube.com/watch?v=$videoId';
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

class _SocialSlideData {
  final IconData icon;
  final String title;
  final String description;
  final String url;

  const _SocialSlideData(this.icon, this.title, this.description, this.url);
}

class _HighlightCard extends StatelessWidget {
  final _HighlightData data;

  const _HighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _HomePalette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _HomePalette.goldDark.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: _HomePalette.goldSoft,
            ),
            child: Icon(data.icon, size: 17, color: _HomePalette.goldDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 8,
                    color: _HomePalette.goldDark,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 13,
                    color: _HomePalette.title,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 10,
                    color: _HomePalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteStat extends StatelessWidget {
  final String value;
  final String label;

  const _WebsiteStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101916),
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF71807B),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _MobileHeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _MobileHeroStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFE4C783),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFE7DDC9),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WebsiteBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160B2B24),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB8F13C),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0B2B24)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF101916),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF71807B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: _HomePalette.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _HomePalette.goldDark.withValues(alpha: 0.14),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal =
                constraints.maxWidth > constraints.maxHeight * 1.8;
            final iconBox = Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _HomePalette.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: _HomePalette.goldDark),
            );
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 14,
                    color: _HomePalette.title,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 10,
                    color: _HomePalette.muted,
                  ),
                ),
              ],
            );
            if (horizontal) {
              return Row(
                children: [
                  iconBox,
                  const SizedBox(width: 12),
                  Expanded(child: text),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [iconBox, text],
            );
          },
        ),
      ),
    );
  }
}
