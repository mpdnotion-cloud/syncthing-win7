#!/usr/bin/env bash
# build-win7.sh
# Cross-compiles Syncthing for Windows 7 / Windows Server 2008 R2 SP1 (x64)
# from Linux, using the go-legacy-win7 toolchain.
# See build-win7.ps1 and README-Win7.md for details.
#
# Usage: ./build-win7.sh
# Output: syncthing-windows-amd64-<version>.zip in the repository root.
set -euo pipefail

GO_LEGACY_VERSION="${GO_LEGACY_VERSION:-1.26.7-1}"
VERSION="${VERSION:-v2.1.5+win7}"

root="$(cd "$(dirname "$0")" && pwd)"
tooldir="$root/.toolchain"
godir="$tooldir/go-legacy-win7"

case "$(uname -m)" in
	x86_64) hostarch=amd64 ;;
	aarch64 | arm64) hostarch=arm64 ;;
	*) echo "Unsupported host architecture: $(uname -m)" >&2; exit 1 ;;
esac
case "$(uname -s)" in
	Linux) hostos=linux ;;
	Darwin) hostos=darwin ;;
	*) echo "Unsupported host OS: $(uname -s)" >&2; exit 1 ;;
esac

if [ ! -x "$godir/bin/go" ]; then
	mkdir -p "$tooldir"
	url="https://github.com/thongtech/go-legacy-win7/releases/download/v${GO_LEGACY_VERSION}/go-legacy-win7-${GO_LEGACY_VERSION}.${hostos}_${hostarch}.tar.gz"
	echo "Downloading $url"
	curl -fsSL "$url" | tar xz -C "$tooldir"
fi

export PATH="$godir/bin:$PATH"
export GOTOOLCHAIN=local # never let Go download the official toolchain
export CGO_ENABLED=0     # pure-Go SQLite
export GOAMD64=v1        # no AVX required
export VERSION

go version
cd "$root"
go run build.go -goos windows -goarch amd64 -no-upgrade zip
