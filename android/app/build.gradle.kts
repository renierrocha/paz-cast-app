plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.paz_castanhal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "paz_cast.app.v26"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // COLOCANDO OS DADOS DIRETAMENTE PARA ELIMINAR ERROS DE LEITURA
            keyAlias = "upload"
            keyPassword = "grego123"
            storePassword = "grego123"
            
            // O arquivo deve estar na pasta 'android/app/'
            storeFile = file("upload-keystore.jks")
        }
    }

    buildTypes {
        getByName("release") {
            // Vincula a assinatura configurada acima
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}