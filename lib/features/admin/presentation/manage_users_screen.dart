import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/features/admin/presentation/admin_cubit.dart';

class ManageUsersScreen extends StatefulWidget {
  final List<AdminUser> users;
  final String          currentUserRole;

  const ManageUsersScreen({
    super.key,
    required this.users,
    required this.currentUserRole,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _filter   = 'all';
  String _search   = '';

  List<AdminUser> get _filtered {
    var list = widget.users;
    if (_filter != 'all') {
      list = list.where((u) => u.role == _filter).toList();
    }
    if (_search.isNotEmpty) {
      list = list.where((u) =>
        u.username.contains(_search) ||
        (u.displayName?.contains(_search) ?? false)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUserRole == 'admin';
    final isMod   = widget.currentUserRole == 'moderator';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('إدارة المستخدمين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style:     GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText:    'بحث عن مستخدم...',
                hintStyle:   GoogleFonts.cairo(
                    color: const Color(0xFF999999)),
                prefixIcon:  const Icon(Icons.search_rounded,
                    color: Color(0xFF999999)),
                filled:      true,
                fillColor:   const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2394FC), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Filter
          Container(
            color:  Colors.white,
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              children: [
                _FilterChip(label: 'الكل',      value: 'all',        current: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'مدير',      value: 'admin',      current: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'مشرف',      value: 'moderator',  current: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'مترجم',     value: 'translator', current: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'أعضاء',     value: 'member',     current: _filter, onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount:   _filtered.length,
              itemBuilder: (context, i) {
                final user = _filtered[i];
                return _UserTile(
                  user:            user,
                  canChangeRole:   isAdmin || (isMod && user.role == 'member'),
                  canBan:          isAdmin,
                  currentUserRole: widget.currentUserRole,
                  onRoleChange: (newRole) =>
                      context.read<AdminCubit>()
                          .changeUserRole(user.id, newRole),
                  onToggleBan: () =>
                      context.read<AdminCubit>()
                          .toggleBan(user.id, user.isBanned),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String                  label;
  final String                  value;
  final String                  current;
  final ValueChanged<String>    onTap;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:  const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF2394FC)
              : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF2394FC),
            )),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser     user;
  final bool          canChangeRole;
  final bool          canBan;
  final String        currentUserRole;
  final Function(String) onRoleChange;
  final VoidCallback  onToggleBan;

  const _UserTile({
    required this.user,
    required this.canChangeRole,
    required this.canBan,
    required this.currentUserRole,
    required this.onRoleChange,
    required this.onToggleBan,
  });

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFFe74c3c);
      case 'moderator':  return const Color(0xFFa78bfa);
      case 'translator': return const Color(0xFF2394FC);
      default:           return const Color(0xFF999999);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':      return '👑 مدير';
      case 'moderator':  return '🛡️ مشرف';
      case 'translator': return '✍️ مترجم';
      default:           return '👤 عضو';
    }
  }

  List<String> _availableRoles() {
    if (currentUserRole == 'admin') {
      return ['member', 'translator', 'moderator', 'admin'];
    }
    if (currentUserRole == 'moderator') {
      return ['member', 'translator'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        user.isBanned
            ? const Color(0xFFFFF0F0)
            : Colors.white,
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
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        _roleColor(user.role).withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: GoogleFonts.cairo(
                  fontSize:   18,
                  fontWeight: FontWeight.w900,
                  color:      _roleColor(user.role),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(user.displayName ?? user.username,
                      style: GoogleFonts.cairo(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                      )),
                  if (user.isBanned) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFe74c3c)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('محظور',
                          style: GoogleFonts.cairo(
                            fontSize:   10,
                            color:      const Color(0xFFe74c3c),
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ]),
                Text('@${user.username}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color:    const Color(0xFF999999),
                    )),
              ],
            ),
          ),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        _roleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_roleLabel(user.role),
                style: GoogleFonts.cairo(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      _roleColor(user.role),
                )),
          ),

          // Actions
          if (canChangeRole || canBan)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF999999),
              ),
              onSelected: (action) {
                if (action == 'ban') {
                  onToggleBan();
                } else {
                  onRoleChange(action);
                }
              },
              itemBuilder: (_) => [
                if (canChangeRole)
                  ..._availableRoles()
                      .where((r) => r != user.role)
                      .map((r) => PopupMenuItem(
                        value: r,
                        child: Text(
                          'تعيين كـ ${_roleLabel(r)}',
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                      )),
                if (canBan)
                  PopupMenuItem(
                    value: 'ban',
                    child: Text(
                      user.isBanned ? 'رفع الحظر' : 'حظر المستخدم',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color:    user.isBanned
                            ? const Color(0xFF2ecc71)
                            : const Color(0xFFe74c3c),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
