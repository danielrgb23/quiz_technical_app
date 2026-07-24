/// Remote configuration abstraction.
///
/// Implementations: Firebase Remote Config (stg/prod, in `shared`) and a
/// fixed-values fake for dev/tests. Consumers must never import Firebase
/// directly.
abstract class RemoteConfigService {
  /// Minimum app version allowed to run (semver string).
  Future<String> minAppVersion();

  /// Latest published question bank version.
  Future<int> latestBankVersion();

  /// Generic feature flag lookup.
  Future<bool> isFeatureEnabled(String key);
}

/// Fixed-values implementation used in dev and tests.
class FakeRemoteConfigService implements RemoteConfigService {
  const FakeRemoteConfigService({
    this.fakeMinAppVersion = '0.0.0',
    this.fakeLatestBankVersion = 1,
    this.enabledFlags = const {},
  });

  final String fakeMinAppVersion;
  final int fakeLatestBankVersion;
  final Set<String> enabledFlags;

  @override
  Future<String> minAppVersion() async => fakeMinAppVersion;

  @override
  Future<int> latestBankVersion() async => fakeLatestBankVersion;

  @override
  Future<bool> isFeatureEnabled(String key) async => enabledFlags.contains(key);
}
