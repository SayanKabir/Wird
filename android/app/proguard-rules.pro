# Flutter Local Notifications Plugin - Keep all necessary classes
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Keep Gson type tokens (used by flutter_local_notifications)
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep serialization for notification data
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter embedding classes 
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Timezone plugin
-keep class com.baseflow.** { *; }

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }

# Keep R8 from removing notification action classes
-keep class androidx.core.app.NotificationCompat$* { *; }

# Google Play Core (used by Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
