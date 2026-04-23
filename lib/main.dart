import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blutoon/features/auth/presentation/login_screen.dart';
import 'package:blutoon/features/home/presentation/home_screen.dart';

const _supabaseUrl     = 'https://tymzjemjgrrjdmtjypga.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bXpqZW1qZ3JyamRtdGp5cGdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NTUyNDksImV4cCI6MjA5MjIzMTI0OX0.-lfJBVMl7h4EytBz3onqdW06Qr3yxE2VLucBAGuJUf0';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const BlutoonApp());
}

class BlutoonApp extends StatelessWidget {
  const BlutoonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blutoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2394FC)),
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();
  @override State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  void initState() { super.initState(); _redirect(); }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final session = supabase.auth.currentSession;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => session != null ? const HomeScreen() : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: CircularProgressIndicator(
        color: Color(0xFF2394FC), strokeWidth: 2.5)),
  );
}
