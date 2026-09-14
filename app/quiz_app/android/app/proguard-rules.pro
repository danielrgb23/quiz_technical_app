# Flutter's own engine/plugin embedding classes — most plugins ship
# consumer rules in their AARs, but keeping the embedding API itself
# avoids reflection-related breakage across Flutter versions.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase/Google Play Services use reflection on model classes for
# (de)serialization; keep field names so R8 doesn't rename them away.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# local_auth's BiometricPrompt callback classes.
-keep class androidx.biometric.** { *; }

# Flutter's engine references Play Core's "deferred components" API even
# though we don't use dynamic feature modules; the classes genuinely
# aren't on the classpath, and that's fine — tell R8 not to fail on it.
-dontwarn com.google.android.play.core.**
