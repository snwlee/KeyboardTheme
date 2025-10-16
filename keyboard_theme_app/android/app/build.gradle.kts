import java.util.Properties

plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader(Charsets.UTF_8))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// Function to load keystore properties for a specific flavor
fun loadKeystoreProperties(flavorName: String): Properties {
    val properties = Properties()
    val propertiesFile = rootProject.file("key_${flavorName}.properties")
    if (propertiesFile.exists()) {
        properties.load(propertiesFile.reader(Charsets.UTF_8))
        println("Loaded keystore properties for flavor: $flavorName")
    } else {
        println("WARNING: key_${flavorName}.properties not found, trying default key.properties")
        val defaultFile = rootProject.file("key.properties")
        if (defaultFile.exists()) {
            properties.load(defaultFile.reader(Charsets.UTF_8))
        }
    }
    return properties
}

android {
    namespace = "com.example.wallpaper_engine"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.snwlee.wallpaperengine" // Base package name
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
        // 64-bit ABI only to avoid driver crashes on Huawei Mali devices
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    signingConfigs {
        // Signing configs will be created dynamically for REQUESTED flavors only
        // This improves build performance by only processing what's needed

        // Detect which flavors are being built from the task names
        val requestedFlavors = project.gradle.startParameter.taskNames
            .filter { it.contains("assemble", ignoreCase = true) ||
                     it.contains("bundle", ignoreCase = true) ||
                     it.contains("install", ignoreCase = true) }
            .mapNotNull { task ->
                when {
                    task.contains("Kedehun", ignoreCase = true) -> "kedehun"
                    task.contains("AespaWinter", ignoreCase = true) -> "aespa_winter"
                    task.contains("AespaKarina", ignoreCase = true) -> "aespa_karina"
                    task.contains("SoloLeveling", ignoreCase = true) -> "soloLeveling"
                    task.contains("Blackpink", ignoreCase = true) -> "blackpink"
                    else -> null
                }
            }
            .distinct()

        // If no specific flavor detected (e.g., gradle sync), use kedehun as default
        val flavorsToProcess = requestedFlavors.ifEmpty { listOf("kedehun") }

        println("Processing signing configs for flavors: $flavorsToProcess")

        flavorsToProcess.forEach { flavorName ->
            val propertiesFile = rootProject.file("key_${flavorName}.properties")
            if (propertiesFile.exists()) {
                // Convert flavor name to camelCase for signing config name
                // kedehun -> kedehunRelease, aespa_winter -> aespaWinterRelease
                val configName = flavorName.split("_")
                    .mapIndexed { index, part ->
                        if (index == 0) part else part.capitalize()
                    }
                    .joinToString("") + "Release"
                create(configName) {
                    val props = loadKeystoreProperties(flavorName)
                    keyAlias = props["keyAlias"] as? String
                    keyPassword = props["keyPassword"] as? String
                    storeFile = props["storeFile"]?.let { file(it.toString()) }
                    storePassword = props["storePassword"] as? String
                }
                println("Created signing config: $configName")
            } else {
                println("Skipping signing config for $flavorName (key file not found)")
            }
        }
    }

    buildTypes {
        debug {
            // Debug build type
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // Release build type
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        // IMPORTANT: Package names and AdMob IDs are also defined in lib/config/app_config.dart
        // Make sure to keep them in sync when making changes!

        create("kedehun") {
            dimension = "app"
            applicationIdSuffix = ".kedehun" // Must match AppConfig.packageName
            resValue("string", "app_name", "K-POP DEMON HUNTER WALLPAPER")
            // AdMob App ID will be set in AndroidManifest
            manifestPlaceholders["admobAppId"] = "ca-app-pub-6294755768841981~3929039390"
            // Set signing config for this flavor if it exists
            signingConfigs.findByName("kedehunRelease")?.let {
                signingConfig = it
            }
        }
        create("aespaWinter") {
            dimension = "app"
            applicationId = "com.snwlee.winterwallpapers" // Must match AppConfig.packageName
            resValue("string", "app_name", "윈터 배경화면 - Winter Wallpapers")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-6294755768841981~5408317572"
            // Set signing config for this flavor if it exists
            signingConfigs.findByName("aespaWinterRelease")?.let {
                signingConfig = it
            }
        }
        create("aespaKarina") {
            dimension = "app"
            applicationId = "com.snwlee.karinawallpapers" // Must match AppConfig.packageName
            resValue("string", "app_name", "카리나 배경화면 - Karina Wallpapers")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-6294755768841981~2800860754"
            // Set signing config for this flavor if it exists
            signingConfigs.findByName("aespaKarinaRelease")?.let {
                signingConfig = it
            }
        }
        create("soloLeveling") {
            dimension = "app"
            applicationId = "com.snwlee.sololevelingwallpapers"
            resValue("string", "app_name", "Solo Leveling Wallpapers")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-6294755768841981~6994260785"
            signingConfigs.findByName("soloLevelingRelease")?.let {
                signingConfig = it
            }
        }
        create("blackpink") {
            dimension = "app"
            applicationId = "com.snwlee.blackpinkwallpapers"
            resValue("string", "app_name", "BLACKPINK Wallpapers")
            manifestPlaceholders["admobAppId"] = "ca-app-pub-6294755768841981~3591870693"
            signingConfigs.findByName("blackpinkRelease")?.let {
                signingConfig = it
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(kotlin("stdlib-jdk7"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.5.2")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-ads:23.0.0")
}
