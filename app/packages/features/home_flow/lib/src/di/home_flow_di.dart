import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage(
  ignoreUnregisteredTypesInPackages: [
    'package:core',
    'package:shared',
    'package:question_bank_module',
    'package:quiz_module',
  ],
)
void initHomeFlowPackageModule(GetIt getIt) {}
