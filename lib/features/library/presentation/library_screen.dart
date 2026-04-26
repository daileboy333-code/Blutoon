import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:blutoon/main.dart';
import 'package:blutoon/shared/models/manga_model.dart';
import 'package:blutoon/features/manga_detail/presentation/manga_detail_screen.dart';
import 'package:blutoon/features/auth/presentation/login_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
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
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مكتبتي',
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111111),
                      )),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabs,
                    labelColor: const Color(0xFF111111),
                    unselectedLabelColor: const Color(0xFF999999),
                    indicatorColor: const Color(0xFF2394FC),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'المفضلة'),
                      Tab(text: 'التاريخ'),
                      Tab(text: 'التحميلات'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: user == null
                  ? _NotLoggedIn()
                  : TabBarView(
                      controller: _tabs,
                      children: const [
                        _FavoritesTab(),
                        _HistoryTab(),
                        _DownloadsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// NOT LOGGED IN
// ════════════════════════════════════════════════════
class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(45),
              ),
              child: const Center(
                child: Text('📚', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            Text('سجّل دخولك',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                )),
            const SizedBox(height: 8),
            Text(
              'سجّل دخولك لتتمكن من حفظ المفضلة ومتابعة تاريخ القراءة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF999999),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
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
                child: Text('تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// FAVORITES TAB
// ════════════════════════════════════════════════════
class _FavoritesTab extends StatefulWidget {
  const _FavoritesTab();
  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  List<MangaModel> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final res = await supabase
          .from('favorites')
          .select('manga_id, manga(*, latest_chapter_num:chapters(chapter_number).order(chapter_number.desc).limit(1))')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      // جلب بيانات المانجا مباشرة
      final mangaIds = (res as List).map((e) => e['manga_id']).toList();
      if (mangaIds.isEmpty) {
        setState(() { _items = []; _loading = false; });
        return;
      }

      final mangaRes = await supabase
          .from('manga_with_latest_chapter')
          .select()
          .inFilter('id', mangaIds);

      setState(() {
        _items = (mangaRes as List)
            .map((e) => MangaModel.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(int mangaId) async {
    try {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('manga_id', mangaId);
      setState(() => _items.removeWhere((m) => m.id == mangaId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return _buildShimmer();
    if (_items.isEmpty) {
      return _EmptyState(
        emoji: '🔖',
        title: 'لا توجد مفضلة',
        subtitle: 'اضغط على أيقونة المفضلة في أي مانجا لإضافتها هنا',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2394FC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        itemBuilder: (context, i) => _LibraryRow(
          manga: _items[i],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) =>
                      MangaDetailScreen(mangaId: _items[i].id))),
          trailing: IconButton(
            icon: const Icon(
              Icons.bookmark_remove_rounded,
              color: Color(0xFFe74c3c),
              size: 22,
            ),
            onPressed: () => _removeFavorite(_items[i].id),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() => _LibraryShimmer();
}

// ════════════════════════════════════════════════════
// HISTORY TAB
// ════════════════════════════════════════════════════
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final res = await supabase
          .from('reading_progress')
          .select('manga_id, last_chapter_id, last_page, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(50);

      if ((res as List).isEmpty) {
        setState(() { _items = []; _loading = false; });
        return;
      }

      final mangaIds = res.map((e) => e['manga_id']).toList();
      final mangaRes = await supabase
          .from('manga')
          .select('id, title_ar, cover_url, type')
          .inFilter('id', mangaIds);

      final mangaMap = {
        for (final m in mangaRes as List) m['id']: m
      };

      setState(() {
        _items = res.map((e) {
          final manga = mangaMap[e['manga_id']];
          return {
            'manga_id':    e['manga_id'],
            'title_ar':    manga?['title_ar'] ?? '',
            'cover_url':   manga?['cover_url'] ?? '',
            'type':        manga?['type'] ?? 'manga',
            'last_chapter_id': e['last_chapter_id'],
            'last_page':   e['last_page'],
            'updated_at':  e['updated_at'],
          };
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeHistory(int mangaId) async {
    try {
      await supabase
          .from('reading_progress')
          .delete()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('manga_id', mangaId);
      setState(() =>
          _items.removeWhere((m) => m['manga_id'] == mangaId));
    } catch (_) {}
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 30)  return '${d.day}/${d.month}/${d.year}';
    if (diff.inDays > 0)   return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0)  return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return _LibraryShimmer();
    if (_items.isEmpty) {
      return _EmptyState(
        emoji: '📖',
        title: 'لا يوجد تاريخ',
        subtitle: 'ستظهر هنا المانجا التي قرأتها',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2394FC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return _LibraryRow(
            manga: MangaModel(
              id:         item['manga_id'] as int,
              titleAr:    item['title_ar'] as String,
              slug:       '',
              coverUrl:   item['cover_url'] as String,
              type:       item['type'] as String,
              status:     'ongoing',
              rating:     0,
              views:      0,
              isFeatured: false,
            ),
            subtitle: _timeAgo(item['updated_at'] as String?),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => MangaDetailScreen(
                        mangaId: item['manga_id'] as int))),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFCCCCCC),
                size: 22,
              ),
              onPressed: () =>
                  _removeHistory(item['manga_id'] as int),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DOWNLOADS TAB
// ════════════════════════════════════════════════════
class _DownloadsTab extends StatefulWidget {
  const _DownloadsTab();
  @override
  State<_DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<_DownloadsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _EmptyState(
      emoji: '⬇️',
      title: 'لا توجد تحميلات',
      subtitle: 'ستظهر هنا الفصول التي قمت بتحميلها للقراءة بدون إنترنت',
      showComingSoon: true,
    );
  }
}

// ════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════
class _LibraryRow extends StatelessWidget {
  final MangaModel  manga;
  final String?     subtitle;
  final VoidCallback onTap;
  final Widget?     trailing;

  const _LibraryRow({
    required this.manga,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(children: [
          // غلاف
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: manga.coverUrl,
              width: 56, height: 78, fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  width: 56, height: 78,
                  color: const Color(0xFFEEEEEE)),
              errorWidget: (_, __, ___) => Container(
                  width: 56, height: 78,
                  color: const Color(0xFFDDDDDD)),
            ),
          ),
          const SizedBox(width: 14),
          // معلومات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manga.titleAr,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111111),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2394FC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(manga.type,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2394FC),
                        )),
                  ),
                  if (manga.latestChapterNum != null) ...[
                    const SizedBox(width: 6),
                    Text('ف ${manga.latestChapterNum}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF999999),
                        )),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(width: 6),
                    Text(subtitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF999999),
                        )),
                  ],
                ]),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool showComingSoon;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.showComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: const Color(0xFF999999),
                  height: 1.6,
                )),
            if (showComingSoon) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('قريباً',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF999999),
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Row(children: [
            Container(
              width: 56, height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 180,
                      color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 11, width: 100,
                      color: Colors.white),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
