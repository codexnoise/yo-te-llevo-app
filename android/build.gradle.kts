val mapboxToken = run {
    val envFile = file("../.env")
    var token = ""
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.startsWith("MAPBOX_SECRET_TOKEN=") && !trimmed.startsWith("#")) {
                token = trimmed.substringAfter("=").trim()
            }
        }
    }
    token.ifEmpty { System.getenv("MAPBOX_SECRET_TOKEN") ?: "" }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials.username = "mapbox"
            credentials.password = mapboxToken
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
