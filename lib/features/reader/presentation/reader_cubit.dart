import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:blutoon/shared/models/chapter_model.dart';
import 'package:blutoon/main.dart';

// ── States ─────────────────────────────────────────────────────
abstract class ReaderState extends Equatable {
  @override List<Object?> get props => [];
}

class ReaderLoading extends ReaderState {}

class ReaderError extends ReaderState {
  final String msg;
  ReaderError(this.msg);
  @override List<Object?> get props => [msg];
}

class ReaderLoaded extends ReaderState {
  final ChapterModel chapter;
  final List<String> pageUrls;    // Hotlink URLs من Supabase
  final int          currentPage;
  final bool         showBars;    // إخفاء/إظهار الـ bars عند الضغط
  final ReaderMode   mode;

  const ReaderLoaded({
    required this.chapter,
    required this.pageUrls,
    this.currentPage = 0,
    this.showBars    = true,
    this.mode        = ReaderMode.webtoon,
  });

  // نسبة التقدم من 0.0 إلى 1.0 لشريط الـ Slider
  double get progress =>
      pageUrls.isEmpty ? 0 : (currentPage + 1) / pageUrls.length;

  ReaderLoaded copyWith({
    int?        currentPage,
    bool?       showBars,
    ReaderMode? mode,
  }) => ReaderLoaded(
    chapter:     chapter,
    pageUrls:    pageUrls,
    currentPage: currentPage ?? this.currentPage,
    showBars:    showBars    ?? this.showBars,
    mode:        mode        ?? this.mode,
  );

  @override
  List<Object?> get props =>
      [chapter, pageUrls, currentPage, showBars, mode];
}

enum ReaderMode { webtoon, paged }

// ── Cubit ──────────────────────────────────────────────────────
class ReaderCubit extends Cubit<ReaderState> {
  final int mangaId;

  ReaderCubit(this.mangaId) : super(ReaderLoading());

  Future<void> loadChapter(int chapterId) async {
    emit(ReaderLoading());
    try {
      final results = await Future.wait([
        // بيانات الفصل
        supabase
            .from('chapters')
            .select()
            .eq('id', chapterId)
            .single(),

        // صفحات الفصل مرتبة تصاعدياً
        supabase
            .from('pages')
            .select('image_url')
            .eq('chapter_id', chapterId)
            .order('page_number'),
      ]);

      final chapter = ChapterModel.fromJson(
          results[0] as Map<String, dynamic>);

      final pageUrls = (results[1] as List)
          .map((p) => p['image_url'] as String)
          .toList();

      emit(ReaderLoaded(chapter: chapter, pageUrls: pageUrls));

    } catch (e) {
      emit(ReaderError('$e'));
    }
  }

  // يُستدعى كلما تغيرت الصفحة — يحدّث الـ state ويحفظ التقدم
  void onPageChanged(int page) {
    final s = state;
    if (s is! ReaderLoaded) return;
    emit(s.copyWith(currentPage: page));
    _saveProgress(s.chapter, page);
  }

  // إخفاء أو إظهار الـ Top/Bottom bars عند الضغط على الشاشة
  void toggleBars() {
    final s = state;
    if (s is ReaderLoaded) emit(s.copyWith(showBars: !s.showBars));
  }

  // تبديل بين وضع Webtoon (تمرير) و Paged (صفحة بصفحة)
  void toggleMode() {
    final s = state;
    if (s is! ReaderLoaded) return;
    emit(s.copyWith(
      mode: s.mode == ReaderMode.webtoon
          ? ReaderMode.paged
          : ReaderMode.webtoon,
    ));
  }

  // ── حفظ التقدم في Supabase ─────────────────────────────────
  // Debounce: لا يحفظ إلا كل 3 ثوانٍ على الأقل لتقليل الطلبات
  DateTime? _lastSave;

  void _saveProgress(ChapterModel ch, int page) {
    final now = DateTime.now();
    if (_lastSave != null &&
        now.difference(_lastSave!).inSeconds < 3) return;
    _lastSave = now;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // upsert = insert إذا لم يكن موجوداً، أو update إذا كان موجوداً
    supabase.from('reading_progress').upsert({
      'user_id':         userId,
      'manga_id':        mangaId,
      'last_chapter_id': ch.id,
      'last_page':       page + 1,
      'updated_at':      DateTime.now().toIso8601String(),
    });
  }
}
