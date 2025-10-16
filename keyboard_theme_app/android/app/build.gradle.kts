import groovy.json.JsonSlurper

fun loadFlavorConfig(flavor: String? = null): Map<String, *> {
    val path = if (flavor != null) {
        "src/$flavor/res/raw/config.json"
    } else {
        "src/main/res/raw/config.json"
    }
    val configFile = file(path)
    require(configFile.exists()) {
        "Missing config file for ${flavor ?: "main"} flavor at $path"
    }
    @Suppress("UNCHECKED_CAST")
    return JsonSlurper().parse(configFile) as Map<String, *>
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val baseConfig = loadFlavorConfig()
    namespace = baseConfig["packageName"].toString()
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
        val admob = baseConfig["admob"] as Map<*, *>
        applicationId = baseConfig["packageName"].toString()
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", baseConfig["appName"].toString())
        manifestPlaceholders["admobAppId"] = admob["appId"].toString()
    }

    flavorDimensions += "brand"

    productFlavors {
        create("kpopdemon") {
            dimension = "brand"
            val config = loadFlavorConfig(name)
            val admob = config["admob"] as Map<*, *>
            applicationId = config["packageName"].toString()
            resValue("string", "app_name", config["appName"].toString())
            manifestPlaceholders["admobAppId"] = admob["appId"].toString()
        }
        create("blackpink") {
            dimension = "brand"
            val config = loadFlavorConfig(name)
            val admob = config["admob"] as Map<*, *>
            applicationId = config["packageName"].toString()
            resValue("string", "app_name", config["appName"].toString())
            manifestPlaceholders["admobAppId"] = admob["appId"].toString()
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
