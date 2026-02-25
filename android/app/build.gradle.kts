import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load signing configuration from key.properties
val keystorePropertiesFile = File(project.projectDir.parentFile, "key.properties")  
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.coop_commerce"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Official application ID for Coop Commerce on Google Play Store
        applicationId = "com.example.coop_commerce"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = keystoreProperties.getProperty("storeFile", "").trim()
            val keyAliasVal = keystoreProperties.getProperty("keyAlias", "").trim()
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword", "").trim()
            val storePasswordVal = keystoreProperties.getProperty("storePassword", "").trim()
            
            if (keystorePath.isNotEmpty() && keyAliasVal.isNotEmpty() && keyPasswordVal.isNotEmpty() && storePasswordVal.isNotEmpty()) {
                // storeFile path is relative to the android directory (one level up from app/)
                val androidDir = project.projectDir.parentFile
                val keystoreFileObj = File(androidDir, keystorePath)
                storeFile = keystoreFileObj
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storePassword = storePasswordVal
            } else {
                // Properties are missing, signing will fail - this is OK for debug builds
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}

flutter {
    source = "../.."
}
