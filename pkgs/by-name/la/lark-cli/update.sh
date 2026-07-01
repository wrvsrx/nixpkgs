#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash sd curl git jq nix nix-update perl

set -euo pipefail

nixpkgs="$(git rev-parse --show-toplevel)"
nix_file="$nixpkgs/pkgs/by-name/la/lark-cli/package.nix"

nix-update lark-cli

# if not changed, exit
if git diff --quiet -- "$nix_file"; then
    exit 0
fi

# Update the metadata hash after normalizing unstable JSON object key order.
version=$(nix eval --raw .#lark-cli.version)
target_url="https://open.feishu.cn/api/tools/open/api_definition?protocol=meta&client_version=v${version}"
metadata_file=$(mktemp)
trap 'rm -f "$metadata_file"' EXIT

curl -fsSL "$target_url" | jq -S . > "$metadata_file"
new_hash=$(nix hash file "$metadata_file")

perl -0777 -i -pe 's|(metaDataRaw = fetchurl \{.*?hash = )"[^"]*"|$1"'"$new_hash"'"|s' "$nix_file"

# Update date
new_date=$(date +%Y-%m-%d)
sd "Date=[0-9]{4}-[0-9]{2}-[0-9]{2}" "Date=$new_date" "$nix_file"
