#!/bin/sh
set -eu

version="1.0.1"
architecture="amd64"
expected_sha256="8406b8ec98f22876fc1cb7784f1e6470db4df2c75aad67fa19680b19f0181684"
release_base="https://github.com/sblee1/AgentHub/releases/download/v${version}"
package_name="aiagent_${version}_${architecture}.deb"

fail() {
    echo "AI Agent Hub installer: $*" >&2
    exit 1
}

command -v dpkg >/dev/null 2>&1 || fail "Ubuntu or Debian is required."
command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required."
command -v apt-get >/dev/null 2>&1 || fail "APT is required."

detected_architecture=$(dpkg --print-architecture)
[ "$detected_architecture" = "$architecture" ] ||
    fail "unsupported architecture: $detected_architecture (expected $architecture)"

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/agenthub-install.XXXXXX")
trap 'rm -rf -- "$temporary_directory"' EXIT HUP INT TERM
package_file="$temporary_directory/$package_name"

echo "Downloading AI Agent Hub $version for $architecture..."
curl -fL --retry 3 --output "$package_file" "$release_base/$package_name"

actual_sha256=$(sha256sum "$package_file" | awk '{print $1}')
[ "$actual_sha256" = "$expected_sha256" ] ||
    fail "checksum verification failed"
echo "SHA-256 verified."

if [ "$(id -u)" -eq 0 ]; then
    apt-get install -y "$package_file"
else
    command -v sudo >/dev/null 2>&1 || fail "sudo is required for installation."
    sudo apt-get install -y "$package_file"
fi

installed_version=$(aiAgent --version 2>/dev/null || true)
[ "$installed_version" = "AI Agent Hub $version" ] ||
    fail "installation finished, but the installed version could not be verified"

echo "Installed: $installed_version"
echo "Launch AI Agent Hub from the application menu or run: aiAgent"
