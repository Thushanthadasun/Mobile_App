plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
=======
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> 43376c16547ad2f3c7b6cbde5b95fad1c8c053d7
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.example.vehicle_maintenance"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // Matches plugin requirements (image_picker, permission_handler)
=======
    namespace = "com.example.untitled5"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
>>>>>>> 43376c16547ad2f3c7b6cbde5b95fad1c8c053d7

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.example.vehicle_maintenance"
        minSdk = 21 // Compatible with plugins
        targetSdk = 35
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.untitled5"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
>>>>>>> 43376c16547ad2f3c7b6cbde5b95fad1c8c053d7
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
<<<<<<< HEAD
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
=======
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
>>>>>>> 43376c16547ad2f3c7b6cbde5b95fad1c8c053d7
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
<<<<<<< HEAD
}
=======
}
>>>>>>> 43376c16547ad2f3c7b6cbde5b95fad1c8c053d7
