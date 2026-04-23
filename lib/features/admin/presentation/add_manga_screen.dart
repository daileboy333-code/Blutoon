import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blutoon/features/admin/presentation/admin_cubit.dart';

class AddMangaScreen extends StatefulWidget {
  const AddMangaScreen({super.key});

  @override
  State<AddMangaScreen> createState() => _AddMangaScreenState();
}

class _AddMangaScreenState extends State<AddMangaScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleArCtrl = TextEditingController();
  final _titleEnCtrl = TextEditingController();
  final _slugCtrl    = TextEditingController();
  final _coverCtrl   = TextEditingController();
  final _bannerCtrl  = TextEditingController();
  final _descCtrl    = TextEditingController();

  String _type   = 'manga';
  String _status = 'ongoing';
  bool   _loading = false;

  final _types = ['manga', 'manhwa', 'manhua', 'novel'];
  final _statuses = ['ongoing', 'completed', 'hiatus', 'dropped'];

  final _typeLabels   = {'manga': 'مانجا', 'manhwa': 'مانهوا', 'manhua': 'مانهوا صيني', 'novel': 'رواية'};
  final _statusLabels = {'ongoing': 'مستمر', 'completed': 'مكتمل', 'hiatus': 'متوقف', 'dropped': 'متروك'};

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _slugCtrl.dispose();
    _coverCtrl.dispose();
    _bannerCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await context.read<AdminCubit>().addManga(
      titleAr:     _titleArCtrl.text.trim(),
      titleEn:     _titleEnCtrl.text.trim().isEmpty ? null : _titleEnCtrl.text.trim(),
      slug:        _slugCtrl.text.trim(),
      coverUrl:    _coverCtrl.text.trim(),
      bannerUrl:   _bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      type:        _type,
      status:      _status,
    );

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('إضافة مانجا جديدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Field(
              ctrl:      _titleArCtrl,
              label:     'العنوان بالعربي *',
              hint:      'مثال: هجوم العمالقة',
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            _Field(
              ctrl:  _titleEnCtrl,
              label: 'العنوان بالإنجليزي',
              hint:  'مثال: Attack on Titan',
            ),
            _Field(
              ctrl:      _slugCtrl,
              label:     'الـ Slug *',
              hint:      'مثال: attack-on-titan',
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (v.contains(' ')) return 'لا يحتوي على مسافات';
                return null;
              },
            ),
            _Field(
              ctrl:      _coverCtrl,
              label:     'رابط صورة الغلاف *',
              hint:      'https://...',
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              keyboard:  TextInputType.url,
            ),
            _Field(
              ctrl:     _bannerCtrl,
              label:    'رابط صورة البانر',
              hint:     'https://... (اختياري)',
              keyboard: TextInputType.url,
            ),
            _Field(
              ctrl:    _descCtrl,
              label:   'القصة / الوصف',
              hint:    'اكتب ملخص القصة...',
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            // النوع
            Text('النوع', style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) => ChoiceChip(
                label: Text(_typeLabels[t]!,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: _type == t ? Colors.white : Colors.black,
                    )),
                selected:          _type == t,
                selectedColor:     const Color(0xFF2394FC),
                backgroundColor:   const Color(0xFFF0F4FF),
                onSelected: (_) => setState(() => _type = t),
              )).toList(),
            ),

            const SizedBox(height: 20),

            // الحالة
            Text('الحالة', style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _statuses.map((s) => ChoiceChip(
                label: Text(_statusLabels[s]!,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: _status == s ? Colors.white : Colors.black,
                    )),
                selected:        _status == s,
                selectedColor:   const Color(0xFF2ecc71),
                backgroundColor: const Color(0xFFF0FFF4),
                onSelected: (_) => setState(() => _status = s),
              )).toList(),
            ),

            const SizedBox(height: 32),

            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2394FC), Color(0xFF0066D6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:      const Color(0xFF2394FC).withOpacity(0.35),
                      blurRadius: 14,
                      offset:     const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)
                      : Text('إضافة المانجا',
                          style: GoogleFonts.cairo(
                            color:      Colors.white,
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                          )),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String               label;
  final String               hint;
  final int                  maxLines;
  final TextInputType?       keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   ctrl,
          maxLines:     maxLines,
          keyboardType: keyboard,
          validator:    validator,
          style:        GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: GoogleFonts.cairo(
                color: const Color(0xFF999999), fontSize: 13),
            filled:     true,
            fillColor:  const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF2394FC), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe74c3c)),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    ),
  );
}
