#!/usr/bin/env bash
# Runs `apt-get update` and makes sure the Ubuntu archive is among the apt
# sources. Some hosted runners boot an Ubuntu image whose only apt source is
# packages.microsoft.com, and every Ubuntu package then fails with "Unable to
# locate package". When no index of origin Ubuntu is present after the
# update, this adds the archive for the image's codename and updates again.
#
# Run as root (sudo). APT_SOURCES_DIR and OS_RELEASE_FILE override
# /etc/apt/sources.list.d and /etc/os-release for the self-test.
set -euo pipefail

sources_dir="${APT_SOURCES_DIR:-/etc/apt/sources.list.d}"
os_release="${OS_RELEASE_FILE:-/etc/os-release}"

has_ubuntu_archive() {
  # Not `apt-cache policy | grep -q`: grep exiting early would fail the
  # pipeline under pipefail.
  grep -q 'o=Ubuntu,' <<<"$(apt-cache policy)"
}

apt-get update

# shellcheck disable=SC1090
id="$(. "$os_release" && echo "${ID:-}")"
codename="$(. "$os_release" && echo "${VERSION_CODENAME:-}")"
if [[ "$id" != "ubuntu" || -z "$codename" ]] || has_ubuntu_archive; then
  exit 0
fi

echo "No Ubuntu archive in the apt sources; adding it for $codename." >&2
keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg
components="main restricted universe multiverse"
target="$sources_dir/ubuntu-archive.sources"
case "$(dpkg --print-architecture)" in
  amd64 | i386)
    cat > "$target" <<SOURCES
Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: $codename $codename-updates $codename-backports
Components: $components
Signed-By: $keyring

Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: $codename-security
Components: $components
Signed-By: $keyring
SOURCES
    ;;
  *)
    cat > "$target" <<SOURCES
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: $codename $codename-updates $codename-backports $codename-security
Components: $components
Signed-By: $keyring
SOURCES
    ;;
esac

apt-get update
if ! has_ubuntu_archive; then
  echo "The Ubuntu archive is still missing after adding $target." >&2
  exit 1
fi
