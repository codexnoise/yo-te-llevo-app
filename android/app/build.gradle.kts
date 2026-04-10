plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Generate google-services.json from .env
// ---------------------------------------------------------------------------
fun readEnvFile(): Map<String, String> {
    val envFile = file("../../.env")
    val env = mutableMapOf<String, String>()
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val trimmed = line.trim()
            if (!trimmed.startsWith("#") && trimmed.contains("=")) {
                val key = trimmed.substringBefore("=").trim()
                val value = trimmed.substringAfter("=").trim()
                env[key] = value
            }
        }
    }
    return env
}

tasks.register("generateGoogleServicesJson") {
    description = "Generates google-services.json from .env variables"
    val envFile = file("../../.env")
    val outputFile = file("google-services.json")
    inputs.file(envFile)
    outputs.file(outputFile)

    doLast {
        val env = readEnvFile()
        val projectNumber = env["FIREBASE_MESSAGING_SENDER_ID"] ?: ""
        val projectId = env["FIREBASE_PROJECT_ID"] ?: ""
        val storageBucket = env["FIREBASE_STORAGE_BUCKET"] ?: ""
        val appId = env["FIREBASE_ANDROID_APP_ID"] ?: ""
        val apiKey = env["FIREBASE_ANDROID_API_KEY"] ?: ""

        val json = """
{
  "project_info": {
    "project_number": "$projectNumber",
    "project_id": "$projectId",
    "storage_bucket": "$storageBucket"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "$appId",
        "android_client_info": {
          "package_name": "com.yotellevo.app"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "$apiKey"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
""".trimIndent()
        outputFile.writeText(json)
        logger.lifecycle("Generated google-services.json from .env")
    }
}

afterEvaluate {
    tasks.matching {
        it.name != "generateGoogleServicesJson" && it.name.contains("GoogleServices")
    }.configureEach {
        dependsOn("generateGoogleServicesJson")
    }
}

android {
    namespace = "com.yotellevo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yotellevo.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
