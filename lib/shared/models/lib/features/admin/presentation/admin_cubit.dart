import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../main.dart';

// ── Models ─────────────────────────────────────────────────────
class AdminUser {
  final String id;
  final String username;
  final String? displayName;
  final String role;
  final String? avatarUrl;
  final bool   isBanned;

  const AdminUser({
    required this.id,
    required this.username,
    this.displayName,
    required this.role,
    this.avatarUrl,
    required this.isBanned,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id:          j['id'] as String,
    username:    j['username'] as String,
    displayName: j['display_name'] as String?,
    role:        j['role'] as String,
    avatarUrl:   j['avatar_url'] as String?,
    isBanned:    j['is_banned'] as bool,
  );
}

class AdminManga {
  final int    id;
  final String titleAr;
  final String type;
  final String status;
  final int    views;
  final int    chaptersCount;

  const AdminManga({
    required this.id,
    required this.titleAr,
    required this.type,
    required this.status,
    required this.views,
    required this.chaptersCount,
  });

  factory AdminManga.fromJson(Map<String, dynamic> j) => AdminManga(
    id:            j['id'] as int,
    titleAr:       j['title_ar'] as String,
    type:          j['type'] as String,
    status:        j['status'] as String,
    views:         (j['views'] ?? 0) as int,
    chaptersCount: (j['chapters_count'] ?? 0) as int,
  );
}

// ── States ─────────────────────────────────────────────────────
abstract class AdminState extends Equatable {
  @override List<Object?> get props => [];
}

class AdminInitial  extends AdminState {}
class AdminLoading  extends AdminState {}
class AdminError    extends AdminState {
  final String msg;
  AdminError(this.msg);
  @override List<Object?> get props => [msg];
}

class AdminLoaded extends AdminState {
  final List<AdminManga> mangas;
  final List<AdminUser>  users;
  final String           currentUserRole;
  final int              totalMangas;
  final int              totalUsers;
  final int              totalChapters;

  const AdminLoaded({
    required this.mangas,
    required this.users,
    required this.currentUserRole,
    required this.totalMangas,
    required this.totalUsers,
    required this.totalChapters,
  });

  @override
  List<Object?> get props =>
      [mangas, users, currentUserRole, totalMangas, totalUsers, totalChapters];
}

class AdminActionSuccess extends AdminState {
  final String message;
  AdminActionSuccess(this.message);
  @override List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────
class AdminCubit extends Cubit<AdminState> {
  AdminCubit() : super(AdminInitial());

  Future<void> loadDashboard() async {
    emit(AdminLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(AdminError('غير مسجل الدخول'));
        return;
      }

      final results = await Future.wait([
        // معلومات المستخدم الحالي
        supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .single(),

        // قائمة المانجا مع عدد الفصول
        supabase
            .from('manga')
            .select('id, title_ar, type, status, views')
            .order('created_at', ascending: false)
            .limit(50),

        // قائمة المستخدمين
        supabase
            .from('users')
            .select()
            .order('created_at', ascending: false)
            .limit(100),

        // إحصائيات
        supabase.from('manga').select('id'),
        supabase.from('users').select('id'),
        supabase.from('chapters').select('id'),
      ]);

      final currentRole = (results[0] as Map)['role'] as String;

      // التحقق من الصلاحية
      if (!['admin', 'moderator', 'translator'].contains(currentRole)) {
        emit(AdminError('ليس لديك صلاحية للوصول'));
        return;
      }

      // جلب عدد الفصول لكل مانجا
      final mangaList = results[1] as List;
      final List<AdminManga> mangas = [];

      for (final m in mangaList) {
        final chapCount = await supabase
            .from('chapters')
            .select('id')
            .eq('manga_id', m['id'] as int);
        mangas.add(AdminManga(
          id:            m['id'] as int,
          titleAr:       m['title_ar'] as String,
          type:          m['type'] as String,
          status:        m['status'] as String,
          views:         (m['views'] ?? 0) as int,
          chaptersCount: (chapCount as List).length,
        ));
      }

      emit(AdminLoaded(
        mangas:          mangas,
        users:           (results[2] as List)
            .map((e) => AdminUser.fromJson(e))
            .toList(),
        currentUserRole: currentRole,
        totalMangas:     (results[3] as List).length,
        totalUsers:      (results[4] as List).length,
        totalChapters:   (results[5] as List).length,
      ));

    } catch (e) {
      emit(AdminError('$e'));
    }
  }

  // ── تغيير دور مستخدم ────────────────────────────────────────
  Future<void> changeUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);
      emit(AdminActionSuccess('تم تغيير الدور بنجاح'));
      await loadDashboard();
    } catch (e) {
      emit(AdminError('فشل تغيير الدور: $e'));
    }
  }

  // ── حظر / رفع حظر مستخدم ────────────────────────────────────
  Future<void> toggleBan(String userId, bool currentStatus) async {
    try {
      await supabase
          .from('users')
          .update({'is_banned': !currentStatus})
          .eq('id', userId);
      emit(AdminActionSuccess(
          currentStatus ? 'تم رفع الحظر' : 'تم حظر المستخدم'));
      await loadDashboard();
    } catch (e) {
      emit(AdminError('فشل: $e'));
    }
  }

  // ── حذف مانجا ────────────────────────────────────────────────
  Future<void> deleteManga(int mangaId) async {
    try {
      await supabase.from('manga').delete().eq('id', mangaId);
      emit(AdminActionSuccess('تم حذف المانجا'));
      await loadDashboard();
    } catch (e) {
      emit(AdminError('فشل الحذف: $e'));
    }
  }

  // ── إضافة مانجا جديدة ───────────────────────────────────────
  Future<void> addManga({
    required String titleAr,
    String?         titleEn,
    required String slug,
    required String coverUrl,
    String?         bannerUrl,
    String?         description,
    required String type,
    required String status,
  }) async {
    try {
      await supabase.from('manga').insert({
        'title_ar':    titleAr,
        'title_en':    titleEn,
        'slug':        slug,
        'cover_url':   coverUrl,
        'banner_url':  bannerUrl,
        'description': description,
        'type':        type,
        'status':      status,
      });
      emit(AdminActionSuccess('تمت إضافة المانجا بنجاح ✅'));
      await loadDashboard();
    } catch (e) {
      emit(AdminError('فشل الإضافة: $e'));
    }
  }

  // ── رفع فصل جديد ────────────────────────────────────────────
  Future<void> addChapter({
    required int    mangaId,
    required double chapterNumber,
    String?         title,
    required List<String> pageUrls,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      // إنشاء الفصل
      final chapterRes = await supabase
          .from('chapters')
          .insert({
            'manga_id':       mangaId,
            'chapter_number': chapterNumber,
            'title':          title,
            'uploaded_by':    userId,
          })
          .select()
          .single();

      final chapterId = chapterRes['id'] as int;

      // إضافة الصفحات
      final pages = pageUrls.asMap().entries.map((e) => {
        'chapter_id':  chapterId,
        'page_number': e.key + 1,
        'image_url':   e.value,
      }).toList();

      await supabase.from('pages').insert(pages);

      emit(AdminActionSuccess('تم رفع الفصل بنجاح ✅'));
      await loadDashboard();
    } catch (e) {
      emit(AdminError('فشل رفع الفصل: $e'));
    }
  }
}
