#!/usr/bin/env bash

set -eu -o pipefail

log() {
  echo "$*" >&2
}

# get_next_arg(name, argv...)
get_next_arg() {
  local arg_name v
  arg_name="$1"
  v="${2-}"

  if [[ -z "$v" ]]; then
    error "Missing required argument: $arg_name" >&2
    usage
    exit 1
  fi

  echo "$v"
}

# ensure_opt_set(flag_name, value) - fails if a required option/flag wasn't
# provided.
ensure_opt_set() {
  local opt_name value
  opt_name="$1"
  value="$2"

  if [[ -z "$value" ]]; then
    log "Missing required option: $opt_name - see --help for more information."
    exit 1
  fi
}

usage() {
  local prog
  prog=$(basename "$0")
  {
    echo "Usage: $prog OPTIONS..."
    echo ""
    echo "DOWNLOAD OPTIONS"
    echo "    --version         The zizmor version to install (git tag), list:"
    echo "                      https://github.com/zizmorcore/zizmor/releases"
    echo ""
    echo "    --amd64-digest    The SHA-256 digest for the given Zizmor version for"
    echo "                      the AMD64/x86_64 platform. May support other digests"
    echo "                      in the future (e.g., SHA-3)"
    echo "                      You will find the value under 'zizmor-x86_64-unknown-linux-gnu.tar.gz'"
    echo "                      in https://github.com/zizmorcore/zizmor/releases"
    echo ""
    echo "    --aarch64-digest  The SHA-256 digest for the given Zizmor version for"
    echo "                      ARM64."
    echo "                      You will find the value under 'zizmor-aarch64-unknown-linux-gnu.tar.gz'"
    echo "                      in https://github.com/zizmorcore/zizmor/releases"
    echo ""
    echo "    --strict          Disables skipping attestation checks if 'gh' command isn't available."
    echo ""
    echo "INSTALL OPTIONS"
    echo "    --target          Directory where to install Zizmor. Directory must exist"
    echo "                      (will not be created)"
    echo "EXAMPLE"
    echo "    $prog --version v1.24.1 \\"
    echo "          --aarch64-digest d66e37ef8a375fb07939c630ebf9709a6e0f20242bdc3faf672a7ed97e0b768d \\"
    echo "          --amd64-digest a8000f3c683319a523d3b20df0e75457ba591f049cfcbfa98966631b56733c03 \\"
    echo "          --target /usr/local/bin"
  } >&2
}

version=
amd64_digest=
aarch64_digest=
strict=
target=

while [[ $# -gt 0 ]]; do
  opt="$1"
  shift
  case "$opt" in
  --version)
    version=$(get_next_arg "--version" "$@")
    shift
    ;;
  --amd64-digest)
    amd64_digest=$(get_next_arg "--amd64-digest" "$@")
    shift
    ;;
  --aarch64-digest)
    aarch64_digest=$(get_next_arg "--aarch64-digest" "$@")
    shift
    ;;
  --strict)
    strict=1
    ;;
  --target)
    target=$(get_next_arg "--target" "$@")
    shift
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  *)
    log "Unknown option $opt. See $(basename "$0") --help"
    exit 1
    ;;
  esac
done

ensure_opt_set "--version" "$version"
ensure_opt_set "--amd64-digest" "$amd64_digest"
ensure_opt_set "--aarch64-digest" "$aarch64_digest"
ensure_opt_set "--target" "$target"

case "$(uname -m)" in
x86_64 | amd64)
  arch="x86_64"
  expected_digest="$amd64_digest"
  ;;
aarch64 | arm64)
  arch="aarch64"
  expected_digest="$aarch64_digest"
  ;;
*)
  log "Fatal: unsupported arch: $(uname -m)"
  return 1
  ;;
esac

dl_gh_repo=zizmorcore/zizmor
dl_filename="zizmor-${arch}-unknown-linux-gnu.tar.gz"
dl_url="https://github.com/${dl_gh_repo}/releases/download/$version/$dl_filename"

dl_path=$(mktemp -d)/"$dl_filename"

# Note: we can use 'gh release download' however in order to be somewhat vendor
#       agnostic, we are using cURL instead so users aren't stuck with GitHub
log "Downloading $dl_url to $dl_path..."
curl -Lsf -o "$dl_path" "$dl_url"

# Verify attestation
if command -v gh >/dev/null; then
  log "INFO: Verifying release's attestation..."
  gh release verify-asset "$version" "$dl_path" --repo="$dl_gh_repo"
# Fail if strict mode is enabled (CI)
elif [[ -n "$strict" ]]; then
  log "FATAL: couldn't verify release attestation because GitHub CLI isn't installed."
  log "       Please install GitHub CLI, or remove the '--strict' flag."
  exit 2
# Warn if non-strict mode (in theory should only happen during local use)
else
  log "WARNING: couldn't verify the release's attestation because GitHub CLI isn't installed"
fi

log "INFO: Checking integrity..."
if ! (echo "$expected_digest $dl_path" | sha256sum -c); then
  log "FATAL: failed checksum check"
  exit 1
fi

log "Extracting zizmor..."
tar -C "$target" -xf "$dl_path"
rm "$dl_path"
