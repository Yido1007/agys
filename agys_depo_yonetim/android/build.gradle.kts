// android/build.gradle.kts  (root-android)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Aggregate build folder one level up from android/
val aggBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(aggBuildDir)

subprojects {
    // Each module writes into ../../build/<moduleName>
    layout.buildDirectory.set(aggBuildDir.dir(project.name))

    // Ensure :app is configured before others when needed
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
