import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_module/home_module.dart';
import 'package:injectable/injectable.dart';

part 'home_item_detail_cubit.freezed.dart';

@freezed
abstract class HomeItemDetailState with _$HomeItemDetailState {
  const factory HomeItemDetailState.initial() = HomeItemDetailInitial;
  const factory HomeItemDetailState.loading() = HomeItemDetailLoading;
  const factory HomeItemDetailState.loaded(HomeItem item) =
      HomeItemDetailLoaded;
  const factory HomeItemDetailState.failure(String message) =
      HomeItemDetailFailure;
}

@injectable
class HomeItemDetailCubit extends Cubit<HomeItemDetailState> {
  HomeItemDetailCubit(this._getHomeItemByIdUseCase)
    : super(const HomeItemDetailState.initial());

  final GetHomeItemByIdUseCase _getHomeItemByIdUseCase;

  Future<void> loadItem(String id) async {
    emit(const HomeItemDetailState.loading());

    final result = await _getHomeItemByIdUseCase(id);

    result.when(
      success: (item) => emit(HomeItemDetailState.loaded(item)),
      failure: (failure) => emit(HomeItemDetailState.failure(failure.message)),
    );
  }
}
