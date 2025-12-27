import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun resolveKeystoreValue(propertyName: String, envName: String): String? {
    return keystoreProperties.getProperty(propertyName) ?: System.getenv(envName)
}

val releaseStoreFile = resolveKeystoreValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = resolveKeystoreValue(
    "storePassword",
    "ANDROID_KEYSTORE_PASSWORD",
)
val releaseKeyAlias = resolveKeystoreValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = resolveKeystoreValue("keyPassword", "ANDROID_KEY_PASSWORD")

val hasReleaseSigning =
    !releaseStoreFile.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank()

val requiresReleaseSigning = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

if (requiresReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Release signing not configured. Provide android/key.properties or ANDROID_KEYSTORE_* env vars.",
    )
}

android {
    namespace = "com.dooapps.tisane"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dooapps.tisane"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
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
