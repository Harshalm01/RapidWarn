// File: android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.7.3")
        
        // Google Services (Firebase, Maps, etc.)
        classpath("com.google.gms:google-services:4.3.15")
        
        // Kotlin Gradle Plugin
        classpath(kotlin("gradle-plugin", version = "2.1.0"))
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Change the build directory to match Flutter's structure
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
