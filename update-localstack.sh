#!/bin/sh

# Description: Download, verify and install localstack-cli on Linux and Mac
# Author: Chuck Nemeth
# https://github.com/localstack/localstack-cli

# Colored output
code_err() { tput setaf 1; printf '%s\n' "$*" >&2; tput sgr0; }
code_grn() { tput setaf 2; printf '%s\n' "$*"; tput sgr0; }
code_yel() { tput setaf 3; printf '%s\n' "$*"; tput sgr0; }

# Delete temporary install files
clean_up() {
  printf '%s\n' "[INFO] Cleaning up install files"
  cd && rm -rf "${tmp_dir}"
}

# Variables
bin_dir="$HOME/.local/bin"

if command -v localstack >/dev/null 2>&1; then
  localstack_installed_version="v$(localstack --version)"
else
  localstack_installed_version="Not Installed"
fi

localstack_version="$(curl -s https://api.github.com/repos/localstack/localstack-cli/releases/latest | \
                      awk -F': ' '/tag_name/ { gsub(/\"|\,/,"",$2); print $2 }')"
localstack_url="https://github.com/localstack/localstack-cli/releases/download/${localstack_version}/"

# PATH Check
case :$PATH: in
  *:"${bin_dir}":*)  ;;  # do nothing
  *)
    code_err "[ERROR] ${bin_dir} was not found in \$PATH!"
    code_err "Add ${bin_dir} to PATH or select another directory to install to"
    exit 1 ;;
esac

# Version Check
if [ "${localstack_version}" = "${localstack_installed_version}" ]; then
  printf '%s\n' "Installed Verision: ${localstack_installed_version}"
  printf '%s\n' "Latest Version: ${localstack_version}"
  code_yel "[INFO] Already using latest version. Exiting."
  exit
else
  printf '%s\n' "Installed Verision: ${localstack_installed_version}"
  printf '%s\n' "Latest Version: ${localstack_version}"
  tmp_dir="$(mktemp -d /tmp/localstack.XXXXXXXX)"
  trap clean_up EXIT
  cd "${tmp_dir}" || exit
fi

# OS Check
archi=$(uname -sm)
case "$archi" in
  Darwin\ arm64)
    localstack_archive="localstack-cli-${localstack_version##v}-darwin-arm64-onefile" ;;
  Darwin\ x86_64)
    localstack_archive="localstack-cli-${localstack_version##v}-darwin-amd64-onefile" ;;
  Linux\ armv[5-9]* | Linux\ aarch64*)
    localstack_archive="localstack-cli-${localstack_version##v}-linux-arm64-onefile" ;;
  Linux\ *64)
    localstack_archive="localstack-cli-${localstack_version##v}-linux-amd64-onefile" ;;
  *)
    code_err "[ERROR] Unsupported OS. Exiting" && exit 1 ;;
esac

# Download
printf '%s\n' "[INFO] Downloading localstack archive and verification files"
curl -sL -o "${tmp_dir}/${localstack_archive}.tar.gz" "${localstack_url}/${localstack_archive}.tar.gz"
curl -sL -o "${tmp_dir}/checksums" "${localstack_url}/localstack-cli-${localstack_version##v}-checksums.txt"

printf '%s\n' "[INFO] Verifying ${localstack_archive}.tar.gz"
if ! shasum --ignore-missing -qc "${tmp_dir}/checksums"; then
  code_err "[ERROR] Problem with checksum!"
  exit 1
fi

# Extract
printf '%s\n' "[INFO] Extracting ${localstack_archive}.tar.gz"
tar -xf "${localstack_archive}.tar.gz"

# Create directories
[ ! -d "${bin_dir}" ] && install -m 0700 -d "${bin_dir}"

# Install localstack binary
if [ -f "${tmp_dir}/localstack" ]; then
  printf '%s\n' "[INFO] Installing localstack binary"
  mv "${tmp_dir}/localstack" "${bin_dir}/localstack"
  chmod 0700 "${bin_dir}/localstack"
fi

# Version Check
code_grn "[INFO] Done!"
code_grn "Installed Version: $(localstack --version)"

# vim: ft=sh ts=2 sts=2 sw=2 sr et
