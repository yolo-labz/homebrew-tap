# ADR-001: yolo-labz/homebrew-tap ↔ yolo-labz/wa — proposed 2026-05-27

## Status

**proposed** — Pedro signs off (accept / reject) before Phase 3 of the yolo-labz consolidation sprint fires.

## Context

The yolo-labz portfolio audit on 2026-05-27 (see `phsb5321/notes-work` PR #24, `YOLO-LABZ-AUDIT-2026-05-27.md`) flagged `homebrew-tap` as a Tier-3 release-engineering repo whose single purpose is to publish a Homebrew formula for `yolo-labz/wa`. The audit surfaced one mergeable initiative for ADR review.

**Repo A: `yolo-labz/homebrew-tap`**
- Ruby (Homebrew formula syntax)
- Contents: `Formula/wa.rb`, `README.md`, `SECURITY.md`, `sonar-project.properties`, `.github/workflows/sonar.yml`
- Released artifact count: 0 (tap repos do not cut releases)
- Maintenance: `Formula/wa.rb` auto-updated by upstream `yolo-labz/wa` GoReleaser pipeline via `brews:` block in `.goreleaser.yaml`, conditional on `HOMEBREW_TAP_GITHUB_TOKEN` PAT being set on `yolo-labz/wa`
- Sonar: wired (SHA-pinned harden-runner audit, permissions deny-all top-level)

**Repo B: `yolo-labz/wa`**
- Go 1.26.2, Apache-2.0
- Personal WhatsApp automation CLI + daemon via the `whatsmeow` library
- Tier-1 release-engineering: SLSA L2 (`attest-build-provenance@v4.1.0` SHA-pinned), dual SBOM (CycloneDX + SPDX), cosign keyless OIDC, Scorecard, Renovate with `# vX.Y.Z` comment preservation, lefthook (commitlint + gofmt + govet + golangci-lint + gomod-tidy + goreleaser-check + gitleaks + actionlint + zizmor), harden-runner on all workflows, git-cliff CHANGELOG
- Latest release: v2.0.1 with darwin-arm64, linux-amd64, linux-arm64 tarballs + .deb/.rpm/.apk packages

**Overlap signature:**

- `homebrew-tap` exists *only* to receive `Formula/wa.rb` from `wa`'s GoReleaser. There is no independent maintenance, no separate test suite, no second formula housed.
- `wa`'s `.goreleaser.yaml` already defines a `brews:` block pointing at `yolo-labz/homebrew-tap`. The relationship is purely a publisher → bucket pattern.
- Neither repo references the other in human-written code; the linkage is configuration-only.

## Decision options

### Option 1 — Keep separate (current)

Maintain `homebrew-tap` as a standalone repo. GoReleaser continues to push formula updates on each `vX.Y.Z` tag.

**Pro:**
- Clean Homebrew tap URL: `brew tap yolo-labz/wa && brew install wa`
- Standard Homebrew convention (`<org>/homebrew-<tap>` → `brew tap <org>/<tap>`)
- Headroom for future formulas — when a second yolo-labz Go binary ships, it lands in the same tap (e.g., `Formula/fand-linux-bridge.rb`, `Formula/kokoro-speakd-cli.rb`)

**Con:**
- Two repos to maintain release-engineering controls across (Sonar, dependabot/renovate, permissions, SHA-pinning)
- `homebrew-tap` will perpetually trail the canonical bar (no SLSA/SBOM/cosign — none of which apply to a tap repo anyway)

**Migration cost:** zero (no-op).

### Option 2 — Merge `homebrew-tap` into `wa`

Move `Formula/wa.rb` into `wa/dist/homebrew/wa.rb` (or similar). Update `wa`'s `.goreleaser.yaml` `brews:` block to write directly into `wa`'s own filesystem at release time. Archive `homebrew-tap` (or delete it).

**Pro:**
- Single source of truth — `wa` repo houses code + release artifacts + Homebrew formula
- One repo to maintain release-engineering controls

**Con:**
- `brew tap yolo-labz/wa` URL breaks. Users would need:
  ```bash
  brew install yolo-labz/wa/wa
  ```
  ...after first adding `yolo-labz/wa` as a tap. This works only because Homebrew accepts non-`homebrew-` repo names as taps, but the install command is less ergonomic.
- Future formulas (second yolo-labz Go binary) would need either:
  - their own tap (defeating the consolidation rationale), OR
  - all-binaries-in-one tap living in one of the binary repos (awkward; which repo owns the tap?)
- Loses GoReleaser convention — `brews:` block typically targets an external tap repo, not a same-repo write target. Possible but non-canonical.

**Migration cost:** 1-2 hour engineering. Steps:
1. Update `wa/.goreleaser.yaml` `brews:` target
2. Verify next release publishes `wa/dist/homebrew/wa.rb`
3. Update `wa/README.md` + `wa/CLAUDE.md` with new install URL
4. Add deprecation README to `homebrew-tap` pointing users at new install
5. Archive `homebrew-tap` (keeps URL alive for legacy installs)

### Option 3 — Sunset `homebrew-tap`, use `wa` GitHub Release tarballs directly

Drop Homebrew distribution entirely. Users install via:
```bash
curl -LO https://github.com/yolo-labz/wa/releases/latest/download/wa_$(uname -s)_$(uname -m).tar.gz
```

**Pro:**
- Cleanest: one repo, one release surface, one verification path (`gh attestation verify wa_*.tar.gz --owner yolo-labz`)

**Con:**
- Loses Homebrew users — no `brew upgrade` semantics
- Pedro's macOS muscle memory expects `brew install` for personal tools

**Migration cost:** archival only.

### Option 4 — Extract third repo `Formula/` umbrella

Create `yolo-labz/formula-tap` (rename `homebrew-tap`) as the umbrella tap for ALL future yolo-labz binaries.

**Pro:**
- Future-proof for multi-binary publication
- Same Homebrew convention preserved

**Con:**
- Rename = breaking change (existing `brew tap yolo-labz/wa` users need to re-add)
- Anticipates demand that may not materialize (yolo-labz has only one tap-published binary today: `wa`)

**Migration cost:** 30 min (rename repo, redirect via GitHub).

## Decision (recommended)

**Option 1 — Keep separate.**

Rationale:
- Migration cost is zero
- Current GoReleaser flow already works
- `brew tap yolo-labz/wa` URL is the most ergonomic install path for Pedro's macOS install muscle memory
- Future yolo-labz Go binaries (if shipped) can land in the same tap with no further renames
- Release-engineering tax on `homebrew-tap` is bounded (Sonar + permissions; no SLSA/SBOM/cosign needed for a tap)

**Pedro signs off below.** If approved, Phase 3 PR #12 of the sprint plan executes: `chore: add LICENSE file (Apache-2.0 from wa) + verify HOMEBREW_TAP_GITHUB_TOKEN PAT`.

If Pedro chooses Option 2 instead, Phase 3 PR #12 becomes a merge-execution PR plus a follow-up archival PR on `homebrew-tap`.

## Consequences (recommended option 1)

**Positive:**
- Zero migration cost
- Future multi-binary headroom
- Conventional Homebrew tap URL preserved
- `homebrew-tap` continues as a thin publisher bucket with no maintenance pressure beyond Dependabot/Renovate SHA pins

**Negative:**
- Tier-3 release-engineering tier remains permanent for `homebrew-tap` (no path to Tier-1 since tap repos don't cut releases — SBOM/cosign/SLSA are inapplicable)
- Two repos to track in `phsb5321/notes-work` sprint plans

**Migration cost:** zero.

## Verification

- `git log` evidence:
  ```bash
  # homebrew-tap is a passive recipient
  cd yolo-labz/homebrew-tap && git log --pretty='%h %s' | head -10
  # Mostly: GoReleaser auto-commits + dependabot bumps + initial seed.

  # wa is the active publisher
  cd yolo-labz/wa && grep -A 10 'brews:' .goreleaser.yaml
  # Confirms: brews block targets yolo-labz/homebrew-tap with HOMEBREW_TAP_GITHUB_TOKEN env
  ```

- Capability matrix:
  | Capability | homebrew-tap | wa |
  |---|---|---|
  | Source code (Go) | ❌ | ✅ |
  | Release tarballs | ❌ | ✅ |
  | Homebrew formula (Ruby) | ✅ (Formula/wa.rb) | ❌ (would need to be added under option 2) |
  | GoReleaser pipeline | ❌ | ✅ |
  | SLSA L2 attestation | N/A | ✅ |
  | dual SBOM | N/A | ✅ |
  | cosign keyless | N/A | ✅ |
  | Renovate | ❌ (no actions to update beyond sonar) | ✅ |
  | Sonar | ✅ | ✅ |
  | harden-runner | ✅ audit | ✅ all-WFs |

  No capability overlap; clean separation of concerns.

- Falsification: if a second yolo-labz Go binary ships in the next 6 months AND it does NOT need Homebrew distribution, the multi-formula headroom argument weakens. Re-evaluate then.

## References

- Audit doc: `phsb5321/notes-work` PR #24 — `YOLO-LABZ-AUDIT-2026-05-27.md`
- Canonical release-engineering bar: user global plugin-release-engineering rules
- GoReleaser `brews:` docs: https://goreleaser.com/customization/homebrew/
- Homebrew tap repo naming: https://docs.brew.sh/Taps#repository-naming-conventions
