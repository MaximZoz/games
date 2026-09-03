plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.zozugames.app"
    // in_app_update 4.2.5 компилируется против SDK 36.
    compileSdk = 36
    // Плагины (audioplayers, notifications, google_sign_in, …) требуют NDK 27.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications требует desugaring (java.time и т.п.).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // applicationId задаётся в productFlavors (prod / dev).
        minSdk = flutter.minSdkVersion
        // Play с 31.08.2026 принимает только targetSdk >= 36 (Android 16).
        // Flutter 3.27.4 даёт flutter.targetSdkVersion = 35 — из-за этого
        // r0adkll/upload-google-play падает: "Target SDK of artifact is too low".
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("prod") {
            dimension = "env"
            applicationId = "com.zozugames.app"
            resValue("string", "app_name", "Zozu Games")
        }
        create("dev") {
            dimension = "env"
            applicationId = "com.zozugames.app.dev"
            resValue("string", "app_name", "Zozu Games DEV")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Для Play Internal/Production нужен release keystore (android/key.properties).
            // Пока файла нет — debug signing, чтобы локальный --release не падал.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

val googleServicesFiles = listOf(
    file("google-services.json"),
    file("src/prod/google-services.json"),
    file("src/dev/google-services.json"),
)
if (googleServicesFiles.any { it.exists() }) {
    apply(plugin = "com.google.gms.google-services")
}
