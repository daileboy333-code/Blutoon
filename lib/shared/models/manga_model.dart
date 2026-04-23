class MangaModel {
  final int      id;
  final String   titleAr;
  final String?  titleEn;
  final String   slug;
  final String   coverUrl;
  final String?  bannerUrl;
  final String?  description;
  final String   type;
  final String   status;
  final double   rating;
  final int      views;
  final bool     isFeatured;
  final int?     latestChapterNum;
  final DateTime? latestChapterDate;

  const MangaModel({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.slug,
    required this.coverUrl,
    this.bannerUrl,
    this.description,
    required this.type,
    required this.status,
    required this.rating,
    required this.views,
    required this.isFeatured,
    this.latestChapterNum,
    this.latestChapterDate,
  });

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    return MangaModel(
      id:          json['id'] as int,
      titleAr:     json['title_ar'] as String,
      titleEn:     json['title_en'] as String?,
      slug:        json['slug'] as String,
      coverUrl:    json['cover_url'] as String,
      bannerUrl:   json['banner_url'] as String?,
      description: json['description'] as String?,
      type:        json['type'] as String,
      status:      json['status'] as String,
      rating:      (json['rating'] ?? 0).toDouble(),
      views:       (json['views'] ?? 0) as int,
      isFeatured:  json['is_featured'] as bool,
      latestChapterNum: json['latest_chapter_num'] != null
          ? (json['latest_chapter_num'] as num).toInt()
          : null,
      latestChapterDate: json['latest_chapter_date'] != null
          ? DateTime.parse(json['latest_chapter_date'])
          : null,
    );
  }
}
