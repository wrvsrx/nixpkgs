#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash cacert git nix-update

# `nix-update` maintains the version, the release-tarball hash and the pnpm
# dependency hash.  It cannot maintain `DSH_CLIENT_COMMIT_HASH` though: the
# client build wants a hex commit and upstream only publishes tags, so resolve
# the tag it just selected here.
set -euo pipefail

pkgdir="$(cd "$(dirname "$0")" && pwd)"
cd "$(git -C "$pkgdir" rev-parse --show-toplevel)"

nix-update --version unstable deepseek-harness

version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$pkgdir/package.nix")"
tag="dsh-v${version}"

# Lightweight tags resolve to the commit directly; annotated tags need the
# peeled ref, so try that first.
commit="$(git ls-remote https://github.com/deepseek-ai/deepseek-harness "refs/tags/${tag}^{}" | cut -f1)"
if [[ -z "$commit" ]]; then
  commit="$(git ls-remote https://github.com/deepseek-ai/deepseek-harness "refs/tags/${tag}" | cut -f1)"
fi
if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: could not resolve $tag to a commit" >&2
  exit 1
fi

echo ">> $tag -> $commit"
sed -i -E "s/(DSH_CLIENT_COMMIT_HASH = \")[0-9a-fA-F]{7,40}(\";)/\1${commit}\2/" "$pkgdir/package.nix"
