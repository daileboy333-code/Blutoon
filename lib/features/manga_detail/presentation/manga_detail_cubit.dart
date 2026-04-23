import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:blutoon/shared/models/manga_model.dart';
import 'package:blutoon/shared/models/chapter_model.dart';
import 'package:blutoon/main.dart';

// ── States ─────────────────────────────────────────────────────
abstract class MangaDetailState extends Equatable {
  @override List<Object?> get props => [];
}
class MangaDetailLoading extends MangaDetailState {}
class MangaDetailError extends MangaDetailState {
  final String msg;
  MangaDetailError(this.msg);
  @override List<Object?> get props => [msg];
}

class MangaDetailLoaded extends MangaDetailState {
  final MangaModel         manga;
  final List<ChapterModel> chapters;
  final bool               isFavorited;
  final int?               lastReadChapterId;

  const MangaDetailLoaded({
    required this.manga,
    required this.chapters,
    this.isFavorited = false,
    this.lastReadChapterId,
  });

  MangaDetailLoaded copyWith({bool? isFavorited}) => MangaDetailLoaded(
    manga: manga,
    chapters: chapters,
    isFavorited: isFavorited ?? this.isFavorited,
    lastReadChapterId: lastReadChapterId,
  );

  @override List<Object?> get props => [manga, chapters, isFavorited, lastReadChapterId];
}

// ── Cubit ──────────────────────────────────────────────────────
class MangaDetailCubit extends Cubit<MangaDetailState> {
  MangaDetailCubit() : super(MangaDetailLoading());

  Future<void> load(int mangaId) async {
    emit(MangaDetailLoading());
    try {
      final userId = supabase.auth.currentUser?.id;

      final results = await Future.wait([
        // تفاصيل المانجا
        supabase
            .from('manga')
            .select()
            .eq('id', mangaId)
            .single(),

        // قائمة الفصول تنازلياً
        supabase
            .from('chapters')
            .select()
            .eq('manga_id', mangaId)
            .order('chapter_number', ascending: false),

        // هل في المفضلة؟
        if (userId != null)
          supabase
              .from('favorites')
              .select()
              .eq('user_id', userId)
              .eq('manga_id', mangaId)
              .maybeSingle()
        else
          Future.value(null),

        // آخر فصل قُرئ
        if (userId != null)
          supabase
              .from('reading_progress')
              .select('last_chapter_id')
              .eq('user_id', userId)
              .eq('manga_id', mangaId)
              .maybeSingle()
        else
          Future.value(null),
      ]);

      emit(MangaDetailLoaded(
        manga:    MangaModel.fromJson(results[0] as Map<String, dynamic>),
        chapters: (results[1] as List).map((e) => ChapterModel.fromJson(e)).toList(),
        isFavorited:       results[2] != null,
        lastReadChapterId: (results[3] as Map?)?['last_chapter_id'] as int?,
      ));

      // زيادة عداد المشاهدات بشكل غير متزامن
      supabase.rpc('increment_manga_views', params: {'manga_id': mangaId});

    } catch (e) {
      emit(MangaDetailError('$e'));
    }
  }

  Future<void> toggleFavorite() async {
    final s = state;
    if (s is! MangaDetailLoaded) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic update — يتغير الزر فوراً قبل انتظار الـ server
    emit(s.copyWith(isFavorited: !s.isFavorited));

    try {
      if (!s.isFavorited) {
        await supabase.from('favorites').insert({
          'user_id': userId,
          'manga_id': s.manga.id,
        });
      } else {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('manga_id', s.manga.id);
      }
    } catch (_) {
      // Rollback إذا فشل الـ server
      emit(s.copyWith(isFavorited: s.isFavorited));
    }
  }
}
