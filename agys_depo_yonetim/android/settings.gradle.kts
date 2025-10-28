pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val p = properties.getProperty("flutter.sdk")
        require(p != null) { "flutter.sdk not set in local.properties" }
        p
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("com.android.library")    version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}


include(":app")
