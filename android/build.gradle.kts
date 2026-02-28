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
    
    // Fix untuk package lawas (tipe AGP 8.0+) yang tidak memiliki namespace
    pluginManager.withPlugin("com.android.library") {
        val extension = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        if (extension.namespace == null) {
            val packageId = project.group.toString().takeIf { it.isNotEmpty() } ?: "com.example.${project.name}"
            extension.namespace = packageId
        }
    }
    
    pluginManager.withPlugin("com.android.application") {
        val extension = extensions.getByName("android") as com.android.build.gradle.internal.dsl.BaseAppModuleExtension
        if (extension.namespace == null) {
            val packageId = project.group.toString().takeIf { it.isNotEmpty() } ?: "com.example.${project.name}"
            extension.namespace = packageId
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
