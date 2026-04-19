set -eu -o pipefail

here=$(readlink -f "$(dirname "$0")")

"$here"/install.sh --version v1.24.1 \
  --aarch64-digest d66e37ef8a375fb07939c630ebf9709a6e0f20242bdc3faf672a7ed97e0b768d \
  --amd64-digest a8000f3c683319a523d3b20df0e75457ba591f049cfcbfa98966631b56733c03 \
  --target /usr/local/bin "$@"
