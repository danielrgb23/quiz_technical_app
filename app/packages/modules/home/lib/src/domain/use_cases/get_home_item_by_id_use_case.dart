import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/home_item.dart';
import '../repositories/home_repository.dart';

@lazySingleton
class GetHomeItemByIdUseCase implements UseCase<String, HomeItem> {
  GetHomeItemByIdUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Result<HomeItem>> call(String params) =>
      _repository.getHomeItemById(params);
}
