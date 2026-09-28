#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
installer="${repository_root}/script-templates/otel-dotnet-auto-install.sh.template"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/beacon-dotnet-uninstall-test.XXXXXX")"
cleanup() {
  rm -rf -- "${test_root}"
}
trap cleanup EXIT

mkdir -p "${test_root}/package"
printf '%s\n' '{}' > "${test_root}/package/BEACON-METADATA.json"
printf '%s\n' '#!/bin/sh' > "${test_root}/package/instrument.sh"
(
  cd "${test_root}/package"
  zip -q "${test_root}/beacon.zip" BEACON-METADATA.json instrument.sh
)

install_dir="${test_root}/install with spaces"
VERSION=v0.0.0 \
  OS_TYPE=linux-glibc \
  ARCHITECTURE=x64 \
  SKIP_RELEASE_VERIFICATION=true \
  LOCAL_PATH="${test_root}/beacon.zip" \
  OTEL_DOTNET_AUTO_HOME="${install_dir}" \
  sh "${installer}"

[[ -x "${install_dir}/instrument.sh" ]]
[[ -x "${install_dir}/uninstall.sh" ]]
sh "${install_dir}/uninstall.sh"
[[ ! -e "${install_dir}" ]]

# The downloaded installer can also remove an existing installation directly.
VERSION=v0.0.0 \
  OS_TYPE=linux-glibc \
  ARCHITECTURE=x64 \
  SKIP_RELEASE_VERIFICATION=true \
  LOCAL_PATH="${test_root}/beacon.zip" \
  OTEL_DOTNET_AUTO_HOME="${install_dir}" \
  sh "${installer}"
OTEL_DOTNET_AUTO_HOME="${install_dir}" sh "${installer}" --uninstall
[[ ! -e "${install_dir}" ]]

# Repeated uninstall is a successful no-op.
OTEL_DOTNET_AUTO_HOME="${install_dir}" sh "${installer}" --uninstall

# An arbitrary directory without Beacon metadata must never be removed.
mkdir "${install_dir}"
if OTEL_DOTNET_AUTO_HOME="${install_dir}" sh "${installer}" --uninstall; then
  echo "error: uninstall removed or accepted an unmarked directory" >&2
  exit 1
fi
[[ -d "${install_dir}" ]]

# Broad targets are rejected even if an attacker places a marker there.
fake_home="${test_root}/fake-home"
mkdir "${fake_home}"
printf '%s\n' '{}' > "${fake_home}/BEACON-METADATA.json"
if HOME="${fake_home}" OTEL_DOTNET_AUTO_HOME="${fake_home}" sh "${installer}" --uninstall; then
  echo "error: uninstall accepted the home directory" >&2
  exit 1
fi
[[ -d "${fake_home}" ]]

echo "uninstall tests passed"
