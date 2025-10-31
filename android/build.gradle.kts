buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id "com.android.application" version "8.4.2" apply false
    id "com.android.library" version "8.4.2" apply false
    id "org.jetbrains.kotlin.android" version "1.9.24" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

// ---- optional: your shared build dir logic (converted to Groovy) ----
gradle.afterProject { proj ->
    if (proj == rootProject) {
        def newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get().asFile
        rootProject.layout.buildDirectory.set(newBuildDir)
    } else {
        def rootBuildDir = rootProject.layout.buildDirectory.get().asFile
        def subDir = new File(rootBuildDir, proj.name)
        proj.layout.buildDirectory.set(subDir)
    }
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}
