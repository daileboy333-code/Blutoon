import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'reader_cubit.dart';
import '../../../shared/models/chapter_model.dart';

// ═══════════════════════════════════════════════════════════════
// ReaderScreen — Entry point
// ═══════════════════════════════════════════════════════════════
class ReaderScreen extends StatelessWidget {
  final int                mangaId;
  final int                chapterId;
  final List<ChapterModel> allChapters;

  const ReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    required this.allChapters,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReaderCubit(mangaId)..loadChapter(chapterId),
      child: _ReaderView(allChapters: allChapters),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ReaderView
// ═══════════════════════════════════════════════════════════════
class _ReaderView extends StatefulWidget {
  final List<ChapterModel> allChapters;
  const _ReaderView({required this.allChapters});

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> {
  final _pageCtrl   = PageController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // إخفاء شريط الحالة أثناء القراءة للشاشة الكاملة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    // استعادة شريط الحالة عند الخروج
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          if (state is ReaderLoading) return const _ReaderLoading();
          if (state is ReaderError)   return _ReaderError(msg: state.msg);
          if (state is ReaderLoaded) {
            return GestureDetector(
              onTap: () =>
                  context.read<ReaderCubit>().toggleBars(),
              child: Stack(
                children: [
                  // ── المحتوى الرئيسي ────────────────────────
                  state.mode == ReaderMode.webtoon
                      ? _WebtoonReader(
                          pageUrls:   state.pageUrls,
                          scrollCtrl: _scrollCtrl,
                          onScroll:   (page) => context
                              .read<ReaderCubit>()
                              .onPageChanged(page),
                        )
                      : _PagedReader(
                          pageUrls: state.pageUrls,
                          pageCtrl: _pageCtrl,
                          onPage:   (page) => context
                              .read<ReaderCubit>()
                              .onPageChanged(page),
                        ),

                  // ── Top Bar ────────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: state.showBars ? 0 : -90,
                    left: 0,
                    right: 0,
                    child: _TopBar(
                      chapter:      state.chapter,
                      allChapters:  widget.allChapters,
                      mode:         state.mode,
                      onModeToggle: () =>
                          context.read<ReaderCubit>().toggleMode(),
                    ),
                  ),

                  // ── Bottom Bar ─────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    bottom: state.showBars ? 0 : -110,
                    left: 0,
                    right: 0,
                    child: _BottomBar(
                      state:          state,
                      allChapters:    widget.allChapters,
                      onPrevChapter:  () => _navigate(context, state, -1),
                      onNextChapter:  () => _navigate(context, state,  1),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _navigate(BuildContext ctx, ReaderLoaded state, int dir) {
    final idx     = widget.allChapters
        .indexWhere((c) => c.id == state.chapter.id);
    final nextIdx = idx - dir; // القائمة تنازلية لذا نعكس الاتجاه
    if (nextIdx < 0 || nextIdx >= widget.allChapters.length) return;
    ctx.read<ReaderCubit>()
        .loadChapter(widget.allChapters[nextIdx].id);
    // العودة للبداية عند تغيير الفصل
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    if (_pageCtrl.hasClients)   _pageCtrl.jumpToPage(0);
  }
}

// ═══════════════════════════════════════════════════════════════
// WEBTOON MODE — تمرير عمودي متصل
// ═══════════════════════════════════════════════════════════════
class _WebtoonReader extends StatelessWidget {
  final List<String>      pageUrls;
  final ScrollController  scrollCtrl;
  final ValueChanged<int> onScroll;

  const _WebtoonReader({
    required this.pageUrls,
    required this.scrollCtrl,
    required this.onScroll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller:  scrollCtrl,
      itemCount:   pageUrls.length,
      padding:     EdgeInsets.zero,
      itemBuilder: (context, i) => _MangaPageImage(
        url:       pageUrls[i],
        fit:       BoxFit.fitWidth,
        onVisible: () => onScroll(i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGED MODE — صفحة بصفحة أفقياً
// ═══════════════════════════════════════════════════════════════
class _PagedReader extends StatelessWidget {
  final List<String>      pageUrls;
  final PageController    pageCtrl;
  final ValueChanged<int> onPage;

  const _PagedReader({
    required this.pageUrls,
    required this.pageCtrl,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller:    pageCtrl,
      itemCount:     pageUrls.length,
      onPageChanged: onPage,
      itemBuilder:   (context, i) => _MangaPageImage(
        url: pageUrls[i],
        fit: BoxFit.contain,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// صورة صفحة المانجا — Shimmer + Retry + VisibilityDetector
// ═══════════════════════════════════════════════════════════════
class _MangaPageImage extends StatelessWidget {
  final String       url;
  final BoxFit       fit;
  final VoidCallback? onVisible;

  const _MangaPageImage({
    required this.url,
    required this.fit,
    this.onVisible,
  });

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(url),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) onVisible?.call();
      },
      child: CachedNetworkImage(
        imageUrl: url,
        fit:      fit,
        width:    double.infinity,
        // Shimmer داكن أثناء تحميل الصورة
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor:      const Color(0xFF1A1A1A),
          highlightColor: const Color(0xFF2A2A2A),
          child: Container(
            height: 400,
            color:  Colors.white,
          ),
        ),
        // رسالة خطأ مع أيقونة عند فشل التحميل
        errorWidget: (_, __, ___) => Container(
          height: 200,
          color:  const Color(0xFF111111),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF444444),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'تعذّر تحميل الصورة',
                  style: GoogleFonts.cairo(
                    color:    const Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final ChapterModel       chapter;
  final List<ChapterModel> allChapters;
  final ReaderMode         mode;
  final VoidCallback       onModeToggle;

  const _TopBar({
    required this.chapter,
    required this.allChapters,
    required this.mode,
    required this.onModeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.96),
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        right:  4,
        left:   8,
      ),
      child: Row(
        children: [
          // زر الرجوع
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
            ),
            color:     Colors.black,
            onPressed: () => Navigator.pop(context),
          ),

          // عنوان الفصل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(
                  'الفصل ${chapter.displayNumber}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize:   15,
                    color:      Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (chapter.title != null)
                  Text(
                    chapter.title!,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color:    const Color(0xFF888888),
                    ),
                  ),
              ],
            ),
          ),

          // تبديل وضع القراءة Webtoon / Paged
          IconButton(
            icon: Icon(
              mode == ReaderMode.webtoon
                  ? Icons.view_day_outlined
                  : Icons.view_carousel_outlined,
              size: 22,
            ),
            color:     Colors.black,
            onPressed: onModeToggle,
            tooltip: mode == ReaderMode.webtoon
                ? 'وضع الصفحات'
                : 'وضع الويبتون',
          ),

          // قائمة الفصول
          IconButton(
            icon: const Icon(Icons.list_rounded, size: 22),
            color:     Colors.black,
            onPressed: () => _showChapterPicker(context),
          ),
        ],
      ),
    );
  }

  void _showChapterPicker(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => SizedBox(
        height: 420,
        child: Column(
          children: [
            // مقبض السحب
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color:        const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'قائمة الفصول',
                    style: GoogleFonts.cairo(
                      fontSize:   17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${allChapters.length} فصل',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color:    const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount:   allChapters.length,
                itemBuilder: (_, i) {
                  final ch        = allChapters[i];
                  final isCurrent = ch.id == chapter.id;
                  return ListTile(
                    leading: Container(
                      width:  36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF2394FC)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          ch.displayNumber,
                          style: GoogleFonts.cairo(
                            fontSize:   12,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      ch.title ?? 'الفصل ${ch.displayNumber}',
                      style: GoogleFonts.cairo(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? const Color(0xFF2394FC)
                            : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.play_circle_filled_rounded,
                            color: Color(0xFF2394FC),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context
                          .read<ReaderCubit>()
                          .loadChapter(ch.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM BAR
// ═══════════════════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  final ReaderLoaded       state;
  final List<ChapterModel> allChapters;
  final VoidCallback       onPrevChapter;
  final VoidCallback       onNextChapter;

  const _BottomBar({
    required this.state,
    required this.allChapters,
    required this.onPrevChapter,
    required this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    final idx     = allChapters
        .indexWhere((c) => c.id == state.chapter.id);
    final hasPrev = idx < allChapters.length - 1;
    final hasNext = idx > 0;

    return Container(
      color: Colors.white.withOpacity(0.96),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top:    8,
        right:  16,
        left:   16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط التقدم
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:   const Color(0xFF2394FC),
              inactiveTrackColor: const Color(0xFFEEEEEE),
              thumbColor:         const Color(0xFF2394FC),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
              trackHeight:  3,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: state.progress,
              onChanged: (v) {
                final page =
                    (v * (state.pageUrls.length - 1)).round();
                context
                    .read<ReaderCubit>()
                    .onPageChanged(page);
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الفصل السابق
              TextButton.icon(
                onPressed: hasPrev ? onPrevChapter : null,
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                ),
                label: Text(
                  'السابق',
                  style: GoogleFonts.cairo(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasPrev
                      ? Colors.black
                      : const Color(0xFFCCCCCC),
                ),
              ),

              // عداد الصفحات
              Text(
                '${state.currentPage + 1} / ${state.pageUrls.length}',
                style: GoogleFonts.cairo(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      const Color(0xFF666666),
                ),
              ),

              // زر الفصل التالي
              TextButton.icon(
                onPressed: hasNext ? onNextChapter : null,
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 13,
                ),
                label: Text(
                  'التالي',
                  style: GoogleFonts.cairo(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasNext
                      ? const Color(0xFF2394FC)
                      : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Loading & Error States
// ═══════════════════════════════════════════════════════════════
class _ReaderLoading extends StatelessWidget {
  const _ReaderLoading();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color:       Color(0xFF2394FC),
          strokeWidth: 2.5,
        ),
        const SizedBox(height: 14),
        Text(
          'جاري تحميل الفصل...',
          style: GoogleFonts.cairo(
            color: const Color(0xFF888888),
          ),
        ),
      ],
    ),
  );
}

class _ReaderError extends StatelessWidget {
  final String msg;
  const _ReaderError({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wifi_off_rounded,
          color: Color(0xFF666666),
          size:  48,
        ),
        const SizedBox(height: 12),
        Text(
          msg,
          style: GoogleFonts.cairo(
            color: const Color(0xFF888888),
          ),
          textAlign: TextAlign.center,
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
