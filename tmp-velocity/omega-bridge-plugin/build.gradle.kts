plugins {
    java
}

group = "com.dlog.bridge"
version = "0.1.0"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
    withSourcesJar()
}

repositories {
    mavenCentral()
    maven("https://repo.papermc.io/repository/maven-public/")
    maven("https://hub.spigotmc.org/nexus/content/repositories/snapshots/")
    maven("https://oss.sonatype.org/content/groups/public/")
}

dependencies {
    compileOnly("org.spigotmc:spigot-api:1.8.8-R0.1-SNAPSHOT")
}

tasks.withType<Jar> {
    archiveBaseName.set("OmegaBridge")
    from("src/main/resources")
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
}
