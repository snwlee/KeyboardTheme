plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "keyboard.keyboardtheme.free.theme.custom.personalkeyboard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "keyboard.keyboardtheme.free.theme.custom.personalkeyboard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Keyboard Theme")
        manifestPlaceholders["admobAppId"] = "ca-app-pub-xxxxxxxxxxxxxxxx~default"
    }

    flavorDimensions += "brand"

    productFlavors {
        create("kpopdemon") {
            dimension = "brand"
            applicationId = "keyboard.keyboardtheme.free.theme.custom.personalkeyboard.kpopdemon"
            resValue("string", "app_name", "KPOP Demon Keyboard")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-xxxxxxxxxxxxxxxx~kpopdemon"
        }
        create("blackpink") {
            dimension = "brand"
            applicationId = "keyboard.keyboardtheme.free.theme.custom.personalkeyboard.blackpink"
            resValue("string", "app_name", "BLACKPINK Keyboard")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-xxxxxxxxxxxxxxxx~blackpink"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
