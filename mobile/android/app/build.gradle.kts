plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// ============ 加载签名配置 ============
// 从 key.properties 读取签名密钥信息
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("key.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

android {
    namespace = "com.example.bedtime_story_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.bedtime_story_app"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    // ============ 签名配置 ============
    signingConfigs {
        create("release") {
            keyAlias = localProperties.getProperty("keyAlias") ?: "androidkey"
            keyPassword = localProperties.getProperty("keyPassword") ?: ""
            storeFile = localProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = localProperties.getProperty("storePassword") ?: ""
        }
    }

    buildTypes {
        release {
            // 使用 release 签名配置
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // 代码混淆和优化
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
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
