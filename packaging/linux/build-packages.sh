#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
input=""
output=""
architecture=""
format="all"

fail() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  echo "usage: $0 --input <tracer-home> --output <directory> --architecture <amd64|arm64> [--format <deb|rpm|all>]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) [[ $# -ge 2 ]] || usage; input="$2"; shift 2 ;;
    --output) [[ $# -ge 2 ]] || usage; output="$2"; shift 2 ;;
    --architecture) [[ $# -ge 2 ]] || usage; architecture="$2"; shift 2 ;;
    --format) [[ $# -ge 2 ]] || usage; format="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "${input}" && -n "${output}" && -n "${architecture}" ]] || usage
[[ "${architecture}" == "amd64" || "${architecture}" == "arm64" ]] || fail "unsupported architecture: ${architecture}"
[[ "${format}" == "deb" || "${format}" == "rpm" || "${format}" == "all" ]] || fail "unsupported format: ${format}"
[[ -d "${input}" ]] || fail "input directory does not exist: ${input}"
[[ -f "${input}/instrument.sh" ]] || fail "input does not contain instrument.sh"
[[ -f "${input}/LICENSE" ]] || fail "input does not contain LICENSE"
[[ -f "${input}/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll" ]] || fail "input does not contain the startup hook"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"

if [[ "${format}" == "deb" || "${format}" == "all" ]]; then
  command -v dpkg-deb >/dev/null 2>&1 || fail "dpkg-deb is required"
fi
if [[ "${format}" == "rpm" || "${format}" == "all" ]]; then
  command -v rpmbuild >/dev/null 2>&1 || fail "rpmbuild is required"
fi

bash "${repository_root}/beacon/scripts/check-version.sh" >/dev/null
version="$(sed -n 's/^beacon\.version=//p' "${repository_root}/beacon/version.properties")"
case "${architecture}" in
  amd64) beacon_target="linux-glibc-x64"; runtime_arch="x64"; rpm_arch="x86_64" ;;
  arm64) beacon_target="linux-glibc-arm64"; runtime_arch="arm64"; rpm_arch="aarch64" ;;
esac
[[ -f "${input}/linux-${runtime_arch}/OpenTelemetry.AutoInstrumentation.Native.so" ]] || \
  fail "input does not contain the linux-${runtime_arch} native profiler"

mkdir -p "${output}"
output="$(cd "${output}" && pwd)"
staging="$(mktemp -d "${TMPDIR:-/tmp}/beacon-dotnet-native-package.XXXXXX")"
cleanup() {
  rm -rf -- "${staging}"
}
trap cleanup EXIT

package_root="${staging}/package-root"
install_root="${package_root}/opt/beacon/dotnet"
mkdir -p "${install_root}" "${package_root}/usr/bin"
cp -a "${input}/." "${install_root}/"
cp "${repository_root}/packaging/linux/beacon-dotnet" "${package_root}/usr/bin/beacon-dotnet"
chmod 755 "${package_root}/usr/bin/beacon-dotnet" "${install_root}/instrument.sh"
chmod -R go-w "${package_root}"
bash "${repository_root}/beacon/scripts/write-metadata.sh" \
  --directory "${install_root}" \
  --target "${beacon_target}" >/dev/null

artifacts=()

if [[ "${format}" == "deb" || "${format}" == "all" ]]; then
  deb_root="${staging}/deb-root"
  cp -a "${package_root}" "${deb_root}"
  mkdir -p "${deb_root}/DEBIAN"
  installed_size="$(du -sk "${deb_root}/opt" "${deb_root}/usr" | awk '{ total += $1 } END { print total }')"
  cat > "${deb_root}/DEBIAN/control" <<EOF
Package: beacon-dotnet
Version: ${version}
Architecture: ${architecture}
Maintainer: Beacon Observability <maintainers@beacon-observability.dev>
Installed-Size: ${installed_size}
Section: utils
Priority: optional
Homepage: https://github.com/beacon-observability/beacon-dotnet
Depends: libc6
Description: Beacon .NET Automatic Instrumentation
 OpenTelemetry-based automatic instrumentation for .NET applications.
EOF
  (
    cd "${deb_root}"
    find opt usr -type f -print0 | LC_ALL=C sort -z | xargs -0 md5sum > DEBIAN/md5sums
  )
  deb_path="${output}/beacon-dotnet-${version}-linux-${architecture}.deb"
  [[ ! -e "${deb_path}" ]] || fail "output already exists: ${deb_path}"
  dpkg-deb --root-owner-group --build "${deb_root}" "${deb_path}" >/dev/null
  artifacts+=("${deb_path}")
fi

if [[ "${format}" == "rpm" || "${format}" == "all" ]]; then
  rpm_version="${version%%-*}"
  if [[ "${version}" == *-* ]]; then
    rpm_release="0.${version#*-}"
    rpm_release="${rpm_release//-/.}"
  else
    rpm_release="1"
  fi
  rpm_top="${staging}/rpmbuild"
  mkdir -p "${rpm_top}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
  tar -C "${staging}" -czf "${rpm_top}/SOURCES/beacon-dotnet-${rpm_version}.tar.gz" package-root
  cat > "${rpm_top}/SPECS/beacon-dotnet.spec" <<EOF
%global __strip /bin/true
Name: beacon-dotnet
Version: ${rpm_version}
Release: ${rpm_release}%{?dist}
Summary: Beacon .NET Automatic Instrumentation
License: Apache-2.0
URL: https://github.com/beacon-observability/beacon-dotnet
Source0: beacon-dotnet-${rpm_version}.tar.gz
BuildArch: ${rpm_arch}
AutoReqProv: no
Requires: /bin/sh
Requires: glibc

%description
OpenTelemetry-based automatic instrumentation for .NET applications.

%prep
%setup -q -n package-root

%build

%install
mkdir -p %{buildroot}
cp -a opt usr %{buildroot}/

%files
/opt/beacon/dotnet
/usr/bin/beacon-dotnet

%changelog
* $(LC_ALL=C date '+%a %b %d %Y') Beacon Observability <maintainers@beacon-observability.dev> - ${rpm_version}-${rpm_release}
- Package Beacon .NET Automatic Instrumentation.
EOF
  rpm_log="${staging}/rpmbuild.log"
  if ! rpmbuild -bb \
      --define "_topdir ${rpm_top}" \
      --define "_build_id_links none" \
      --target "${rpm_arch}" \
      "${rpm_top}/SPECS/beacon-dotnet.spec" >"${rpm_log}" 2>&1; then
    cat "${rpm_log}" >&2
    fail "rpmbuild failed"
  fi
  built_rpm="$(find "${rpm_top}/RPMS" -type f -name '*.rpm' -print -quit)"
  [[ -n "${built_rpm}" ]] || fail "rpmbuild did not produce an RPM"
  rpm_path="${output}/beacon-dotnet-${version}-linux-${rpm_arch}.rpm"
  [[ ! -e "${rpm_path}" ]] || fail "output already exists: ${rpm_path}"
  cp "${built_rpm}" "${rpm_path}"
  artifacts+=("${rpm_path}")
fi

for artifact in "${artifacts[@]}"; do
  (
    cd "${output}"
    sha256sum "$(basename "${artifact}")" > "$(basename "${artifact}").sha256"
    sha256sum --check "$(basename "${artifact}").sha256" >/dev/null
  )
  printf '%s\n' "${artifact}" "${artifact}.sha256"
done
