plugins {
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
    // add this ONLY if you have google-services.json
    // id "com.google.gms.google-services"
}

android {
    namespace "com.aquafiresolutions.splitmate"
    compileSdk 35

    defaultConfig {
        applicationId "com.aquafiresolutions.splitmate"
        minSdk 23
        targetSdk 35
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    buildTypes {
        release {
            // for now no shrink to avoid R8 issues
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            minifyEnabled false
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
                targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += ["/META-INF/{AL2.0,LGPL2.1}"]
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.24"

    // Firebase (you said connect with Firebase)
    implementation platform("com.google.firebase:firebase-bom:33.4.0")
    implementation "com.google.firebase:firebase-analytics-ktx"
    implementation "com.google.firebase:firebase-auth-ktx"
    implementation "com.google.firebase:firebase-firestore-ktx"
    implementation "com.google.firebase:firebase-storage-ktx"

    implementation "androidx.multidex:multidex:2.0.1"
}
