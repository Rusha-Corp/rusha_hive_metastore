name := "hive-iceberg-delta"
version := "1.0"
scalaVersion := "2.12.19"  // Use a Scala version compatible with Spark
javacOptions ++= Seq("-source", "17", "-target", "17")  // Java 17 compatibility

libraryDependencies ++= Seq(
  "org.apache.iceberg" % "iceberg-aws" % "1.7.1" % "runtime",
  "org.apache.iceberg" %% "iceberg-spark-runtime-3.5" % "1.7.1",
  "org.apache.iceberg" % "iceberg-aws-bundle" % "1.7.1",
  "org.postgresql" % "postgresql" % "42.7.5",
  "org.apache.spark" %% "spark-hadoop-cloud" % "3.5.3"
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
