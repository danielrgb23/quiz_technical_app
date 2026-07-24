import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage(
  ignoreUnregisteredTypesInPackages: [
    'package:core',
    'package:shared',
    'package:quiz_module',
    'package:question_bank_module',
  ],
)
void initQuizFlowPackageModule(GetIt getIt) {}
