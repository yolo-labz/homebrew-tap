# yolo-labz/homebrew-tap

Homebrew tap for [`yolo-labz/wa`](https://github.com/yolo-labz/wa) — a personal
WhatsApp automation CLI + daemon written in Go.

## Install

```bash
brew install yolo-labz/tap/wa
```

This installs both binaries (`wa` and `wad`) into your Homebrew prefix.

## Maintenance

Formulas under `Formula/` are maintained by GoReleaser's `brews` publisher.
Every `vX.Y.Z` tag on `yolo-labz/wa` writes an updated `Formula/wa.rb` here
automatically, provided the `HOMEBREW_TAP_GITHUB_TOKEN` secret is set on the
upstream repo (a GitHub PAT with `public_repo` or `repo` scope).

The initial v0.3.2 formula was seeded manually so that `brew install` works
even before the first automated publication. Subsequent releases replace it
end-to-end via the GoReleaser pipeline.

## License

The tap infrastructure is Apache-2.0 (matching the upstream project). The
formulas themselves are trivially derived from the release tarballs; they
carry no separate license.
