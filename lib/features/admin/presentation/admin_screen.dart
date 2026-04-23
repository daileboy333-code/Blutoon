import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/features/admin/presentation/admin_cubit.dart';
import 'package:blutoon/features/admin/presentation/add_manga_screen.dart';
import 'package:blutoon/features/admin/presentation/upload_chapter_screen.dart';
import 'package:blutoon/features/admin/presentation/manage_users_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminCubit()..loadDashboard(),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: GoogleFonts.cairo(color: Colors.white)),
                backgroundColor: const Color(0xFF2ecc71),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.msg,
                    style: GoogleFonts.cairo(color: Colors.white)),
                backgroundColor: const Color(0xFFe74c3c),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2394FC),
                strokeWidth: 2.5,
              ),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 64, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 16),
                  Text(state.msg,
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF999999))),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<AdminCubit>().loadDashboard(),
                    child: Text('إعادة المحاولة',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF2394FC))),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            return _Dashboard(state: state);
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final AdminLoaded state;
  const _Dashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isAdmin = state.currentUserRole == 'admin';
    final isMod   = state.currentUserRole == 'moderator';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('لوحة التحكم',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          )),
                      Text(
                        _roleLabel(state.currentUserRole),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF2394FC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () =>
                        context.read<AdminCubit>().loadDashboard(),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon:  Icons.auto_stories_rounded,
                    label: 'مانجا',
                    value: '${state.totalMangas}',
                    color: const Color(0xFF2394FC),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon:  Icons.menu_book_rounded,
                    label: 'فصول',
                    value: '${state.totalChapters}',
                    color: const Color(0xFF2ecc71),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon:  Icons.people_rounded,
                    label: 'مستخدم',
                    value: '${state.totalUsers}',
                    color: const Color(0xFFf1c40f),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إجراءات سريعة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon:  Icons.add_circle_outline_rounded,
                          label: 'إضافة مانجا',
                          color: const Color(0xFF2394FC),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AdminCubit>(),
                                child: const AddMangaScreen(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon:  Icons.upload_file_rounded,
                          label: 'رفع فصل',
                          color: const Color(0xFF2ecc71),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AdminCubit>(),
                                child: UploadChapterScreen(
                                    mangas: state.mangas),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isAdmin || isMod) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionBtn(
                            icon:  Icons.manage_accounts_rounded,
                            label: 'المستخدمون',
                            color: const Color(0xFFa78bfa),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AdminCubit>(),
                                  child: ManageUsersScreen(
                                    users: state.users,
                                    currentUserRole:
                                        state.currentUserRole,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Manga List ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('المانجا المضافة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  )),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _MangaAdminTile(
                manga:          state.mangas[i],
                canDelete:      isAdmin || isMod,
                onDelete: () => _confirmDelete(
                    context, state.mangas[i]),
                onUploadChapter: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AdminCubit>(),
                      child: UploadChapterScreen(
                        mangas:         state.mangas,
                        preselectedId:  state.mangas[i].id,
                      ),
                    ),
                  ),
                ),
              ),
              childCount: state.mangas.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':      return '👑 مدير';
      case 'moderator':  return '🛡️ مشرف';
      case 'translator': return '✍️ مترجم';
      default:           return 'عضو';
    }
  }

  void _confirmDelete(BuildContext context, AdminManga manga) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف المانجا',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text(
          'هل أنت متأكد من حذف "${manga.titleAr}"؟\nسيتم حذف جميع فصولها وصفحاتها.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: const Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteManga(manga.id);
            },
            child: Text('حذف',
                style: GoogleFonts.cairo(
                    color: const Color(0xFFe74c3c),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// Widgets
// ════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.cairo(
                fontSize:   22,
                fontWeight: FontWeight.w900,
                color:      color,
              )),
          Text(label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color:    const Color(0xFF999999),
              )),
        ],
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.cairo(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      color,
              )),
        ],
      ),
    ),
  );
}

class _MangaAdminTile extends StatelessWidget {
  final AdminManga   manga;
  final bool         canDelete;
  final VoidCallback onDelete;
  final VoidCallback onUploadChapter;
  const _MangaAdminTile({
    required this.manga,
    required this.canDelete,
    required this.onDelete,
    required this.onUploadChapter,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color:      Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset:     const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:        const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              manga.titleAr.substring(0, 1),
              style: GoogleFonts.cairo(
                fontSize:   18,
                fontWeight: FontWeight.w900,
                color:      const Color(0xFF2394FC),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(manga.titleAr,
                  style: GoogleFonts.cairo(
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis),
              Row(children: [
                _Badge(
                  label: manga.type.toUpperCase(),
                  color: const Color(0xFF2394FC),
                ),
                const SizedBox(width: 6),
                _Badge(
                  label: '${manga.chaptersCount} فصل',
                  color: const Color(0xFF2ecc71),
                ),
                const SizedBox(width: 6),
                Text('${manga.views} مشاهدة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color:    const Color(0xFF999999),
                    )),
              ]),
            ],
          ),
        ),
        // رفع فصل
        IconButton(
          icon: const Icon(
            Icons.upload_rounded,
            color: Color(0xFF2ecc71),
            size: 22,
          ),
          onPressed: onUploadChapter,
          tooltip: 'رفع فصل',
        ),
        // حذف
        if (canDelete)
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFe74c3c),
              size: 22,
            ),
            onPressed: onDelete,
            tooltip: 'حذف',
          ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: GoogleFonts.cairo(
          fontSize:   10,
          fontWeight: FontWeight.w700,
          color:      color,
        )),
  );
}
