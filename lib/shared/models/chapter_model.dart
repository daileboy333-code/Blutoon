// lib/shared/models/chapter_model.dart

class ChapterModel {
  final int      id;
  final int      mangaId;
  final double   chapterNumber;
  final String?  title;
  final bool     isFree;
  final int      views;
  final DateTime publishedAt;

  const ChapterModel({
    required this.id,
    required this.mangaId,
    required this.chapterNumber,
    this.title,
    required this.isFree,
    required this.views,
    required this.publishedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id:            json['id']             as int,
      mangaId:       json['manga_id']       as int,
      chapterNumber: (json['chapter_number'] as num).toDouble(),
      title:         json['title']           as String?,
      isFree:        json['is_free']         as bool,
      views:         (json['views'] ?? 0)    as int,
      publishedAt:   DateTime.parse(json['published_at'] as String),
    );
  }

  // عرض رقم الفصل: 12.0 → "12"، 12.5 → "12.5"
  String get displayNumber =>
      chapterNumber == chapterNumber.truncateToDouble()
          ? chapterNumber.toInt().toString()
          : chapterNumber.toString();
}
