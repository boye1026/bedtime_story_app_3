@echo off
chcp 65001 >nul
echo ========================================
echo 修复 Flutter/Gradle 版本冲突
echo 项目: bedtime_story_app
echo 用户: boye1026
echo ========================================
echo.

cd /d "D:\应用\app生成\项目\AI-睡前故事\bedtime_story_app"

echo [1/9] 确保在 main 分支...
git checkout main
git pull origin main

echo [2/9] 删除旧的 CI 配置文件...
if exist .github\workflows\flutter-ci.yml del .github\workflows\flutter-ci.yml
if exist .github\workflows\build-apk.yml del .github\workflows\build-apk.yml
if exist .github\workflows\direct-build.yml del .github\workflows\direct-build.yml

echo [3/9] 创建新的 CI 配置文件...
mkdir .github\workflows 2>nul

(
echo name: Build APK
echo.
echo on:
echo   push:
echo     branches: [ main ]
echo   workflow_dispatch:
echo.
echo jobs:
echo   build:
echo     runs-on: ubuntu-latest
echo.
echo     steps:
echo       - uses: actions/checkout@v4
echo.
echo       - name: Setup Java
echo         uses: actions/setup-java@v4
echo         with:
echo           distribution: 'temurin'
echo           java-version: '17'
echo.
echo       - name: Setup Flutter
echo         uses: subosito/flutter-action@v2
echo         with:
echo           flutter-version: '3.22.0'
echo           channel: 'stable'
echo.
echo       - name: Cache Gradle
echo         uses: actions/cache@v4
echo         with:
echo           path: ^|
echo             ~/.gradle/caches
echo             ~/.gradle/wrapper
echo           key: ${{ runner.os }}-gradle-${{ hashFiles('**/gradle-wrapper.properties') }}
echo           restore-keys: ${{ runner.os }}-gradle-
echo.
echo       - name: Configure Gradle
echo         working-directory: mobile
echo         run: ^|
echo           cat ^> android/gradle/wrapper/gradle-wrapper.properties ^<^< 'EOF'
echo           distributionBase=GRADLE_USER_HOME
echo           distributionPath=wrapper/dists
echo           distributionUrl=https\://services.gradle.org/distributions/gradle-8.3-bin.zip
echo           zipStoreBase=GRADLE_USER_HOME
echo           zipStorePath=wrapper/dists
echo           EOF
echo.
echo           cat ^> android/build.gradle ^<^< 'EOF'
echo           buildscript {
echo               ext.kotlin_version = '1.9.22'
echo               repositories {
echo                   google()
echo                   mavenCentral()
echo               }
echo               dependencies {
echo                   classpath 'com.android.tools.build:gradle:8.1.4'
echo                   classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
echo               }
echo           }
echo           allprojects {
echo               repositories {
echo                   google()
echo                   mavenCentral()
echo               }
echo           }
echo           rootProject.buildDir = '../build'
echo           subprojects {
echo               project.buildDir = "${rootProject.buildDir}/${project.name}"
echo           }
echo           subprojects {
echo               project.evaluationDependsOn(':app')
echo           }
echo           tasks.register('clean', Delete) {
echo               delete rootProject.buildDir
echo           }
echo           EOF
echo.
echo       - name: Install dependencies
echo         working-directory: mobile
echo         run: ^|
echo           flutter clean
echo           flutter pub get
echo.
echo       - name: Build APK
echo         working-directory: mobile
echo         run: flutter build apk --release
echo.
echo       - uses: actions/upload-artifact@v4
echo         with:
echo           name: bedtime-story-app
echo           path: mobile/build/app/outputs/flutter-apk/app-release.apk
) > .github\workflows\build-apk.yml

echo [4/9] 更新 pubspec.yaml...
cd mobile
(
echo name: bedtime_story_app
echo description: AI睡前故事应用
echo publish_to: 'none'
echo version: 1.0.0+1
echo.
echo environment:
echo   sdk: ">=3.2.0 ^<4.0.0"
echo   flutter: ">=3.16.0"
echo.
echo dependencies:
echo   flutter:
echo     sdk: flutter
echo   flutter_tts: 3.8.5
echo   google_fonts: 6.1.0
echo   shared_preferences: 2.2.2
echo   path_provider: 2.1.1
echo.
echo dev_dependencies:
echo   flutter_test:
echo     sdk: flutter
echo   flutter_lints: 3.0.0
echo.
echo flutter:
echo   uses-material-design: true
) > pubspec.yaml

