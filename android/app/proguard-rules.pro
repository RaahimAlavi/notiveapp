# --- Fix Missing type parameter bug ---
-keepattributes Signature
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# --- Keep flutter_local_notifications internals ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
