#!/usr/bin/env bash
# Runs `apt-get update` and makes sure the Ubuntu archive is among the apt
# sources. Some hosted runners boot an Ubuntu image whose only apt source is
# packages.microsoft.com, and every Ubuntu package then fails with "Unable to
# locate package". When no index of origin Ubuntu is present after the
# update, this adds the archive for the image's codename and updates again.
#
# Before the first update it also drops any *.ec2.archive.ubuntu.com entry
# from the runner's apt mirror list. Runners that draw that mirror have
# taken more than 20 minutes to download the Linux build packages, while the
# Ubuntu and Azure archives serve them in about a minute. When nothing else
# is left in the list, the Ubuntu archive takes the mirror's place.
#
# Run as root (sudo). APT_SOURCES_DIR, OS_RELEASE_FILE and APT_MIRRORS_FILE
# override /etc/apt/sources.list.d, /etc/os-release and
# /etc/apt/apt-mirrors.txt for the self-test.
set -euo pipefail

sources_dir="${APT_SOURCES_DIR:-/etc/apt/sources.list.d}"
os_release="${OS_RELEASE_FILE:-/etc/os-release}"
mirrors_file="${APT_MIRRORS_FILE:-/etc/apt/apt-mirrors.txt}"
ec2_mirror='^[a-z]+://[^/[:space:]]+\.ec2\.archive\.ubuntu\.com([/[:space:]]|$)'

if [[ -f "$mirrors_file" ]] && grep -Eq "$ec2_mirror" "$mirrors_file"; then
  echo "Dropping the slow EC2 apt mirror from $mirrors_file:" >&2
  grep -E "$ec2_mirror" "$mirrors_file" >&2
  kept="$(grep -Ev "$ec2_mirror" "$mirrors_file" || true)"
  if [[ -z "${kept//[[:space:]]/}" ]]; then
    kept="$(printf 'http://archive.ubuntu.com/ubuntu/\tpriority:1')"
  fi
  printf '%s\n' "$kept" > "$mirrors_file"
fi

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
