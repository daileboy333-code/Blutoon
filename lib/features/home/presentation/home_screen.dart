import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/features/home/presentation/home_cubit.dart';
import 'package:blutoon/shared/models/manga_model.dart';
import 'package:blutoon/features/manga_detail/presentation/manga_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadHome(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            _TabBar(),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading || state is HomeInitial) {
                    return const _ShimmerHomeLayout();
                  }
                  if (state is HomeError) {
                    return _ErrorView(msg: state.msg);
                  }
                  if (state is HomeLoaded) {
                    return _HomeContent(state: state);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// ─────────────────────────── APP BAR ────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Blu',
                  style: GoogleFonts.cairo(
                    fontSize:   22,
                    fontWeight: FontWeight.w900,
                    color:      const Color(0xFF2394FC),
                  ),
                ),
                TextSpan(
                  text: 'toon',
                  style: GoogleFonts.cairo(
                    fontSize:   22,
                    fontWeight: FontWeight.w900,
                    color:      const Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF333333),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF333333),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── TAB BAR ────────────────────────────
class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final activeTab =
            state is HomeLoaded ? state.activeTab : 'manga';
        return Container(
          height: 48,
          color:  Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical:   8,
            ),
            children: [
              _TabPill(
                label:  'مانجا',
                value:  'manga',
                active: activeTab == 'manga',
              ),
              _TabPill(
                label:  'مانهوا',
                value:  'manhwa',
                active: activeTab == 'manhwa',
              ),
              _TabPill(
                label:  'روايات',
                value:  'novel',
                active: activeTab == 'novel',
              ),
              _TabPill(
                label:  'رائج',
                value:  'popular',
                active: activeTab == 'popular',
              ),
              _TabPill(
                label:  'مكتمل',
                value:  'completed',
                active: activeTab == 'completed',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final String value;
  final bool   active;

  const _TabPill({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<HomeCubit>().switchTab(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:  const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical:   6,
        ),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF111111)
              : Colors.white,
          border: Border.all(
            color: active
                ? const Color(0xFF111111)
                : const Color(0xFFEEEEEE),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize:   12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── HOME CONTENT ───────────────────────────
class _HomeContent extends StatelessWidget {
  final HomeLoaded state;
  const _HomeContent({required this.state});

  // ── دالة التنقل المركزية — تُستخدم في كل مكان ──────────────
  static void _openDetail(BuildContext context, int mangaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaDetailScreen(mangaId: mangaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Featured Banner ──────────────────────────────────
        SliverToBoxAdapter(
          child: _FeaturedBanner(
            items:    state.featured,
            onTap:    (id) => _openDetail(context, id),
          ),
        ),

        // ── Section: أحدث الإضافات ───────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Text(
                  'أحدث الإضافات',
                  style: GoogleFonts.cairo(
                    fontSize:   18,
                    fontWeight: FontWeight.w900,
                    color:      const Color(0xFF111111),
                  ),
                ),
                const Spacer(),
                Text(
                  'عرض الكل',
                  style: GoogleFonts.cairo(
                    fontSize:   13,
                    color:      const Color(0xFF2394FC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _LatestChapterRow(
              manga: state.latest[i],
              onTap: () => _openDetail(context, state.latest[i].id),
            ),
            childCount: state.latest.take(12).length,
          ),
        ),

        // ── Section: الأكثر مشاهدة ───────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'الأكثر مشاهدة',
              style: GoogleFonts.cairo(
                fontSize:   18,
                fontWeight: FontWeight.w900,
                color:      const Color(0xFF111111),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 10,
              mainAxisSpacing:  14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _MangaGridCard(
                manga: state.popular[i],
                onTap: () =>
                    _openDetail(context, state.popular[i].id),
              ),
              childCount: state.popular.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}

// ────────────────────── FEATURED BANNER ─────────────────────────
class _FeaturedBanner extends StatefulWidget {
  final List<MangaModel>    items;
  final ValueChanged<int>   onTap;

  const _FeaturedBanner({
    required this.items,
    required this.onTap,
  });

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final _ctrl  = PageController(viewportFraction: 0.88);
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller:    _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount:     widget.items.length,
            itemBuilder:   (context, i) {
              final manga = widget.items[i];
              return GestureDetector(
                // ── الضغط على البانر يفتح صفحة التفاصيل ──
                onTap: () => widget.onTap(manga.id),
                child: AnimatedScale(
                  scale:    _current == i ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical:   8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: manga.bannerUrl ?? manga.coverUrl,
                            fit:      BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFEEEEEE),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFDDDDDD),
                            ),
                          ),
                          // Gradient overlay
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin:  Alignment.topCenter,
                                end:    Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xCC000000),
                                ],
                                stops: [0.4, 1.0],
                              ),
                            ),
                          ),
                          // معلومات المانجا
                          Positioned(
                            bottom: 14,
                            right:  14,
                            left:   14,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manga.titleAr,
                                  style: GoogleFonts.cairo(
                                    fontSize:   17,
                                    fontWeight: FontWeight.w900,
                                    color:      Colors.white,
                                  ),
                                  maxLines:  1,
                                  overflow:  TextOverflow.ellipsis,
                                ),
                                if (manga.latestChapterNum != null)
                                  Text(
                                    'الفصل ${manga.latestChapterNum}',
                                    style: GoogleFonts.cairo(
                                      fontSize:   12,
                                      color: const Color(0xFF2394FC),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dots indicator
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  _current == i ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _current == i
                      ? const Color(0xFF2394FC)
                      : const Color(0xFFDDDDDD),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── LATEST CHAPTER ROW ─────────────────────────
class _LatestChapterRow extends StatelessWidget {
  final MangaModel  manga;
  final VoidCallback onTap;

  const _LatestChapterRow({
    required this.manga,
    required this.onTap,
  });

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0)  return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // ── الضغط على الصف يفتح صفحة التفاصيل ──────────────
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical:   8,
        ),
        child: Row(
          children: [
            // الغلاف
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: manga.coverUrl,
                width:    52,
                height:   72,
                fit:      BoxFit.cover,
                placeholder: (_, __) => Container(
                  color:  const Color(0xFFEEEEEE),
                  width:  52,
                  height: 72,
                ),
                errorWidget: (_, __, ___) => Container(
                  color:  const Color(0xFFDDDDDD),
                  width:  52,
                  height: 72,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.titleAr,
                    style: GoogleFonts.cairo(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical:   3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ecc71),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ف ${manga.latestChapterNum ?? "—"}',
                          style: GoogleFonts.cairo(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(manga.latestChapterDate),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color:    const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── MANGA GRID CARD ────────────────────────────
class _MangaGridCard extends StatelessWidget {
  final MangaModel   manga;
  final VoidCallback onTap;

  const _MangaGridCard({
    required this.manga,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ── الضغط على البطاقة يفتح صفحة التفاصيل ───────────
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: manga.coverUrl,
                    width:    double.infinity,
                    height:   double.infinity,
                    fit:      BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFEEEEEE),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFDDDDDD),
                    ),
                  ),
                ),
                // Badge نوع المحتوى
                Positioned(
                  top:   6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical:   2,
                    ),
                    decoration: BoxDecoration(
                      color: manga.type == 'manhwa'
                          ? const Color(0xFFF1C40F)
                          : const Color(0xFF2394FC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      manga.type.toUpperCase(),
                      style: GoogleFonts.cairo(
                        fontSize:   8,
                        fontWeight: FontWeight.w900,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.titleAr,
            style: GoogleFonts.cairo(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      const Color(0xFF111111),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (manga.latestChapterNum != null)
            Text(
              'ف ${manga.latestChapterNum}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color:    const Color(0xFF999999),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────── SHIMMER LAYOUT ────────────────────────────
class _ShimmerHomeLayout extends StatelessWidget {
  const _ShimmerHomeLayout();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:      const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner shimmer
            Container(
              margin: const EdgeInsets.all(14),
              height: 180,
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            _ShLine(
              width:  120,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            ),
            // List rows shimmer
            for (var _ in List.filled(5, null))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical:   6,
                ),
                child: Row(
                  children: [
                    Container(
                      width:  52,
                      height: 72,
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShLine(width: 160),
                        const SizedBox(height: 8),
                        _ShLine(width: 80),
                      ],
                    ),
                  ],
                ),
              ),
            _ShLine(
              width:  100,
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            ),
            // Grid shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 0.68,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _ShLine(width: double.infinity),
                          const SizedBox(height: 4),
                          _ShLine(width: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShLine extends StatelessWidget {
  final double       width;
  final EdgeInsets?  margin;
  const _ShLine({required this.width, this.margin});

  @override
  Widget build(BuildContext context) => Container(
    width:  width,
    height: 12,
    margin: margin,
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ──────────────────── BOTTOM NAV ────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color:  Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(
            icon:   Icons.grid_view_rounded,
            label:  'كوميك',
            active: true,
          ),
          _NavItem(
            icon:   Icons.menu_book_rounded,
            label:  'روايات',
            active: false,
          ),
          _NavItem(
            icon:   Icons.people_outline_rounded,
            label:  'مجتمع',
            active: false,
          ),
          _NavItem(
            icon:   Icons.bookmark_border_rounded,
            label:  'مكتبتي',
            active: false,
          ),
          _NavItem(
            icon:   Icons.person_outline_rounded,
            label:  'حسابي',
            active: false,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF2394FC)
        : const Color(0xFF999999);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize:   10,
            color:      color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ──────────────────── ERROR VIEW ────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String msg;
  const _ErrorView({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size:  48,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: GoogleFonts.cairo(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<HomeCubit>().loadHome(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2394FC),
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
