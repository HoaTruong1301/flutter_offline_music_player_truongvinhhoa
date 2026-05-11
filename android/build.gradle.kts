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
    val subproject = this
    
    // 1. Cấu hình thư mục build
    val newSubprojectBuildDir: Directory = newBuildDir.dir(subproject.name)
    subproject.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        // 2. Sửa lỗi Namespace và ép về Java 17
        if (subproject.plugins.hasPlugin("com.android.library") || subproject.plugins.hasPlugin("com.android.application")) {
            val android = subproject.extensions.getByName("android")

            // Tự động gán Namespace nếu thiếu (cho các plugin cũ)
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    val ns = if (subproject.group.toString().isNotEmpty())
                        subproject.group.toString()
                    else
                        "com.example.${subproject.name.replace("-", "_")}"
                    setNamespace.invoke(android, ns)
                }
            } catch (e: Exception) {}

            // Ép Java 17 cho CompileOptions
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val javaVersion = org.gradle.api.JavaVersion.VERSION_17
                compileOptions.javaClass.getMethod("setSourceCompatibility", javaVersion.javaClass).invoke(compileOptions, javaVersion)
                compileOptions.javaClass.getMethod("setTargetCompatibility", javaVersion.javaClass).invoke(compileOptions, javaVersion)
            } catch (e: Exception) {}
        }

        // 3. Ép Kotlin về JVM 17 (Tương thích Kotlin 2.x và cũ hơn)
        subproject.tasks.matching { it.javaClass.name.contains("KotlinCompile") }.configureEach {
            try {
                // Thử compilerOptions (Kotlin 2.0+)
                val compilerOptions = this.javaClass.getMethod("getCompilerOptions").invoke(this)
                val jvmTargetProp = compilerOptions.javaClass.getMethod("getJvmTarget").invoke(compilerOptions)
                val jvmTargetClass = java.lang.Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                val jvm17 = jvmTargetClass.getField("JVM_17").get(null)
                jvmTargetProp.javaClass.getMethod("set", jvm17.javaClass).invoke(jvmTargetProp, jvm17)
            } catch (e: Exception) {
                // Fallback cho Kotlin cũ
                try {
                    val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
                    val kotlinOptions = getKotlinOptions.invoke(this)
                    kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")
                } catch (e2: Exception) {}
            }
        }
    }
}

subprojects {
    if (name != "app") {
        try {
            evaluationDependsOn(":app")
        } catch (e: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
