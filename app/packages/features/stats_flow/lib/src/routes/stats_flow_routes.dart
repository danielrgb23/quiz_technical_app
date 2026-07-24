import 'package:auto_route/auto_route.dart';

import '../presentation/pages/stats_page.dart';

part 'stats_flow_routes.gr.dart';

@AutoRouterConfig()
class StatsFlowRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: StatsRoute.page)];
}
