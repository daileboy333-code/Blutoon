import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/main.dart';
import 'package:blutoon/features/auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      final res = await supabase.from('users').select().eq('id', userId).single();
      setState(() { _profile = res; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2394FC), strokeWidth: 2.5))
          : user == null
            ? _notLoggedIn(context)
            : _loggedIn(context, user.email ?? ''),
      ),
    );
  }

  Widget _notLoggedIn(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('👤', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      Text('لم تسجل دخولك', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2394FC), Color(0xFF0066D6)]), borderRadius: BorderRadius.circular(14)),
          child: Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    ]),
  );

  Widget _loggedIn(BuildContext context, String email) {
    final role = _profile?['role'] ?? 'member';
    final username = _profile?['username'] ?? email.split('@')[0];
    final roleLabel = {'admin': '👑 مدير', 'moderator': '🛡️ مشرف', 'translator': '✍️ مترجم', 'member': '👤 عضو'}[role] ?? '👤 عضو';
    final roleColor = {'admin': const Color(0xFFe74c3c), 'moderator': const Color(0xFFa78bfa), 'translator': const Color(0xFF2394FC), 'member': const Color(0xFF999999)}[role] ?? const Color(0xFF999999);

    return ListView(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2394FC), Color(0xFF0066D6)]),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(child: Text(username.substring(0,1).toUpperCase(), style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            const SizedBox(height: 14),
            Text(username, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(email, style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF999999))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
              child: Text(roleLabel, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: roleColor)),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // الإعدادات
        _Section(title: 'الحساب', items: [
          _Item(icon: Icons.person_outline_rounded, label: 'تعديل الملف الشخصي', onTap: () {}),
          _Item(icon: Icons.lock_outline_rounded, label: 'تغيير كلمة المرور', onTap: () {}),
          _Item(icon: Icons.notifications_none_rounded, label: 'الإشعارات', onTap: () {}),
        ]),

        const SizedBox(height: 12),

        _Section(title: 'التطبيق', items: [
          _Item(icon: Icons.info_outline_rounded, label: 'عن Blutoon', onTap: () {}),
          _Item(icon: Icons.shield_outlined, label: 'سياسة الخصوصية', onTap: () {}),
        ]),

        const SizedBox(height: 12),

        // تسجيل الخروج
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFe74c3c).withOpacity(0.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout_rounded, color: Color(0xFFe74c3c), size: 20),
                const SizedBox(width: 8),
                Text('تسجيل الخروج', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFe74c3c))),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Section({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF999999))),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(children: items.asMap().entries.map((e) => Column(children: [
          e.value,
          if (e.key < items.length - 1) const Divider(height: 1, indent: 52),
        ])).toList()),
      ),
    ]),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF555555)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_left_rounded, color: Color(0xFFCCCCCC), size: 20),
      ]),
    ),
  );
}
