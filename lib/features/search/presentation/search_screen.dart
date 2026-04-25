import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:blutoon/main.dart';
import 'package:blutoon/shared/models/manga_model.dart';
import 'package:blutoon/features/manga_detail/presentation/manga_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl    = TextEditingController();
  final _focus   = FocusNode();

  List<MangaModel> _results    = [];
  List<MangaModel> _trending   = [];
  bool             _loading    = false;
  bool             _hasSearched = false;
  String           _activeGenre = '';

  // تصنيفات ثابتة
  static const _genres = [
    '🔥 رائج', '⚔️ أكشن', '😂 كوميدي', '💕 رومانسي',
    '🧙 فنتازيا', '👻 رعب', '🚀 خيال علمي', '⚽ رياضي',
    '🎭 دراما', '🧠 نفسي', '🌀 إيسيكاي', '📖 شونن',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrending();
    // فتح الكيبورد تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    try {
      final res = await supabase
          .from('manga')
          .select()
          .order('views', ascending: false)
          .limit(8);
      if (mounted) {
        setState(() => _trending =
            (res as List).map((e) => MangaModel.fromJson(e)).toList());
      }
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() { _loading = true; _hasSearched = true; });
    try {
      final res = await supabase
          .from('manga')
          .select()
          .or('title_ar.ilike.%$query%,title_en.ilike.%$query%,slug.ilike.%$query%')
          .limit(30);
      if (mounted) {
        setState(() {
          _results = (res as List).map((e) => MangaModel.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchByGenre(String genre) async {
    // إزالة الإيموجي
    final clean = genre.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '').trim();
    setState(() { _activeGenre = genre; _loading = true; _hasSearched = true; _ctrl.clear(); });
    try {
      // ابحث في genres
      final genreRes = await supabase
          .from('genres')
          .select('id')
          .ilike('name_ar', '%$clean%')
          .limit(1);

      if ((genreRes as List).isEmpty) {
        setState(() { _results = []; _loading = false; });
        return;
      }

      final genreId = genreRes[0]['id'] as int;
      final mangaIds = await supabase
          .from('manga_genres')
          .select('manga_id')
          .eq('genre_id', genreId);

      if ((mangaIds as List).isEmpty) {
        setState(() { _results = []; _loading = false; });
        return;
      }

      final ids = mangaIds.map((e) => e['manga_id']).toList();
      final res = await supabase
          .from('manga')
          .select()
          .inFilter('id', ids)
          .limit(30);

      if (mounted) {
        setState(() {
          _results = (res as List).map((e) => MangaModel.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    _ctrl.clear();
    setState(() { _results = []; _hasSearched = false; _activeGenre = ''; });
    _focus.requestFocus();
  }

  void _open(int mangaId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MangaDetailScreen(mangaId: mangaId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────
            _SearchBar(
              ctrl:    _ctrl,
              focus:   _focus,
              onChanged: (v) => _search(v),
              onClear:   _clear,
            ),

            // ── Content ───────────────────────────────────────
            Expanded(
              child: _hasSearched
                  ? _SearchResults(
                      results:  _results,
                      loading:  _loading,
                      query:    _ctrl.text,
                      onTap:    _open,
                    )
                  : _DiscoverView(
                      genres:      _genres,
                      trending:    _trending,
                      activeGenre: _activeGenre,
                      onGenreTap:  _searchByGenre,
                      onMangaTap:  _open,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// SEARCH BAR
// ════════════════════════════════════════════════════
class _SearchBar extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode             focus;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onClear;
  const _SearchBar({required this.ctrl, required this.focus, required this.onChanged, required this.onClear});
  @override State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;
  @override void initState() { super.initState(); widget.ctrl.addListener(() => setState(() => _hasText = widget.ctrl.text.isNotEmpty)); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller:    widget.ctrl,
              focusNode:     widget.focus,
              onChanged:     widget.onChanged,
              textAlign:     TextAlign.right,
              style:         GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:  'ابحث عن مانجا أو رواية...',
                hintStyle: GoogleFonts.cairo(color: const Color(0xFF999999), fontWeight: FontWeight.w500, fontSize: 14),
                border:    InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF999999), size: 22),
                suffixIcon: _hasText
                    ? GestureDetector(
                        onTap: widget.onClear,
                        child: const Icon(Icons.cancel_rounded, color: Color(0xFFCCCCCC), size: 20),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
// DISCOVER VIEW (الحالة الافتراضية)
// ════════════════════════════════════════════════════
class _DiscoverView extends StatelessWidget {
  final List<String>     genres;
  final List<MangaModel> trending;
  final String           activeGenre;
  final ValueChanged<String> onGenreTap;
  final ValueChanged<int>    onMangaTap;
  const _DiscoverView({required this.genres, required this.trending, required this.activeGenre, required this.onGenreTap, required this.onMangaTap});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Genre Pills ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('استكشف حسب التصنيف',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map((g) {
                final active = activeGenre == g;
                return GestureDetector(
                  onTap: () => onGenreTap(g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(g,
                        style: GoogleFonts.cairo(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : const Color(0xFF333333),
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Trending ─────────────────────────────────────────
        if (trending.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              child: Row(children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF2394FC), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text('الأكثر رواجاً', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _TrendingCard(manga: trending[i], onTap: () => onMangaTap(trending[i].id)),
                childCount: trending.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// SEARCH RESULTS
// ════════════════════════════════════════════════════
class _SearchResults extends StatelessWidget {
  final List<MangaModel> results;
  final bool             loading;
  final String           query;
  final ValueChanged<int> onTap;
  const _SearchResults({required this.results, required this.loading, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE8E8E8),
        highlightColor: const Color(0xFFF5F5F5),
        child: ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(children: [
              Container(width: 60, height: 85, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 180, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 11, width: 100, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 11, width: 140, color: Colors.white),
              ])),
            ]),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(40)), child: const Center(child: Text('🔍', style: TextStyle(fontSize: 36)))),
          const SizedBox(height: 16),
          Text('لا توجد نتائج', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111111))),
          const SizedBox(height: 6),
          Text('جرّب كلمة بحث مختلفة', style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF999999))),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('${results.length} نتيجة',
              style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF999999), fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, i) => _ResultRow(manga: results[i], onTap: () => onTap(results[i].id)),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// RESULT ROW
// ════════════════════════════════════════════════════
class _ResultRow extends StatelessWidget {
  final MangaModel  manga;
  final VoidCallback onTap;
  const _ResultRow({required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          // غلاف
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: manga.coverUrl,
              width: 60, height: 85, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 60, height: 85, color: const Color(0xFFEEEEEE)),
              errorWidget: (_, __, ___) => Container(width: 60, height: 85, color: const Color(0xFFDDDDDD)),
            ),
          ),
          const SizedBox(width: 14),
          // معلومات
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(manga.titleAr,
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (manga.titleEn != null) ...[
              const SizedBox(height: 2),
              Text(manga.titleEn!, style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF999999)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              _Badge(label: manga.type, color: const Color(0xFF2394FC)),
              const SizedBox(width: 6),
              _Badge(
                label: manga.status == 'ongoing' ? 'مستمر' : manga.status == 'completed' ? 'مكتمل' : 'متوقف',
                color: manga.status == 'ongoing' ? const Color(0xFF2ecc71) : const Color(0xFF999999),
              ),
              const SizedBox(width: 6),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF1C40F)),
                const SizedBox(width: 2),
                Text(manga.rating.toStringAsFixed(1), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF666666))),
              ]),
            ]),
          ])),
          const Icon(Icons.chevron_left_rounded, color: Color(0xFFCCCCCC)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TRENDING CARD
// ════════════════════════════════════════════════════
class _TrendingCard extends StatelessWidget {
  final MangaModel  manga;
  final VoidCallback onTap;
  const _TrendingCard({required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: manga.coverUrl,
                width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFFEEEEEE)),
                errorWidget: (_, __, ___) => Container(color: const Color(0xFFDDDDDD)),
              ),
            ),
            // Rating badge
            Positioned(bottom: 6, right: 6, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF1C40F)),
                const SizedBox(width: 2),
                Text(manga.rating.toStringAsFixed(1), style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 6),
        Text(manga.titleAr,
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
// BADGE
// ════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}
