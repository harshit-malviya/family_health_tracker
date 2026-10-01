import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val rawStoreFilePath = keystoreProperties["storeFile"] as String?
val resolvedStoreFile = if (rawStoreFilePath != null) {
    val f = file(rawStoreFilePath)
    if (f.exists()) f else rootProject.file(rawStoreFilePath)
} else null

fun validateReleaseSigning() {
    val errors = mutableListOf<String>()
    if (!keystorePropertiesFile.exists()) {
        errors.add("Missing configuration file: '${keystorePropertiesFile.absolutePath}'.")
    } else {
        val requiredKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        for (key in requiredKeys) {
            val value = keystoreProperties.getProperty(key)?.trim()
            if (value.isNullOrEmpty() || value.startsWith("YOUR_")) {
                errors.add("Property '$key' is missing or set to a template placeholder in '${keystorePropertiesFile.name}'.")
            }
        }
        val storePath = keystoreProperties.getProperty("storeFile")?.trim()
        if (!storePath.isNullOrEmpty() && !storePath.startsWith("YOUR_")) {
            val appFile = file(storePath)
            val rootFile = rootProject.file(storePath)
            if (!appFile.exists() && !rootFile.exists()) {
                errors.add("Keystore file '$storePath' referenced in '${keystorePropertiesFile.name}' does not exist on disk.")
            }
        }
    }

    if (errors.isNotEmpty()) {
        val errorDetails = errors.joinToString("\n") { "  * $it" }
        throw GradleException(
            """
            |
            |==================================================================================
            |RELEASE BUILD FAILED: Missing or Invalid Release Keystore Configuration [CRIT-11]
            |==================================================================================
            |$errorDetails
            |
            |To resolve this:
            |  1. Copy 'android/key.properties.example' to 'android/key.properties'.
            |  2. Set your valid keystore passwords, key alias, and keystore file path.
            |  3. Ensure the referenced keystore file exists on disk.
            |==================================================================================
            """.trimMargin()
        )
    }
}

gradle.taskGraph.whenReady {
    val isReleaseSigningRequested = allTasks.any { task ->
        val name = task.name
        name.contains("Release", ignoreCase = false) && (
            name.startsWith("assemble") ||
            name.startsWith("bundle") ||
            name.startsWith("package") ||
            name.startsWith("validateSigning")
        )
    }
    if (isReleaseSigningRequested) {
        validateReleaseSigning()
    }
}

android {
    namespace = "com.toofanalpha.health_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.toofanalpha.health_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = resolvedStoreFile
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
