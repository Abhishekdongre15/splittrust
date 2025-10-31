pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter artifacts
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    plugins {
        id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "splittrust"
include ":app"
