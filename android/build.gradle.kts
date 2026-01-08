// Configuration Android pour les permissions BLE
// Ce fichier est minimal car on utilise directement les classes Android via jnigen

plugins {
    id("com.android.library")
}

android {
    namespace = "com.example.my_package_ffi"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }
}
