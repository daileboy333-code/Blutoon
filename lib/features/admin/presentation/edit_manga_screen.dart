import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/features/admin/presentation/admin_cubit.dart';
import 'package:blutoon/main.dart';

class EditMangaScreen extends StatefulWidget {
  final AdminManga manga;
  const EditMangaScreen({super.key, required this.manga});
  @override State<EditMangaScreen> createState() => _EditMangaScreenState();
}

class _EditMangaScreenState extends State<EditMangaScreen> {
  late final _titleArCtrl = TextEditingController(text: '');
  late final _titleEnCtrl = TextEditingController(text: '');
  late final _coverCtrl   = TextEditingController(text: '');
  late final _bannerCtrl  = TextEditingController(text: '');
  late final _descCtrl    = TextEditingController(text: '');
  String _type   = 'manga';
  String _status = 'ongoing';
  bool   _loading = true;

  @override
  void initState() { super.initState(); _loadFull(); }

  Future<void> _loadFull() async {
    final res = await supabase.from('manga').select().eq('id', widget.manga.id).single();
    setState(() {
      _titleArCtrl.text = res['title_ar'] ?? '';
      _titleEnCtrl.text = res['title_en'] ?? '';
      _coverCtrl.text   = res['cover_url'] ?? '';
      _bannerCtrl.text  = res['banner_url'] ?? '';
      _descCtrl.text    = res['description'] ?? '';
      _type             = res['type'] ?? 'manga';
      _status           = res['status'] ?? 'ongoing';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await supabase.from('manga').update({
        'title_ar':    _titleArCtrl.text.trim(),
        'title_en':    _titleEnCtrl.text.trim().isEmpty ? null : _titleEnCtrl.text.trim(),
        'cover_url':   _coverCtrl.text.trim(),
        'banner_url':  _bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'type':        _type,
        'status':      _status,
        'updated_at':  DateTime.now().toIso8601String(),
      }).eq('id', widget.manga.id);
      if (mounted) {
        context.read<AdminCubit>().loadDashboard();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.cairo(color: const Color(0xFF999999), fontSize: 13),
    filled: true, fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2394FC), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 16),
    child: Text(t, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('تعديل: ${widget.manga.titleAr}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFEEEEEE), height: 1)),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _save,
              child: Text('حفظ', style: GoogleFonts.cairo(
                  color: const Color(0xFF2394FC), fontWeight: FontWeight.w800, fontSize: 15)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2394FC), strokeWidth: 2.5))
          : ListView(padding: const EdgeInsets.all(20), children: [
              _lbl('العنوان بالعربي *'),
              TextFormField(controller: _titleArCtrl, style: GoogleFonts.cairo(fontSize: 14), decoration: _dec('العنوان العربي')),
              _lbl('العنوان بالإنجليزي'),
              TextFormField(controller: _titleEnCtrl, style: GoogleFonts.cairo(fontSize: 14), decoration: _dec('العنوان الإنجليزي')),
              _lbl('رابط الغلاف *'),
              TextFormField(controller: _coverCtrl, keyboardType: TextInputType.url, style: GoogleFonts.cairo(fontSize: 14), decoration: _dec('https://...')),
              _lbl('رابط البانر'),
              TextFormField(controller: _bannerCtrl, keyboardType: TextInputType.url, style: GoogleFonts.cairo(fontSize: 14), decoration: _dec('https://...')),
              _lbl('الوصف'),
              TextFormField(controller: _descCtrl, maxLines: 4, style: GoogleFonts.cairo(fontSize: 14), decoration: _dec('وصف القصة...')),
              _lbl('النوع'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['manga','manhwa','manhua','novel'].map((t) =>
                ChoiceChip(
                  label: Text({'manga':'مانجا','manhwa':'مانهوا','manhua':'مانهوا صيني','novel':'رواية'}[t]!,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: _type == t ? Colors.white : Colors.black)),
                  selected: _type == t, selectedColor: const Color(0xFF2394FC),
                  backgroundColor: const Color(0xFFF0F4FF),
                  onSelected: (_) => setState(() => _type = t),
                )
              ).toList()),
              _lbl('الحالة'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['ongoing','completed','hiatus','dropped'].map((s) =>
                ChoiceChip(
                  label: Text({'ongoing':'مستمر','completed':'مكتمل','hiatus':'متوقف','dropped':'متروك'}[s]!,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: _status == s ? Colors.white : Colors.black)),
                  selected: _status == s, selectedColor: const Color(0xFF2ecc71),
                  backgroundColor: const Color(0xFFF0FFF4),
                  onSelected: (_) => setState(() => _status = s),
                )
              ).toList()),
              const SizedBox(height: 32),
            ]),
    );
  }
}
