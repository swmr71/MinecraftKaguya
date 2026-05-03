plugins {
    java
}

group = "com.example"
version = "1.0.1"

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(21))
}

repositories {
    mavenCentral()
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:1.21.4-R0.1-SNAPSHOT")
}

tasks.processResources {
    filteringCharset = "UTF-8"
}

tasks.jar {
    archiveFileName.set("bgm-plugin-${version}.jar")
}
