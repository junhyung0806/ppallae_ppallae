plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ppallae_ppallae"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO(release-blocker): applicationId 미정 — Play Console 업로드 후에는 변경 불가.
        //   현재 값 "com.example.*" 는 Play 정책상 거부될 수 있는 placeholder.
        //   namespace (위 line 9) 도 같은 값으로 함께 변경할 것.
        //   변경 시 android/app/src/main/kotlin 하위 패키지 디렉토리/Kotlin 파일의
        //   package 선언, AndroidManifest.xml 의 component 참조도 함께 옮겨야 함.
        applicationId = "com.example.ppallae_ppallae"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO(release-blocker): release 빌드를 debug 키로 서명 중 → Play 업로드 거부됨.
            //   1) `keytool -genkey -v -keystore ~/ppallae-release.jks ...` 로 keystore 생성
            //   2) android/key.properties 만들고 (gitignore 처리) storeFile/storePassword/keyAlias/keyPassword 기입
            //   3) 본 블록을 release signingConfig 로 교체. 예:
            //      val keystoreProperties = Properties().apply { load(rootProject.file("key.properties").inputStream()) }
            //      signingConfigs.create("release") { storeFile = file(keystoreProperties["storeFile"]); ... }
            //      buildTypes.release.signingConfig = signingConfigs.getByName("release")
            //   4) Play Console 의 Play App Signing 도 함께 설정.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
