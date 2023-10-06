# Action for publishing Sunbeam extensions

A Sunbeam extension is any GitHub repository named `sunbeam-*` that publishes a Release with precompiled binaries. This GitHub Action can be used in your extension repository to automate the creation and publishing of those binaries.

## Go extensions

Create a workflow file at `.github/workflows/release.yml`:

```yaml
name: release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: pomdtr/sunbeam-extension-precompile@v1
        with:
          go_version: "1.21"
```

Then, either push a new git tag like `v1.0.0` to your repository, or create a new Release and have it initialize the associated git tag.

When the `release` workflow finishes running, compiled binaries will be uploaded as assets to the `v1.0.0` Release and your extension will be installable by users of `sunbeam extension install` on supported platforms.

You can safely test out release automation by creating tags that have a `-` in them; for example: `v2.0.0-rc.1`. Such Releases will be published as _prereleases_ and will not count as a stable release of your extension.

To maximize portability of built products, this action builds Go binaries with [cgo](https://pkg.go.dev/cmd/cgo) disabled. To override that, set the `CGO_ENABLED` environment variable:

```yaml
- uses: pomdtr/sunbeam-extension-precompile@v1
  env:
    CGO_ENABLED: 1
```

## Checksum file and signing

This action can optionally produce a checksum file for all published executables and sign it with GPG.

To enable this, make sure your repository has the secrets `GPG_SECRET_KEY` and `GPG_PASSPHRASE` set. Then, configure this action like so:

```yaml
name: release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - id: import_gpg
        uses: crazy-max/ghaction-import-gpg@v5
        with:
          gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
          passphrase: ${{ secrets.GPG_PASSPHRASE }}
      - uses: pomdtr/sunbeam-extension-precompile@v1
        with:
          gpg_fingerprint: ${{ steps.import_gpg.outputs.fingerprint }}
```
