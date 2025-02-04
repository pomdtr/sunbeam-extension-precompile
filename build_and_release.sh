#!/bin/bash
set -ex

platforms=(
  darwin-amd64
  darwin-arm64
  linux-amd64
  linux-arm
  linux-arm64
  windows-amd64
  windows-arm64
)

if [[ $GITHUB_REF = refs/tags/* ]]; then
  tag="${GITHUB_REF#refs/tags/}"
else
  tag="$(git describe --tags --abbrev=0)"
fi

prerelease=""
if [[ $tag = *-* ]]; then
  prerelease="--prerelease"
fi


IFS=$'\n' read -d '' -r -a supported_platforms < <(go tool dist list) || true

for p in "${platforms[@]}"; do
  goos="${p%-*}"
  goarch="${p#*-}"
  if [[ " ${supported_platforms[*]} " != *" ${goos}/${goarch} "* ]]; then
    echo "warning: skipping unsupported platform $p" >&2
    continue
  fi
  ext=""
  if [ "$goos" = "windows" ]; then
    ext=".exe"
  fi
  GOOS="$goos" GOARCH="$goarch" CGO_ENABLED="${CGO_ENABLED:-0}" go build -trimpath -ldflags="-s -w" -o "dist/sunbeam-extension-${p}${ext}"
done

assets=()
for f in dist/*; do
  if [ -f "$f" ]; then
    assets+=("$f")
  fi
done

if [ "${#assets[@]}" -eq 0 ]; then
  echo "error: no files found in dist/*" >&2
  exit 1
fi

if gh release view "$tag" >/dev/null; then
  echo "uploading assets to an existing release..."
  gh release upload "$tag" --clobber -- "${assets[@]}"
else
  echo "creating release and uploading assets..."
  gh release create "$tag" $prerelease --title="${GITHUB_REPOSITORY#*/} ${tag#v}" --generate-notes -- "${assets[@]}"
fi
