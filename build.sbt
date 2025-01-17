name := "spark-iceberg-delta-unitycatalog"
version := "1.0"
scalaVersion := "2.12.19"  // Use a Scala version compatible with Spark
javacOptions ++= Seq("-source", "17", "-target", "17")  // Java 17 compatibility

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "3.5.3" % Provided,
  "org.apache.spark" %% "spark-sql" % "3.5.3" % Provided,
  "io.delta" %% "delta-spark" % "3.2.1",
  "org.apache.spark" %% "spark-hadoop-cloud" % "3.5.3",
  "io.unitycatalog" %% "unitycatalog-spark" % "0.2.1",
  "org.apache.iceberg" %% "iceberg-spark-runtime-3.5" % "1.7.1",
  "org.apache.iceberg" % "iceberg-aws" % "1.7.1" % "runtime",
  "org.apache.iceberg" % "iceberg-aws-bundle" % "1.7.1",
  "org.postgresql" % "postgresql" % "42.7.5"

).map(
  _.exclude("org.slf4j", "slf4j-api") // Exclude SLF4J API
  .exclude("org.slf4j", "slf4j-log4j12") // Exclude SLF4J Log4j binding
  .exclude("org.apache.logging.log4j", "log4j-to-slf4j") // Exclude Log4j to SLF4J adapter
  .exclude("org.apache.logging.log4j", "log4j-slf4j-impl") // Exclude Log4j SLF4J implementation
  .exclude("ch.qos.logback", "logback-classic") // Exclude Logback
)

assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}

// Task to copy dependencies to the target directory
val copyDependencies = taskKey[Unit]("Copy dependencies to target directory")

copyDependencies := {
    val updateReport = update.value
    val targetDir = target.value / "lib"
    IO.createDirectory(targetDir)
    val jars = updateReport.select(configurationFilter("compile"))
    jars.foreach { jar =>
        IO.copyFile(jar, targetDir / jar.getName)
    }
}

// Ensure the copyDependencies task runs after compile
Compile / compile := (Compile / compile).dependsOn(copyDependencies).value
