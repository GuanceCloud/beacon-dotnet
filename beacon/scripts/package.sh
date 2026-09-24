#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
input=""
output=""
target=""

fail() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  echo "usage: $0 --input <tracer-home> --target <platform-id> --output <directory>" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) [[ $# -ge 2 ]] || usage; input="$2"; shift 2 ;;
    --target) [[ $# -ge 2 ]] || usage; target="$2"; shift 2 ;;
    --output) [[ $# -ge 2 ]] || usage; output="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "${input}" && -n "${output}" && -n "${target}" ]] || usage
[[ "${target}" =~ ^[a-z0-9]+(-[a-z0-9]+)+$ ]] || fail "invalid platform identifier: ${target}"
[[ -d "${input}" ]] || fail "input directory does not exist: ${input}"
[[ -f "${input}/instrument.sh" || -f "${input}/instrument.cmd" ]] || fail "input does not contain an instrumentation launcher"
[[ -f "${input}/LICENSE" ]] || fail "input does not contain the upstream license"
[[ -f "${input}/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll" ]] || fail "input does not contain the startup hook"
find "${input}" -type f \( -name 'OpenTelemetry.AutoInstrumentation.Native.so' -o -name 'OpenTelemetry.AutoInstrumentation.Native.dll' -o -name 'OpenTelemetry.AutoInstrumentation.Native.dylib' \) -print -quit | grep -q . || fail "input does not contain a native CLR profiler"
command -v zip >/dev/null 2>&1 || fail "zip is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"

bash "${repository_root}/beacon/scripts/check-version.sh" >/dev/null
version="$(sed -n 's/^beacon\.version=//p' "${repository_root}/beacon/version.properties")"
upstream_repository="$(sed -n 's/.*"repository": "\([^"]*\)".*/\1/p' "${repository_root}/beacon/upstream.lock.json")"
upstream_tag="$(sed -n 's/.*"releaseTag": "\([^"]*\)".*/\1/p' "${repository_root}/beacon/upstream.lock.json")"
upstream_commit="$(sed -n 's/.*"releaseCommit": "\([0-9a-f]*\)".*/\1/p' "${repository_root}/beacon/upstream.lock.json")"
source_commit="$(git -C "${repository_root}" rev-parse HEAD)"

mkdir -p "${output}"
output="$(cd "${output}" && pwd)"
archive_name="beacon-dotnet-auto-${version}-${target}.zip"
archive_path="${output}/${archive_name}"
[[ ! -e "${archive_path}" && ! -e "${archive_path}.sha256" ]] || fail "output already exists: ${archive_path}"

staging="$(mktemp -d "${TMPDIR:-/tmp}/beacon-dotnet-package.XXXXXX")"
cleanup() {
  rm -rf -- "${staging}"
}
trap cleanup EXIT

cp -a "${input}/." "${staging}/"
cat > "${staging}/BEACON-METADATA.json" <<EOF
{
  "product": "Beacon .NET",
  "version": "${version}",
  "target": "${target}",
  "sourceCommit": "${source_commit}",
  "upstream": {
    "repository": "${upstream_repository}",
    "releaseTag": "${upstream_tag}",
    "releaseCommit": "${upstream_commit}"
  }
}
EOF

(cd "${staging}" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 zip -q -X "${archive_path}")
(cd "${output}" && sha256sum "${archive_name}" > "${archive_name}.sha256")
(cd "${output}" && sha256sum --check "${archive_name}.sha256" >/dev/null)

echo "${archive_path}"
echo "${archive_path}.sha256"
