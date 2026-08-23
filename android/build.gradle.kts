allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// home_widget 0.9.0 declares its Android dependencies with open-ended version ranges
// ("1.+", "2.+"), so they drift onto whatever androidx publishes next -- including
// prereleases, which breaks the build with no change on our side:
//
//   androidx.glance:glance-appwidget:1.+ -> 1.3.0-alpha02, which requires compileSdk 37
//     and AGP 9.1 and fails :app:checkReleaseAarMetadata (we build against 35 / AGP 8.7).
//   androidx.work:work-runtime-ktx:2.+  -> 2.12.0-beta01, which is compiled to Java 11
//     bytecode and cannot be inlined into home_widget's own JVM 1.8 compilation.
//
// Pin both to the newest stable release. 2.11.2 is still Java 8 bytecode, so the plugin
// keeps compiling at the JVM target its author intended. home_widget is the only
// consumer of either library in this project, so nothing else is affected.
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.work:work-runtime-ktx:2.11.2")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
