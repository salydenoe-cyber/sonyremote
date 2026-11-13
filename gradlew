#!/usr/bin/env sh
set -eu

APP_HOME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GRADLE_VERSION=8.13
DIST_NAME="gradle-${GRADLE_VERSION}"
DIST_ZIP="${DIST_NAME}-bin.zip"
CACHE_BASE="${GRADLE_USER_HOME:-${HOME}/.gradle}/wrapper/dists/${DIST_NAME}"
DIST_DIR=""

if command -v gradle >/dev/null 2>&1; then
  exec gradle "$@"
fi

if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
  JAVA="${JAVA_HOME}/bin/java"
elif command -v java >/dev/null 2>&1; then
  JAVA="$(command -v java)"
else
  echo "ERROR: JAVA_HOME is not set and java was not found." >&2
  exit 1
fi

for candidate in "${CACHE_BASE}"/*/; do
  if [ -x "${candidate}bin/gradle" ]; then
    DIST_DIR="${candidate}"
    break
  fi
done

if [ -z "${DIST_DIR}" ]; then
  mkdir -p "${CACHE_BASE}"
  TMP_DIR="${CACHE_BASE}/.tmp-$$"
  mkdir -p "${TMP_DIR}"
  ARCHIVE="${TMP_DIR}/${DIST_ZIP}"
  URL="https://services.gradle.org/distributions/${DIST_ZIP}"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 "${URL}" -o "${ARCHIVE}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "${URL}" -O "${ARCHIVE}"
  else
    "${JAVA}" -cp "${APP_HOME}/gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
    exit $?
  fi
  unzip -q "${ARCHIVE}" -d "${TMP_DIR}"
  DIST_DIR="${TMP_DIR}/${DIST_NAME}/"
  FINAL_DIR="${CACHE_BASE}/$(date +%s)-${DIST_NAME}"
  mv "${DIST_DIR}" "${FINAL_DIR}"
  rm -rf "${TMP_DIR}"
  DIST_DIR="${FINAL_DIR}/"
fi

exec "${DIST_DIR}bin/gradle" -p "${APP_HOME}" "$@"
