# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress Google Play Core deferred components warnings (not using Play Store dynamic features)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# SQLite native hooks
-keep class com.tekartik.sqflite.** { *; }

# PDF & Printing native interfaces
-keep class net.nfet.flutter.printing.** { *; }

# File Picker & Share Plus
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep generic attributes
-dontwarn javax.annotation.**
-keepattributes *Annotation*,EnclosingMethod,Signature
