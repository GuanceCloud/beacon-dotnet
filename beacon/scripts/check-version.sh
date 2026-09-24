#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
version_file="${repository_root}/beacon/version.properties"
lock_file="${repository_root}/beacon/upstream.lock.json"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "${version_file}" ]] || fail "missing ${version_file}"
[[ -f "${lock_file}" ]] || fail "missing ${lock_file}"

mapfile -t version_lines < <(sed -n 's/^beacon\.version=//p' "${version_file}")
[[ ${#version_lines[@]} -eq 1 ]] || fail "version.properties must contain exactly one beacon.version"
version="${version_lines[0]}"
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+\.)*[0-9A-Za-z-]+)?(\+[0-9A-Za-z.-]+)?$'
[[ "${version}" =~ ${semver} ]] || fail "invalid Beacon SemVer: ${version}"

upstream_tag="$(sed -n 's/.*"releaseTag": "\([^"]*\)".*/\1/p' "${lock_file}")"
upstream_commit="$(sed -n 's/.*"releaseCommit": "\([0-9a-f]*\)".*/\1/p' "${lock_file}")"
[[ "${upstream_tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || fail "invalid upstream releaseTag"
[[ "${upstream_commit}" =~ ^[0-9a-f]{40}$ ]] || fail "invalid upstream releaseCommit"

git -C "${repository_root}" cat-file -e "${upstream_commit}^{commit}" 2>/dev/null || fail "upstream commit is not available locally"
git -C "${repository_root}" merge-base --is-ancestor "${upstream_commit}" HEAD || fail "upstream commit is not an ancestor of HEAD"

if [[ -n "${BEACON_RELEASE_TAG:-}" ]]; then
  expected_tag="beacon-v${version}"
  [[ "${BEACON_RELEASE_TAG}" == "${expected_tag}" ]] || fail "release tag must be ${expected_tag}"
  [[ "${version}" != *+* ]] || fail "release version cannot contain SemVer build metadata"
fi

echo "Beacon version: ${version}"
echo "Upstream baseline: ${upstream_tag} (${upstream_commit})"
