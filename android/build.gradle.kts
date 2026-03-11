allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
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

// 为缺少 namespace 的旧版插件自动注入 namespace（AGP 8+ 必需）
subprojects {
    plugins.withId("com.android.library") {
        val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.compileSdkVersion?.toIntOrNull()?.let { it < 35 } != false) {
            android.compileSdk = 35
        }
        if (android.namespace.isNullOrEmpty()) {
            android.namespace = project.group.toString().ifEmpty {
                "com.jpush.flutter"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
