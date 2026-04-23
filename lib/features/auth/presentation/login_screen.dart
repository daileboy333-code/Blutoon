import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/main.dart';
import 'package:blutoon/features/home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool   _loading  = false;
  bool   _obscure  = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      if (res.user != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on AuthException {
      setState(() => _error = 'البريد أو كلمة المرور غير صحيحة');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Center(child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2394FC), Color(0xFF0066D6)]),
                    ),
                    child: Center(child: Text('B', style: GoogleFonts.cairo(
                        fontSize: 32, fontWeight: FontWeight.w900,
                        color: Colors.white))),
                  ),
                  const SizedBox(height: 16),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: 'Blu', style: GoogleFonts.cairo(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: const Color(0xFF2394FC))),
                    TextSpan(text: 'toon', style: GoogleFonts.cairo(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: const Color(0xFF111111))),
                  ])),
                ])),
                const SizedBox(height: 40),
                Text('تسجيل الدخول', textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            color: const Color(0xFFCC0000), fontSize: 14)),
                  ),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.cairo(),
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    hintStyle: GoogleFonts.cairo(color: const Color(0xFF999999)),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF999999)),
                    filled: true, fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2394FC), width: 2)),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'بريد غير صالح' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.cairo(),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور',
                    hintStyle: GoogleFonts.cairo(color: const Color(0xFF999999)),
                    prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF999999)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF999999)),
                      onPressed: () => setState(() => _obscure = !_obscure)),
                    filled: true, fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2394FC), width: 2)),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'كلمة المرور قصيرة' : null,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loading ? null : _login,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2394FC), Color(0xFF0066D6)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF2394FC).withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 5))],
                    ),
                    child: Center(child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        : Text('دخول', style: GoogleFonts.cairo(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white))),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('ليس لديك حساب؟',
                      style: GoogleFonts.cairo(color: const Color(0xFF666666))),
                  TextButton(
                    onPressed: () {},
                    child: Text('إنشاء حساب', style: GoogleFonts.cairo(
                        color: const Color(0xFF2394FC),
                        fontWeight: FontWeight.w700))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
