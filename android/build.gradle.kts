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

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                // Infer namespace from group or set a default
                val inferredNamespace = if (project.group.toString().isNotEmpty() && project.group.toString() != "unspecified") {
                    project.group.toString().replace("-", "_")
                } else {
                    "com.legacy.${project.name.replace("-", "_")}"
                }
                println("Setting namespace for ${project.name} to $inferredNamespace")
                namespace = inferredNamespace
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
