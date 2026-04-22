import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_cubit.dart';

class UploadChapterScreen extends StatefulWidget {
  final List<AdminManga> mangas;
  final int?             preselectedId;

  const UploadChapterScreen({
    super.key,
    required this.mangas,
    this.preselectedId,
  });

  @override
  State<UploadChapterScreen> createState() => _UploadChapterScreenState();
}

class _UploadChapterScreenState extends State<UploadChapterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _chNumCtrl    = TextEditingController();
  final _titleCtrl    = TextEditingController();
  final _urlsCtrl     = TextEditingController();

  int?  _selectedMangaId;
  bool  _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedMangaId = widget.preselectedId ?? 
        (widget.mangas.isNotEmpty ? widget.mangas.first.id : null);
  }

  @override
  void dispose() {
    _chNumCtrl.dispose();
    _titleCtrl.dispose();
    _urlsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMangaId == null) return;

    setState(() => _loading = true);

    // تقسيم الروابط — كل رابط في سطر
    final urls = _urlsCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.startsWith('http'))
        .toList();

    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أضف رابط صورة واحد على الأقل',
              style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: const Color(0xFFe74c3c),
        ),
      );
      setState(() => _loading = false);
      return;
    }

    await context.read<AdminCubit>().addChapter(
      mangaId:       _selectedMangaId!,
      chapterNumber: double.parse(_chNumCtrl.text.trim()),
      title:         _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim(),
      pageUrls:      urls,
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
        title: Text('رفع فصل جديد',
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
            // اختيار المانجا
            Text('المانجا *', style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:        const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value:     _selectedMangaId,
                  isExpanded: true,
                  style:     GoogleFonts.cairo(
                      color: Colors.black, fontSize: 14),
                  items: widget.mangas.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.titleAr,
                        style: GoogleFonts.cairo(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedMangaId = v),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // رقم الفصل
            Text('رقم الفصل *', style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller:   _chNumCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              style:        GoogleFonts.cairo(fontSize: 14),
              decoration:   _inputDec('مثال: 1 أو 12.5'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null) return 'رقم غير صالح';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // عنوان الفصل
            Text('عنوان الفصل', style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              style:      GoogleFonts.cairo(fontSize: 14),
              decoration: _inputDec('مثال: ليلة الهجوم (اختياري)'),
            ),

            const SizedBox(height: 16),

            // روابط الصور
            Row(
              children: [
                Text('روابط الصور *', style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text('كل رابط في سطر منفصل',
                    style: GoogleFonts.cairo(
                      fontSize:   11,
                      color:      const Color(0xFF999999),
                    )),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _urlsCtrl,
              maxLines:   10,
              style:      GoogleFonts.cairo(fontSize: 13),
              decoration: _inputDec(
                'https://example.com/page1.jpg\nhttps://example.com/page2.jpg\n...',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'أضف روابط الصور' : null,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2394FC).withOpacity(0.2)),
              ),
              child: Text(
                '💡 ضع رابط كل صورة في سطر منفصل.\nالروابط يجب أن تبدأ بـ https://\nالترتيب مهم — الصورة الأولى ستكون الصفحة الأولى.',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color:    const Color(0xFF2394FC),
                  height:   1.6,
                ),
              ),
            ),

            const SizedBox(height: 32),

            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:      const Color(0xFF2ecc71).withOpacity(0.35),
                      blurRadius: 14,
                      offset:     const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)
                      : Text('رفع الفصل',
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

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText:  hint,
    hintStyle: GoogleFonts.cairo(
        color: const Color(0xFF999999), fontSize: 12),
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
  );
}
