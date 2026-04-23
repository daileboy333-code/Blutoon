import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:blutoon/shared/models/manga_model.dart';
import 'package:blutoon/main.dart';

abstract class HomeState extends Equatable {
  @override List<Object?> get props => [];
}
class HomeInitial extends HomeState {}
class HomeLoading  extends HomeState {}
class HomeError    extends HomeState {
  final String msg;
  HomeError(this.msg);
  @override List<Object?> get props => [msg];
}
class HomeLoaded extends HomeState {
  final List<MangaModel> featured;
  final List<MangaModel> latest;
  final List<MangaModel> popular;
  final String           activeTab;
  const HomeLoaded({
    required this.featured,
    required this.latest,
    required this.popular,
    this.activeTab = 'manga',
  });
  @override List<Object?> get props => [featured, latest, popular, activeTab];
  HomeLoaded copyWith({String? activeTab}) => HomeLoaded(
    featured: featured, latest: latest, popular: popular,
    activeTab: activeTab ?? this.activeTab,
  );
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadHome({String contentType = 'manga'}) async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        supabase.from('manga_with_latest_chapter').select()
            .eq('is_featured', true).eq('type', contentType).limit(5),
        supabase.from('manga_with_latest_chapter').select()
            .eq('type', contentType)
            .not('latest_chapter_num', 'is', null)
            .order('latest_chapter_date', ascending: false).limit(20),
        supabase.from('manga_with_latest_chapter').select()
            .eq('type', contentType)
            .order('views', ascending: false).limit(10),
      ]);
      emit(HomeLoaded(
        featured:  (results[0] as List).map((e) => MangaModel.fromJson(e)).toList(),
        latest:    (results[1] as List).map((e) => MangaModel.fromJson(e)).toList(),
        popular:   (results[2] as List).map((e) => MangaModel.fromJson(e)).toList(),
        activeTab: contentType,
      ));
    } catch (e) {
      emit(HomeError('$e'));
    }
  }

  void switchTab(String tab) => loadHome(contentType: tab);
}
