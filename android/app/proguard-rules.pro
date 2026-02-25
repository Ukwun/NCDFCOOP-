# Flutter default proguard rules

# Keep all Flutter native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Flutter-related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Android lifecycle components
-keep class androidx.lifecycle.** { *; }
-keep interface androidx.lifecycle.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep FlutterToast plugin
-keep class io.github.ponnamkarthik.toast.** { *; }
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }
-dontwarn io.github.ponnamkarthik.toast.**

# Keep Go Router plugin
-keep class com.google.flutter.embedding.engine.plugins.** { *; }
-keep interface com.google.flutter.embedding.engine.plugins.** { *; }

# Keep all annotation classes
-keepattributes *Annotation*
-keepattributes SourceFile
-keepattributes LineNumberTable

# Keep any custom application classes
-keep class * implements java.io.Serializable { *; }

# Generic Flutter plugin keep rules
-keep class ** implements io.flutter.embedding.engine.FlutterPlugin { *; }

# Keep all plugin classes registered in GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
