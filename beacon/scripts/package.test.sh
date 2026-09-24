#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/beacon-dotnet-package-test.XXXXXX")"
cleanup() {
  rm -rf -- "${test_root}"
}
trap cleanup EXIT

mkdir -p "${test_root}/input/net" "${test_root}/input/linux-x64" "${test_root}/output"
touch "${test_root}/input/instrument.sh"
touch "${test_root}/input/LICENSE"
touch "${test_root}/input/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll"
touch "${test_root}/input/linux-x64/OpenTelemetry.AutoInstrumentation.Native.so"

mapfile -t outputs < <(bash "${repository_root}/beacon/scripts/package.sh" \
  --input "${test_root}/input" \
  --target linux-glibc-x64 \
  --output "${test_root}/output")

[[ ${#outputs[@]} -eq 2 ]]
archive="${outputs[0]}"
checksum="${outputs[1]}"
[[ -f "${archive}" && -f "${checksum}" ]]
unzip -p "${archive}" BEACON-METADATA.json | grep -q '"product": "Beacon .NET"'
unzip -l "${archive}" | grep -q 'net/OpenTelemetry.AutoInstrumentation.StartupHook.dll'
(cd "${test_root}/output" && sha256sum --check "$(basename "${checksum}")")

if bash "${repository_root}/beacon/scripts/package.sh" \
  --input "${test_root}/input" \
  --target '../../invalid' \
  --output "${test_root}/output" >/dev/null 2>&1; then
  echo "error: invalid platform identifier was accepted" >&2
  exit 1
fi

echo "package tests passed"
