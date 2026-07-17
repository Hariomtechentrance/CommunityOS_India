plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.communityos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.communityos.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The firebase_messaging Flutter plugin keeps its own Firebase Messaging
    // dependency at `implementation` scope, so it isn't visible to our own
    // Kotlin code (CallFirebaseMessagingService extends the plugin's service
    // class, which needs FirebaseMessagingService/RemoteMessage directly).
    // Pinned to the exact version firebase_core's own (module-scoped, not
    // visible here) BoM already resolves elsewhere in the build - an
    // unpinned platform() here previously pulled in a *different* version
    // (25.1.0 vs the working 25.0.1), causing two conflicting copies of
    // firebase-messaging and silently breaking getToken().
    implementation("com.google.firebase:firebase-messaging:25.0.1")
}
