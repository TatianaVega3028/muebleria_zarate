plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de los anteriores
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 Plugin necesario para enlazar Firebase (usa tu google-services.json)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.muebleria_zarate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // 🆔 ID del paquete (debe coincidir con google-services.json)
        applicationId = "com.example.muebleria_zarate"

        // ⚙️ Firebase requiere al menos minSdk 21
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 📦 Importa la plataforma BoM de Firebase (para manejar versiones en conjunto)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // 🔥 Dependencias de Firebase que estás usando
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
