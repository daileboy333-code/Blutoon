import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:blutoon/features/manga_detail/presentation/manga_detail_cubit.dart';
import 'package:blutoon/features/reader/presentation/reader_screen.dart';
import 'package:blutoon/shared/models/chapter_model.dart';
import 'package:blutoon/shared/models/manga_model.dart';

// ═══════════════════════════════════════════════════════════════
// MangaDetailScreen — Entry point
// ═══════════════════════════════════════════════════════════════
class MangaDetailScreen extends StatelessWidget {
  final int mangaId;
  const MangaDetailScreen({super.key, required this.mangaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MangaDetailCubit()..load(mangaId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<MangaDetailCubit, MangaDetailState>(
        builder: (context, state) {
          if (state is MangaDetailLoading) return const _DetailShimmer();
          if (state is MangaDetailError)   return _ErrorView(msg: state.msg);
          if (state is MangaDetailLoaded)  return _LoadedView(state: state);
          return const SizedBox();
        },
      ),
    );
  }
}

// ── Loaded View ─────────────────────────────────────────────────
class _LoadedView extends StatefulWidget {
  final MangaDetailLoaded state;
  const _LoadedView({required this.state});
  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manga    = widget.state.manga;
    final chapters = widget.state.chapters;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar مع غلاف ضبابي ───────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            BlocBuilder<MangaDetailCubit, MangaDetailState>(
              builder: (context, s) {
                final fav = s is MangaDetailLoaded && s.isFavorited;
                return IconButton(
                  icon: Icon(
                    fav ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: fav
                        ? const Color(0xFF2394FC)
                        : Colors.black,
                  ),
                  onPressed: () =>
                      context.read<MangaDetailCubit>().toggleFavorite(),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // خلفية ضبابية
                CachedNetworkImage(
                  imageUrl: manga.coverUrl,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                // Gradient أسفل
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),
                // الغلاف في المنتصف
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: manga.coverUrl,
                          width: 130,
                          height: 190,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          manga.titleAr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ),
                      if (manga.titleEn != null)
                        Text(
                          manga.titleEn!,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats Row ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF1C40F),
                  label: manga.rating.toStringAsFixed(1),
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF2394FC),
                  label: '${chapters.length} فصل',
                ),
                const SizedBox(width: 12),
                _StatusChip(status: manga.status),
              ],
            ),
          ),
        ),

        // ── Start / Continue Reading Button ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _PrimaryBtn(
                    label: widget.state.lastReadChapterId != null
                        ? 'متابعة القراءة'
                        : 'ابدأ القراءة',
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      if (chapters.isEmpty) return;
                      final ch = widget.state.lastReadChapterId != null
                          ? chapters.firstWhere(
                              (c) =>
                                  c.id ==
                                  widget.state.lastReadChapterId,
                              orElse: () => chapters.last)
                          : chapters.last;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            mangaId: manga.id,
                            chapterId: ch.id,
                            allChapters: chapters,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _ShareBtn(mangaTitle: manga.titleAr),
              ],
            ),
          ),
        ),

        // ── Tabs ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: TabBar(
            controller: _tabs,
            labelColor: Colors.black,
            unselectedLabelColor: const Color(0xFFAAAAAA),
            indicatorColor: const Color(0xFF2394FC),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'الفصول'),
              Tab(text: 'القصة'),
              Tab(text: 'تفاصيل'),
            ],
          ),
        ),

        // ── Tab Content ───────────────────────────────────────────
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabs,
            children: [
              // Tab 0: الفصول
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: chapters.length,
                itemBuilder: (context, i) => _ChapterTile(
                  chapter: chapters[i],
                  isLastRead: chapters[i].id ==
                      widget.state.lastReadChapterId,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(
                        mangaId: manga.id,
                        chapterId: chapters[i].id,
                        allChapters: chapters,
                      ),
                    ),
                  ),
                ),
              ),

              // Tab 1: القصة
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  manga.description ?? 'لا يوجد وصف متاح.',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF333333),
                    height: 1.8,
                  ),
                ),
              ),

              // Tab 2: التفاصيل
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'النوع',       value: manga.type),
                    _InfoRow(label: 'الحالة',      value: manga.status),
                    _InfoRow(
                        label: 'عدد الفصول',
                        value: '${chapters.length}'),
                    _InfoRow(
                        label: 'التقييم',
                        value: '⭐ ${manga.rating}'),
                    _InfoRow(
                        label: 'المشاهدات',
                        value: '${manga.views}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Small Widgets
// ═══════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == 'ongoing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOngoing
            ? const Color(0xFF2ecc71)
            : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        isOngoing ? 'مستمر' : 'مكتمل',
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOngoing ? Colors.white : const Color(0xFF666666),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2394FC), Color(0xFF0066D6)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2394FC).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShareBtn extends StatelessWidget {
  final String mangaTitle;
  const _ShareBtn({required this.mangaTitle});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      // Share.share(mangaTitle); ← أضف حزمة share_plus لاحقاً
    },
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.ios_share_rounded,
        color: Color(0xFF444444),
      ),
    ),
  );
}

class _ChapterTile extends StatelessWidget {
  final ChapterModel  chapter;
  final bool          isLastRead;
  final VoidCallback  onTap;
  const _ChapterTile({
    required this.chapter,
    required this.isLastRead,
    required this.onTap,
  });

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 30) return '${d.day}/${d.month}/${d.year}';
    if (diff.inDays > 0)  return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isLastRead
              ? const Color(0xFFE8F4FD)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Row(
          children: [
            // رقم الفصل
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLastRead
                    ? const Color(0xFF2394FC)
                    : const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  chapter.displayNumber,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isLastRead
                        ? Colors.white
                        : const Color(0xFF333333),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // العنوان والتاريخ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title ??
                        'الفصل ${chapter.displayNumber}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isLastRead
                          ? const Color(0xFF2394FC)
                          : const Color(0xFF111111),
                    ),
                  ),
                  Text(
                    _fmt(chapter.publishedAt),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            // أيقونة يمين
            if (isLastRead)
              Text(
                'متابعة',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: const Color(0xFF2394FC),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Icon(
                Icons.play_circle_outline_rounded,
                color: Color(0xFFCCCCCC),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: const Color(0xFF999999),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Shimmer & Error
// ═══════════════════════════════════════════════════════════════

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE8E8E8),
    highlightColor: const Color(0xFFF5F5F5),
    child: Column(
      children: [
        Container(height: 320, color: Colors.white),
        const SizedBox(height: 16),
        for (var _ in List.filled(6, null))
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 12,
                          width: 160,
                          color: Colors.white),
                      const SizedBox(height: 6),
                      Container(
                          height: 10,
                          width: 90,
                          color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String msg;
  const _ErrorView({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 48,
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'رجوع',
            style: GoogleFonts.cairo(
              color: const Color(0xFF2394FC),
            ),
          ),
        ),
      ],
    ),
  );
}