echo [5/9] 更新 Gradle 配置...
cd android
(
echo buildscript {
echo     ext.kotlin_version = '1.9.22'
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo.
echo     dependencies {
echo         classpath 'com.android.tools.build:gradle:8.1.4'
echo         classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
echo     }
echo }
echo.
echo allprojects {
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo }
echo.
echo rootProject.buildDir = '../build'
echo subprojects {
echo     project.buildDir = "${rootProject.buildDir}/${project.name}"
echo }
echo subprojects {
echo     project.evaluationDependsOn(':app')
echo }
echo.
echo tasks.register('clean', Delete) {
echo     delete rootProject.buildDir
echo }
) > build.gradle

echo [6/9] 更新 Gradle Wrapper...
cd gradle\wrapper
(
echo distributionBase=GRADLE_USER_HOME
echo distributionPath=wrapper/dists
echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.3-bin.zip
echo zipStoreBase=GRADLE_USER_HOME
echo zipStorePath=wrapper/dists
) > gradle-wrapper.properties
cd ..\..

echo [7/9] 更新 app/build.gradle...
cd app
(
echo def localProperties = new Properties^(^)
echo def localPropertiesFile = rootProject.file('local.properties')
echo if ^(localPropertiesFile.exists()^) {
echo     localPropertiesFile.withReader('UTF-8') { reader -^>
echo         localProperties.load(reader^)
echo     }
echo }
echo.
echo def flutterRoot = localProperties.getProperty('flutter.sdk')
echo if ^(flutterRoot == null^) {
echo     throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
echo }
echo.
echo def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
echo if ^(flutterVersionCode == null^) {
echo     flutterVersionCode = '1'
echo }
echo.
echo def flutterVersionName = localProperties.getProperty('flutter.versionName')
echo if ^(flutterVersionName == null^) {
echo     flutterVersionName = '1.0'
echo }
echo.
echo apply plugin: 'com.android.application'
echo apply plugin: 'kotlin-android'
echo apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
echo.
echo android {
echo     namespace 'com.bedtimestory.app'
echo     compileSdk 34
echo.
echo     compileOptions {
echo         sourceCompatibility JavaVersion.VERSION_17
echo         targetCompatibility JavaVersion.VERSION_17
echo     }
echo.
echo     kotlinOptions {
echo         jvmTarget = '17'
echo     }
echo.
echo     defaultConfig {
echo         applicationId "com.bedtimestory.app"
echo         minSdk 21
echo         targetSdk 34
echo         versionCode flutterVersionCode.toInteger()
echo         versionName flutterVersionName
echo     }
echo.
echo     buildTypes {
echo         release {
echo             signingConfig signingConfigs.debug
echo         }
echo     }
echo }
echo.
echo flutter {
echo     source '../..'
echo }
echo.
echo dependencies {
echo     implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
echo }
echo.
echo // 修复 Groovy 版本冲突
echo configurations.all {
echo     resolutionStrategy {
echo         force 'org.codehaus.groovy:groovy:3.0.19'
echo         force 'org.codehaus.groovy:groovy-xml:3.0.19'
echo     }
echo }
) > build.gradle
cd ..\..\..

echo [8/9] 提交修改...
git add .
git commit -m "fix: 修复 Gradle/Groovy 版本冲突

- 统一 Flutter 版本为 3.22.0
- 升级 Gradle 到 8.3
- 升级 AGP 到 8.1.4
- 升级 Kotlin 到 1.9.22
- 添加 Groovy 版本强制锁定
- 删除重复的 CI 配置文件
- 锁定 pubspec.yaml 依赖版本"

echo [9/9] 推送到 GitHub...
git push origin main

echo.
echo ========================================
echo 完成！请访问以下链接查看 Actions 运行状态：
echo https://github.com/boye1026/bedtime_story_app/actions
echo ========================================
pause