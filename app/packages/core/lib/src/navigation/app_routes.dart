/// Centralized route paths used across all features.
///
/// This avoids hardcoded strings in feature packages and ensures
/// consistency between app router definitions and feature navigation.
///
/// Usage: `context.router.pushPath(AppRoutes.login)`
abstract final class AppRoutes {
  static const home = '/home';
  static const homeDetail = '/home/:id';
  static String homeDetailPath(String id) => '/home/$id';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';

  // Deeplinks do quiz (Spec 02): quizapp://... e https://<dominio>/...
  static const quizTopic = '/quiz/:topic';
  static String quizTopicPath(String topic) => '/quiz/$topic';
  static const question = '/question/:id';
  static String questionPath(String id) => '/question/$id';
  static const daily = '/daily';
  static const review = '/review';
  static const stats = '/stats';
}
