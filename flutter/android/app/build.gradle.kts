plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

fun signingValue(propertyKey: String, envKey: String): String? {
    val fromProperties = keystoreProperties[propertyKey] as String?
    if (!fromProperties.isNullOrBlank()) return fromProperties
    val fromEnv = System.getenv(envKey)
    if (!fromEnv.isNullOrBlank()) return fromEnv
    return null
}

val releaseStoreFile = signingValue("storeFile", "CAPE_NOOR_STORE_FILE")
val releaseStorePassword = signingValue("storePassword", "CAPE_NOOR_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "CAPE_NOOR_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "CAPE_NOOR_KEY_PASSWORD")

android {
    namespace = "com.salaah.cape_noor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.salaah.cape_noor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release key from android/key.properties or environment variables.
            if (!releaseStoreFile.isNullOrBlank()
                && !releaseStorePassword.isNullOrBlank()
                && !releaseKeyAlias.isNullOrBlank()
                && !releaseKeyPassword.isNullOrBlank()
            ) {
                signingConfig = signingConfigs.create("release") {
                    keyAlias = releaseKeyAlias
                    keyPassword = releaseKeyPassword
                    storeFile = file(releaseStoreFile)
                    storePassword = releaseStorePassword
                }
            } else {
                throw GradleException(
                    "Missing release signing config. Provide android/key.properties or env vars: " +
                        "CAPE_NOOR_STORE_FILE, CAPE_NOOR_STORE_PASSWORD, CAPE_NOOR_KEY_ALIAS, CAPE_NOOR_KEY_PASSWORD"
                )
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
