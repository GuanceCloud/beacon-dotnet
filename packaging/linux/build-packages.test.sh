#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/beacon-dotnet-native-package-test.XXXXXX")"
cleanup() {
  rm -rf -- "${test_root}"
}
trap cleanup EXIT

mkdir -p \
  "${test_root}/input/net" \
  "${test_root}/input/linux-x64" \
  "${test_root}/input/linux-arm64" \
  "${test_root}/output" \
  "${test_root}/output-arm64"
cp "${repository_root}/LICENSE" "${test_root}/input/LICENSE"
touch "${test_root}/input/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll"
cp /bin/true "${test_root}/input/linux-x64/OpenTelemetry.AutoInstrumentation.Native.so"
cp /bin/true "${test_root}/input/linux-arm64/OpenTelemetry.AutoInstrumentation.Native.so"
cat > "${test_root}/input/instrument.sh" <<'EOF'
#!/bin/sh
[ -z "${ARCHITECTURE+x}" ] || exit 86
exec "$@"
EOF
chmod 755 "${test_root}/input/instrument.sh"

mapfile -t outputs < <(bash "${repository_root}/packaging/linux/build-packages.sh" \
  --input "${test_root}/input" \
  --output "${test_root}/output" \
  --architecture amd64)

[[ ${#outputs[@]} -eq 4 ]]
deb="${outputs[0]}"
rpm="${outputs[2]}"
[[ -f "${deb}" && -f "${rpm}" ]]
deb_info="$(dpkg-deb --info "${deb}")"
deb_contents="$(dpkg-deb --contents "${deb}")"
rpm_info="$(rpm -qp --queryformat '%{NAME} %{ARCH}\n' "${rpm}")"
rpm_contents="$(rpm -qpl "${rpm}")"
grep -q 'Package: beacon-dotnet' <<< "${deb_info}"
grep -q './usr/bin/beacon-dotnet' <<< "${deb_contents}"
grep -q '^beacon-dotnet x86_64$' <<< "${rpm_info}"
grep -q '^/usr/bin/beacon-dotnet$' <<< "${rpm_contents}"

mkdir -p "${test_root}/deb-extracted"
dpkg-deb --extract "${deb}" "${test_root}/deb-extracted"
cli="${test_root}/deb-extracted/usr/bin/beacon-dotnet"
home="${test_root}/deb-extracted/opt/beacon/dotnet"
status_output="$(BEACON_DOTNET_HOME="${home}" "${cli}" status)"
grep -q 'Status: installed' <<< "${status_output}"
[[ "$(BEACON_DOTNET_HOME="${home}" "${cli}" version)" == "$(sed -n 's/^beacon\.version=//p' "${repository_root}/beacon/version.properties")" ]]
[[ "$(ARCHITECTURE=amd64 BEACON_DOTNET_HOME="${home}" "${cli}" run printf 'instrumented')" == "instrumented" ]]

mapfile -t arm64_outputs < <(bash "${repository_root}/packaging/linux/build-packages.sh" \
  --input "${test_root}/input" \
  --output "${test_root}/output-arm64" \
  --architecture arm64 \
  --format deb)
[[ ${#arm64_outputs[@]} -eq 2 ]]
[[ "$(dpkg-deb --field "${arm64_outputs[0]}" Architecture)" == "arm64" ]]

echo "native Linux package tests passed"
