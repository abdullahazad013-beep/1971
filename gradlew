#!/usr/bin/env sh
set -e
DIRNAME=$(cd "$(dirname "$0")" && pwd)
JAR="$DIRNAME/gradle/wrapper/gradle-wrapper.jar"

if [ -f "$JAR" ]; then
  exec java -classpath "$JAR" org.gradle.wrapper.GradleWrapperMain "$@"
else
  # Fallback to system gradle
  exec gradle "$@"
fi
