buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 🔥 Plugin de Google Services (necesario para Firebase)
        classpath("com.google.gms:google-services:4.4.3")

        // ✅ Asegúrate de incluir el plugin de Gradle para Android
        classpath("com.android.tools.build:gradle:8.5.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
    // ⚙️ Plugin de servicios de Google para Firebase
    id("com.google.gms.google-services") version "4.4.3" apply false
}
